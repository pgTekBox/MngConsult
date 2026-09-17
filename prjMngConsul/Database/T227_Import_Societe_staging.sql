-- =============================================================================
-- T227 — Préparation de la fiche d'entreprise
--
-- « Informations de la société » ne ressemble à aucun autre import. Les autres
-- apportent des lignes à créer : des comptes, des clients, des factures. Celui-ci
-- apporte UNE fiche, qui existe déjà chez nous — nom légal, adresse, téléphone,
-- numéros d'entreprise — et qui vit dans les paramètres de compagnie
-- (T100ParamComptable / T101ParamValues), pas dans une table à elle.
--
-- Il ne s'agit donc pas de créer, mais de COMPARER : pour chaque champ, ce que
-- dit la source, ce que dit MngConsul, et lequel garder. La table est donc à
-- plat — une ligne par champ, pas une ligne par société :
--
--   Champ        ValeurSource            ValeurActuelle         Statut
--   ADDR1        3635 boul de la rous…   41 rue Garneau         DIFFERENT
--   PROVINCE     QC                      QC                     IDENTIQUE
--   CURRENCY     CAD                     (rien)                 ABSENT_ICI
--
-- Rien n'est appliqué automatiquement. Écraser l'adresse d'une entreprise parce
-- qu'un logiciel tiers en connaît une autre serait exactement le genre de chose
-- qu'on ne pardonne pas à un import.
--
-- Procédures : s0788 et s0789.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le registre accepte le nouveau genre
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK
    ([TypeImport] IN ('Client', 'Fournisseur', 'Produit',
                      'PlanComptable', 'FactureClient', 'FactureFournisseur',
                      'Societe'));
GO

-- -----------------------------------------------------------------------------
-- 2) staging.SocieteImport — un champ, deux valeurs, un verdict
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.SocieteImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.SocieteImport
    (
        [Id]             INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]   INT               NULL,
        [RunId]          INT               NULL,
        [CompanyGUID]    UNIQUEIDENTIFIER  NOT NULL,

        [Ordre]          INT               NOT NULL CONSTRAINT DF_SocieteImport_Ordre DEFAULT (0),

        -- Le nom court du paramètre chez nous : LEGAL_NAME, ADDR1, CITY…
        -- Vide quand la source apporte une information qui n'a pas d'équivalent.
        [Champ]          VARCHAR(40)       NULL,
        [Libelle]        NVARCHAR(200)     NOT NULL,

        [ValeurSource]   NVARCHAR(500)     NULL,
        [ValeurActuelle] NVARCHAR(500)     NULL,

        -- IDENTIQUE · DIFFERENT · ABSENT_ICI · ABSENT_SOURCE
        [Statut]         VARCHAR(20)       NOT NULL CONSTRAINT DF_SocieteImport_Statut DEFAULT ('IDENTIQUE'),

        -- Rempli le jour où l'écran de validation appliquera la valeur.
        [AppliqueLe]     DATETIME          NULL,
        [AppliquePar]    INT               NULL,

        [Created]        DATETIME          NOT NULL CONSTRAINT DF_SocieteImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_SocieteImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_SocieteImport_ImportFile FOREIGN KEY ([ImportFileId])
            REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_SocieteImport_Run FOREIGN KEY ([RunId])
            REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_SocieteImport_Company ON staging.SocieteImport ([CompanyGUID], [Created] DESC);
    CREATE INDEX IX_SocieteImport_File ON staging.SocieteImport ([ImportFileId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0788ChargerSocieteImport
--    Reçoit les champs lus chez la source et les confronte aux paramètres de la
--    compagnie. La comparaison se fait ici plutôt que dans le code : c'est en
--    SQL qu'on a les deux côtés sous la main.
--
--    Une nouvelle lecture remplace la précédente : deux extractions de la même
--    fiche ne s'empilent pas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0788ChargerSocieteImport]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Champs       NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50369, 'Aucune compagnie : impossible de déposer la fiche d''entreprise.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.SocieteImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.SocieteImport
        ([ImportFileId], [RunId], [CompanyGUID], [Ordre], [Champ], [Libelle],
         [ValeurSource], [ValeurActuelle], [Statut])
    SELECT @ImportFileId, @RunId, @CompanyGUID,
           j.[Ordre],
           NULLIF(LTRIM(RTRIM(j.[Champ])), ''),
           j.[Libelle],
           NULLIF(LTRIM(RTRIM(j.[Valeur])), ''),
           actuel.[Valeur],
           CASE
               WHEN NULLIF(LTRIM(RTRIM(j.[Valeur])), '') IS NULL THEN 'ABSENT_SOURCE'
               WHEN actuel.[Valeur] IS NULL                      THEN 'ABSENT_ICI'
               -- La comparaison ignore la casse et les espaces de bord : une
               -- différence de frappe n'est pas une différence de fond.
               WHEN LTRIM(RTRIM(actuel.[Valeur])) = LTRIM(RTRIM(j.[Valeur])) THEN 'IDENTIQUE'
               ELSE 'DIFFERENT'
           END
      FROM OPENJSON(@Champs)
           WITH ([Ordre]   INT            '$.ordre',
                 [Champ]   NVARCHAR(80)   '$.champ',
                 [Libelle] NVARCHAR(200)  '$.libelle',
                 [Valeur]  NVARCHAR(500)  '$.valeur') AS j
     OUTER APPLY (
        SELECT NULLIF(LTRIM(RTRIM(v.[sVal])), '') AS [Valeur]
          FROM dbo.T100ParamComptable p
          JOIN dbo.T101ParamValues v
            ON v.[T100Id] = p.[Id] AND v.[CompanyGUID] = p.[CompanyGUID]
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[ShortName] = j.[Champ]
     ) AS actuel;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbChamps],
           SUM(CASE WHEN [Statut] = 'DIFFERENT' THEN 1 ELSE 0 END)     AS [NbDifferents],
           SUM(CASE WHEN [Statut] = 'ABSENT_ICI' THEN 1 ELSE 0 END)    AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'IDENTIQUE' THEN 1 ELSE 0 END)     AS [NbIdentiques]
      FROM staging.SocieteImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0789GetSocieteImport
--    Ce que l'écran de comparaison affichera : les écarts d'abord, puisque ce
--    sont eux qui demandent une décision.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0789GetSocieteImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [ImportFileId], [RunId], [Ordre], [Champ], [Libelle],
           [ValeurSource], [ValeurActuelle], [Statut], [AppliqueLe], [Created]
      FROM staging.SocieteImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE [Statut]
                  WHEN 'DIFFERENT'     THEN 1
                  WHEN 'ABSENT_ICI'    THEN 2
                  WHEN 'IDENTIQUE'     THEN 3
                  ELSE 4
              END,
              [Ordre], [Libelle];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0787GetImportsCompagnie — la fiche compte aussi
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0787GetImportsCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 100
           f.[Id], f.[TypeImport], f.[OriginalName], f.[FileExtension], f.[FileSize],
           f.[UploadDate], f.[Status], f.[ProcessedRows], f.[ModelUsed],
           l.[Id]            AS [LotId],
           l.[SystemeSource],
           l.[NbLignesLues], l.[NbLignesRetenues], l.[NbAnomalies],
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])     AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id])   AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id])    AS [NbComptes],
           (SELECT COUNT(*) FROM staging.DocumentImport di WHERE di.[ImportFileId] = f.[Id])  AS [NbDocuments],
           (SELECT COUNT(*) FROM staging.SocieteImport si WHERE si.[ImportFileId] = f.[Id])   AS [NbChampsSociete]
      FROM staging.ImportFiles f
      LEFT JOIN staging.ImportLot l ON l.[ImportFileId] = f.[Id]
     WHERE f.[CompanyGUID] = @CompanyGUID
     ORDER BY f.[UploadDate] DESC;
END
GO
