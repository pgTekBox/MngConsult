-- =============================================================================
-- T415 — Factures et dépenses : le bénéficiaire peut être un client
--
-- Gazon : une dépense « Interac e-Transfer to /Diane Brunet » payée à
-- « Follosoft Gazon », qui est un CLIENT dans QuickBooks (n° 39). s0855 ne
-- cherchait le tiers d'une pièce fournisseur que parmi les fournisseurs : la
-- pièce restait « sans tiers ». Faute de fournisseur, on prend maintenant le
-- client de même identifiant source ET de même nom.
-- Le reste de s0855 est la version installée (T410), inchangée.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- -----------------------------------------------------------------------------
-- s0855 : le corps de T404, à une condition près. Le « lien mort » ne remet
-- plus à vide le tiers d'une pièce qui n'en a aucun dans la source : ce tiers
-- est le fournisseur divers posé par s1032, pas un lien de préparation.
-- -----------------------------------------------------------------------------
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

    UPDATE d
       SET d.[PartyGUID] = NULL
      FROM staging.DocumentImport d
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND d.[PartyImportId] IS NULL AND d.[PartyGUID] IS NOT NULL
       AND (NULLIF(LTRIM(RTRIM(ISNULL(d.[TiersExterneId], ''))), '') IS NOT NULL
            OR NULLIF(LTRIM(RTRIM(ISNULL(d.[TiersNom], ''))), '') IS NOT NULL);

    UPDATE l
       SET l.[ProductImportId] = NULL, l.[ProductId] = NULL
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductImportId] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ProductImport p WHERE p.[Id] = l.[ProductImportId]);

    UPDATE l
       SET l.[CompteImportId] = NULL, l.[CompteCible] = NULL
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[CompteImportId] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportPlanComptable p WHERE p.[Id] = l.[CompteImportId]);

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

    -- T415 : le bénéficiaire d'une dépense (ou d'une facture fournisseur) peut
    -- être un CLIENT dans QuickBooks. Faute de fournisseur, on prend le client
    -- qui a le même identifiant source ET le même nom — jamais l'un sans l'autre.
    UPDATE d
       SET d.[PartyImportId] = x.[Id]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.PartyImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID
                     AND p.[TypeImport] = 'Client'
                     AND p.[Status] <> 'Error'
                     AND p.[SourceId] = d.[TiersExterneId]
                     AND (UPPER(LTRIM(RTRIM(p.[Name]))) = UPPER(LTRIM(RTRIM(d.[TiersNom])))
                          OR UPPER(LTRIM(RTRIM(ISNULL(p.[DisplayName], '')))) = UPPER(LTRIM(RTRIM(d.[TiersNom]))))
                   ORDER BY p.[Id] DESC) x
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND d.[DocumentTypeId] IN (2, 4, 6)
       AND d.[PartyImportId] IS NULL
       AND NULLIF(d.[TiersExterneId], '') IS NOT NULL
       AND NULLIF(LTRIM(RTRIM(d.[TiersNom])), '') IS NOT NULL;

    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;

    -- ── 3) Les produits ─────────────────────────────────────────────────────
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

    -- ── 4) Les comptes, dans le plan comptable importé ──────────────────────
    -- Par le numéro source quand il y en a un, sinon par la clé de nom — la
    -- même qui sert à l'écran du plan comptable (CleSource, TypeCle = NOM).
    UPDATE l
       SET l.[CompteImportId] = x.[Id]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.ImportPlanComptable p
                   WHERE p.[CompanyGUID] = @CompanyGUID
                     AND ((NULLIF(l.[CompteSource], '') IS NOT NULL AND p.[CompteSource] = l.[CompteSource])
                          OR (NULLIF(l.[CompteNom], '') IS NOT NULL
                              AND (p.[CleSource] = UPPER(LTRIM(RTRIM(l.[CompteNom])))
                                   OR UPPER(LTRIM(RTRIM(ISNULL(p.[NomSource], '')))) = UPPER(LTRIM(RTRIM(l.[CompteNom]))))))
                   ORDER BY p.[Id] DESC) x
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[CompteImportId] IS NULL;

    -- Le compte d'ici (T404) : celui que l'écran du plan comptable a DÉCIDÉ
    -- (f1028 : Lier, Créer, Ignorer ; sinon la proposition). Recalculé à chaque
    -- passage tant que la facture n'est pas créée, pour suivre une décision changée.
    UPDATE l
       SET l.[CompteCible] = m.[Compte]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN dbo.f1028CompteDecide(@CompanyGUID) m ON m.[ImportId] = l.[CompteImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL;

    -- Une ligne sans compte à elle mais avec un produit : le compte du produit
    -- dans QuickBooks, tel que décidé au plan — revenus pour un document
    -- client, dépenses pour un document fournisseur.
    UPDATE l
       SET l.[CompteCible] = m.[Compte]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ProductImport pr ON pr.[Id] = l.[ProductImportId]
     CROSS APPLY (SELECT TOP 1 x.[Compte] FROM dbo.f1028CompteDecide(@CompanyGUID) x
                   WHERE x.[Compte] IS NOT NULL
                     AND UPPER(LTRIM(RTRIM(CASE WHEN d.[DocumentTypeId] IN (2, 4, 6) THEN pr.[ExpenseAccountName] ELSE pr.[IncomeAccountName] END)))
                         IN (x.[CleSource], x.[NomCle], x.[NomCompletCle])
                   ORDER BY x.[ImportId] DESC) m
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[CompteImportId] IS NULL;
END
GO
