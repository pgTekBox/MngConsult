-- =============================================================================
-- T370 — Rapprochement : une ligne du relevé, plusieurs pièces, et l'écart
--        inscrit aux livres
--
-- Jusqu'ici une ligne du relevé portait UN règlement (T142.ReglementId), sans
-- contrôle du montant : un dépôt de 419,25 $ relié à un encaissement de 100 $
-- passait « Réglé » et 319,25 $ disparaissaient. Désormais :
--
--   T208ReleveLien : les pièces d'une ligne, chacune avec le montant qu'elle
--   couvre — un règlement (T140) ou une écriture (T135) inscrite depuis le
--   relevé. La ligne est « Réglé » quand la somme couvre son montant,
--   « Partiel » entre les deux, « Importé » sans lien.
--
--   s0989InscrireReleveEcriture : inscrit aux livres ce qui ne correspond à
--   aucune facture (vente au comptoir du terminal, frais bancaires, loyer,
--   paie…) — écriture validée au journal de banque, 101x contre le compte
--   choisi, à la date du relevé — puis la relie à la ligne.
--   s0990RetirerLienReleve : retire une pièce (la pièce reste aux livres).
--   s0991MajStatutReleve   : recalcule l'état d'une ligne.
--
-- Les liens existants (T142.ReglementId) sont repris dans T208, puis la
-- colonne n'est plus lue ni écrite (remise à NULL). Les procédures des
-- scripts T366, T367, T368 et T369 lisent T208 (réappliquées après celui-ci).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T208ReleveLien') IS NULL
CREATE TABLE dbo.T208ReleveLien (
    Id           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T208ReleveLien PRIMARY KEY,
    CompanyGUID  UNIQUEIDENTIFIER NOT NULL,
    ReleveId     INT NOT NULL,                 -- T142ReleveBancaire.Id
    ReglementId  INT NULL,                     -- T140Reglement.Id
    EcrituresId  INT NULL,                     -- T135Ecritures.Id (inscrite depuis le relevé)
    Montant      DECIMAL(15, 2) NOT NULL,      -- la part de la ligne couverte (positive)
    Created      DATETIME NOT NULL CONSTRAINT DF_T208_Created DEFAULT (GETDATE()),
    CreatedBy    INT NULL,
    CONSTRAINT CK_T208_Piece CHECK ((ReglementId IS NULL AND EcrituresId IS NOT NULL) OR (ReglementId IS NOT NULL AND EcrituresId IS NULL)),
    CONSTRAINT CK_T208_Montant CHECK (Montant > 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T208_Releve')
    CREATE INDEX IX_T208_Releve ON dbo.T208ReleveLien (CompanyGUID, ReleveId);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_T208_Reglement')
    CREATE UNIQUE INDEX UX_T208_Reglement ON dbo.T208ReleveLien (ReglementId) WHERE ReglementId IS NOT NULL;
GO

-- Reprise des liens existants (un règlement par ligne), puis la colonne se vide
INSERT INTO dbo.T208ReleveLien (CompanyGUID, ReleveId, ReglementId, Montant)
SELECT t.CompanyGUID, t.Id, t.ReglementId,
       CASE WHEN r.Montant < ABS(t.Montant) THEN r.Montant ELSE ABS(t.Montant) END
FROM dbo.T142ReleveBancaire t
JOIN dbo.T140Reglement r ON r.Id = t.ReglementId
WHERE t.ReglementId IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dbo.T208ReleveLien l WHERE l.ReglementId = t.ReglementId);

UPDATE dbo.T142ReleveBancaire SET ReglementId = NULL WHERE ReglementId IS NOT NULL;
GO

-- ── La part d'une ligne déjà couverte par ses pièces ───────────────────────
CREATE OR ALTER FUNCTION dbo.fReleveRelie (@ReleveId INT)
RETURNS DECIMAL(15, 2)
AS
BEGIN
    RETURN ISNULL((SELECT SUM(Montant) FROM dbo.T208ReleveLien WHERE ReleveId = @ReleveId), 0);
END
GO

-- ── L'état d'une ligne : Réglé, Partiel ou Importé (Ignoré reste tel quel) ─
CREATE OR ALTER PROCEDURE dbo.s0991MajStatutReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t
    SET Statut = CASE
                     WHEN dbo.fReleveRelie(t.Id) >= ABS(t.Montant) - 0.005 THEN 'Réglé'
                     WHEN dbo.fReleveRelie(t.Id) > 0 THEN 'Partiel'
                     WHEN t.Statut IN ('Ignoré', 'Ignore') THEN t.Statut
                     ELSE 'Importé'
                 END
    FROM dbo.T142ReleveBancaire t
    WHERE t.Id = @ReleveId AND t.CompanyGUID = @CompanyGUID;
END
GO

-- ── Inscrire aux livres ce qui ne correspond à aucune facture ──────────────
CREATE OR ALTER PROCEDURE dbo.s0989InscrireReleveEcriture
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReleveId    INT,
    @CompteId    INT,                     -- T121PlanComptable.Id (la contrepartie)
    @Montant     DECIMAL(15, 2) = NULL,   -- NULL = tout le reste à relier
    @Libelle     VARCHAR(250) = NULL,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.s0987VerifierVerrouReleve @CompanyGUID, @ReleveId;

    DECLARE @Ligne DECIMAL(15, 2), @Date DATE, @Desc VARCHAR(500), @Statut VARCHAR(120);
    SELECT @Ligne = Montant, @Date = DateMouvement, @Desc = Description, @Statut = Statut
    FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId AND CompanyGUID = @CompanyGUID;
    IF @Ligne IS NULL THROW 51030, 'Ligne du relevé introuvable.', 1;

    DECLARE @Reste DECIMAL(15, 2) = ABS(@Ligne) - dbo.fReleveRelie(@ReleveId);
    IF @Reste <= 0.005 THROW 51070, 'Cette ligne est déjà entièrement reliée.', 1;
    IF @Montant IS NULL OR @Montant <= 0 SET @Montant = @Reste;
    IF @Montant > @Reste + 0.005
    BEGIN
        DECLARE @MsgM NVARCHAR(300) = N'Le montant dépasse le reste à relier (' + CONVERT(NVARCHAR(30), @Reste) + N' $).';
        THROW 51071, @MsgM, 1;
    END

    DECLARE @GLId INT = (SELECT TOP 1 c.Id FROM dbo.T121PlanComptable c
                         WHERE c.CompanyGUID = @CompanyGUID AND c.Actif = 1 AND c.compte LIKE '101%' ORDER BY c.compte);
    IF @GLId IS NULL THROW 51038, 'Aucun compte de banque (101x) dans le plan comptable.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable WHERE Id = @CompteId AND CompanyGUID = @CompanyGUID AND Actif = 1)
        THROW 51072, 'Compte de contrepartie introuvable.', 1;
    IF @CompteId = @GLId THROW 51073, 'La contrepartie ne peut pas être le compte de banque lui-même.', 1;

    DECLARE @Journal INT = (SELECT TOP 1 Id FROM dbo.T130Journaux
                            WHERE Type = 'BANQUE' AND Actif = 1 AND (CompanyGUID = @CompanyGUID OR CompanyGUID IS NULL)
                            ORDER BY CASE WHEN CompanyGUID = @CompanyGUID THEN 0 ELSE 1 END);
    IF @Journal IS NULL THROW 50005, 'Journal BANQUE introuvable dans T130Journaux.', 1;

    DECLARE @Periode INT = (SELECT p.id FROM dbo.T112Periodes p JOIN dbo.T111Exercices ex ON ex.id = p.exercice_id
                            WHERE p.CompanyGUID = @CompanyGUID AND ex.annee = YEAR(@Date) AND p.mois = MONTH(@Date)
                              AND p.statut = 'OUVERTE' AND ex.statut = 'OUVERT');
    IF @Periode IS NULL THROW 50006, 'Période comptable clôturée ou inexistante.', 1;

    IF @Libelle IS NULL OR LTRIM(RTRIM(@Libelle)) = '' SET @Libelle = LEFT(ISNULL(@Desc, 'Relevé bancaire'), 250);

    -- Une pièce unique par inscription : REL-<ligne>-<n>
    DECLARE @Piece VARCHAR(50) = 'REL-' + CAST(@ReleveId AS VARCHAR(20)) + '-' +
        CAST((SELECT COUNT(*) + 1 FROM dbo.T208ReleveLien WHERE ReleveId = @ReleveId AND EcrituresId IS NOT NULL) AS VARCHAR(10));
    WHILE EXISTS (SELECT 1 FROM dbo.T135Ecritures WHERE CompanyGUID = @CompanyGUID AND NumeroPiece = @Piece)
        SET @Piece = @Piece + 'b';

    -- Entrée d'argent (montant négatif au relevé) : banque au débit ; sortie : au crédit
    DECLARE @Lignes dbo.TVP_LigneEcriture;
    IF @Ligne < 0
        INSERT INTO @Lignes (Id, PlanComptableId, PartyId, Libelle, MontantDebit, MontantCredit, Ordre, Dirty, Deleted)
        VALUES (0, @GLId, NULL, LEFT(@Libelle, 250), @Montant, 0, 1, 1, 0),
               (0, @CompteId, NULL, LEFT(@Libelle, 250), 0, @Montant, 2, 1, 0);
    ELSE
        INSERT INTO @Lignes (Id, PlanComptableId, PartyId, Libelle, MontantDebit, MontantCredit, Ordre, Dirty, Deleted)
        VALUES (0, @CompteId, NULL, LEFT(@Libelle, 250), @Montant, 0, 1, 1, 0),
               (0, @GLId, NULL, LEFT(@Libelle, 250), 0, @Montant, 2, 1, 0);

    EXEC dbo.sp_SaveEcriture
         @EcritureId = 0, @CompanyGUID = @CompanyGUID, @JournauxId = @Journal, @PeriodeId = @Periode,
         @DateEcriture = @Date, @NumeroPiece = @Piece, @Libelle = @Libelle,
         @ToValider = 1, @UserId = @UserId, @Lignes = @Lignes;

    DECLARE @EcrituresId INT = (SELECT TOP 1 Id FROM dbo.T135Ecritures
                                WHERE CompanyGUID = @CompanyGUID AND NumeroPiece = @Piece ORDER BY Id DESC);
    IF @EcrituresId IS NULL THROW 51074, 'L''écriture n''a pas été créée.', 1;

    INSERT INTO dbo.T208ReleveLien (CompanyGUID, ReleveId, EcrituresId, Montant, CreatedBy)
    VALUES (@CompanyGUID, @ReleveId, @EcrituresId, @Montant, @UserId);

    EXEC dbo.s0991MajStatutReleve @CompanyGUID, @ReleveId;

    SELECT @EcrituresId AS EcrituresId, @Piece AS NumeroPiece, @Montant AS Montant,
           ABS(@Ligne) - dbo.fReleveRelie(@ReleveId) AS Reste;
END
GO

-- ── Retirer une pièce de la ligne (la pièce reste aux livres) ──────────────
CREATE OR ALTER PROCEDURE dbo.s0990RetirerLienReleve
    @CompanyGUID UNIQUEIDENTIFIER,
    @LienId      INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ReleveId INT = (SELECT ReleveId FROM dbo.T208ReleveLien WHERE Id = @LienId AND CompanyGUID = @CompanyGUID);
    IF @ReleveId IS NULL THROW 51075, 'Lien introuvable.', 1;
    EXEC dbo.s0987VerifierVerrouReleve @CompanyGUID, @ReleveId;
    DELETE FROM dbo.T208ReleveLien WHERE Id = @LienId AND CompanyGUID = @CompanyGUID;
    EXEC dbo.s0991MajStatutReleve @CompanyGUID, @ReleveId;
    SELECT @ReleveId AS ReleveId, ABS((SELECT Montant FROM dbo.T142ReleveBancaire WHERE Id = @ReleveId)) - dbo.fReleveRelie(@ReleveId) AS Reste;
END
GO

-- ── La part d'une ligne couverte par des pièces déjà aux livres à une date ──
-- (conciliation, T368) : un encaissement du 10 novembre relié à un dépôt du
-- 1er octobre ne couvre pas ce dépôt au 31 octobre — il n'est pas encore aux
-- livres ; la différence reste « au relevé, pas aux livres » pour octobre.
CREATE OR ALTER FUNCTION dbo.fReleveRelieAu (@ReleveId INT, @Date DATE)
RETURNS DECIMAL(15, 2)
AS
BEGIN
    RETURN ISNULL((
        SELECT SUM(l.Montant)
        FROM dbo.T208ReleveLien l
        LEFT JOIN dbo.T140Reglement r ON r.Id = l.ReglementId
        LEFT JOIN dbo.T135Ecritures e ON e.Id = l.EcrituresId
        WHERE l.ReleveId = @ReleveId
          AND ISNULL(r.DateReglement, CAST(e.DateEcriture AS DATE)) <= @Date), 0);
END
GO
