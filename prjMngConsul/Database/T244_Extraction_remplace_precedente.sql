-- =============================================================================
-- T244 — Une extraction Apideck remplace la précédente
--
-- Le registre staging.ImportFiles garde une ligne par import, et c'est bien :
-- il répond à « qu'est-ce qui est entré, et quand ». Mais une extraction
-- Apideck relit TOUJOURS la même source. Répétée, elle empile des copies de la
-- même chose — trente-deux fichiers pour dix ressources, quatre cent cinquante
-- et un tiers là où la source en compte deux cent un.
--
-- Un dépôt de fichier manuel, lui, garde tout son sens en plusieurs
-- exemplaires : trois listes de clients de trois succursales sont trois
-- fichiers distincts, et l'historique compte.
--
-- D'où la distinction, et elle tient à une colonne : ModelUsed porte
-- « apideck/… » pour une lecture directe, et autre chose pour un fichier
-- déposé à la main. Seules les extractions se remplacent.
--
-- Ce qui a déjà été créé dans l'application n'est PAS touché : on efface la
-- préparation, jamais l'œuvre. C'est la même règle que s0775, qui abandonne un
-- fichier sans reprendre les tiers qu'il a servi à créer.
--
-- Procédure : s0819.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0819RemplacerImportApideck]
    @CompanyGUID UNIQUEIDENTIFIER,
    @TypeImport  VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50394, 'Aucune compagnie : refus de remplacer une extraction.', 1;

    -- Les extractions Apideck précédentes de ce type, et elles seules. Un
    -- fichier déposé à la main n'a pas « apideck/ » dans ModelUsed et reste.
    DECLARE @vieux TABLE ([Id] INT PRIMARY KEY);

    INSERT INTO @vieux ([Id])
    SELECT [Id]
      FROM staging.ImportFiles
     WHERE [CompanyGUID] = @CompanyGUID
       AND [TypeImport]  = @TypeImport
       AND [ModelUsed] LIKE 'apideck/%';

    IF NOT EXISTS (SELECT 1 FROM @vieux)
    BEGIN
        SELECT 0 AS [NbFichiers], 0 AS [NbLignes];
        RETURN;
    END

    DECLARE @lignes INT = 0;

    BEGIN TRANSACTION;

    -- ── Les enfants d'abord : une clé étrangère pendante fait tout échouer ──
    DELETE l
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport e ON e.[Id] = l.[EnteteId]
      JOIN @vieux v ON v.[Id] = e.[ImportFileId];
    SET @lignes += @@ROWCOUNT;

    DELETE l
      FROM staging.PieceCommercialeImportLigne l
      JOIN staging.PieceCommercialeImport e ON e.[Id] = l.[EnteteId]
      JOIN @vieux v ON v.[Id] = e.[ImportFileId];
    SET @lignes += @@ROWCOUNT;

    DELETE a
      FROM staging.PaiementImportAffectation a
      JOIN staging.PaiementImport p ON p.[Id] = a.[PaiementId]
      JOIN @vieux v ON v.[Id] = p.[ImportFileId];
    SET @lignes += @@ROWCOUNT;

    DELETE l
      FROM staging.EcritureImportLigne l
      JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
      JOIN @vieux v ON v.[Id] = e.[ImportFileId];
    SET @lignes += @@ROWCOUNT;

    DELETE l
      FROM staging.RapportImportLigne l
      JOIN staging.RapportImport r ON r.[Id] = l.[RapportId]
      JOIN @vieux v ON v.[Id] = r.[ImportFileId];
    SET @lignes += @@ROWCOUNT;

    -- ── Puis les tables rattachées au fichier ──────────────────────────────
    DELETE x FROM staging.PartyImport x             JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.ProductImport x           JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.DocumentImport x          JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.ImportPlanComptable x     JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.SocieteImport x           JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.TaxeImport x              JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.ModePaiementImport x      JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.CategorieSuiviImport x    JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.DepartementImport x       JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.EmplacementImport x       JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.PieceCommercialeImport x  JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.PaiementImport x          JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.EcritureImport x          JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.RapportImport x           JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.BalanceAgeeImport x       JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.PieceJointeImport x       JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;
    DELETE x FROM staging.ConditionPaiementImport x JOIN @vieux v ON v.[Id] = x.[ImportFileId]; SET @lignes += @@ROWCOUNT;

    -- ── Le registre en dernier : tout le reste y pointait ──────────────────
    DELETE f FROM staging.ImportFiles f JOIN @vieux v ON v.[Id] = f.[Id];
    DECLARE @fichiers INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @fichiers AS [NbFichiers], @lignes AS [NbLignes];
END
GO
