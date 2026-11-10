-- =============================================================================
-- T367 — Rapprochement du relevé bancaire : relier une ligne à un règlement
--
-- L'écran Relevé bancaire (wbfReleve) gagne trois gestes par ligne :
--
--   Relier  → une fenêtre propose
--             a) les règlements déjà saisis (T140) du même sens et non encore
--                reliés, le plus probable en premier (montant, date) :
--                s0979 pose T142.ReglementId et le statut « Réglé » ;
--             b) les factures encore ouvertes (clients pour un dépôt,
--                fournisseurs pour une sortie) : s0980 enregistre le
--                règlement de la facture (sp_EncaisserFactureClient ou
--                sp_PayerFactureFournisseur, compte de banque 101x de la
--                compagnie, date du relevé) puis relie la ligne. Une seule
--                écriture, pas de doublon.
--   Délier  → s0981 : la ligne redevient « Importé » ; le règlement reste.
--   Ignorer → s0982 : « Ignoré » (frais, loyer…) ; un second clic rétablit.
--
-- Convention Plaid du relevé : montant NÉGATIF = entrée (encaissement),
-- POSITIF = sortie (décaissement).
--
-- s0047GetReleveBancaire renvoie en plus le règlement relié (ReglementInfo).
-- Les anciennes sp_RapprocherEncaissement / sp_RapprocherMouvement ne sont
-- pas utilisées : elles créent un second règlement et échouent à l'appel.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── Lecture du relevé, avec le règlement relié ──────────────────────────────
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
        ,T142.[ReglementId]
        ,T142.[Created]
        ,T142.[CreatedBy]
        ,CASE WHEN r.Id IS NULL THEN NULL
              ELSE CASE WHEN r.Sens = 'ENCAISSEMENT' THEN 'ENC' ELSE 'DEC' END
                   + '|' + CONVERT(VARCHAR(10), r.DateReglement, 23)
                   + '|' + ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, ''))
                   + '|' + ISNULL(docs.Numeros, '')
         END AS ReglementInfo
    FROM [T142ReleveBancaire] T142
    LEFT JOIN [dbo].[T143PlaidAccount] T143
           ON T142.CompteBanque = T143.[AccountId] AND T143.CompanyGUID = T142.CompanyGUID
    LEFT JOIN dbo.T140Reglement r ON r.Id = T142.ReglementId AND r.CompanyGUID = T142.CompanyGUID
    LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
    OUTER APPLY (SELECT STUFF((SELECT ', ' + d.DocumentNumber
                               FROM dbo.T141ReglementDocument rd
                               JOIN dbo.T060Document d ON d.Id = rd.DocumentId
                               WHERE rd.ReglementId = r.Id
                               FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, '') AS Numeros) docs
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

-- ── Les candidats d'une ligne : règlements puis factures ouvertes ──────────
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

    -- 0. La ligne elle-même
    SELECT Id, DateMouvement, Description, Reference, Montant, Statut, ReglementId, @Entree AS Entree
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId;

    -- 1. Règlements du même sens, pas encore reliés à une ligne du relevé
    SELECT TOP (15)
           r.Id, r.DateReglement, r.Montant, r.Reference, r.TypeReglement,
           ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, '')) AS Tiers,
           docs.Numeros,
           CASE WHEN ABS(r.Montant - @Abs) < 0.01 AND ABS(DATEDIFF(DAY, r.DateReglement, @Date)) <= 7 THEN 1 ELSE 0 END AS Probable
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
      AND NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire x
                      WHERE x.CompanyGUID = @CompanyGUID AND x.ReglementId = r.Id)
    ORDER BY ABS(r.Montant - @Abs), ABS(DATEDIFF(DAY, r.DateReglement, @Date)), r.Id DESC;

    -- 2. Factures comptabilisées encore ouvertes (clients si entrée, fournisseurs si sortie)
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
           CASE WHEN ABS(o.Reste - @Abs) < 0.01 THEN 1 ELSE 0 END AS MontantExact,
           CASE WHEN o.Tiers <> '' AND CHARINDEX(UPPER(o.Tiers), @Desc) > 0 THEN 1
                WHEN ISNULL(o.DocumentNumber, '') <> '' AND CHARINDEX(UPPER(o.DocumentNumber), @Desc) > 0 THEN 1
                ELSE 0 END AS NomTrouve
    FROM Ouvertes o
    WHERE o.Reste > 0.005
    ORDER BY CASE WHEN ISNULL(o.DocumentNumber, '') <> '' AND CHARINDEX(UPPER(o.DocumentNumber), @Desc) > 0 THEN 0 ELSE 1 END,
             CASE WHEN ABS(o.Reste - @Abs) < 0.01 THEN 0 ELSE 1 END,
             CASE WHEN o.Tiers <> '' AND CHARINDEX(UPPER(o.Tiers), @Desc) > 0 THEN 0 ELSE 1 END,
             ABS(o.Reste - @Abs), o.DueDate;
END
GO

-- ── Relier une ligne à un règlement existant ────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0979LierReleveReglement
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT,
    @ReglementId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Montant DECIMAL(15, 2), @Lie INT;
    SELECT @Montant = Montant, @Lie = ReglementId
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;

    IF @Montant IS NULL THROW 51030, 'Ligne du relevé introuvable.', 1;
    IF @Lie IS NOT NULL THROW 51031, 'Cette ligne est déjà reliée à un règlement.', 1;

    DECLARE @Sens VARCHAR(20);
    SELECT @Sens = Sens FROM dbo.T140Reglement
    WHERE Id = @ReglementId AND CompanyGUID = @CompanyGUID AND Statut <> 'ANNULE';

    IF @Sens IS NULL THROW 51032, 'Règlement introuvable.', 1;
    IF (@Montant < 0 AND @Sens <> 'ENCAISSEMENT') OR (@Montant >= 0 AND @Sens = 'ENCAISSEMENT')
        THROW 51033, 'Le règlement n''est pas dans le même sens que la ligne du relevé.', 1;
    IF EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire WHERE CompanyGUID = @CompanyGUID AND ReglementId = @ReglementId)
        THROW 51034, 'Ce règlement est déjà relié à une autre ligne du relevé.', 1;

    UPDATE dbo.T142ReleveBancaire
    SET ReglementId = @ReglementId, Statut = 'Réglé'
    WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;

    SELECT @ReglementId AS ReglementId;
END
GO

-- ── Régler une facture ouverte depuis la ligne, puis la relier ─────────────
CREATE OR ALTER PROCEDURE dbo.s0980ReglerFactureDepuisReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT,
    @DocumentId  INT,
    @UserId      INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Montant DECIMAL(15, 2), @Lie INT, @Date DATE, @Ref VARCHAR(200), @Statut VARCHAR(120);
    SELECT @Montant = Montant, @Lie = ReglementId, @Date = DateMouvement,
           @Ref = LEFT(ISNULL(NULLIF(Reference, ''), 'RELEVE-' + CAST(Id AS VARCHAR(20))), 200), @Statut = Statut
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;

    IF @Montant IS NULL THROW 51030, 'Ligne du relevé introuvable.', 1;
    IF @Lie IS NOT NULL THROW 51031, 'Cette ligne est déjà reliée à un règlement.', 1;

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

    DECLARE @Regle DECIMAL(15, 2) = CASE WHEN ABS(@Montant) < @Reste THEN ABS(@Montant) ELSE @Reste END;

    -- Le compte de banque du grand livre (101x), comme la fenêtre d'encaissement
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

    UPDATE dbo.T142ReleveBancaire
    SET ReglementId = @ReglementId, Statut = 'Réglé'
    WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;

    SELECT @ReglementId AS ReglementId, @Regle AS MontantRegle, @Reste - @Regle AS ResteFacture;
END
GO

-- ── Délier ──────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0981DelierReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T142ReleveBancaire
    SET ReglementId = NULL, Statut = 'Importé'
    WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    IF @@ROWCOUNT = 0 THROW 51030, 'Ligne du relevé introuvable.', 1;
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
    IF EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire
               WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID AND ReglementId IS NOT NULL)
        THROW 51031, 'Cette ligne est reliée à un règlement : déliez-la d''abord.', 1;

    UPDATE dbo.T142ReleveBancaire
    SET Statut = CASE WHEN @Ignorer = 1 THEN 'Ignoré' ELSE 'Importé' END
    WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    IF @@ROWCOUNT = 0 THROW 51030, 'Ligne du relevé introuvable.', 1;
    SELECT @ReleveId AS ReleveId;
END
GO
