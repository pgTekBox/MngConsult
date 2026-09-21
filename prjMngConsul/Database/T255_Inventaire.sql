-- =============================================================================
-- T255 — L'inventaire en préparation
--
-- Le dernier poste de la feuille de route. Pour qui tient un inventaire
-- permanent, la bascule doit reprendre trois choses par article : combien il
-- en reste, ce qu'il a coûté, et donc ce qu'il vaut. Sans elles, le premier
-- coût des marchandises vendues est faux, et la marge avec.
--
-- CE QUE LA SOURCE DONNE. L'entité Item, par la passerelle : QtyOnHand, le
-- coût d'achat, le compte d'actif de stock, le point de commande et la date à
-- laquelle le suivi a commencé. Le rapport InventoryValuationSummary existe
-- aussi, mais il ne dit rien de plus que les articles eux-mêmes — et il ne
-- rend que deux colonnes, dont une « Calcul Moyenne ».
--
-- LE CONTRÔLE QUI COMPTE, ET IL EST CROISÉ. La somme des valeurs d'articles
-- doit égaler le solde du compte d'actif de stock au grand livre. Les deux
-- viennent de la même comptabilité : un écart ne dit pas lequel a tort, il dit
-- qu'un article a été bougé sans passer par le stock — ou l'inverse. C'est la
-- seule vérification qui attrape une reprise d'inventaire silencieusement
-- fausse, et le troisième jeu de s0834 la sert toute faite.
--
-- LA VALEUR EST RECALCULÉE, ET C'EST ASSUMÉ. Quantité × coût unitaire. La
-- source ne rend pas la valeur en ligne sur l'article, seulement ses deux
-- facteurs. Le calcul est donc fait ici — mais la quantité et le coût restent
-- à côté, pour qu'on puisse toujours refaire la multiplication à la main.
--
-- CE QU'ON N'EN FAIT PAS. Rien ne s'applique : aucun article n'est créé,
-- aucune écriture de stock n'est passée. Pièce de contrôle, remplacée à chaque
-- extraction.
--
-- Procédures : s0833 (charger), s0834 (lire).
-- La liste blanche du registre accueille « Inventaire ».
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.InventaireImport') IS NULL
CREATE TABLE staging.InventaireImport (
    [Id]                INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_InventaireImport PRIMARY KEY,
    [ImportFileId]      INT NULL,
    [RunId]             INT NULL,
    [CompanyGUID]       UNIQUEIDENTIFIER NOT NULL,

    [DateArrete]        DATE NULL,
    [Devise]            VARCHAR(10) NULL,

    [Rang]              INT NOT NULL CONSTRAINT DF_InventaireImport_Rang DEFAULT (0),
    [ExterneId]         NVARCHAR(100) NULL,
    [Sku]               NVARCHAR(100) NULL,
    [Nom]               NVARCHAR(400) NULL,
    [NomComplet]        NVARCHAR(600) NULL,
    [Description]       NVARCHAR(1000) NULL,

    [CompteActifNom]    NVARCHAR(400) NULL,   -- le compte de stock : la clé du contrôle croisé
    [CompteRevenuNom]   NVARCHAR(400) NULL,
    [CompteCoutNom]     NVARCHAR(400) NULL,

    -- Les deux facteurs sont gardés À CÔTÉ de leur produit : la source ne rend
    -- pas la valeur, on la calcule, et une valeur calculée doit pouvoir être
    -- refaite à la main.
    [QuantiteEnMain]    DECIMAL(18,4) NULL,
    [CoutUnitaire]      DECIMAL(18,4) NULL,
    [ValeurTotale]      DECIMAL(18,2) NULL,

    [PrixVente]         DECIMAL(18,4) NULL,
    [PointCommande]     DECIMAL(18,4) NULL,
    [DateDebutSuivi]    DATE NULL,
    [Actif]             BIT NOT NULL CONSTRAINT DF_InventaireImport_Actif DEFAULT (1),

    [Statut]            VARCHAR(20) NOT NULL CONSTRAINT DF_InventaireImport_Statut DEFAULT ('OK'),
    [Anomalie]          NVARCHAR(500) NULL,
    [Created]           DATETIME NOT NULL CONSTRAINT DF_InventaireImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InventaireImport_Compagnie')
    CREATE INDEX IX_InventaireImport_Compagnie
        ON staging.InventaireImport ([CompanyGUID], [Statut], [Rang]);
GO

-- -----------------------------------------------------------------------------
-- s0833ChargerInventaire
--
-- Les anomalies sont posées À L'ARRIVÉE, parce qu'un inventaire faux se
-- reconnaît à des signes précis qu'il vaut mieux nommer tout de suite :
--
--   quantité NÉGATIVE  — physiquement impossible. La source a laissé vendre
--                        plus qu'il n'y en avait ; le coût des ventes est faux.
--   quantité SANS COÛT — on sait combien il en reste, pas ce que ça vaut.
--                        Reprendre zéro écraserait un actif réel.
--   coût SANS QUANTITÉ — un article à zéro qui porte encore un coût unitaire
--                        est normal ; il n'est signalé que s'il porte une
--                        valeur, ce qui serait contradictoire.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0833ChargerInventaire]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Articles     NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50401, 'Aucune compagnie : impossible de déposer un inventaire.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.InventaireImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.InventaireImport
        ([RunId], [ImportFileId], [CompanyGUID], [DateArrete], [Devise], [Rang],
         [ExterneId], [Sku], [Nom], [NomComplet], [Description],
         [CompteActifNom], [CompteRevenuNom], [CompteCoutNom],
         [QuantiteEnMain], [CoutUnitaire], [ValeurTotale], [PrixVente],
         [PointCommande], [DateDebutSuivi], [Actif], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           TRY_CONVERT(DATE, NULLIF(j.[arrete], '')),
           LEFT(j.[devise], 10),
           ISNULL(TRY_CONVERT(INT, NULLIF(j.[rang], '')), 0),
           LEFT(j.[externe_id], 100), LEFT(j.[sku], 100),
           j.[nom], j.[nom_complet], j.[description],
           j.[compte_actif], j.[compte_revenu], j.[compte_cout],
           v.[qte], v.[cout],
           ROUND(ISNULL(v.[qte], 0) * ISNULL(v.[cout], 0), 2),
           TRY_CONVERT(DECIMAL(18,4), NULLIF(j.[prix], '')),
           TRY_CONVERT(DECIMAL(18,4), NULLIF(j.[point_commande], '')),
           TRY_CONVERT(DATE, NULLIF(j.[debut_suivi], '')),
           CASE WHEN j.[actif] = 'false' THEN 0 ELSE 1 END,
           CASE WHEN v.[qte] < 0 THEN 'ANOMALIE'
                WHEN v.[qte] > 0 AND ISNULL(v.[cout], 0) = 0 THEN 'A_VERIFIER'
                ELSE 'OK' END,
           CASE WHEN v.[qte] < 0
                THEN N'Quantité négative : la source a laissé sortir plus de stock qu''il n''y en avait.'
                WHEN v.[qte] > 0 AND ISNULL(v.[cout], 0) = 0
                THEN N'Quantité en main sans coût unitaire : la valeur ne peut pas être établie.'
                END
      FROM OPENJSON(@Articles)
           WITH ([arrete] NVARCHAR(40) '$.arrete', [devise] NVARCHAR(20) '$.devise',
                 [rang] NVARCHAR(40) '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                 [sku] NVARCHAR(100) '$.sku', [nom] NVARCHAR(400) '$.nom',
                 [nom_complet] NVARCHAR(600) '$.nom_complet',
                 [description] NVARCHAR(1000) '$.description',
                 [compte_actif] NVARCHAR(400) '$.compte_actif',
                 [compte_revenu] NVARCHAR(400) '$.compte_revenu',
                 [compte_cout] NVARCHAR(400) '$.compte_cout',
                 [qte] NVARCHAR(40) '$.qte', [cout] NVARCHAR(40) '$.cout',
                 [prix] NVARCHAR(40) '$.prix', [point_commande] NVARCHAR(40) '$.point_commande',
                 [debut_suivi] NVARCHAR(40) '$.debut_suivi', [actif] NVARCHAR(10) '$.actif') AS j
     CROSS APPLY (
        SELECT TRY_CONVERT(DECIMAL(18,4), NULLIF(REPLACE(j.[qte], ' ', ''), ''))  AS [qte],
               TRY_CONVERT(DECIMAL(18,4), NULLIF(REPLACE(j.[cout], ' ', ''), '')) AS [cout]
     ) AS v;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS [NbArticles],
           (SELECT SUM([ValeurTotale]) FROM staging.InventaireImport
             WHERE [CompanyGUID] = @CompanyGUID) AS [ValeurTotale],
           (SELECT COUNT(*) FROM staging.InventaireImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Statut] <> 'OK') AS [NbAnomalies];
END
GO

-- -----------------------------------------------------------------------------
-- s0834GetInventaire — ce que l'écran affiche
--
-- Trois jeux : le récapitulatif, les articles, puis LE CONTRÔLE CROISÉ —
-- la valeur calculée par compte de stock, en face du solde que la balance de
-- vérification donne au même compte.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0834GetInventaire]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*)                                             AS [NbArticles],
           SUM(CASE WHEN [Actif] = 1 THEN 1 ELSE 0 END)         AS [NbActifs],
           SUM(ISNULL([QuantiteEnMain], 0))                     AS [QuantiteTotale],
           SUM(ISNULL([ValeurTotale], 0))                       AS [ValeurTotale],
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END)    AS [NbAnomalies],
           MAX([DateArrete])                                    AS [DateArrete],
           MAX([Devise])                                        AS [Devise],
           MAX([Created])                                       AS [Depose]
      FROM staging.InventaireImport
     WHERE [CompanyGUID] = @CompanyGUID;

    -- Ce qui cloche remonte en premier.
    SELECT [Rang], [ExterneId], [Sku], [Nom], [NomComplet], [Description],
           [CompteActifNom], [CompteRevenuNom], [CompteCoutNom],
           [QuantiteEnMain], [CoutUnitaire], [ValeurTotale], [PrixVente],
           [PointCommande], [DateDebutSuivi], [Actif], [Statut], [Anomalie]
      FROM staging.InventaireImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN [Statut] <> 'OK' THEN 0 ELSE 1 END,
              [CompteActifNom], [Nom], [Id];

    -- Le contrôle croisé. La balance de vérification venue de la passerelle ne
    -- porte PAS le numéro de compte, seulement son nom — le rapprochement se
    -- fait donc par le nom, et un compte renommé entre deux extractions
    -- ressortira sans solde plutôt que d'être apparié de travers.
    SELECT i.[CompteActifNom],
           COUNT(*)                        AS [NbArticles],
           SUM(ISNULL(i.[ValeurTotale],0)) AS [ValeurCalculee],
           b.[SoldeLivre],
           SUM(ISNULL(i.[ValeurTotale],0)) - ISNULL(b.[SoldeLivre], 0) AS [Ecart],
           CASE WHEN b.[SoldeLivre] IS NULL THEN 1 ELSE 0 END          AS [SansSolde]
      FROM staging.InventaireImport i
      OUTER APPLY (
          SELECT SUM(ISNULL(v.[Debit], 0) - ISNULL(v.[Credit], 0)) AS [SoldeLivre]
            FROM staging.BalanceVerification v
           WHERE v.[CompanyGUID] = i.[CompanyGUID]
             AND NULLIF(i.[CompteActifNom], '') IS NOT NULL
             AND v.[Description] = i.[CompteActifNom]
          HAVING COUNT(*) > 0
      ) AS b
     WHERE i.[CompanyGUID] = @CompanyGUID
     GROUP BY i.[CompteActifNom], b.[SoldeLivre]
     ORDER BY i.[CompteActifNom];
END
GO

-- -----------------------------------------------------------------------------
-- La liste blanche du registre accueille « Inventaire »
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
        'Client', 'Fournisseur', 'Produit', 'Inventaire',
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
