-- =============================================================================
-- T408 — Importation 2 : une nouvelle extraction rattache ses clients et
--        fournisseurs aux tiers déjà créés
--
-- Chaque extraction remet en préparation (staging.PartyImport, Status
-- 'Pending') tous les clients et fournisseurs de la source. Ceux qui existent
-- déjà ici sont comptés « déjà là » : rien n'est créé, mais la ligne restait
-- « Pending » sans MigratedToPartyId. Or les factures retrouvent leur tiers
-- par MigratedToPartyId (s0855, s0785) : elles restaient « sans tiers »
-- alors que tous les tiers avaient été importés.
--
-- s1031 fait pour les tiers ce que s0774 fait déjà pour les produits : chaque
-- ligne en attente qui correspond à un tiers existant de la compagnie — même
-- identifiant source (SourceId) d'abord, sinon même nom — passe à 'Skipped'
-- avec MigratedToPartyId = ce tiers. Le tiers existant n'est pas modifié.
-- Puis le PartyGUID des documents encore en préparation est complété.
--
--   s1031RattacherTiersExistants @CompanyGUID → NbRattaches, NbDocuments
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1031RattacherTiersExistants]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @n INT = 0, @d INT = 0;

    -- En attente, ou écartée comme doublon de nom (s0774) : dans les deux cas la
    -- ligne n'a pas de tiers, et ses factures non plus.
    UPDATE p
       SET p.[MigratedToPartyId] = ex.[Id],
           p.[ErrorMessage] = CASE WHEN p.[Status] = 'Skipped' THEN ISNULL(p.[ErrorMessage] + N' ', N'') + N'Rattachée au tiers existant (Id=' + CAST(ex.[Id] AS NVARCHAR(10)) + N').'
                                   ELSE N'Existe déjà dans vos ' + CASE WHEN p.[TypeImport] = 'Fournisseur' THEN N'fournisseurs' ELSE N'clients' END
                                        + N' (Id=' + CAST(ex.[Id] AS NVARCHAR(10)) + N') : laissé tel quel.' END,
           p.[Status] = 'Skipped'
      FROM staging.PartyImport p
      JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId] AND f.[CompanyGUID] = @CompanyGUID
     CROSS APPLY (SELECT TOP 1 t.[Id]
                    FROM dbo.T050Party t
                   WHERE t.[CompanyGUID] = @CompanyGUID
                     AND ISNULL(t.[isDeleted], 0) = 0
                     AND t.[Type] IN (CASE WHEN p.[TypeImport] = 'Fournisseur' THEN 2 ELSE 1 END, 3)
                     AND ((NULLIF(p.[SourceId], '') IS NOT NULL AND t.[SourceId] = p.[SourceId])
                          OR UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name]))))
                   ORDER BY CASE WHEN t.[SourceId] = p.[SourceId] THEN 0 ELSE 1 END, t.[Id]) ex
     WHERE p.[Status] IN ('Pending', 'Skipped')
       AND p.[TypeImport] IN ('Client', 'Fournisseur')
       AND p.[MigratedToPartyId] IS NULL;
    SET @n = @@ROWCOUNT;

    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;
    SET @d = @@ROWCOUNT;

    SELECT @n AS NbRattaches, @d AS NbDocuments;
END
GO
