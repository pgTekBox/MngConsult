-- =============================================================================
-- T263 — La résolution des factures ne regarde plus la production
--
-- T262 acceptait un raccourci : un tiers ou un produit en préparation non
-- encore « Créé » pouvait être reconnu en dbo par son SourceId, posé par un
-- import antérieur. Pierre l'a refusé : la préparation ne fait référence qu'à
-- la préparation. Le SEUL pont vers T050Party et T075Products est le bouton
-- « Créer » des écrans Clients, Fournisseurs et Produits, qui pose
-- MigratedToPartyId / MigratedToProductId. Une facture reconnaît son tiers et
-- ses produits par ces liens-là, et par rien d'autre.
--
-- Conséquence assumée : après une nouvelle extraction de la liste des clients,
-- il faut recliquer « Créer » (les existants sont reliés, pas dupliqués) pour
-- que les factures retrouvent leur tiers.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0855ResoudreDocumentsImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Le tiers : créé depuis son écran, et seulement ainsi.
    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;

    -- Le produit de chaque ligne : dans la préparation, par identifiant source
    -- puis par nom exact.
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

    -- Le produit créé : depuis son écran, et seulement ainsi.
    UPDATE l
       SET l.[ProductId] = p.[MigratedToProductId]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ProductImport p ON p.[Id] = l.[ProductImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductId] IS NULL AND p.[MigratedToProductId] IS NOT NULL;
END
GO
