-- =============================================================================
-- T252 — L'état de pointage des opérations, en préparation
--
-- Le poste « Opérations non rapprochées ». À la bascule, la base de l'ERP est
-- VIDE : c'est donc le pointage de la source qui fait foi, et il faut le
-- reprendre. Sans lui, le premier rapprochement bancaire est faux de tous les
-- chèques émis avant la bascule et encaissés après.
--
-- OÙ LE TROUVER — ET POURQUOI JE NE L'AI PAS TROUVÉ DU PREMIER COUP.
--
-- Le rapport « UnclearedTransactions » n'existe pas dans l'API : refusé, trois
-- essais. J'ai alors demandé la colonne « cleared » à TransactionList, qui l'a
-- retirée de la réponse sans un mot — j'en ai conclu, à tort et deux fois, que
-- QuickBooks n'exposait pas le pointage.
--
-- La colonne s'appelle « is_cleared ». Elle est servie normalement. Une colonne
-- au mauvais nom est SILENCIEUSEMENT IGNORÉE par QuickBooks : on demande huit
-- colonnes, on en reçoit sept, et rien ne signale laquelle a sauté. D'où la
-- règle appliquée par le lecteur : repérer les colonnes par leur CLÉ dans la
-- réponse, jamais par leur rang, et se taire si la clé attendue manque plutôt
-- que de lire la colonne d'à côté.
--
-- CE QUE PORTE LA COLONNE. Vide quand l'opération n'est pas pointée, « C »
-- quand elle est marquée compensée, « R » quand elle a été rapprochée dans un
-- rapprochement clos. On garde la lettre TELLE QUELLE en plus du booléen : les
-- deux états ne se valent pas, et écraser la nuance ferait perdre l'information
-- au moment où on en aurait besoin.
--
-- CE QU'ON N'EN FAIT PAS. Rien ne s'applique à la comptabilité : la table reste
-- en préparation, comme le grand livre et les taxes. T142ReleveBancaire porte
-- le relevé de la banque et n'est pas touchée.
--
-- Procédures : s0827 (charger), s0828 (lire).
-- La liste blanche du registre accueille « Rapprochement ».
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.RapprochementImport') IS NULL
CREATE TABLE staging.RapprochementImport (
    [Id]             INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RapprochementImport PRIMARY KEY,
    [ImportFileId]   INT NULL,
    [RunId]          INT NULL,
    [CompanyGUID]    UNIQUEIDENTIFIER NOT NULL,

    [PeriodeDebut]   DATE NULL,
    [PeriodeFin]     DATE NULL,
    [Devise]         VARCHAR(10) NULL,

    [Rang]           INT NOT NULL CONSTRAINT DF_RapprochementImport_Rang DEFAULT (0),
    [DateOperation]  DATE NULL,
    [TypeOperation]  NVARCHAR(100) NULL,
    [Numero]         NVARCHAR(100) NULL,
    [TiersNom]       NVARCHAR(400) NULL,
    [Memo]           NVARCHAR(1000) NULL,
    [CompteNom]      NVARCHAR(400) NULL,

    -- La lettre de la source, gardée telle quelle : '' non pointée, 'C'
    -- compensée, 'R' rapprochée dans un rapprochement clos.
    [EtatPointage]   NVARCHAR(20) NULL,
    [EstPointee]     BIT NOT NULL CONSTRAINT DF_RapprochementImport_EstPointee DEFAULT (0),

    [Montant]        DECIMAL(18,2) NULL,

    [Created]        DATETIME NOT NULL CONSTRAINT DF_RapprochementImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RapprochementImport_Compagnie')
    CREATE INDEX IX_RapprochementImport_Compagnie
        ON staging.RapprochementImport ([CompanyGUID], [EstPointee], [Rang]);
GO

-- -----------------------------------------------------------------------------
-- s0827ChargerOperationsRapprochement
--
-- Une seule extraction en préparation à la fois : la nouvelle remplace la
-- précédente. Un état de pointage à moitié remplacé serait pire que pas d'état
-- du tout — on croirait savoir.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0827ChargerOperationsRapprochement]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Operations   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50398, 'Aucune compagnie : impossible de déposer un état de pointage.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.RapprochementImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.RapprochementImport
        ([RunId], [ImportFileId], [CompanyGUID], [PeriodeDebut], [PeriodeFin], [Devise],
         [Rang], [DateOperation], [TypeOperation], [Numero], [TiersNom], [Memo],
         [CompteNom], [EtatPointage], [EstPointee], [Montant])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           LEFT(j.[devise], 10),
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           TRY_CONVERT(DATE, NULLIF(j.[date], '')),
           LEFT(j.[type], 100),
           LEFT(j.[numero], 100),
           j.[tiers],
           j.[memo],
           j.[compte],
           LEFT(j.[pointage], 20),
           -- Tout ce qui n'est pas vide compte comme pointé : « C » et « R »
           -- sont deux façons de l'être, et une lettre qu'on ne connaîtrait pas
           -- encore vaut mieux comptée pointée que perdue.
           CASE WHEN NULLIF(LTRIM(RTRIM(j.[pointage])), '') IS NULL THEN 0 ELSE 1 END,
           TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[montant], ' ', ''), ''))
      FROM OPENJSON(@Operations)
           WITH ([debut]    NVARCHAR(40)   '$.debut',
                 [fin]      NVARCHAR(40)   '$.fin',
                 [devise]   NVARCHAR(20)   '$.devise',
                 [rang]     NVARCHAR(40)   '$.rang',
                 [date]     NVARCHAR(40)   '$.date',
                 [type]     NVARCHAR(200)  '$.type',
                 [numero]   NVARCHAR(200)  '$.numero',
                 [tiers]    NVARCHAR(400)  '$.tiers',
                 [memo]     NVARCHAR(1000) '$.memo',
                 [compte]   NVARCHAR(400)  '$.compte',
                 [pointage] NVARCHAR(40)   '$.pointage',
                 [montant]  NVARCHAR(40)   '$.montant') AS j;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS [NbOperations],
           (SELECT COUNT(*) FROM staging.RapprochementImport
             WHERE [CompanyGUID] = @CompanyGUID AND [EstPointee] = 0) AS [NbNonPointees],
           (SELECT SUM(ISNULL([Montant], 0)) FROM staging.RapprochementImport
             WHERE [CompanyGUID] = @CompanyGUID AND [EstPointee] = 0) AS [MontantNonPointe];
END
GO

-- -----------------------------------------------------------------------------
-- s0828GetOperationsRapprochement — ce que l'écran affiche
--
-- @NonPointeesSeulement : l'écran s'ouvre sur ce qui reste à pointer, parce que
-- c'est la question du poste ; le reste se demande explicitement.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0828GetOperationsRapprochement]
    @CompanyGUID          UNIQUEIDENTIFIER,
    @NonPointeesSeulement BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MIN([PeriodeDebut])                                   AS [PeriodeDebut],
           MAX([PeriodeFin])                                     AS [PeriodeFin],
           MAX([Devise])                                         AS [Devise],
           COUNT(*)                                              AS [NbOperations],
           SUM(CASE WHEN [EstPointee] = 0 THEN 1 ELSE 0 END)     AS [NbNonPointees],
           SUM(CASE WHEN [EstPointee] = 0 THEN ISNULL([Montant], 0) ELSE 0 END) AS [MontantNonPointe],
           COUNT(DISTINCT [CompteNom])                           AS [NbComptes],
           MAX([Created])                                        AS [Depose]
      FROM staging.RapprochementImport
     WHERE [CompanyGUID] = @CompanyGUID;

    SELECT [Rang], [DateOperation], [TypeOperation], [Numero], [TiersNom], [Memo],
           [CompteNom], [EtatPointage], [EstPointee], [Montant]
      FROM staging.RapprochementImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@NonPointeesSeulement = 0 OR [EstPointee] = 0)
     ORDER BY [CompteNom], [DateOperation], [Rang], [Id];
END
GO

-- -----------------------------------------------------------------------------
-- La liste blanche du registre accueille « Rapprochement »
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK ([TypeImport] IN (
        -- Structure
        'PlanComptable', 'Societe', 'Taxe', 'ModePaiement', 'ConditionPaiement',
        'CategorieSuivi', 'Departement', 'Emplacement', 'CompteBancaire',
        -- Tiers et articles
        'Client', 'Fournisseur', 'Produit',
        -- Ventes et achats
        'FactureClient', 'FactureFournisseur', 'AvoirClient', 'AvoirFournisseur',
        'Depense', 'RecuVente', 'Soumission', 'BonCommande',
        'Encaissement', 'Decaissement', 'Remboursement',
        -- Grand livre et contrôles
        'EcritureJournal', 'PieceJointe',
        'GrandLivre', 'Rapprochement',
        'BalanceVerification',
        'BalanceAgeeClient', 'BalanceAgeeFournisseur',
        'RapportBilan', 'RapportResultats', 'RapportTaxes',
        -- Anciens types : gardés pour les fichiers déjà inscrits
        'BalanceAgee', 'Rapport'
    ));
GO
