-- =============================================================================
-- T404 — Produits et factures repris : le compte est celui DÉCIDÉ au plan
--
-- Avant :
--   · un produit recevait toujours 4000 / 5000 (RevenueAccount / ExpenseAccount
--     par défaut), alors que QuickBooks dit pour chacun son compte de revenus
--     et de dépenses (IncomeAccountName / ExpenseAccountName) ;
--   · une ligne de facture cherchait la décision « Lier » par son CompteCible
--     texte, que la liaison un par un et la liaison des propositions sûres
--     (s0760) ne remplissent pas (seulement PlanComptableId) : la décision était
--     ignorée et la proposition par numéro ou nom prise à sa place ; et une fois
--     posé, le compte ne suivait plus une décision changée.
--
-- Maintenant, un seul endroit dit « le compte d'ici d'un compte importé » :
--   f1028CompteDecide(@CompanyGUID) — pour chaque compte du plan importé :
--     · décidé « Lier » ou « Créer » (créé) → le compte de la décision
--       (PlanComptableId, sinon le CompteCible d'une liaison) ;
--     · décidé « Ignorer » → aucun ;
--     · pas encore décidé → la proposition (numéro, nom, alias), comme avant.
--
--   s1028ComptesProduitsImport @CompanyGUID, @ImportFileId : avant la création,
--     RevenueAccount / ExpenseAccount de chaque produit en attente prennent le
--     compte décidé de son compte QuickBooks (par numéro, sinon par nom). Sans
--     correspondance trouvée, la valeur précédente reste (4000 / 5000).
--   s0774 (produits) l'appelle juste avant s0608.
--   s0855 (factures) : le compte de chaque ligne d'une facture pas encore créée
--     est RECALCULÉ à chaque passage depuis f1028 ; une ligne sans compte à elle
--     mais avec un produit prend le compte du produit — revenus pour un document
--     client, dépenses pour un document fournisseur (types 2, 4, 6).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION [dbo].[f1028CompteDecide] (@CompanyGUID UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
    SELECT p.[Id]          AS ImportId,
           p.[CleSource],
           p.[CompteSource],
           UPPER(LTRIM(RTRIM(ISNULL(p.[NomSource], ''))))  AS NomCle,
           UPPER(LTRIM(RTRIM(ISNULL(p.[NomComplet], '')))) AS NomCompletCle,
           CASE WHEN cc.[Action] = 'IGNORER' THEN NULL
                WHEN cc.[Id] IS NOT NULL THEN COALESCE(pd.[Compte],
                     CASE WHEN cc.[Action] = 'LIER' THEN NULLIF(cc.[CompteCible], '') END)
                ELSE pp.[Compte] END                         AS Compte,
           CASE WHEN cc.[Id] IS NULL THEN 0 ELSE 1 END       AS Decide
      FROM staging.ImportPlanComptable p
     OUTER APPLY (SELECT TOP 1 c.[Id], c.[Action], c.[PlanComptableId], c.[CompteCible]
                    FROM staging.CorrespondanceCompte c
                   WHERE c.[CompanyGUID] = @CompanyGUID
                     AND c.[SystemeSource] = p.[SystemeSource]
                     AND c.[CleSource] = p.[CleSource]
                   ORDER BY c.[Id] DESC) cc
      LEFT JOIN dbo.T121PlanComptable pd ON pd.[Id] = cc.[PlanComptableId] AND pd.[CompanyGUID] = @CompanyGUID
      LEFT JOIN dbo.T121PlanComptable pp ON pp.[Id] = p.[PlanComptableId]  AND pp.[CompanyGUID] = @CompanyGUID
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE');
GO

CREATE OR ALTER PROCEDURE [dbo].[s1028ComptesProduitsImport]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pr
       SET pr.[RevenueAccount] = ISNULL(rv.[Compte], pr.[RevenueAccount]),
           pr.[ExpenseAccount] = ISNULL(dp.[Compte], pr.[ExpenseAccount])
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId] AND f.[CompanyGUID] = @CompanyGUID
     OUTER APPLY (SELECT TOP 1 m.[Compte] FROM dbo.f1028CompteDecide(@CompanyGUID) m
                   WHERE m.[Compte] IS NOT NULL
                     AND ((NULLIF(pr.[IncomeAccountCode], '') IS NOT NULL AND m.[CompteSource] = pr.[IncomeAccountCode])
                          OR (NULLIF(LTRIM(RTRIM(pr.[IncomeAccountName])), '') IS NOT NULL
                              AND UPPER(LTRIM(RTRIM(pr.[IncomeAccountName]))) IN (m.[CleSource], m.[NomCle], m.[NomCompletCle])))
                   ORDER BY CASE WHEN m.[CompteSource] = pr.[IncomeAccountCode] THEN 0 ELSE 1 END, m.[ImportId] DESC) rv
     OUTER APPLY (SELECT TOP 1 m.[Compte] FROM dbo.f1028CompteDecide(@CompanyGUID) m
                   WHERE m.[Compte] IS NOT NULL
                     AND ((NULLIF(pr.[ExpenseAccountCode], '') IS NOT NULL AND m.[CompteSource] = pr.[ExpenseAccountCode])
                          OR (NULLIF(LTRIM(RTRIM(pr.[ExpenseAccountName])), '') IS NOT NULL
                              AND UPPER(LTRIM(RTRIM(pr.[ExpenseAccountName]))) IN (m.[CleSource], m.[NomCle], m.[NomCompletCle])))
                   ORDER BY CASE WHEN m.[CompteSource] = pr.[ExpenseAccountCode] THEN 0 ELSE 1 END, m.[ImportId] DESC) dp
     WHERE pr.[ImportFileId] = @ImportFileId
       AND pr.[Status] = 'Pending';
END
GO


-- -----------------------------------------------------------------------------
-- s0774AppliquerImportFichier — creer pour de bon ce qui est nouveau
--
--   Ecarte d'abord ce qui ne doit pas etre cree : la repetition d'un nom dans
--   le fichier, et -- pour les produits -- ce qui existe deja. Les tiers deja
--   presents sont ecartes par s0607 elle-meme. Puis confie le reste a s0607
--   ou s0608, dont le resume est rendu tel quel.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0774AppliquerImportFichier]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Type VARCHAR(20);

    SELECT @Type = [TypeImport]
      FROM staging.ImportFiles
     WHERE [Id] = @ImportFileId
       AND [CompanyGUID] = @CompanyGUID;

    IF @Type IS NULL
        THROW 50361, 'Ce fichier n''existe pas pour cette compagnie.', 1;

    IF @Type IN ('Client', 'Fournisseur')
    BEGIN
        ;WITH d AS (
            SELECT [Status], [ErrorMessage],
                   ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM([Name])))
                                      ORDER BY ISNULL([LineNumber], 0), [Id]) AS Rang
              FROM staging.PartyImport
             WHERE [ImportFileId] = @ImportFileId
               AND [Status] = 'Pending'
               AND LTRIM(RTRIM(ISNULL([Name], ''))) <> ''
        )
        UPDATE d
           SET [Status] = 'Skipped',
               [ErrorMessage] = N'Doublon : le fichier répète ce nom, seule la première ligne est créée.'
         WHERE Rang > 1;

        EXEC dbo.s0607MigratePartyImportToProd
             @ImportFileId = @ImportFileId,
             @CompanyGUID  = @CompanyGUID;
    END
    ELSE IF @Type = 'Produit'
    BEGIN
        ;WITH d AS (
            SELECT [Status], [ErrorMessage],
                   ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM([Name])))
                                      ORDER BY ISNULL([LineNumber], 0), [Id]) AS Rang
              FROM staging.ProductImport
             WHERE [ImportFileId] = @ImportFileId
               AND [Status] = 'Pending'
               AND LTRIM(RTRIM(ISNULL([Name], ''))) <> ''
        )
        UPDATE d
           SET [Status] = 'Skipped',
               [ErrorMessage] = N'Doublon : le fichier répète ce nom, seule la première ligne est créée.'
         WHERE Rang > 1;

        UPDATE p
           SET [Status] = 'Skipped',
               [MigratedToProductId] = ex.[Id],
               [ErrorMessage] = N'Existe déjà dans vos produits et services (Id=' + CAST(ex.[Id] AS NVARCHAR(10)) + N') : laissé tel quel.'
          FROM staging.ProductImport p
         CROSS APPLY (SELECT TOP 1 t.[Id]
                        FROM dbo.T075Products t
                       WHERE t.[CompanyGUID] = @CompanyGUID
                         AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name])))
                       ORDER BY t.[Id]) ex
         WHERE p.[ImportFileId] = @ImportFileId
           AND p.[Status] = 'Pending';

        -- T404 : les comptes de vente et d'achat décidés au plan, avant la création.
        EXEC dbo.s1028ComptesProduitsImport @CompanyGUID = @CompanyGUID, @ImportFileId = @ImportFileId;

        EXEC dbo.s0608MigrateProductImportToProd
             @ImportFileId = @ImportFileId,
             @CompanyGUID  = @CompanyGUID;
    END
END
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
