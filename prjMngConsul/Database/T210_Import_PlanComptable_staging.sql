-- =============================================================================
-- Importation comptable — la zone de preparation, et le plan comptable
-- -----------------------------------------------------------------------------
-- Une compagnie qui arrive d'un autre logiciel comptable (QuickBooks, Sage 50,
-- Acomba...) depose ici ses donnees avant qu'elles ne touchent la comptabilite.
-- Rien de ce qui entre en preparation n'est encore comptable : c'est ce qui
-- rend l'operation reversible tant qu'on ne l'a pas appliquee.
--
-- Le modele est volontairement independant du logiciel d'origine. Ce sont les
-- colonnes « Source » qui portent ce que le fichier disait, et les colonnes
-- normalisees qui portent ce que nous en avons compris. Les deux restent cote a
-- cote : quand un ecart apparait plus tard, on peut relire ce qui avait ete
-- reellement extrait.
--
-- Les tables Sage propres au plan comptable sont renommees en fin de script :
-- elles precedaient ce modele et ne servaient qu'a un seul logiciel.
--
-- Re-executable.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
GO

-- -----------------------------------------------------------------------------
-- 1) Le lot d'importation
--    Un depot de fichier = un lot. Il porte d'ou viennent les donnees, ce
--    qu'elles decrivent, et ou en est le traitement. Tout ce qui est charge se
--    rattache a un lot, ce qui permet de le rejouer ou de l'abandonner en bloc.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ImportLot', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ImportLot (
        [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ImportLot PRIMARY KEY,
        [LotGUID]         UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ImportLot_GUID DEFAULT (NEWID()),
        [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,

        -- D'ou viennent les donnees : QBO, SAGE50, ACOMBA, AUTRE
        [SystemeSource]   VARCHAR(20) NOT NULL,
        -- Ce qu'elles decrivent : PLAN_COMPTABLE, TIERS, PRODUITS, FACTURES...
        [TypeDonnees]     VARCHAR(30) NOT NULL,

        [NomFichier]      NVARCHAR(260) NULL,
        [Separateur]      VARCHAR(10) NULL,
        [Encodage]        VARCHAR(20) NULL,

        [NbLignesLues]    INT NOT NULL CONSTRAINT DF_ImportLot_Lues DEFAULT (0),
        [NbLignesRetenues] INT NOT NULL CONSTRAINT DF_ImportLot_Retenues DEFAULT (0),
        [NbAnomalies]     INT NOT NULL CONSTRAINT DF_ImportLot_Anomalies DEFAULT (0),

        -- EN_COURS -> CHARGE -> APPLIQUE, ou ANNULE a tout moment
        [Statut]          VARCHAR(20) NOT NULL CONSTRAINT DF_ImportLot_Statut DEFAULT ('EN_COURS'),
        [Note]            NVARCHAR(1000) NULL,

        [Created]         DATETIME NOT NULL CONSTRAINT DF_ImportLot_Created DEFAULT (GETDATE()),
        [CreatedBy]       INT NULL,
        [AppliqueLe]      DATETIME NULL,
        [AppliquePar]     INT NULL
    );

    CREATE INDEX IX_ImportLot_Company ON staging.ImportLot ([CompanyGUID], [TypeDonnees], [Created] DESC);
END
GO

-- -----------------------------------------------------------------------------
-- 2) Les lignes du plan comptable en preparation
--    Colonnes « Source » : ce que le fichier disait, sans retouche.
--    Colonnes normalisees : ce que nous en avons compris.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ImportPlanComptable', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ImportPlanComptable (
        [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ImportPlanComptable PRIMARY KEY,
        [LotId]           INT NOT NULL,
        [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,
        [LigneNo]         INT NOT NULL,

        -- tel que lu dans le fichier
        [CompteSource]    NVARCHAR(50) NULL,
        [NomSource]       NVARCHAR(200) NULL,
        [TypeSource]      NVARCHAR(100) NULL,
        [SoldeSource]     NVARCHAR(50) NULL,
        [SensSource]      NVARCHAR(20) NULL,

        -- tel que nous l'avons compris
        [Compte]          VARCHAR(20) NULL,
        [Nom]             NVARCHAR(200) NULL,
        [TypeNormalise]   VARCHAR(20) NULL,   -- ACTIF, PASSIF, CAPITAUX, PRODUIT, CHARGE
        [Solde]           DECIMAL(18,2) NULL,
        [Sens]            VARCHAR(10) NULL,   -- DEBIT, CREDIT

        -- ce que le controle en dit
        -- OK | EXISTE | DOUBLON_FICHIER | INVALIDE
        [Statut]          VARCHAR(20) NOT NULL CONSTRAINT DF_ImportPC_Statut DEFAULT ('OK'),
        [Anomalie]        NVARCHAR(500) NULL,

        -- le compte du plan de la compagnie auquel celui-ci correspond, quand
        -- il a ete reconnu. C'est le point de depart de l'etape de mise en
        -- correspondance, qui vient ensuite.
        [PlanComptableId] INT NULL,

        [Created]         DATETIME NOT NULL CONSTRAINT DF_ImportPC_Created DEFAULT (GETDATE()),

        CONSTRAINT FK_ImportPC_Lot FOREIGN KEY ([LotId])
            REFERENCES staging.ImportLot ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_ImportPC_Lot ON staging.ImportPlanComptable ([LotId], [LigneNo]);
    CREATE INDEX IX_ImportPC_Compte ON staging.ImportPlanComptable ([CompanyGUID], [Compte]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0751OuvrirImportLot — ouvre un lot et rend son identifiant
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0751OuvrirImportLot]
    @CompanyGUID   UNIQUEIDENTIFIER,
    @SystemeSource VARCHAR(20),
    @TypeDonnees   VARCHAR(30),
    @NomFichier    NVARCHAR(260) = NULL,
    @Separateur    VARCHAR(10) = NULL,
    @Encodage      VARCHAR(20) = NULL,
    @UserId        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
        THROW 50301, 'Aucune compagnie : impossible d''ouvrir un lot d''importation.', 1;

    INSERT INTO staging.ImportLot
        ([CompanyGUID], [SystemeSource], [TypeDonnees], [NomFichier],
         [Separateur], [Encodage], [Statut], [CreatedBy])
    VALUES
        (@CompanyGUID, @SystemeSource, @TypeDonnees, @NomFichier,
         @Separateur, @Encodage, 'EN_COURS', @UserId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS LotId;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0752ChargerPlanComptableStaging
--    Charge tout un fichier en un appel : les lignes arrivent en JSON. Un
--    aller-retour par ligne serait inutilement bavard, et la validation se fait
--    mieux ici, ou l'on voit l'ensemble du lot d'un coup.
--
--    Le controle pose trois verdicts :
--      INVALIDE        pas de numero de compte
--      DOUBLON_FICHIER le meme numero apparait plus haut dans le fichier
--      EXISTE          le compte est deja au plan de la compagnie — ce n'est
--                      pas une erreur, c'est meme le cas courant : cela
--                      annonce une correspondance plutot qu'une creation
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0752ChargerPlanComptableStaging]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Lignes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ImportLot
                    WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID)
        THROW 50302, 'Lot d''importation introuvable pour cette compagnie.', 1;

    BEGIN TRANSACTION;

    -- Un rechargement remplace le contenu du lot : on ne cumule pas deux
    -- lectures du meme fichier.
    DELETE FROM staging.ImportPlanComptable WHERE [LotId] = @LotId;

    INSERT INTO staging.ImportPlanComptable
        ([LotId], [CompanyGUID], [LigneNo],
         [CompteSource], [NomSource], [TypeSource], [SoldeSource], [SensSource],
         [Compte], [Nom], [TypeNormalise], [Solde], [Sens])
    SELECT
        @LotId, @CompanyGUID, j.LigneNo,
        j.CompteSource, j.NomSource, j.TypeSource, j.SoldeSource, j.SensSource,
        LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20),
        j.Nom,
        j.TypeNormalise,
        j.Solde,
        j.Sens
    FROM OPENJSON(@Lignes)
         WITH (
            LigneNo       INT            '$.LigneNo',
            CompteSource  NVARCHAR(50)   '$.CompteSource',
            NomSource     NVARCHAR(200)  '$.NomSource',
            TypeSource    NVARCHAR(100)  '$.TypeSource',
            SoldeSource   NVARCHAR(50)   '$.SoldeSource',
            SensSource    NVARCHAR(20)   '$.SensSource',
            Compte        NVARCHAR(50)   '$.Compte',
            Nom           NVARCHAR(200)  '$.Nom',
            TypeNormalise VARCHAR(20)    '$.TypeNormalise',
            Solde         DECIMAL(18,2)  '$.Solde',
            Sens          VARCHAR(10)    '$.Sens'
         ) j;

    -- ── Verdicts ─────────────────────────────────────────────────────────
    UPDATE staging.ImportPlanComptable
       SET [Statut]   = 'INVALIDE',
           [Anomalie] = N'Numéro de compte absent.'
     WHERE [LotId] = @LotId
       AND ISNULL([Compte], '') = '';

    ;WITH d AS (
        SELECT [Id],
               ROW_NUMBER() OVER (PARTITION BY [Compte] ORDER BY [LigneNo]) AS rn
          FROM staging.ImportPlanComptable
         WHERE [LotId] = @LotId AND [Statut] = 'OK'
    )
    UPDATE p
       SET p.[Statut]   = 'DOUBLON_FICHIER',
           p.[Anomalie] = N'Ce numéro apparaît plus haut dans le fichier.'
      FROM staging.ImportPlanComptable p
     INNER JOIN d ON d.[Id] = p.[Id]
     WHERE d.rn > 1;

    -- Deja au plan de la compagnie : on le signale et on note le compte vise.
    UPDATE p
       SET p.[PlanComptableId] = pc.[Id],
           p.[Statut]          = 'EXISTE',
           p.[Anomalie]        = N'Déjà au plan comptable : ' + pc.[Nom]
      FROM staging.ImportPlanComptable p
     INNER JOIN dbo.T121PlanComptable pc
             ON pc.[CompanyGUID] = p.[CompanyGUID]
            AND pc.[Compte] = p.[Compte]
     WHERE p.[LotId] = @LotId
       AND p.[Statut] = 'OK';

    -- ── Comptes du lot ───────────────────────────────────────────────────
    UPDATE l
       SET l.[NbLignesLues]     = x.Total,
           l.[NbLignesRetenues] = x.Retenues,
           l.[NbAnomalies]      = x.Anomalies,
           l.[Statut]           = 'CHARGE'
      FROM staging.ImportLot l
     CROSS APPLY (
        SELECT COUNT(*) AS Total,
               SUM(CASE WHEN [Statut] IN ('OK', 'EXISTE') THEN 1 ELSE 0 END) AS Retenues,
               SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS Anomalies
          FROM staging.ImportPlanComptable WHERE [LotId] = @LotId
     ) x
     WHERE l.[Id] = @LotId;

    COMMIT TRANSACTION;

    SELECT [NbLignesLues], [NbLignesRetenues], [NbAnomalies], [Statut]
      FROM staging.ImportLot WHERE [Id] = @LotId;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0753GetPlanComptableStaging — le contenu d'un lot
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0753GetPlanComptableStaging]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Statut      VARCHAR(20) = NULL,   -- NULL = tout
    @Top         INT = 500
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        p.[Id], p.[LigneNo],
        p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SoldeSource], p.[SensSource],
        p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde], p.[Sens],
        p.[Statut], p.[Anomalie],
        p.[PlanComptableId],
        pc.[Nom] AS NomAuPlan
    FROM staging.ImportPlanComptable p
    LEFT JOIN dbo.T121PlanComptable pc ON pc.[Id] = p.[PlanComptableId]
    WHERE p.[LotId] = @LotId
      AND p.[CompanyGUID] = @CompanyGUID
      AND (@Statut IS NULL OR p.[Statut] = @Statut)
    ORDER BY p.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0754GetImportLots — les derniers lots de la compagnie
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0754GetImportLots]
    @CompanyGUID UNIQUEIDENTIFIER,
    @TypeDonnees VARCHAR(30) = NULL,
    @Top         INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        l.[Id], l.[SystemeSource], l.[TypeDonnees], l.[NomFichier],
        l.[NbLignesLues], l.[NbLignesRetenues], l.[NbAnomalies],
        l.[Statut], l.[Created], l.[AppliqueLe],
        u.[Email] AS CreeParEmail
    FROM staging.ImportLot l
    LEFT JOIN dbo.T015User u ON u.[Id] = l.[CreatedBy]
    WHERE l.[CompanyGUID] = @CompanyGUID
      AND (@TypeDonnees IS NULL OR l.[TypeDonnees] = @TypeDonnees)
    ORDER BY l.[Id] DESC;
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0755SupprimerImportLot — abandonne un lot
--    Les lignes suivent par la cascade. Un lot deja applique ne se supprime
--    pas : il est la trace de ce qui est entre en comptabilite.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0755SupprimerImportLot]
    @LotId       INT,
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM staging.ImportLot
                WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID AND [Statut] = 'APPLIQUE')
        THROW 50303, 'Ce lot a été appliqué : il ne peut plus être supprimé.', 1;

    DELETE FROM staging.ImportLot
     WHERE [Id] = @LotId AND [CompanyGUID] = @CompanyGUID;

    SELECT @@ROWCOUNT AS Supprimes;
END
GO

-- -----------------------------------------------------------------------------
-- 8) Les anciennes tables Sage du plan comptable
--    Elles precedaient ce modele et ne servaient qu'a Sage 50. Renommees plutot
--    que supprimees : staging.SageComptes porte 227 lignes dont l'origine n'est
--    pas documentee.
--
--    Les autres tables Sage (factures, tiers, produits) sont laissees en place :
--    leurs pages les visent encore, et elles seront reprises quand l'etape
--    correspondante sera construite.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.SageComptes', 'U') IS NOT NULL
   AND OBJECT_ID('staging.Ancien_SageComptes', 'U') IS NULL
    EXEC sp_rename 'staging.SageComptes', 'Ancien_SageComptes';
GO

IF OBJECT_ID('staging.SageComptesClasse', 'U') IS NOT NULL
   AND OBJECT_ID('staging.Ancien_SageComptesClasse', 'U') IS NULL
    EXEC sp_rename 'staging.SageComptesClasse', 'Ancien_SageComptesClasse';
GO

IF OBJECT_ID('staging.SageComptesOLD', 'U') IS NOT NULL
    DROP TABLE staging.SageComptesOLD;   -- vide, et deja marquee comme perimee
GO

PRINT N'T210_Import_PlanComptable_staging.sql : termine.';
GO
