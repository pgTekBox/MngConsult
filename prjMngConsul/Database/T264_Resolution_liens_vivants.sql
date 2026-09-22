-- =============================================================================
-- T264 — Une facture ne garde pas un lien vers un tiers qui n'est plus là
--
-- Vu chez Pierre : l'écran des factures disait « Amanda Reid — en préparation,
-- pas encore créé » alors que la préparation des clients était vide. La facture
-- pointait (PartyImportId) vers une ligne de staging.PartyImport effacée entre-
-- temps — fichier abandonné, ou remplacé par une extraction plus récente.
-- Le lien survivait à sa cible.
--
-- Désormais s0855, rejouée à chaque affichage, à chaque dépôt et à chaque
-- création :
--   1) retire les liens dont la cible n'existe plus (tiers et produits) ;
--   2) refait la reconnaissance parmi ce qui est en préparation AUJOURD'HUI —
--      par identifiant source, puis par nom exact ;
--   3) pose le PartyGUID / ProductId seulement par le lien « Créé ».
--
-- La reconnaissance quitte donc s0781 (qui ne fait plus que déposer) : elle
-- vit à un seul endroit, et suit la préparation telle qu'elle est.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0855ResoudreDocumentsImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- ── 1) Les liens morts ──────────────────────────────────────────────────
    UPDATE d
       SET d.[PartyImportId] = NULL
      FROM staging.DocumentImport d
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND d.[PartyImportId] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.PartyImport p WHERE p.[Id] = d.[PartyImportId]);

    -- Un tiers reconnu par un lien mort, jamais créé : on repart de zéro.
    UPDATE d
       SET d.[PartyGUID] = NULL
      FROM staging.DocumentImport d
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND d.[PartyImportId] IS NULL AND d.[PartyGUID] IS NOT NULL;

    UPDATE l
       SET l.[ProductImportId] = NULL, l.[ProductId] = NULL
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductImportId] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ProductImport p WHERE p.[Id] = l.[ProductImportId]);

    -- ── 2) Le tiers, dans la préparation d'aujourd'hui ──────────────────────
    UPDATE d
       SET d.[PartyImportId] = x.[Id]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.PartyImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID
                     AND p.[TypeImport] = CASE WHEN d.[DocumentTypeId] IN (2, 4, 6) THEN 'Fournisseur' ELSE 'Client' END
                     AND p.[Status] <> 'Error'
                     AND p.[SourceId] = d.[TiersExterneId]
                   ORDER BY p.[Id] DESC) x
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND d.[PartyImportId] IS NULL AND NULLIF(d.[TiersExterneId], '') IS NOT NULL;

    UPDATE d
       SET d.[PartyImportId] = x.[Id]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.PartyImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID
                     AND p.[TypeImport] = CASE WHEN d.[DocumentTypeId] IN (2, 4, 6) THEN 'Fournisseur' ELSE 'Client' END
                     AND p.[Status] <> 'Error'
                     AND (UPPER(LTRIM(RTRIM(p.[Name]))) = UPPER(LTRIM(RTRIM(d.[TiersNom])))
                          OR UPPER(LTRIM(RTRIM(ISNULL(p.[DisplayName], '')))) = UPPER(LTRIM(RTRIM(d.[TiersNom]))))
                   ORDER BY p.[Id] DESC) x
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND d.[PartyImportId] IS NULL AND NULLIF(LTRIM(RTRIM(d.[TiersNom])), '') IS NOT NULL;

    -- Créé depuis son écran, et seulement ainsi.
    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;

    -- ── 3) Les produits, de même ────────────────────────────────────────────
    UPDATE l
       SET l.[ProductImportId] = x.[Id]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.ProductImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID AND p.[Status] <> 'Error'
                     AND p.[SourceId] = l.[ProduitExterneId]
                   ORDER BY p.[Id] DESC) x
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductImportId] IS NULL AND NULLIF(l.[ProduitExterneId], '') IS NOT NULL;

    UPDATE l
       SET l.[ProductImportId] = x.[Id]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.ProductImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID AND p.[Status] <> 'Error'
                     AND UPPER(LTRIM(RTRIM(p.[Name]))) = UPPER(LTRIM(RTRIM(l.[ProduitNom])))
                   ORDER BY p.[Id] DESC) x
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductImportId] IS NULL AND NULLIF(LTRIM(RTRIM(l.[ProduitNom])), '') IS NOT NULL;

    UPDATE l
       SET l.[ProductId] = p.[MigratedToProductId]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ProductImport p ON p.[Id] = l.[ProductImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductId] IS NULL AND p.[MigratedToProductId] IS NOT NULL;
END
GO
