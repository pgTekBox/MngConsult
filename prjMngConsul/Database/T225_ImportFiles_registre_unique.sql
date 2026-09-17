-- =============================================================================
-- T225 — staging.ImportFiles devient le registre de TOUS les imports
--
-- L'application avait deux entêtes pour la même idée :
--
--   staging.ImportFiles   les listes — clients, fournisseurs, produits
--   staging.ImportLot     le plan comptable, et lui seul
--
-- Résultat : impossible de répondre à « qu'est-ce qui est entré dans cette
-- compagnie, et quand ». La moitié de la réponse était dans une table, l'autre
-- moitié ailleurs, sans lien entre les deux.
--
-- Ce script ne fusionne pas les deux — les procédures et les écrans du plan
-- comptable travaillent sur [LotId] et continueront. Il fait plus simple : tout
-- import dépose désormais AUSSI une ligne dans ImportFiles, avec le contenu
-- d'origine, et le lot pointe dessus.
--
--   ImportFiles  ◄──── ImportLot.ImportFileId ◄──── ImportPlanComptable.LotId
--        ▲
--        └──── PartyImport.ImportFileId, ProductImport.ImportFileId
--
-- ImportFiles répond alors à « quoi, quand, par qui, depuis quelle source », et
-- chaque table de préparation garde son détail.
--
-- Le lien est facultatif : les lots déjà en base restent valides avec un
-- ImportFileId nul, et rien de ce qui existe ne se met à jour de force.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le lien du lot vers le fichier
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.ImportLot', 'ImportFileId') IS NULL
BEGIN
    ALTER TABLE staging.ImportLot ADD [ImportFileId] INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ImportLot_ImportFile')
BEGIN
    -- Pas de cascade : effacer un fichier ne doit pas faire disparaître en
    -- silence un lot dont les lignes sont peut-être déjà appliquées au plan.
    ALTER TABLE staging.ImportLot
        ADD CONSTRAINT FK_ImportLot_ImportFile FOREIGN KEY ([ImportFileId])
            REFERENCES staging.ImportFiles ([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ImportLot_ImportFile')
    CREATE INDEX IX_ImportLot_ImportFile ON staging.ImportLot ([ImportFileId]);
GO

-- -----------------------------------------------------------------------------
-- 2) s0751OuvrirImportLot — un paramètre de plus, facultatif
--
--    Les appelants qui ne le passent pas fonctionnent comme avant : c'est ce qui
--    permet d'aligner les écrans un par un plutôt que tous le même jour.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0751OuvrirImportLot]
    @CompanyGUID   UNIQUEIDENTIFIER,
    @SystemeSource VARCHAR(20),
    @TypeDonnees   VARCHAR(30),
    @NomFichier    NVARCHAR(260) = NULL,
    @Separateur    VARCHAR(10) = NULL,
    @Encodage      VARCHAR(20) = NULL,
    @UserId        INT = NULL,
    @ImportFileId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
        THROW 50301, 'Aucune compagnie : impossible d''ouvrir un lot d''importation.', 1;

    -- Un fichier d'une autre compagnie n'a rien à faire ici : le lien doit
    -- rester vérifiable, sinon il ne vaut rien.
    IF @ImportFileId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportFiles
                        WHERE [Id] = @ImportFileId
                          AND ([CompanyGUID] IS NULL OR [CompanyGUID] = @CompanyGUID))
        THROW 50367, 'Le fichier d''importation n''appartient pas à cette compagnie.', 1;

    INSERT INTO staging.ImportLot
        ([CompanyGUID], [SystemeSource], [TypeDonnees], [NomFichier],
         [Separateur], [Encodage], [Statut], [CreatedBy], [ImportFileId])
    VALUES
        (@CompanyGUID, @SystemeSource, @TypeDonnees, @NomFichier,
         @Separateur, @Encodage, 'EN_COURS', @UserId, @ImportFileId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS LotId;
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0787GetImportsCompagnie
--    La réponse à « qu'est-ce qui est entré, et quand » — enfin en un seul
--    endroit. Chaque ligne d'ImportFiles, avec ce qu'elle a produit selon le
--    chemin qu'elle a emprunté.
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
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])   AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id]) AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id])  AS [NbComptes]
      FROM staging.ImportFiles f
      LEFT JOIN staging.ImportLot l ON l.[ImportFileId] = f.[Id]
     WHERE f.[CompanyGUID] = @CompanyGUID
     ORDER BY f.[UploadDate] DESC;
END
GO
