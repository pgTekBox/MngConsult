-- =============================================================================
-- T250 — Les comptes et soldes bancaires en préparation
--
-- Le poste « Soldes bancaires » de l'écran d'import : les comptes de banque et
-- de carte de crédit de la source, avec ce qu'ils portent. Apideck ne les
-- expose pas — /accounting/bank-accounts répond 404 pour QuickBooks — alors ils
-- arrivent par la passerelle, comme la balance de vérification et le grand
-- livre.
--
-- CE QU'ON N'EN FAIT PAS, ET POURQUOI CE N'EST PAS LE RAPPROCHEMENT.
--
-- La feuille de route visait T142ReleveBancaire, alimentée par « le dernier
-- Reconciliation Report ». Ce rapport N'EXISTE PAS dans l'API de QuickBooks :
-- ReconciliationReport, Reconciliation, BankReconciliation et
-- UnclearedTransactions sont tous refusés, et la colonne « cleared » demandée
-- à TransactionList est silencieusement retirée de la réponse. L'état de
-- rapprochement d'une opération n'est pas exposé.
--
-- Et même s'il l'était, il ne faudrait pas verser ceci dans T142. Cette table
-- porte le RELEVÉ DE LA BANQUE, celui contre lequel les livres se rapprochent.
-- Le fabriquer à partir des mouvements comptables de la source reviendrait à
-- rapprocher les livres d'eux-mêmes : l'opération passerait toujours, et ne
-- prouverait rien. Un relevé vient de la banque, jamais de la comptabilité.
--
-- Ce qui est versé ici reste donc en préparation, comme le grand livre et les
-- déclarations de taxes : on le regarde, on le compare, rien ne s'applique à
-- la comptabilité.
--
-- DEUX SOLDES, ET ILS NE DISENT PAS LA MÊME CHOSE. QuickBooks rend
-- « CurrentBalance », le solde du compte seul, et « CurrentBalanceWithSubAccounts »,
-- qui ajoute ses sous-comptes. Sommer la première colonne sur une hiérarchie
-- compte le parent puis ses enfants ; sommer la seconde compte deux fois. Les
-- deux sont gardées, et l'écran dit laquelle il additionne.
--
-- Procédures : s0824 (charger), s0825 (lire).
-- La liste blanche du registre accueille « CompteBancaire ».
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.CompteBancaireImport') IS NULL
CREATE TABLE staging.CompteBancaireImport (
    [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompteBancaireImport PRIMARY KEY,
    [ImportFileId]    INT NULL,
    [RunId]           INT NULL,
    [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,

    [Rang]            INT NOT NULL CONSTRAINT DF_CompteBancaireImport_Rang DEFAULT (0),
    [ExterneId]       NVARCHAR(100) NULL,
    [Numero]          NVARCHAR(100) NULL,   -- AcctNum : souvent vide, la source ne l'impose pas
    [Nom]             NVARCHAR(400) NULL,
    [NomComplet]      NVARCHAR(600) NULL,   -- « Banque:Compte chèques » quand il y a une hiérarchie
    [Description]     NVARCHAR(1000) NULL,
    [TypeCompte]      NVARCHAR(100) NULL,   -- Bank, Credit Card
    [SousType]        NVARCHAR(100) NULL,   -- Checking, Savings, CreditCard…
    [Devise]          VARCHAR(10) NULL,

    -- Les quatre derniers chiffres, quand la source les porte. Jamais le
    -- numéro complet : il n'est pas dans l'API, et il n'aurait rien à faire ici.
    [MasqueCompte]    NVARCHAR(40) NULL,

    [SoldeCourant]    DECIMAL(18,2) NULL,   -- CurrentBalance : le compte seul
    [SoldeAvecSous]   DECIMAL(18,2) NULL,   -- CurrentBalanceWithSubAccounts
    [EstSousCompte]   BIT NOT NULL CONSTRAINT DF_CompteBancaireImport_EstSousCompte DEFAULT (0),
    [ParentExterneId] NVARCHAR(100) NULL,
    [Actif]           BIT NOT NULL CONSTRAINT DF_CompteBancaireImport_Actif DEFAULT (1),

    -- Le solde est arrêté à l'instant de l'extraction : QuickBooks ne rend pas
    -- « le solde au 30 juin » sur l'entité, il rend celui d'aujourd'hui. La
    -- date est gardée pour que personne ne prenne un solde d'hier pour celui
    -- de la bascule.
    [ArreteLe]        DATETIME NULL,

    [Created]         DATETIME NOT NULL CONSTRAINT DF_CompteBancaireImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CompteBancaireImport_Compagnie')
    CREATE INDEX IX_CompteBancaireImport_Compagnie
        ON staging.CompteBancaireImport ([CompanyGUID], [Rang]);
GO

-- -----------------------------------------------------------------------------
-- s0824ChargerComptesBancaires — dépose les comptes lus chez la source
--
-- Une seule extraction en préparation à la fois : la nouvelle remplace la
-- précédente. Des comptes à moitié remplacés ne voudraient rien dire.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0824ChargerComptesBancaires]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Comptes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50397, 'Aucune compagnie : impossible de déposer des comptes bancaires.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.CompteBancaireImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [Numero],
         [Nom], [NomComplet], [Description], [TypeCompte], [SousType], [Devise],
         [MasqueCompte], [SoldeCourant], [SoldeAvecSous],
         [EstSousCompte], [ParentExterneId], [Actif], [ArreteLe])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(j.[externe_id], 100),
           LEFT(j.[numero], 100),
           j.[nom],
           j.[nom_complet],
           j.[description],
           LEFT(j.[type], 100),
           LEFT(j.[sous_type], 100),
           LEFT(j.[devise], 10),
           LEFT(j.[masque], 40),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[solde], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[solde_avec_sous], '')),
           CASE WHEN j.[sous_compte] = 'true' THEN 1 ELSE 0 END,
           LEFT(j.[parent_id], 100),
           CASE WHEN j.[actif] = 'false' THEN 0 ELSE 1 END,
           TRY_CONVERT(DATETIME, NULLIF(j.[arrete_le], ''))
      FROM OPENJSON(@Comptes)
           WITH ([rang]            NVARCHAR(40)   '$.rang',
                 [externe_id]      NVARCHAR(100)  '$.externe_id',
                 [numero]          NVARCHAR(100)  '$.numero',
                 [nom]             NVARCHAR(400)  '$.nom',
                 [nom_complet]     NVARCHAR(600)  '$.nom_complet',
                 [description]     NVARCHAR(1000) '$.description',
                 [type]            NVARCHAR(100)  '$.type',
                 [sous_type]       NVARCHAR(100)  '$.sous_type',
                 [devise]          NVARCHAR(20)   '$.devise',
                 [masque]          NVARCHAR(40)   '$.masque',
                 [solde]           NVARCHAR(40)   '$.solde',
                 [solde_avec_sous] NVARCHAR(40)   '$.solde_avec_sous',
                 [sous_compte]     NVARCHAR(10)   '$.sous_compte',
                 [parent_id]       NVARCHAR(100)  '$.parent_id',
                 [actif]           NVARCHAR(10)   '$.actif',
                 [arrete_le]       NVARCHAR(40)   '$.arrete_le') AS j;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS [NbComptes],
           (SELECT COUNT(*) FROM staging.CompteBancaireImport
             WHERE [CompanyGUID] = @CompanyGUID AND [TypeCompte] = 'Credit Card') AS [NbCartes],
           -- Le total ne somme QUE les comptes racines : additionner un parent
           -- et ses enfants compterait deux fois le même argent.
           (SELECT SUM([SoldeCourant]) FROM staging.CompteBancaireImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Actif] = 1) AS [TotalSoldes];
END
GO

-- -----------------------------------------------------------------------------
-- s0825GetComptesBancaires — ce que l'écran affiche
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0825GetComptesBancaires]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*)                                          AS [NbComptes],
           SUM(CASE WHEN [Actif] = 1 THEN 1 ELSE 0 END)      AS [NbActifs],
           SUM(CASE WHEN [TypeCompte] = 'Credit Card' THEN 1 ELSE 0 END) AS [NbCartes],
           SUM(CASE WHEN [Actif] = 1 THEN ISNULL([SoldeCourant], 0) ELSE 0 END) AS [TotalSoldes],
           MAX([Devise])                                     AS [Devise],
           MAX([ArreteLe])                                   AS [ArreteLe],
           MAX([Created])                                    AS [Depose]
      FROM staging.CompteBancaireImport
     WHERE [CompanyGUID] = @CompanyGUID;

    SELECT [Rang], [ExterneId], [Numero], [Nom], [NomComplet], [Description],
           [TypeCompte], [SousType], [Devise], [MasqueCompte],
           [SoldeCourant], [SoldeAvecSous], [EstSousCompte], [ParentExterneId],
           [Actif], [ArreteLe]
      FROM staging.CompteBancaireImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [TypeCompte], [Rang], [Id];
END
GO

-- -----------------------------------------------------------------------------
-- La liste blanche du registre accueille « CompteBancaire »
--
-- Même précaution qu'en T245, T247 et T249 : une contrainte CHECK ne s'étend
-- pas, elle se remplace. Tout ce qui y était y reste.
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
        'GrandLivre',
        'BalanceVerification',
        'BalanceAgeeClient', 'BalanceAgeeFournisseur',
        'RapportBilan', 'RapportResultats', 'RapportTaxes',
        -- Anciens types : gardés pour les fichiers déjà inscrits
        'BalanceAgee', 'Rapport'
    ));
GO
