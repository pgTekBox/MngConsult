-- =============================================================================
-- T367 — Rapprochement du relevé bancaire : relier une ligne à ses pièces
--
-- L'écran Relevé bancaire (wbfReleve) gagne trois gestes par ligne :
--
--   Relier  → une fenêtre montre le montant de la ligne, ce qui est déjà
--             relié, le reste, et propose
--             a) les règlements déjà saisis (T140) du même sens et non encore
--                reliés, le plus probable en premier (montant, date) : s0979 ;
--             b) les factures encore ouvertes (clients pour un dépôt,
--                fournisseurs pour une sortie) : s0980 enregistre le
--                règlement de la facture pour le reste (sp_EncaisserFactureClient
--                ou sp_PayerFactureFournisseur, compte 101x, date du relevé)
--                puis le relie ;
--             c) inscrire le reste aux livres sur un compte choisi : s0989 (T370).
--             Une ligne porte plusieurs pièces (T208ReleveLien, T370) ; elle est
--             « Réglé » quand elles couvrent son montant, « Partiel » avant.
--   Délier  → s0981 : retire toutes les pièces ; elles restent aux livres.
--   Ignorer → s0982 : « Ignoré » ; un second clic rétablit.
--
-- Convention Plaid du relevé : montant NÉGATIF = entrée (encaissement),
-- POSITIF = sortie (décaissement).
--
-- Les périodes conciliées et clôturées sont verrouillées (s0987, T368).
-- Les anciennes sp_RapprocherEncaissement / sp_RapprocherMouvement ne sont
-- pas utilisées : elles créent un second règlement et échouent à l'appel.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── Lecture du relevé, avec ce qui est relié ───────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0047GetReleveBancaire
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Search         NVARCHAR(200) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
         T142.[Id]
        ,T142.CompteBanque
        ,T143.AccountName
        ,COALESCE(T143.[BankName], '') + ' ' + COALESCE(T143.AccountName, '') + ' ' + COALESCE(T143.AccountNumber, '') AS FullName
        ,T143.[BankName]
        ,T142.[ReleveBancaireGUID]
        ,T142.[CompanyGUID]
        ,T142.[DateMouvement]
        ,T142.[Description]
        ,T142.[Reference]
        ,T142.[Montant]
        ,T142.[Statut]
        ,T142.[Created]
        ,T142.[CreatedBy]
        ,liens.Nb AS NbLiens
        ,ISNULL(liens.Relie, 0) AS Relie
        ,liens.Pieces AS ReglementInfo     -- « Encaissement · Client · FCD-0030 | Écriture REL-… · 4000 Ventes »
    FROM [T142ReleveBancaire] T142
    LEFT JOIN [dbo].[T143PlaidAccount] T143
           ON T142.CompteBanque = T143.[AccountId] AND T143.CompanyGUID = T142.CompanyGUID
    OUTER APPLY (
        SELECT COUNT(*) AS Nb, SUM(l.Montant) AS Relie,
               STUFF((SELECT ' | ' +
                         CASE WHEN l2.ReglementId IS NOT NULL
                              THEN CASE WHEN r.Sens = 'ENCAISSEMENT' THEN 'ENC' ELSE 'DEC' END
                                   + '~' + ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, ''))
                                   + '~' + ISNULL(STUFF((SELECT ', ' + d.DocumentNumber
                                                        FROM dbo.T141ReglementDocument rd
                                                        JOIN dbo.T060Document d ON d.Id = rd.DocumentId
                                                        WHERE rd.ReglementId = r.Id
                                                        FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, ''), '')
                              ELSE 'ECR~' + ISNULL(e.NumeroPiece, '') + '~' + ISNULL(pc.compte + ' ' + pc.Nom, '')
                         END
                      FROM dbo.T208ReleveLien l2
                      LEFT JOIN dbo.T140Reglement r ON r.Id = l2.ReglementId
                      LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
                      LEFT JOIN dbo.T135Ecritures e ON e.Id = l2.EcrituresId
                      OUTER APPLY (SELECT TOP 1 c.compte, c.Nom FROM dbo.T136LignesEcriture le
                                   JOIN dbo.T121PlanComptable c ON c.Id = le.PlanComptableId
                                   WHERE le.EcrituresId = e.Id AND c.compte NOT LIKE '101%' ORDER BY le.Ordre) pc
                      WHERE l2.ReleveId = T142.Id
                      ORDER BY l2.Id
                      FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 3, '') AS Pieces
        FROM dbo.T208ReleveLien l
        WHERE l.ReleveId = T142.Id
    ) liens
    WHERE T142.CompanyGUID = @CompanyGUID
      AND (
            @Search = ''
            OR T142.Description LIKE '%' + @Search + '%'
            OR T142.Reference LIKE '%' + @Search + '%'
            OR T142.CompteBanque LIKE '%' + @Search + '%'
            OR T142.Statut LIKE '%' + @Search + '%'
          )
    ORDER BY T142.DateMouvement DESC, T142.Id DESC;
END
GO

-- ── Les candidats d'une ligne ──────────────────────────────────────────────
-- 0 la ligne (montant, relié, reste) ; 1 les pièces déjà reliées ;
-- 2 les règlements libres du même sens ; 3 les factures ouvertes ;
-- 4 les comptes du plan comptable pour inscrire le reste aux livres.
CREATE OR ALTER PROCEDURE dbo.s0978GetReleveCandidats
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Montant DECIMAL(15, 2), @Date DATE, @Desc VARCHAR(500);
    SELECT @Montant = Montant, @Date = DateMouvement, @Desc = UPPER(ISNULL(Description, ''))
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;

    IF @Montant IS NULL
        THROW 51030, 'Ligne du relevé introuvable.', 1;

    DECLARE @Entree BIT = CASE WHEN @Montant < 0 THEN 1 ELSE 0 END;
    DECLARE @Abs DECIMAL(15, 2) = ABS(@Montant);
    DECLARE @Relie DECIMAL(15, 2) = dbo.fReleveRelie(@ReleveId);
    DECLARE @Reste DECIMAL(15, 2) = @Abs - @Relie;
    DECLARE @Verrou DATE = dbo.fConciliationVerrou(@CompanyGUID,
                              (SELECT CompteBanque FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId));

    -- 0. La ligne elle-même
    SELECT Id, DateMouvement, Description, Reference, Montant, Statut, @Entree AS Entree,
           @Relie AS Relie, @Reste AS Reste,
           CASE WHEN @Verrou IS NOT NULL AND DateMouvement <= @Verrou THEN 1 ELSE 0 END AS Verrouillee
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId;

    -- 1. Les pièces déjà reliées
    SELECT l.Id AS LienId, l.Montant,
           CASE WHEN l.ReglementId IS NOT NULL THEN 'REG' ELSE 'ECR' END AS Genre,
           CASE WHEN l.ReglementId IS NOT NULL
                THEN ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, ''))
                ELSE ISNULL(e.Libelle, '') END AS Libelle,
           CASE WHEN l.ReglementId IS NOT NULL
                THEN 'ENC-' + RIGHT('000000' + CAST(r.Id AS VARCHAR(10)), 6)
                     + ISNULL(' · ' + STUFF((SELECT ', ' + d.DocumentNumber FROM dbo.T141ReglementDocument rd
                                            JOIN dbo.T060Document d ON d.Id = rd.DocumentId
                                            WHERE rd.ReglementId = r.Id FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, ''), '')
                ELSE ISNULL(e.NumeroPiece, '') + ISNULL(' · ' + pc.compte + ' ' + pc.Nom, '') END AS Detail
    FROM dbo.T208ReleveLien l
    LEFT JOIN dbo.T140Reglement r ON r.Id = l.ReglementId
    LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
    LEFT JOIN dbo.T135Ecritures e ON e.Id = l.EcrituresId
    OUTER APPLY (SELECT TOP 1 c.compte, c.Nom FROM dbo.T136LignesEcriture le
                 JOIN dbo.T121PlanComptable c ON c.Id = le.PlanComptableId
                 WHERE le.EcrituresId = e.Id AND c.compte NOT LIKE '101%' ORDER BY le.Ordre) pc
    WHERE l.ReleveId = @ReleveId AND l.CompanyGUID = @CompanyGUID
    ORDER BY l.Id;

    -- 2. Règlements du même sens, pas encore reliés au relevé
    SELECT TOP (15)
           r.Id, r.DateReglement, r.Montant, r.Reference, r.TypeReglement,
           ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, '')) AS Tiers,
           docs.Numeros,
           CASE WHEN ABS(r.Montant - @Reste) < 0.01 AND ABS(DATEDIFF(DAY, r.DateReglement, @Date)) <= 7 THEN 1 ELSE 0 END AS Probable,
           CASE WHEN r.Montant <= @Reste + 0.005 THEN 1 ELSE 0 END AS Possible
    FROM dbo.T140Reglement r
    LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
    OUTER APPLY (SELECT STUFF((SELECT ', ' + d.DocumentNumber
                               FROM dbo.T141ReglementDocument rd
                               JOIN dbo.T060Document d ON d.Id = rd.DocumentId
                               WHERE rd.ReglementId = r.Id
                               FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, '') AS Numeros) docs
    WHERE r.CompanyGUID = @CompanyGUID
      AND r.Statut <> 'ANNULE'
      AND ((@Entree = 1 AND r.Sens = 'ENCAISSEMENT') OR (@Entree = 0 AND r.Sens <> 'ENCAISSEMENT'))
      AND NOT EXISTS (SELECT 1 FROM dbo.T208ReleveLien x WHERE x.ReglementId = r.Id)
    ORDER BY CASE WHEN r.Montant <= @Reste + 0.005 THEN 0 ELSE 1 END,
             ABS(r.Montant - @Reste), ABS(DATEDIFF(DAY, r.DateReglement, @Date)), r.Id DESC;

    -- 3. Factures comptabilisées encore ouvertes (clients si entrée, fournisseurs si sortie)
    ;WITH Payes AS (
        SELECT rd.DocumentId, SUM(rd.MontantImpute) AS Paye
        FROM dbo.T141ReglementDocument rd
        JOIN dbo.T140Reglement r ON r.Id = rd.ReglementId
        WHERE r.CompanyGUID = @CompanyGUID AND r.Statut <> 'ANNULE'
        GROUP BY rd.DocumentId
    ), Ouvertes AS (
        SELECT d.Id, d.DocumentNumber, d.DueDate,
               ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, '')) AS Tiers,
               CAST(ISNULL(d.Total, 0) - ISNULL(pa.Paye, 0) AS DECIMAL(15, 2)) AS Reste
        FROM dbo.T060Document d
        LEFT JOIN dbo.T050Party p ON p.PartyGUID = d.PartyGUID
        LEFT JOIN Payes pa ON pa.DocumentId = d.Id
        WHERE d.CompanyGUID = @CompanyGUID
          AND d.DocumentTypeId = CASE WHEN @Entree = 1 THEN 1 ELSE 2 END
          AND d.ComptabilisationStatus = 'COMPTABILISE'
    )
    SELECT TOP (15) o.Id, o.DocumentNumber, o.DueDate, o.Tiers, o.Reste,
           CASE WHEN ABS(o.Reste - @Reste) < 0.01 THEN 1 ELSE 0 END AS MontantExact,
           CASE WHEN o.Tiers <> '' AND CHARINDEX(UPPER(o.Tiers), @Desc) > 0 THEN 1
                WHEN ISNULL(o.DocumentNumber, '') <> '' AND CHARINDEX(UPPER(o.DocumentNumber), @Desc) > 0 THEN 1
                ELSE 0 END AS NomTrouve
    FROM Ouvertes o
    WHERE o.Reste > 0.005
    ORDER BY CASE WHEN ISNULL(o.DocumentNumber, '') <> '' AND CHARINDEX(UPPER(o.DocumentNumber), @Desc) > 0 THEN 0 ELSE 1 END,
             CASE WHEN ABS(o.Reste - @Reste) < 0.01 THEN 0 ELSE 1 END,
             CASE WHEN o.Tiers <> '' AND CHARINDEX(UPPER(o.Tiers), @Desc) > 0 THEN 0 ELSE 1 END,
             ABS(o.Reste - @Reste), o.DueDate;

    -- 4. Comptes pour inscrire le reste aux livres (pas les comptes de banque 101x).
    --    Le plus utilisé depuis le relevé pour ce sens vient en premier (Suggere = 1).
    SELECT c.Id, c.compte AS Compte, c.Nom,
           CASE WHEN c.Id = (SELECT TOP 1 le.PlanComptableId
                             FROM dbo.T208ReleveLien l
                             JOIN dbo.T142ReleveBancaire t ON t.Id = l.ReleveId
                             JOIN dbo.T136LignesEcriture le ON le.EcrituresId = l.EcrituresId
                             JOIN dbo.T121PlanComptable c2 ON c2.Id = le.PlanComptableId AND c2.compte NOT LIKE '101%'
                             WHERE l.CompanyGUID = @CompanyGUID AND l.EcrituresId IS NOT NULL
                               AND SIGN(t.Montant) = SIGN(@Montant)
                               AND LEFT(UPPER(t.Description), 12) = LEFT(@Desc, 12)
                             ORDER BY l.Id DESC) THEN 1 ELSE 0 END AS Suggere
    FROM dbo.T121PlanComptable c
    WHERE c.CompanyGUID = @CompanyGUID AND c.Actif = 1 AND c.compte NOT LIKE '101%'
    ORDER BY c.compte;
END
GO

-- ── Relier un règlement existant à la ligne ────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0979LierReleveReglement
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT,
    @ReglementId INT,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Période déjà conciliée et clôturée (T368) : la ligne ne bouge plus
    EXEC dbo.s0987VerifierVerrouReleve @CompanyGUID, @ReleveId;

    DECLARE @Montant DECIMAL(15, 2);
    SELECT @Montant = Montant FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    IF @Montant IS NULL THROW 51030, 'Ligne du relevé introuvable.', 1;

    DECLARE @Sens VARCHAR(20), @MontantReg DECIMAL(15, 2);
    SELECT @Sens = Sens, @MontantReg = Montant FROM dbo.T140Reglement
    WHERE Id = @ReglementId AND CompanyGUID = @CompanyGUID AND Statut <> 'ANNULE';

    IF @Sens IS NULL THROW 51032, 'Règlement introuvable.', 1;
    IF (@Montant < 0 AND @Sens <> 'ENCAISSEMENT') OR (@Montant >= 0 AND @Sens = 'ENCAISSEMENT')
        THROW 51033, 'Le règlement n''est pas dans le même sens que la ligne du relevé.', 1;
    IF EXISTS (SELECT 1 FROM dbo.T208ReleveLien WHERE ReglementId = @ReglementId)
        THROW 51034, 'Ce règlement est déjà relié à une ligne du relevé.', 1;

    DECLARE @Reste DECIMAL(15, 2) = ABS(@Montant) - dbo.fReleveRelie(@ReleveId);
    IF @MontantReg > @Reste + 0.005
    BEGIN
        DECLARE @Msg NVARCHAR(300) = N'Ce règlement (' + CONVERT(NVARCHAR(30), @MontantReg)
            + N' $) dépasse le reste à relier de la ligne (' + CONVERT(NVARCHAR(30), @Reste) + N' $).';
        THROW 51035, @Msg, 1;
    END

    INSERT INTO dbo.T208ReleveLien (CompanyGUID, ReleveId, ReglementId, Montant, CreatedBy)
    VALUES (@CompanyGUID, @ReleveId, @ReglementId, @MontantReg, @UserId);

    EXEC dbo.s0991MajStatutReleve @CompanyGUID, @ReleveId;
    SELECT @ReglementId AS ReglementId, ABS(@Montant) - dbo.fReleveRelie(@ReleveId) AS Reste;
END
GO

-- ── Régler une facture ouverte depuis la ligne (pour le reste), puis relier ─
CREATE OR ALTER PROCEDURE dbo.s0980ReglerFactureDepuisReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT,
    @DocumentId  INT,
    @UserId      INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    -- Période déjà conciliée et clôturée (T368) : la ligne ne bouge plus
    EXEC dbo.s0987VerifierVerrouReleve @CompanyGUID, @ReleveId;

    DECLARE @Montant DECIMAL(15, 2), @Date DATE, @Ref VARCHAR(200);
    SELECT @Montant = Montant, @Date = DateMouvement,
           @Ref = LEFT(ISNULL(NULLIF(Reference, ''), 'RELEVE-' + CAST(Id AS VARCHAR(20))), 200)
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;

    IF @Montant IS NULL THROW 51030, 'Ligne du relevé introuvable.', 1;

    DECLARE @ResteLigne DECIMAL(15, 2) = ABS(@Montant) - dbo.fReleveRelie(@ReleveId);
    IF @ResteLigne <= 0.005 THROW 51070, 'Cette ligne est déjà entièrement reliée.', 1;

    DECLARE @Entree BIT = CASE WHEN @Montant < 0 THEN 1 ELSE 0 END;

    DECLARE @Total DECIMAL(15, 2), @Type INT;
    SELECT @Total = CAST(ISNULL(Total, 0) AS DECIMAL(15, 2)), @Type = DocumentTypeId
    FROM dbo.T060Document
    WHERE Id = @DocumentId AND CompanyGUID = @CompanyGUID AND ComptabilisationStatus = 'COMPTABILISE';

    IF @Total IS NULL THROW 51035, 'Facture introuvable ou non comptabilisée.', 1;
    IF @Type <> CASE WHEN @Entree = 1 THEN 1 ELSE 2 END
        THROW 51036, 'Un dépôt se relie à une facture client, une sortie à une facture fournisseur.', 1;

    DECLARE @Reste DECIMAL(15, 2) = @Total - ISNULL((
        SELECT SUM(rd.MontantImpute) FROM dbo.T141ReglementDocument rd
        JOIN dbo.T140Reglement r ON r.Id = rd.ReglementId
        WHERE rd.DocumentId = @DocumentId AND r.CompanyGUID = @CompanyGUID AND r.Statut <> 'ANNULE'), 0);

    IF @Reste <= 0.005 THROW 51037, 'Cette facture est déjà payée.', 1;

    -- Le règlement couvre le plus petit des deux : le reste de la ligne, le reste de la facture
    DECLARE @Regle DECIMAL(15, 2) = CASE WHEN @ResteLigne < @Reste THEN @ResteLigne ELSE @Reste END;

    DECLARE @CompteGL VARCHAR(20) = (SELECT TOP 1 c.compte FROM dbo.T121PlanComptable c
                                     WHERE c.CompanyGUID = @CompanyGUID AND c.Actif = 1 AND c.compte LIKE '101%'
                                     ORDER BY c.compte);
    IF @CompteGL IS NULL THROW 51038, 'Aucun compte de banque (101x) dans le plan comptable.', 1;

    DECLARE @Avant INT = ISNULL((SELECT MAX(Id) FROM dbo.T140Reglement WHERE CompanyGUID = @CompanyGUID), 0);

    IF @Entree = 1
        EXEC dbo.sp_EncaisserFactureClient
             @DocumentId = @DocumentId, @CompanyGUID = @CompanyGUID, @MontantEncaisse = @Regle,
             @DateEncaissement = @Date, @TypeReglement = 'VIREMENT', @CompteBanque = @CompteGL,
             @Reference = @Ref, @UserId = @UserId;
    ELSE
        EXEC dbo.sp_PayerFactureFournisseur
             @DocumentId = @DocumentId, @CompanyGUID = @CompanyGUID, @MontantPaye = @Regle,
             @DatePaiement = @Date, @TypeReglement = 'VIREMENT', @CompteBanque = @CompteGL,
             @Reference = @Ref, @UserId = @UserId;

    DECLARE @ReglementId INT = (SELECT MAX(r.Id) FROM dbo.T140Reglement r
                                JOIN dbo.T141ReglementDocument rd ON rd.ReglementId = r.Id
                                WHERE r.CompanyGUID = @CompanyGUID AND rd.DocumentId = @DocumentId AND r.Id > @Avant);

    IF @ReglementId IS NULL THROW 51039, 'Le règlement n''a pas été créé.', 1;

    INSERT INTO dbo.T208ReleveLien (CompanyGUID, ReleveId, ReglementId, Montant, CreatedBy)
    VALUES (@CompanyGUID, @ReleveId, @ReglementId, @Regle, @UserId);

    EXEC dbo.s0991MajStatutReleve @CompanyGUID, @ReleveId;

    SELECT @ReglementId AS ReglementId, @Regle AS MontantRegle, @Reste - @Regle AS ResteFacture,
           ABS(@Montant) - dbo.fReleveRelie(@ReleveId) AS Reste;
END
GO

-- ── Délier : retirer toutes les pièces de la ligne ─────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0981DelierReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Période déjà conciliée et clôturée (T368) : la ligne ne bouge plus
    EXEC dbo.s0987VerifierVerrouReleve @CompanyGUID, @ReleveId;
    IF NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID)
        THROW 51030, 'Ligne du relevé introuvable.', 1;
    DELETE FROM dbo.T208ReleveLien WHERE ReleveId = @ReleveId AND CompanyGUID = @CompanyGUID;
    UPDATE dbo.T142ReleveBancaire SET Statut = 'Importé' WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    SELECT @ReleveId AS ReleveId;
END
GO

-- ── Ignorer / rétablir ──────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0982IgnorerReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT,
    @Ignorer     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    -- Période déjà conciliée et clôturée (T368) : la ligne ne bouge plus
    EXEC dbo.s0987VerifierVerrouReleve @CompanyGUID, @ReleveId;
    IF EXISTS (SELECT 1 FROM dbo.T208ReleveLien WHERE ReleveId = @ReleveId AND CompanyGUID = @CompanyGUID)
        THROW 51031, 'Cette ligne est reliée à des pièces : déliez-la d''abord.', 1;

    UPDATE dbo.T142ReleveBancaire
    SET Statut = CASE WHEN @Ignorer = 1 THEN 'Ignoré' ELSE 'Importé' END
    WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    IF @@ROWCOUNT = 0 THROW 51030, 'Ligne du relevé introuvable.', 1;
    SELECT @ReleveId AS ReleveId;
END
GO
