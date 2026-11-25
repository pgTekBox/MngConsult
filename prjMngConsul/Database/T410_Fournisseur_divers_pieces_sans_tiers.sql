-- =============================================================================
-- T410 — Reprise : les pièces fournisseur sans aucun fournisseur dans la
--        source vont au fournisseur « Fournisseurs divers »
--
-- QuickBooks donne des dépenses sans bénéficiaire (paiements Internet, frais
-- de service, versements…) : aucun tiers à créer ne pouvait les débloquer,
-- elles ne devenaient jamais des documents. Elles sont maintenant rattachées
-- à un fournisseur générique de la compagnie, « Fournisseurs divers », créé
-- au besoin (une seule fois), puis créées en brouillon comme les autres.
--
-- Côté fournisseur seulement : factures (2), crédits (4) et dépenses (6).
-- Une pièce est « sans fournisseur dans la source » quand elle n'a ni
-- identifiant ni nom de tiers. s0855 remet à NULL le tiers d'une pièce sans
-- ligne de tiers en préparation : appeler s1032 APRÈS s0855, juste avant
-- s0785 (Importation2.CreerFacturesPretes).
--
--   s1032AttribuerFournisseurDivers @CompanyGUID → NbDocuments, PartyId, Cree
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1032AttribuerFournisseurDivers]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Nom NVARCHAR(100) = N'Fournisseurs divers';
    DECLARE @PartyId INT = NULL, @PartyGUID UNIQUEIDENTIFIER = NULL, @Cree BIT = 0, @n INT = 0;

    DECLARE @Divers BIT = CASE WHEN EXISTS (
                   SELECT 1 FROM staging.DocumentImport d
                    WHERE d.[CompanyGUID] = @CompanyGUID
                      AND d.[DocumentId] IS NULL AND d.[Statut] = 'OK' AND d.[PartyGUID] IS NULL
                      AND d.[DocumentTypeId] IN (2, 4, 6)
                      AND NULLIF(LTRIM(RTRIM(ISNULL(d.[TiersExterneId], ''))), '') IS NULL
                      AND NULLIF(LTRIM(RTRIM(ISNULL(d.[TiersNom], ''))), '') IS NULL) THEN 1 ELSE 0 END;

    BEGIN TRANSACTION;

    IF @Divers = 1
    BEGIN
    SELECT TOP 1 @PartyId = t.[Id], @PartyGUID = t.[PartyGUID]
      FROM dbo.T050Party t WITH (UPDLOCK, HOLDLOCK)
     WHERE t.[CompanyGUID] = @CompanyGUID
       AND ISNULL(t.[isDeleted], 0) = 0
       AND t.[Type] IN (2, 3)
       AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(@Nom)
     ORDER BY t.[Id];

    IF @PartyId IS NULL
    BEGIN
        INSERT INTO dbo.T050Party ([CompanyGUID], [Name], [DisplayName], [Type], [Origin], [Note], [isDeleted], [PaymentTermDays])
        VALUES (@CompanyGUID, @Nom, @Nom, 2, 1,
                N'Créé par la reprise : regroupe les dépenses que l''ancien logiciel donnait sans fournisseur.', 0, 0);
        SET @PartyId = SCOPE_IDENTITY();
        SELECT @PartyGUID = [PartyGUID] FROM dbo.T050Party WHERE [Id] = @PartyId;
        SET @Cree = 1;
    END

    UPDATE d
       SET d.[PartyGUID] = @PartyGUID
      FROM staging.DocumentImport d
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL AND d.[Statut] = 'OK' AND d.[PartyGUID] IS NULL
       AND d.[DocumentTypeId] IN (2, 4, 6)
       AND NULLIF(LTRIM(RTRIM(ISNULL(d.[TiersExterneId], ''))), '') IS NULL
       AND NULLIF(LTRIM(RTRIM(ISNULL(d.[TiersNom], ''))), '') IS NULL;
    SET @n = @@ROWCOUNT;
    END

    -- Ces dépenses viennent sans total : seules leurs lignes portent un montant,
    -- et sans total le document serait créé à 0 $. Trois cas, d'après la
    -- source (somme des lignes M, prix × quantité P, total des taxes X) :
    --   · taxes comprises  (M − X = P) : total M, sous-total M − X ;
    --   · taxes en sus     (M = P, X > 0) : sous-total M, total M + X ;
    --   · sans taxes       (X = 0)        : total = sous-total = M.
    -- X se coupe en TPS/TVQ dans la proportion du Québec (5 / 9,975).
    DECLARE @Doc TABLE ([Id] INT PRIMARY KEY, [SousTotal] DECIMAL(18,2), [TPS] DECIMAL(18,2), [TVQ] DECIMAL(18,2), [Total] DECIMAL(18,2), [Inclus] BIT);
    INSERT INTO @Doc
    SELECT d.[Id],
           CASE WHEN k.[Inclus] = 1 THEN s.[M] - x.[X] ELSE s.[M] END,
           ROUND(x.[X] * 5.0 / 14.975, 2),
           x.[X] - ROUND(x.[X] * 5.0 / 14.975, 2),
           CASE WHEN k.[Inclus] = 1 THEN s.[M] ELSE s.[M] + x.[X] END,
           k.[Inclus]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT SUM(ISNULL(l.[Montant], 0)) AS [M],
                         SUM(ISNULL(l.[PrixUnitaire], 0) * ISNULL(l.[Quantite], 1)) AS [P]
                    FROM staging.DocumentImportLigne l WHERE l.[EnteteId] = d.[Id]) s
     CROSS APPLY (SELECT ISNULL(d.[TotalTaxes], 0) AS [X]) x
     CROSS APPLY (SELECT CASE WHEN x.[X] > 0 AND ABS(s.[M] - x.[X] - s.[P]) <= 0.02 THEN 1 ELSE 0 END AS [Inclus]) k
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL AND d.[Statut] = 'OK'
       AND d.[Total] IS NULL
       AND s.[M] IS NOT NULL;

    UPDATE d
       SET d.[SousTotal] = t.[SousTotal], d.[TPS] = t.[TPS], d.[TVQ] = t.[TVQ], d.[Total] = t.[Total]
      FROM staging.DocumentImport d JOIN @Doc t ON t.[Id] = d.[Id];

    -- Les lignes : hors taxes, et chacune sa part des taxes de l'entête (le
    -- cent d'arrondi va à la plus grosse ligne), pour que les lignes bouclent
    -- avec l'entête une fois le document créé.
    ;WITH L AS (
        SELECT l.[Id], l.[EnteteId], t.[SousTotal], t.[TPS], t.[TVQ], t.[Inclus],
               CASE WHEN t.[Inclus] = 1 THEN ISNULL(l.[PrixUnitaire], 0) * ISNULL(l.[Quantite], 1) ELSE ISNULL(l.[Montant], 0) END AS [HT],
               ROW_NUMBER() OVER (PARTITION BY l.[EnteteId] ORDER BY ABS(ISNULL(l.[Montant], 0)) DESC, l.[Id]) AS [Rang]
          FROM staging.DocumentImportLigne l JOIN @Doc t ON t.[Id] = l.[EnteteId]
    ), P AS (
        SELECT L.*,
               CASE WHEN L.[SousTotal] = 0 THEN 0 ELSE ROUND(L.[TPS] * L.[HT] / L.[SousTotal], 2) END AS [TPSl],
               CASE WHEN L.[SousTotal] = 0 THEN 0 ELSE ROUND(L.[TVQ] * L.[HT] / L.[SousTotal], 2) END AS [TVQl]
          FROM L
    ), R AS (
        SELECT P.*,
               P.[TPS] - SUM(P.[TPSl]) OVER (PARTITION BY P.[EnteteId]) AS [ResteTPS],
               P.[TVQ] - SUM(P.[TVQl]) OVER (PARTITION BY P.[EnteteId]) AS [ResteTVQ]
          FROM P
    )
    UPDATE l
       SET l.[Montant] = R.[HT],
           l.[TPS] = R.[TPSl] + CASE WHEN R.[Rang] = 1 THEN R.[ResteTPS] ELSE 0 END,
           l.[TVQ] = R.[TVQl] + CASE WHEN R.[Rang] = 1 THEN R.[ResteTVQ] ELSE 0 END
      FROM staging.DocumentImportLigne l JOIN R ON R.[Id] = l.[Id];

    COMMIT TRANSACTION;

    SELECT @n AS NbDocuments, @PartyId AS PartyId, @Cree AS Cree;
END
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
