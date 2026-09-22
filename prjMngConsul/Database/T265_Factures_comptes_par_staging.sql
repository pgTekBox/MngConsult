-- =============================================================================
-- T265 — Les lignes de facture reconnaissent leur COMPTE dans le plan comptable importé
--
-- Jusqu'ici le compte d'une ligne n'était ni vérifié ni repris : QuickBooks
-- donne un NOM (« Services », « Rent or lease payments ») et jamais un numéro,
-- s0785 cherchait un numéro dans T121, ne trouvait rien, et la ligne était
-- créée sans compte.
--
-- Même patron que le tiers (T261) et le produit (T262) :
--   · la ligne reconnaît son compte dans staging.ImportPlanComptable, par la
--     clé de nom (CleSource, TypeCle = NOM) ou par le numéro source quand il
--     y en a un ;
--   · le compte d'ici n'est posé que par ce que l'écran du plan comptable a
--     décidé : une correspondance « LIER » (staging.CorrespondanceCompte), ou
--     le lien PlanComptableId posé quand le compte existait ou a été appliqué ;
--   · un compte non résolu ne bloque pas la facture — le brouillon se corrige
--     avant comptabilisation — mais l'écran le dit.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('staging.DocumentImportLigne', 'CompteImportId') IS NULL
    ALTER TABLE staging.DocumentImportLigne ADD [CompteImportId] INT NULL;
IF COL_LENGTH('staging.DocumentImportLigne', 'CompteCible') IS NULL
    ALTER TABLE staging.DocumentImportLigne ADD [CompteCible] VARCHAR(20) NULL;
GO

-- -----------------------------------------------------------------------------
-- 1) s0855ResoudreDocumentsImport — tiers, produits, et maintenant comptes
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
       AND d.[PartyImportId] IS NULL AND d.[PartyGUID] IS NOT NULL;

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

    -- Le compte d'ici : ce que l'écran du plan comptable a décidé — une
    -- correspondance « LIER », sinon le lien posé quand le compte existait
    -- déjà ou a été appliqué. Jamais une recherche directe en production.
    UPDATE l
       SET l.[CompteCible] = c.[CompteCible]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ImportPlanComptable p ON p.[Id] = l.[CompteImportId]
     CROSS APPLY (SELECT TOP 1 cc.[CompteCible]
                    FROM staging.CorrespondanceCompte cc
                   WHERE cc.[CompanyGUID] = @CompanyGUID AND cc.[Action] = 'LIER'
                     AND NULLIF(cc.[CompteCible], '') IS NOT NULL
                     AND ((NULLIF(p.[CleSource], '') IS NOT NULL AND cc.[CleSource] = p.[CleSource])
                          OR (NULLIF(p.[CompteSource], '') IS NOT NULL AND cc.[CompteSource] = p.[CompteSource]))
                   ORDER BY cc.[Id] DESC) c
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[CompteCible] IS NULL;

    UPDATE l
       SET l.[CompteCible] = t.[Compte]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ImportPlanComptable p ON p.[Id] = l.[CompteImportId]
      JOIN dbo.T121PlanComptable t ON t.[Id] = p.[PlanComptableId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[CompteCible] IS NULL AND p.[PlanComptableId] IS NOT NULL;
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0782GetDocumentsImport — les lignes disent leur compte
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0782GetDocumentsImport]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT = NULL,
    @RunId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.s0855ResoudreDocumentsImport @CompanyGUID = @CompanyGUID;

    SELECT d.[Id], d.[RunId], d.[DocumentTypeId], d.[Rang], d.[ExterneId], d.[Numero],
           d.[DateDocument], d.[DateEcheance], d.[TiersExterneId], d.[TiersNom], d.[PartyGUID],
           d.[PartyImportId],
           p.[Name] AS [TiersReconnu],
           CASE WHEN d.[PartyGUID] IS NOT NULL THEN 1 ELSE 0 END AS [TiersCree],
           d.[Devise], d.[SousTotal], d.[TotalTaxes], d.[TPS], d.[TVQ], d.[Total], d.[Solde],
           d.[StatutSource], d.[NbLignes], d.[Statut], d.[Anomalie],
           d.[DocumentId], d.[MigratedDate], d.[Created]
      FROM staging.DocumentImport d
      LEFT JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (@DocumentTypeId IS NULL OR d.[DocumentTypeId] = @DocumentTypeId)
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     ORDER BY d.[DocumentTypeId], d.[Rang];

    SELECT l.[Id], l.[EnteteId], l.[LigneNo], l.[Description],
           l.[ProduitExterneId], l.[ProduitNom], l.[ProductId], l.[ProductImportId],
           pi.[Name] AS [ProduitReconnu],
           CASE WHEN l.[ProductId] IS NOT NULL THEN 1 ELSE 0 END AS [ProduitCree],
           l.[Quantite], l.[PrixUnitaire], l.[Montant],
           l.[TaxeCode], l.[TPS], l.[TVQ], l.[CompteSource], l.[CompteNom],
           l.[CompteImportId], l.[CompteCible],
           pc.[NomSource] AS [CompteReconnu], pc.[Statut] AS [CompteStatut],
           l.[Statut], l.[Anomalie]
      FROM staging.DocumentImportLigne l
     INNER JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      LEFT JOIN staging.ProductImport pi ON pi.[Id] = l.[ProductImportId]
      LEFT JOIN staging.ImportPlanComptable pc ON pc.[Id] = l.[CompteImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (@DocumentTypeId IS NULL OR d.[DocumentTypeId] = @DocumentTypeId)
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     ORDER BY l.[EnteteId], l.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0785CreerDocumentsDepuisImport — la ligne prend le compte résolu
--    Même corps qu'en T262 ; CompteComptable = CompteCible, plus de recherche en T121.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0785CreerDocumentsDepuisImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ids         NVARCHAR(MAX),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.s0855ResoudreDocumentsImport @CompanyGUID = @CompanyGUID;

    DECLARE @Aptes TABLE ([Id] INT PRIMARY KEY);
    INSERT INTO @Aptes ([Id])
    SELECT d.[Id]
      FROM staging.DocumentImport d
     INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                   FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[Statut] = 'OK'
       AND d.[PartyGUID] IS NOT NULL
       AND (d.[Total] IS NULL
            OR ABS(ISNULL(d.[SousTotal], ISNULL(d.[Total], 0))
                   + ISNULL(d.[TPS], 0) + ISNULL(d.[TVQ], 0)
                   - d.[Total]) <= 0.01);

    DECLARE @TaxableId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'TAXABLE' ORDER BY [Id]);
    DECLARE @ExemptId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'EXEMPT' ORDER BY [Id]);

    BEGIN TRANSACTION;

    DECLARE @Crees TABLE ([EnteteId] INT, [DocumentId] INT);

    MERGE dbo.T060Document AS cible
    USING (
        SELECT d.[Id] AS [EnteteId], d.[CompanyGUID], d.[PartyGUID], d.[DocumentTypeId],
               d.[DateDocument], d.[DateEcheance], d.[Numero],
               ISNULL(d.[SousTotal], ISNULL(d.[Total], 0)) AS [SousTotal],
               ISNULL(d.[TPS], 0) AS [TPS],
               ISNULL(d.[TVQ], 0) AS [TVQ],
               ISNULL(d.[Total], 0) AS [Total],
               p.[Name], p.[DisplayName]
          FROM staging.DocumentImport d
         INNER JOIN @Aptes a ON a.[Id] = d.[Id]
          LEFT JOIN dbo.T050Party p ON p.[PartyGUID] = d.[PartyGUID]
    ) AS src ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT ([DocumentGUID], [CompanyGUID], [PartyGUID], [DocumentTypeId], [StatusId],
                [DocumentDate], [DueDate], [DocumentNumber],
                [SubTotal], [TPS], [TVQ], [Total],
                [Name], [DisplayName], [ComptabilisationStatus], [Created])
        VALUES (NEWID(), src.[CompanyGUID], src.[PartyGUID], src.[DocumentTypeId], 1,
                ISNULL(src.[DateDocument], GETDATE()), src.[DateEcheance], src.[Numero],
                src.[SousTotal], src.[TPS], src.[TVQ], src.[Total],
                src.[Name], src.[DisplayName], 'NON_COMPTABILISE', GETDATE())
    OUTPUT src.[EnteteId], INSERTED.[Id] INTO @Crees;

    INSERT INTO dbo.T061DocumentLine
        ([Created], [DocumentId], [ProductId], [Description], [Qty], [UnitPrice],
         [Amount], [TaxeStatus], [TPS], [TVQ], [CompteComptable], [Ordre], [Total])
    SELECT GETDATE(), c.[DocumentId], l.[ProductId], l.[Description],
           ISNULL(l.[Quantite], 1), ISNULL(l.[PrixUnitaire], 0),
           ISNULL(l.[Montant], 0),
           CASE WHEN ISNULL(l.[TaxeCode], '') <> '' THEN @TaxableId ELSE @ExemptId END,
           ISNULL(l.[TPS], 0), ISNULL(l.[TVQ], 0),
           l.[CompteCible],
           l.[LigneNo],
           ISNULL(l.[Montant], 0)
      FROM staging.DocumentImportLigne l
     INNER JOIN @Crees c ON c.[EnteteId] = l.[EnteteId]
     ORDER BY l.[EnteteId], l.[LigneNo];

    UPDATE d
       SET d.[DocumentId]   = c.[DocumentId],
           d.[MigratedDate] = GETDATE(),
           d.[Statut]       = 'MIGRE',
           d.[Anomalie]     = NULL
      FROM staging.DocumentImport d
     INNER JOIN @Crees c ON c.[EnteteId] = d.[Id];

    COMMIT TRANSACTION;

    SELECT (SELECT COUNT(*) FROM @Crees) AS [NbCrees],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                           FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND d.[PartyGUID] IS NULL) AS [NbSansTiers],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                           FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND d.[PartyGUID] IS NOT NULL
               AND d.[Statut] <> 'OK') AS [NbEcartes],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                           FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND d.[Statut] = 'OK'
               AND d.[PartyGUID] IS NOT NULL
               AND d.[Total] IS NOT NULL
               AND ABS(ISNULL(d.[SousTotal], ISNULL(d.[Total], 0))
                       + ISNULL(d.[TPS], 0) + ISNULL(d.[TVQ], 0)
                       - d.[Total]) > 0.01) AS [NbDesequilibres];
END
GO
