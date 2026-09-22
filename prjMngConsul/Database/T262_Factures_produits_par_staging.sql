-- =============================================================================
-- T262 — Les lignes de facture reconnaissent leur produit dans la PRÉPARATION
--
-- Même principe que T261 pour le tiers : le produit d'une ligne est reconnu
-- parmi les produits et services IMPORTÉS (staging.ProductImport), par
-- l'identifiant source d'abord, par le nom exact sinon. Le ProductId de
-- T075Products n'est posé que si ce produit a été créé depuis l'écran
-- Produits et services — ou l'avait été par un import antérieur (T075.SourceId).
--
-- Un produit absent ne bloque pas la facture : une ligne peut être du texte
-- libre, et T061DocumentLine accepte un ProductId nul. L'écran le montre.
--
-- En plus, pour le tiers : un client créé par un import ANTÉRIEUR porte un
-- SourceId (T257) ; une extraction plus récente de la liste des clients
-- donne des lignes Pending sans MigratedToPartyId. On accepte désormais ce
-- chemin — staging → SourceId → T050Party — qui reste celui de l'import.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('staging.DocumentImportLigne', 'ProductImportId') IS NULL
    ALTER TABLE staging.DocumentImportLigne ADD [ProductImportId] INT NULL;
GO

-- -----------------------------------------------------------------------------
-- 1) dbo.s0855ResoudreDocumentsImport — le tiers et les produits, en un seul geste
--    Appelée par s0781 (au dépôt), s0782 (à l'affichage) et s0785 (à la création) :
--    ce qui a été créé entre-temps est reconnu sans relire les factures.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0855ResoudreDocumentsImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Le tiers : créé depuis l'écran (MigratedToPartyId), ou créé par un
    -- import antérieur (même SourceId). Jamais un tiers saisi à la main.
    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;

    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
     CROSS APPLY (SELECT TOP 1 x.[PartyGUID] FROM dbo.T050Party x
                   WHERE x.[CompanyGUID] = @CompanyGUID AND ISNULL(x.[isDeleted], 0) = 0
                     AND x.[SourceId] = p.[SourceId]
                   ORDER BY x.[Id]) t
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL
       AND p.[MigratedToPartyId] IS NULL AND NULLIF(p.[SourceId], '') IS NOT NULL;

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

    -- Puis le produit créé : depuis l'écran, ou par un import antérieur.
    UPDATE l
       SET l.[ProductId] = p.[MigratedToProductId]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ProductImport p ON p.[Id] = l.[ProductImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductId] IS NULL AND p.[MigratedToProductId] IS NOT NULL;

    UPDATE l
       SET l.[ProductId] = t.[Id]
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.ProductImport p ON p.[Id] = l.[ProductImportId]
     CROSS APPLY (SELECT TOP 1 x.[Id] FROM dbo.T075Products x
                   WHERE x.[CompanyGUID] = @CompanyGUID AND x.[SourceId] = p.[SourceId]
                   ORDER BY x.[Id]) t
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
       AND l.[ProductId] IS NULL AND p.[MigratedToProductId] IS NULL AND NULLIF(p.[SourceId], '') IS NOT NULL;
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0781ChargerDocumentsImport — dépose, lie le tiers, puis résout tout
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0781ChargerDocumentsImport]
    @RunId          INT,
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT,
    @Documents      NVARCHAR(MAX),
    @ImportFileId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50364, 'Aucune compagnie : impossible de déposer des documents.', 1;

    IF @ImportFileId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportFiles
                        WHERE [Id] = @ImportFileId
                          AND ([CompanyGUID] IS NULL OR [CompanyGUID] = @CompanyGUID))
        THROW 50368, 'Le fichier d''importation n''appartient pas à cette compagnie.', 1;

    DECLARE @TypeTiers VARCHAR(20) =
        CASE WHEN @DocumentTypeId IN (2, 4, 6) THEN 'Fournisseur' ELSE 'Client' END;

    BEGIN TRANSACTION;

    DELETE FROM staging.DocumentImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND [DocumentTypeId] = @DocumentTypeId
       AND (([RunId] IS NULL AND @RunId IS NULL) OR [RunId] = @RunId);

    DECLARE @Entetes TABLE ([Id] INT, [Rang] INT);

    INSERT INTO staging.DocumentImport
        ([RunId], [ImportFileId], [CompanyGUID], [DocumentTypeId], [Rang], [ExterneId], [Numero],
         [DateDocument], [DateEcheance], [TiersExterneId], [TiersNom],
         [Devise], [SousTotal], [TotalTaxes], [Total], [Solde], [StatutSource])
    OUTPUT INSERTED.[Id], INSERTED.[Rang] INTO @Entetes
    SELECT @RunId, @ImportFileId, @CompanyGUID, @DocumentTypeId,
           j.[Rang], LEFT(j.[ExterneId], 100), LEFT(j.[Numero], 60),
           TRY_CONVERT(DATE, NULLIF(j.[DateDocument], '')),
           TRY_CONVERT(DATE, NULLIF(j.[DateEcheance], '')),
           LEFT(j.[TiersExterneId], 100), j.[TiersNom],
           LEFT(j.[Devise], 10),
           TRY_CONVERT(DECIMAL(18,2), j.[SousTotal]),
           TRY_CONVERT(DECIMAL(18,2), j.[TotalTaxes]),
           TRY_CONVERT(DECIMAL(18,2), j.[Total]),
           TRY_CONVERT(DECIMAL(18,2), j.[Solde]),
           LEFT(j.[StatutSource], 50)
      FROM OPENJSON(@Documents)
           WITH ([Rang]           INT            '$.rang',
                 [ExterneId]      NVARCHAR(200)  '$.externe_id',
                 [Numero]         NVARCHAR(100)  '$.numero',
                 [DateDocument]   NVARCHAR(40)   '$.date',
                 [DateEcheance]   NVARCHAR(40)   '$.echeance',
                 [TiersExterneId] NVARCHAR(200)  '$.tiers_id',
                 [TiersNom]       NVARCHAR(500)  '$.tiers',
                 [Devise]         NVARCHAR(20)   '$.devise',
                 [SousTotal]      NVARCHAR(40)   '$.sous_total',
                 [TotalTaxes]     NVARCHAR(40)   '$.taxes',
                 [Total]          NVARCHAR(40)   '$.total',
                 [Solde]          NVARCHAR(40)   '$.solde',
                 [StatutSource]   NVARCHAR(100)  '$.statut') AS j;

    INSERT INTO staging.DocumentImportLigne
        ([EnteteId], [LigneNo], [Description], [ProduitExterneId], [ProduitNom],
         [Quantite], [PrixUnitaire], [Montant], [TaxeCode], [TaxeMontant], [CompteSource], [CompteNom])
    SELECT e.[Id], l.[LigneNo], l.[Description],
           LEFT(l.[ProduitExterneId], 100), l.[ProduitNom],
           TRY_CONVERT(DECIMAL(18,4), l.[Quantite]),
           TRY_CONVERT(DECIMAL(18,4), l.[PrixUnitaire]),
           TRY_CONVERT(DECIMAL(18,2), l.[Montant]),
           LEFT(l.[TaxeCode], 50), TRY_CONVERT(DECIMAL(18,2), l.[TaxeMontant]),
           LEFT(l.[CompteSource], 100), l.[CompteNom]
      FROM OPENJSON(@Documents)
           WITH ([Rang]   INT            '$.rang',
                 [Lignes] NVARCHAR(MAX)  '$.lignes' AS JSON) AS d
     CROSS APPLY OPENJSON(d.[Lignes])
           WITH ([LigneNo]          INT            '$.no',
                 [Description]      NVARCHAR(1000) '$.description',
                 [ProduitExterneId] NVARCHAR(200)  '$.produit_id',
                 [ProduitNom]       NVARCHAR(500)  '$.produit',
                 [Quantite]         NVARCHAR(40)   '$.qte',
                 [PrixUnitaire]     NVARCHAR(40)   '$.prix',
                 [Montant]          NVARCHAR(40)   '$.montant',
                 [TaxeCode]         NVARCHAR(100)  '$.taxe',
                 [TaxeMontant]      NVARCHAR(40)   '$.taxe_montant',
                 [CompteSource]     NVARCHAR(200)  '$.compte',
                 [CompteNom]        NVARCHAR(400)  '$.compte_nom') AS l
     INNER JOIN @Entetes e ON e.[Rang] = d.[Rang];

    UPDATE d
       SET [NbLignes] = x.[Nb]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT COUNT(*) AS [Nb] FROM staging.DocumentImportLigne l
                   WHERE l.[EnteteId] = d.[Id]) x
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes);

    -- Le tiers, dans la préparation : par identifiant source, puis par nom.
    UPDATE d
       SET d.[PartyImportId] = x.[Id]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.PartyImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID
                     AND p.[TypeImport] = @TypeTiers
                     AND p.[SourceId] = d.[TiersExterneId]
                     AND p.[Status] <> 'Error'
                   ORDER BY p.[Id] DESC) x
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes)
       AND NULLIF(d.[TiersExterneId], '') IS NOT NULL;

    UPDATE d
       SET d.[PartyImportId] = x.[Id]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT TOP 1 p.[Id]
                    FROM staging.PartyImport p
                    JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
                   WHERE f.[CompanyGUID] = @CompanyGUID
                     AND p.[TypeImport] = @TypeTiers
                     AND p.[Status] <> 'Error'
                     AND (UPPER(LTRIM(RTRIM(p.[Name]))) = UPPER(LTRIM(RTRIM(d.[TiersNom])))
                          OR UPPER(LTRIM(RTRIM(ISNULL(p.[DisplayName], '')))) = UPPER(LTRIM(RTRIM(d.[TiersNom]))))
                   ORDER BY p.[Id] DESC) x
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes)
       AND d.[PartyImportId] IS NULL
       AND NULLIF(LTRIM(RTRIM(d.[TiersNom])), '') IS NOT NULL;

    -- Les verdicts.
    UPDATE staging.DocumentImport
       SET [Statut]   = 'INVALIDE',
           [Anomalie] = N'Ni numéro ni identifiant source : rien ne permet d''identifier ce document.'
     WHERE [Id] IN (SELECT [Id] FROM @Entetes)
       AND ISNULL([Numero], '') = ''
       AND ISNULL([ExterneId], '') = '';

    ;WITH doublons AS (
        SELECT [Id], ROW_NUMBER() OVER (PARTITION BY [Numero] ORDER BY [Rang]) AS rn
          FROM staging.DocumentImport
         WHERE [Id] IN (SELECT [Id] FROM @Entetes)
           AND [Statut] = 'OK'
           AND ISNULL([Numero], '') <> ''
    )
    UPDATE d
       SET d.[Statut]   = 'DOUBLON_FICHIER',
           d.[Anomalie] = N'Ce numéro apparaît plus haut dans la même extraction.'
      FROM staging.DocumentImport d
     INNER JOIN doublons x ON x.[Id] = d.[Id]
     WHERE x.rn > 1;

    UPDATE d
       SET d.[Statut]     = 'EXISTE',
           d.[Anomalie]   = N'Déjà en comptabilité : document ' + CAST(t.[Id] AS NVARCHAR(20)) + N'.',
           d.[DocumentId] = t.[Id]
      FROM staging.DocumentImport d
     INNER JOIN dbo.T060Document t
             ON t.[CompanyGUID] = d.[CompanyGUID]
            AND t.[DocumentTypeId] = d.[DocumentTypeId]
            AND t.[DocumentNumber] = d.[Numero]
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes)
       AND d.[Statut] = 'OK';

    COMMIT TRANSACTION;

    EXEC dbo.s0855ResoudreDocumentsImport @CompanyGUID = @CompanyGUID;

    SELECT COUNT(*) AS [NbDocuments],
           SUM(CASE WHEN [Statut] = 'OK' THEN 1 ELSE 0 END) AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'EXISTE' THEN 1 ELSE 0 END) AS [NbExistants],
           SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS [NbAnomalies],
           SUM(CASE WHEN [PartyImportId] IS NULL THEN 1 ELSE 0 END) AS [NbSansTiers]
      FROM staging.DocumentImport
     WHERE [Id] IN (SELECT [Id] FROM @Entetes);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0782GetDocumentsImport — les lignes disent leur produit en préparation
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
           l.[Statut], l.[Anomalie]
      FROM staging.DocumentImportLigne l
     INNER JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      LEFT JOIN staging.ProductImport pi ON pi.[Id] = l.[ProductImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (@DocumentTypeId IS NULL OR d.[DocumentTypeId] = @DocumentTypeId)
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     ORDER BY l.[EnteteId], l.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0785CreerDocumentsDepuisImport — résout tout, puis crée
--    Même corps qu'en T261 ; seul le premier pas change.
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
           pc.[Compte],
           l.[LigneNo],
           ISNULL(l.[Montant], 0)
      FROM staging.DocumentImportLigne l
     INNER JOIN @Crees c ON c.[EnteteId] = l.[EnteteId]
      LEFT JOIN dbo.T121PlanComptable pc
             ON pc.[CompanyGUID] = @CompanyGUID
            AND pc.[Compte] = l.[CompteSource]
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
