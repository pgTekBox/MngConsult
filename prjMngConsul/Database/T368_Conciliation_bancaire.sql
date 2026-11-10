-- =============================================================================
-- T368 — Conciliation bancaire par période (date de début et de fin du relevé)
--
-- L'écran Relevé bancaire (wbfReleve) choisit une période « du … au … » et
-- calcule la conciliation du compte bancaire avec le compte de banque du grand
-- livre (101x) :
--
--   Solde du relevé à la fin de la période
--     + dépôts en circulation       (encaissements aux livres, pas encore au relevé)
--     − paiements en circulation    (décaissements aux livres, pas encore au relevé)
--   = solde bancaire rajusté
--
--   Solde aux livres (101x, écritures validées) à la fin de la période
--     + entrées du relevé non inscrites aux livres (lignes non reliées)
--     − sorties du relevé non inscrites aux livres
--   = solde aux livres rajusté
--
--   Écart = solde bancaire rajusté − solde aux livres rajusté (0 = concilié).
--
-- Le solde du relevé à une date se déduit du solde courant du compte
-- (T143PlaidAccount.BalanceCurrent) et des mouvements postérieurs ; convention
-- Plaid : un montant positif est une sortie (le solde baisse).
--
-- Une conciliation se CLÔTURE (T207ConciliationBancaire, photo des soldes) :
-- les lignes du relevé datées jusqu'à la fin de la dernière période clôturée
-- ne peuvent plus être reliées, déliées ni ignorées (s0979-s0982 vérifient).
-- Seule la DERNIÈRE conciliation peut être rouverte (s0986).
--
-- Procédures : s0983 (calculer), s0984 (clôturer), s0985 (historique),
--              s0986 (rouvrir), fConciliationVerrou (date verrouillée).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T207ConciliationBancaire') IS NULL
CREATE TABLE dbo.T207ConciliationBancaire (
    Id                   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T207ConciliationBancaire PRIMARY KEY,
    CompanyGUID          UNIQUEIDENTIFIER NOT NULL,
    CompteBanque         NVARCHAR(200) NOT NULL,     -- le compte du relevé (T142.CompteBanque)
    CompteGL             VARCHAR(20) NOT NULL,       -- le compte de banque du grand livre (101x)
    DateDebut            DATE NOT NULL,
    DateFin              DATE NOT NULL,
    SoldeOuverture       DECIMAL(15, 2) NOT NULL,    -- solde du relevé au début
    SoldeFermeture       DECIMAL(15, 2) NOT NULL,    -- solde du relevé à la fin
    DepotsCirculation    DECIMAL(15, 2) NOT NULL,
    PaiementsCirculation DECIMAL(15, 2) NOT NULL,
    SoldeLivres          DECIMAL(15, 2) NOT NULL,
    EntreesNonInscrites  DECIMAL(15, 2) NOT NULL,
    SortiesNonInscrites  DECIMAL(15, 2) NOT NULL,
    Ecart                DECIMAL(15, 2) NOT NULL,
    Note                 NVARCHAR(500) NULL,
    Created              DATETIME NOT NULL CONSTRAINT DF_T207_Created DEFAULT (GETDATE()),
    CreatedBy            INT NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T207_Company_Compte_Fin')
    CREATE UNIQUE INDEX IX_T207_Company_Compte_Fin ON dbo.T207ConciliationBancaire (CompanyGUID, CompteBanque, DateFin);
GO

-- ── La date jusqu'à laquelle le relevé d'un compte est verrouillé ──────────
CREATE OR ALTER FUNCTION dbo.fConciliationVerrou (@CompanyGUID UNIQUEIDENTIFIER, @CompteBanque NVARCHAR(200))
RETURNS DATE
AS
BEGIN
    RETURN (SELECT MAX(DateFin) FROM dbo.T207ConciliationBancaire
            WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque);
END
GO

-- ── Calcul de la conciliation d'une période ────────────────────────────────
-- Résultats : 0 résumé ; 1 en circulation (aux livres, pas au relevé) ;
--             2 non inscrits aux livres (au relevé, pas aux livres) ;
--             3 comptes du relevé disponibles.
CREATE OR ALTER PROCEDURE dbo.s0983GetConciliation
    @CompanyGUID  UNIQUEIDENTIFIER,
    @DateDebut    DATE,
    @DateFin      DATE,
    @CompteBanque NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DateFin < @DateDebut THROW 51040, 'La date de fin précède la date de début.', 1;

    -- Le compte du relevé : celui demandé, sinon le premier compte actif qui a des mouvements
    IF @CompteBanque IS NULL OR @CompteBanque = ''
        SELECT TOP 1 @CompteBanque = a.AccountId
        FROM dbo.T143PlaidAccount a
        WHERE a.CompanyGUID = @CompanyGUID AND a.Active = 1
        ORDER BY CASE WHEN EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire x
                                   WHERE x.CompanyGUID = @CompanyGUID AND x.CompteBanque = a.AccountId) THEN 0 ELSE 1 END, a.Id;

    DECLARE @Solde DECIMAL(15, 2), @NomCompte NVARCHAR(400);
    SELECT TOP 1 @Solde = ISNULL(BalanceCurrent, 0),
                 @NomCompte = LTRIM(ISNULL(BankName, '') + ' ' + ISNULL(AccountName, '') + ' ' + ISNULL(AccountNumber, ''))
    FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID AND AccountId = @CompteBanque;

    -- Le compte de banque du grand livre (101x), comme les règlements
    DECLARE @GL VARCHAR(20), @GLId INT, @GLNom NVARCHAR(200);
    SELECT TOP 1 @GL = c.compte, @GLId = c.Id, @GLNom = c.Nom
    FROM dbo.T121PlanComptable c
    WHERE c.CompanyGUID = @CompanyGUID AND c.Actif = 1 AND c.compte LIKE '101%'
    ORDER BY c.compte;

    -- Soldes du relevé (convention Plaid : positif = sortie)
    DECLARE @SoldeOuv DECIMAL(15, 2) = ISNULL(@Solde, 0) + ISNULL((SELECT SUM(Montant) FROM dbo.T142ReleveBancaire
        WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque AND DateMouvement >= @DateDebut), 0);
    DECLARE @SoldeFin DECIMAL(15, 2) = ISNULL(@Solde, 0) + ISNULL((SELECT SUM(Montant) FROM dbo.T142ReleveBancaire
        WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque AND DateMouvement > @DateFin), 0);

    DECLARE @Entrees DECIMAL(15, 2), @Sorties DECIMAL(15, 2), @NbMouv INT;
    SELECT @Entrees = ISNULL(SUM(CASE WHEN Montant < 0 THEN -Montant ELSE 0 END), 0),
           @Sorties = ISNULL(SUM(CASE WHEN Montant > 0 THEN Montant ELSE 0 END), 0),
           @NbMouv = COUNT(*)
    FROM dbo.T142ReleveBancaire
    WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque
      AND DateMouvement BETWEEN @DateDebut AND @DateFin;

    -- Solde aux livres à la fin (écritures validées)
    DECLARE @Livres DECIMAL(15, 2) = ISNULL((
        SELECT SUM(l.MontantDebit - l.MontantCredit)
        FROM dbo.T136LignesEcriture l
        JOIN dbo.T135Ecritures e ON e.Id = l.EcrituresId
        WHERE e.CompanyGUID = @CompanyGUID AND e.Statut = 'VALIDEE'
          AND l.PlanComptableId = @GLId AND CAST(e.DateEcriture AS DATE) <= @DateFin), 0);

    -- En circulation : règlements comptabilisés sur ce compte, datés au plus tard à
    -- la fin, qu'aucune ligne du relevé datée au plus tard à la fin ne porte.
    DECLARE @Circ TABLE (Id INT, DateReglement DATE, Sens VARCHAR(20), Montant DECIMAL(15, 2),
                         Tiers NVARCHAR(400), Numeros VARCHAR(MAX), Reference VARCHAR(200));
    INSERT INTO @Circ
    SELECT r.Id, r.DateReglement, r.Sens, r.Montant,
           ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, '')),
           STUFF((SELECT ', ' + d.DocumentNumber FROM dbo.T141ReglementDocument rd
                  JOIN dbo.T060Document d ON d.Id = rd.DocumentId
                  WHERE rd.ReglementId = r.Id FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, ''),
           r.Reference
    FROM dbo.T140Reglement r
    LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
    WHERE r.CompanyGUID = @CompanyGUID AND r.Statut <> 'ANNULE' AND r.EcrituresId IS NOT NULL
      AND r.CompteBanque = @GL AND r.DateReglement <= @DateFin
      AND NOT EXISTS (SELECT 1 FROM dbo.T208ReleveLien l JOIN dbo.T142ReleveBancaire x ON x.Id = l.ReleveId
                      WHERE l.ReglementId = r.Id AND x.DateMouvement <= @DateFin);

    -- Non inscrits aux livres : lignes du relevé datées au plus tard à la fin, sans règlement
    DECLARE @NonInscrits TABLE (Id INT, DateMouvement DATE, Description VARCHAR(500), Montant DECIMAL(15, 2), Statut VARCHAR(120));
    INSERT INTO @NonInscrits
    -- la part de chaque ligne que ses pièces (T208, T370) ne couvrent pas, avec le signe de la ligne
    SELECT Id, DateMouvement, Description,
           Montant - SIGN(Montant) * dbo.fReleveRelieAu(Id, @DateFin) AS Montant, Statut
    FROM dbo.T142ReleveBancaire
    WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque
      AND DateMouvement <= @DateFin
      AND ABS(Montant) - dbo.fReleveRelieAu(Id, @DateFin) > 0.005;

    DECLARE @DepCirc DECIMAL(15, 2) = ISNULL((SELECT SUM(Montant) FROM @Circ WHERE Sens = 'ENCAISSEMENT'), 0);
    DECLARE @PaieCirc DECIMAL(15, 2) = ISNULL((SELECT SUM(Montant) FROM @Circ WHERE Sens <> 'ENCAISSEMENT'), 0);
    DECLARE @EntNI DECIMAL(15, 2) = ISNULL((SELECT SUM(-Montant) FROM @NonInscrits WHERE Montant < 0), 0);
    DECLARE @SorNI DECIMAL(15, 2) = ISNULL((SELECT SUM(Montant) FROM @NonInscrits WHERE Montant > 0), 0);

    DECLARE @BanqueRajuste DECIMAL(15, 2) = @SoldeFin + @DepCirc - @PaieCirc;
    DECLARE @LivresRajuste DECIMAL(15, 2) = @Livres + @EntNI - @SorNI;

    DECLARE @Verrou DATE = dbo.fConciliationVerrou(@CompanyGUID, @CompteBanque);
    DECLARE @Cloturee INT = (SELECT Id FROM dbo.T207ConciliationBancaire
                             WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque
                               AND DateDebut = @DateDebut AND DateFin = @DateFin);

    -- 0. Résumé
    SELECT @CompteBanque AS CompteBanque, @NomCompte AS NomCompte, @GL AS CompteGL, @GLNom AS NomGL,
           @DateDebut AS DateDebut, @DateFin AS DateFin,
           @SoldeOuv AS SoldeOuverture, @Entrees AS Entrees, @Sorties AS Sorties, @NbMouv AS NbMouvements,
           @SoldeFin AS SoldeFermeture,
           @DepCirc AS DepotsCirculation, @PaieCirc AS PaiementsCirculation, @BanqueRajuste AS BanqueRajuste,
           @Livres AS SoldeLivres, @EntNI AS EntreesNonInscrites, @SorNI AS SortiesNonInscrites, @LivresRajuste AS LivresRajuste,
           @BanqueRajuste - @LivresRajuste AS Ecart,
           (SELECT COUNT(*) FROM @Circ) AS NbCirculation, (SELECT COUNT(*) FROM @NonInscrits) AS NbNonInscrits,
           @Verrou AS VerrouJusquau, @Cloturee AS ConciliationId;

    -- 1. En circulation
    SELECT * FROM @Circ ORDER BY DateReglement DESC, Id DESC;

    -- 2. Non inscrits aux livres
    SELECT * FROM @NonInscrits ORDER BY DateMouvement DESC, Id DESC;

    -- 3. Comptes du relevé
    SELECT AccountId, LTRIM(ISNULL(BankName, '') + ' ' + ISNULL(AccountName, '') + ' ' + ISNULL(AccountNumber, '')) AS Nom
    FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID AND Active = 1 ORDER BY Id;
END
GO

-- ── Clôturer la conciliation d'une période ─────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0984CloturerConciliation
    @CompanyGUID  UNIQUEIDENTIFIER,
    @DateDebut    DATE,
    @DateFin      DATE,
    @CompteBanque NVARCHAR(200),
    @Note         NVARCHAR(500) = NULL,
    @UserId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DateFin > CAST(GETDATE() AS DATE) THROW 51041, 'On ne clôture pas une période qui n''est pas terminée.', 1;

    DECLARE @Verrou DATE = dbo.fConciliationVerrou(@CompanyGUID, @CompteBanque);
    IF @Verrou IS NOT NULL AND @DateDebut <= @Verrou
        THROW 51042, 'Cette période chevauche une conciliation déjà clôturée.', 1;
    IF @Verrou IS NOT NULL AND @DateDebut > DATEADD(DAY, 1, @Verrou)
        THROW 51043, 'La période doit commencer le lendemain de la dernière conciliation clôturée.', 1;

    -- Recalcul identique à s0983 (le résumé), photographié dans T207
    DECLARE @SoldeCourant DECIMAL(15, 2) = ISNULL((SELECT TOP 1 BalanceCurrent FROM dbo.T143PlaidAccount
                                                   WHERE CompanyGUID = @CompanyGUID AND AccountId = @CompteBanque), 0);
    DECLARE @GL VARCHAR(20), @GLId INT;
    SELECT TOP 1 @GL = c.compte, @GLId = c.Id FROM dbo.T121PlanComptable c
    WHERE c.CompanyGUID = @CompanyGUID AND c.Actif = 1 AND c.compte LIKE '101%' ORDER BY c.compte;
    IF @GL IS NULL THROW 51038, 'Aucun compte de banque (101x) dans le plan comptable.', 1;

    DECLARE @SoldeOuv DECIMAL(15, 2) = @SoldeCourant + ISNULL((SELECT SUM(Montant) FROM dbo.T142ReleveBancaire
        WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque AND DateMouvement >= @DateDebut), 0);
    DECLARE @SoldeFin DECIMAL(15, 2) = @SoldeCourant + ISNULL((SELECT SUM(Montant) FROM dbo.T142ReleveBancaire
        WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque AND DateMouvement > @DateFin), 0);
    DECLARE @Livres DECIMAL(15, 2) = ISNULL((
        SELECT SUM(l.MontantDebit - l.MontantCredit) FROM dbo.T136LignesEcriture l
        JOIN dbo.T135Ecritures e ON e.Id = l.EcrituresId
        WHERE e.CompanyGUID = @CompanyGUID AND e.Statut = 'VALIDEE'
          AND l.PlanComptableId = @GLId AND CAST(e.DateEcriture AS DATE) <= @DateFin), 0);
    DECLARE @DepCirc DECIMAL(15, 2), @PaieCirc DECIMAL(15, 2);
    SELECT @DepCirc = ISNULL(SUM(CASE WHEN r.Sens = 'ENCAISSEMENT' THEN r.Montant ELSE 0 END), 0),
           @PaieCirc = ISNULL(SUM(CASE WHEN r.Sens <> 'ENCAISSEMENT' THEN r.Montant ELSE 0 END), 0)
    FROM dbo.T140Reglement r
    WHERE r.CompanyGUID = @CompanyGUID AND r.Statut <> 'ANNULE' AND r.EcrituresId IS NOT NULL
      AND r.CompteBanque = @GL AND r.DateReglement <= @DateFin
      AND NOT EXISTS (SELECT 1 FROM dbo.T208ReleveLien l JOIN dbo.T142ReleveBancaire x ON x.Id = l.ReleveId
                      WHERE l.ReglementId = r.Id AND x.DateMouvement <= @DateFin);
    DECLARE @EntNI DECIMAL(15, 2), @SorNI DECIMAL(15, 2);
    SELECT @EntNI = ISNULL(SUM(CASE WHEN Montant < 0 THEN ABS(Montant) - dbo.fReleveRelieAu(Id, @DateFin) ELSE 0 END), 0),
           @SorNI = ISNULL(SUM(CASE WHEN Montant > 0 THEN Montant - dbo.fReleveRelieAu(Id, @DateFin) ELSE 0 END), 0)
    FROM dbo.T142ReleveBancaire
    WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @CompteBanque
      AND DateMouvement <= @DateFin
      AND ABS(Montant) - dbo.fReleveRelieAu(Id, @DateFin) > 0.005;

    DECLARE @Ecart DECIMAL(15, 2) = (@SoldeFin + @DepCirc - @PaieCirc) - (@Livres + @EntNI - @SorNI);

    INSERT INTO dbo.T207ConciliationBancaire
        (CompanyGUID, CompteBanque, CompteGL, DateDebut, DateFin, SoldeOuverture, SoldeFermeture,
         DepotsCirculation, PaiementsCirculation, SoldeLivres, EntreesNonInscrites, SortiesNonInscrites,
         Ecart, Note, CreatedBy)
    VALUES
        (@CompanyGUID, @CompteBanque, @GL, @DateDebut, @DateFin, @SoldeOuv, @SoldeFin,
         @DepCirc, @PaieCirc, @Livres, @EntNI, @SorNI, @Ecart, @Note, @UserId);

    SELECT SCOPE_IDENTITY() AS ConciliationId, @Ecart AS Ecart;
END
GO

-- ── Historique des conciliations clôturées ─────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0985GetConciliations
    @CompanyGUID  UNIQUEIDENTIFIER,
    @CompteBanque NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (24) c.Id, c.CompteBanque, c.CompteGL, c.DateDebut, c.DateFin, c.SoldeOuverture, c.SoldeFermeture,
           c.SoldeLivres, c.Ecart, c.Note, c.Created,
           LTRIM(ISNULL(u.FirstName, '') + ' ' + ISNULL(u.LastName, '')) AS Par
    FROM dbo.T207ConciliationBancaire c
    LEFT JOIN dbo.T015User u ON u.Id = c.CreatedBy
    WHERE c.CompanyGUID = @CompanyGUID AND (@CompteBanque IS NULL OR c.CompteBanque = @CompteBanque)
    ORDER BY c.DateFin DESC;
END
GO

-- ── Rouvrir la dernière conciliation ───────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.s0986RouvrirConciliation
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Compte NVARCHAR(200), @Fin DATE;
    SELECT @Compte = CompteBanque, @Fin = DateFin FROM dbo.T207ConciliationBancaire
    WHERE Id = @Id AND CompanyGUID = @CompanyGUID;
    IF @Compte IS NULL THROW 51044, 'Conciliation introuvable.', 1;
    IF @Fin < dbo.fConciliationVerrou(@CompanyGUID, @Compte)
        THROW 51045, 'Seule la dernière conciliation clôturée peut être rouverte.', 1;
    DELETE FROM dbo.T207ConciliationBancaire WHERE Id = @Id AND CompanyGUID = @CompanyGUID;
    SELECT @Id AS Id;
END
GO

-- ── Verrou d'une ligne du relevé (appelé par s0979-s0982, script T367) ─────
CREATE OR ALTER PROCEDURE dbo.s0987VerifierVerrouReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Date DATE, @Compte NVARCHAR(200);
    SELECT @Date = DateMouvement, @Compte = CompteBanque
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    IF @Date IS NULL RETURN;
    DECLARE @Verrou DATE = dbo.fConciliationVerrou(@CompanyGUID, @Compte);
    IF @Verrou IS NOT NULL AND @Date <= @Verrou
    BEGIN
        DECLARE @Msg NVARCHAR(300) = N'Cette ligne fait partie d''une conciliation clôturée (jusqu''au '
                                     + CONVERT(NVARCHAR(10), @Verrou, 23) + N'). Rouvrez la conciliation pour la modifier.';
        THROW 51046, @Msg, 1;
    END
END
GO
