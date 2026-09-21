-- =============================================================================
-- T254 — Les remises de DAS en préparation
--
-- Les déductions à la source : ce que l'employeur retient sur la paie et doit
-- verser au fédéral et au Québec. À la bascule, deux chiffres comptent —
-- combien reste-t-il dû à chaque autorité, et qu'est-ce qui a déjà été versé.
--
-- CE QUE LA SOURCE DONNE, ET CE QU'ELLE NE DONNE PAS.
--
-- Pas par la paie : l'API HRIS d'Apideck répond 401, le compte n'a qu'une seule
-- connexion — « accounting / quickbooks ». La paie de QuickBooks est un produit
-- séparé qui ne passe pas par cette porte.
--
-- Mais par la COMPTABILITÉ, oui. Une remise de DAS est un paiement au Receveur
-- général ou à Revenu Québec qui débite un compte de passif de retenues. Ces
-- mouvements-là sont dans le grand livre, et le grand livre, on le lit déjà.
--
-- D'où la forme de cette table : UN MOUVEMENT PAR LIGNE, sur les comptes de
-- DAS. Le crédit est la retenue qui s'accumule à chaque paie ; le débit est la
-- remise qui l'éteint. La différence est ce qui reste dû — et c'est le chiffre
-- que la bascule doit reprendre.
--
-- L'AUTORITÉ EST DÉDUITE DU COMPTE, ET LE COMPTE EST GARDÉ À CÔTÉ. « Fédéral »
-- ou « Québec » se devine au nom du compte, et une devinette doit pouvoir être
-- vérifiée : le nom d'origine reste sur chaque ligne. Ce qui ne se reconnaît
-- pas ressort en « Autre » plutôt que d'être rangé de force du mauvais côté —
-- une remise fédérale comptée au Québec, c'est deux déclarations fausses.
--
-- CE QU'ON N'EN FAIT PAS. Rien ne s'applique : ni à la comptabilité, ni à
-- paie.Paie. C'est une pièce de contrôle, remplacée à chaque extraction.
--
-- Procédures : s0831 (charger), s0832 (lire).
-- La liste blanche du registre accueille « RemiseDas ».
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.RemiseDasImport') IS NULL
CREATE TABLE staging.RemiseDasImport (
    [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RemiseDasImport PRIMARY KEY,
    [ImportFileId]    INT NULL,
    [RunId]           INT NULL,
    [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,

    [PeriodeDebut]    DATE NULL,
    [PeriodeFin]      DATE NULL,
    [Devise]          VARCHAR(10) NULL,

    [Rang]            INT NOT NULL CONSTRAINT DF_RemiseDasImport_Rang DEFAULT (0),

    -- L'autorité, déduite du compte. « Autre » quand le nom ne tranche pas :
    -- mieux vaut une ligne à classer qu'une remise rangée du mauvais côté.
    [Autorite]        NVARCHAR(30) NOT NULL CONSTRAINT DF_RemiseDasImport_Autorite DEFAULT (N'Autre'),
    [CompteNom]       NVARCHAR(400) NULL,

    [DateOperation]   DATE NULL,
    [TypeOperation]   NVARCHAR(100) NULL,
    [Numero]          NVARCHAR(100) NULL,
    [TiersNom]        NVARCHAR(400) NULL,
    [Memo]            NVARCHAR(1000) NULL,

    -- Sur un compte de passif : le CRÉDIT accumule la retenue, le DÉBIT
    -- l'éteint par une remise. Les deux sont gardés séparément plutôt qu'un
    -- montant signé — le signe d'un passif se lit à l'envers assez souvent
    -- pour qu'on ne s'y fie pas.
    [Debit]           DECIMAL(18,2) NULL,
    [Credit]          DECIMAL(18,2) NULL,
    [EstRemise]       BIT NOT NULL CONSTRAINT DF_RemiseDasImport_EstRemise DEFAULT (0),

    [Created]         DATETIME NOT NULL CONSTRAINT DF_RemiseDasImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RemiseDasImport_Compagnie')
    CREATE INDEX IX_RemiseDasImport_Compagnie
        ON staging.RemiseDasImport ([CompanyGUID], [Autorite], [DateOperation]);
GO

-- -----------------------------------------------------------------------------
-- s0831ChargerRemisesDas
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0831ChargerRemisesDas]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Mouvements   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50400, 'Aucune compagnie : impossible de déposer des remises de DAS.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.RemiseDasImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.RemiseDasImport
        ([RunId], [ImportFileId], [CompanyGUID], [PeriodeDebut], [PeriodeFin], [Devise],
         [Rang], [Autorite], [CompteNom], [DateOperation], [TypeOperation], [Numero],
         [TiersNom], [Memo], [Debit], [Credit], [EstRemise])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           LEFT(j.[devise], 10),
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(ISNULL(NULLIF(j.[autorite], ''), N'Autre'), 30),
           j.[compte],
           TRY_CONVERT(DATE, NULLIF(j.[date], '')),
           LEFT(j.[type], 100), LEFT(j.[numero], 100),
           j.[tiers], j.[memo],
           x.[debit], x.[credit],
           -- Un débit sur un compte de passif éteint la dette : c'est la remise.
           CASE WHEN x.[debit] > 0.005 THEN 1 ELSE 0 END
      FROM OPENJSON(@Mouvements)
           WITH ([debut] NVARCHAR(40) '$.debut', [fin] NVARCHAR(40) '$.fin',
                 [devise] NVARCHAR(20) '$.devise', [rang] NVARCHAR(40) '$.rang',
                 [autorite] NVARCHAR(30) '$.autorite', [compte] NVARCHAR(400) '$.compte',
                 [date] NVARCHAR(40) '$.date', [type] NVARCHAR(200) '$.type',
                 [numero] NVARCHAR(200) '$.numero', [tiers] NVARCHAR(400) '$.tiers',
                 [memo] NVARCHAR(1000) '$.memo',
                 [debit] NVARCHAR(40) '$.debit', [credit] NVARCHAR(40) '$.credit') AS j
     CROSS APPLY (
        SELECT ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[debit], ' ', ''), '')), 0)  AS [debit],
               ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(REPLACE(j.[credit], ' ', ''), '')), 0) AS [credit]
     ) AS x;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS [NbMouvements],
           (SELECT COUNT(*) FROM staging.RemiseDasImport
             WHERE [CompanyGUID] = @CompanyGUID AND [EstRemise] = 1) AS [NbRemises],
           (SELECT SUM([Credit]) - SUM([Debit]) FROM staging.RemiseDasImport
             WHERE [CompanyGUID] = @CompanyGUID) AS [ResteDu],
           (SELECT COUNT(*) FROM staging.RemiseDasImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Autorite] = N'Autre') AS [NbAClasser];
END
GO

-- -----------------------------------------------------------------------------
-- s0832GetRemisesDas — ce que l'écran affiche
--
-- Trois jeux : le récapitulatif, le solde PAR AUTORITÉ — c'est le chiffre de
-- la bascule — puis le détail des mouvements.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0832GetRemisesDas]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MIN([PeriodeDebut])                              AS [PeriodeDebut],
           MAX([PeriodeFin])                                AS [PeriodeFin],
           MAX([Devise])                                    AS [Devise],
           COUNT(*)                                         AS [NbMouvements],
           SUM(CASE WHEN [EstRemise] = 1 THEN 1 ELSE 0 END) AS [NbRemises],
           SUM(ISNULL([Credit], 0))                         AS [TotalRetenu],
           SUM(ISNULL([Debit], 0))                          AS [TotalRemis],
           SUM(ISNULL([Credit], 0)) - SUM(ISNULL([Debit], 0)) AS [ResteDu],
           SUM(CASE WHEN [Autorite] = N'Autre' THEN 1 ELSE 0 END) AS [NbAClasser],
           MAX([Created])                                   AS [Depose]
      FROM staging.RemiseDasImport
     WHERE [CompanyGUID] = @CompanyGUID;

    -- Le solde par autorité : ce qui reste dû au fédéral, et ce qui reste dû
    -- au Québec. C'est ce que la bascule doit reprendre.
    SELECT [Autorite],
           COUNT(*)                                          AS [NbMouvements],
           SUM(CASE WHEN [EstRemise] = 1 THEN 1 ELSE 0 END)   AS [NbRemises],
           SUM(ISNULL([Credit], 0))                           AS [Retenu],
           SUM(ISNULL([Debit], 0))                            AS [Remis],
           SUM(ISNULL([Credit], 0)) - SUM(ISNULL([Debit], 0)) AS [ResteDu],
           MAX([DateOperation])                               AS [DerniereOperation]
      FROM staging.RemiseDasImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [Autorite]
     ORDER BY CASE [Autorite] WHEN N'Federal' THEN 1 WHEN N'Quebec' THEN 2 ELSE 3 END;

    SELECT [Rang], [Autorite], [CompteNom], [DateOperation], [TypeOperation],
           [Numero], [TiersNom], [Memo], [Debit], [Credit], [EstRemise]
      FROM staging.RemiseDasImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE [Autorite] WHEN N'Federal' THEN 1 WHEN N'Quebec' THEN 2 ELSE 3 END,
              [DateOperation], [Rang], [Id];
END
GO

-- -----------------------------------------------------------------------------
-- La liste blanche du registre accueille « RemiseDas »
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
        -- Paie
        'Paie', 'RemiseDas',
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
