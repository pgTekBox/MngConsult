-- =============================================================================
-- T261 — Les factures reconnaissent leur tiers dans la PRÉPARATION, pas en production
--
-- Jusqu'ici s0781 cherchait le tiers d'une facture dans dbo.T050Party, par
-- le nom, et l'écran offrait une liste déroulante pour « rapprocher d'un
-- tiers » à la main. Deux défauts : une facture pouvait se rattacher à un
-- tiers saisi jadis dans l'application, sans rapport avec la reprise ; et le
-- choix manuel ouvrait la porte à l'erreur d'un clic.
--
-- Désormais la chaîne est celle de la reprise elle-même :
--
--   clients / fournisseurs importés → staging.PartyImport → créés → T050Party
--                                             ▲
--   factures importées → staging.DocumentImport.PartyImportId ──┘
--
--   · s0781 reconnaît le tiers parmi les clients et fournisseurs EN
--     PRÉPARATION : par l'identifiant source d'abord (le même client chez
--     QuickBooks), par le nom exact sinon. Jamais dans dbo directement.
--   · s0785 ne crée une facture que si ce tiers a été créé depuis l'écran
--     Clients ou Fournisseurs (PartyImport.MigratedToPartyId) : c'est là
--     qu'on le retrouve en T050Party, au moment de créer, jamais avant.
--   · s0784 ne touche plus au tiers : seules TPS et TVQ se corrigent.
--
-- Une facture dont le tiers n'est pas en préparation attend : il faut
-- importer les clients ou fournisseurs, puis les créer. L'écran le dit.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le lien vers le tiers en préparation
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.DocumentImport', 'PartyImportId') IS NULL
    ALTER TABLE staging.DocumentImport ADD [PartyImportId] INT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DocImport_PartyImport')
    CREATE INDEX IX_DocImport_PartyImport ON staging.DocumentImport ([PartyImportId]);
GO

-- -----------------------------------------------------------------------------
-- 2) s0781ChargerDocumentsImport — le tiers, dans la préparation
--    Même corps qu'en T226/T230 ; seule la reconnaissance du tiers change.
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

    -- Le genre de tiers que ce type de document attend.
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

    -- ── Le tiers, dans la PRÉPARATION ───────────────────────────────────────
    -- 1) Par l'identifiant source : le même client chez QuickBooks, importé
    --    depuis l'écran Clients ou Fournisseurs. La plus récente extraction
    --    du bon genre fait foi.
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

    -- 2) Par le nom exact, sinon — un fichier CSV n'a pas d'identifiant source.
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

    -- 3) Le tiers en préparation a-t-il déjà été créé ? Alors on connaît son
    --    PartyGUID. Sinon il reste NULL, et la facture attend sa création.
    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes);

    -- ── Les verdicts, inchangés ─────────────────────────────────────────────
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
-- 3) s0782GetDocumentsImport — le tiers tel que la préparation le connaît
--    TiersReconnu = le nom en préparation ; TiersCree = 1 quand il a été créé.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0782GetDocumentsImport]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT = NULL,
    @RunId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Un tiers créé depuis la dernière extraction : on le reconnaît au passage,
    -- pour que l'écran n'ait pas à attendre une relecture.
    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;

    SELECT d.[Id], d.[RunId], d.[DocumentTypeId], d.[Rang], d.[ExterneId], d.[Numero],
           d.[DateDocument], d.[DateEcheance], d.[TiersExterneId], d.[TiersNom], d.[PartyGUID],
           d.[PartyImportId],
           p.[Name] AS [TiersReconnu],
           CASE WHEN p.[MigratedToPartyId] IS NOT NULL THEN 1 ELSE 0 END AS [TiersCree],
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
           l.[ProduitExterneId], l.[ProduitNom], l.[ProductId],
           l.[Quantite], l.[PrixUnitaire], l.[Montant],
           l.[TaxeCode], l.[TPS], l.[TVQ], l.[CompteSource], l.[CompteNom],
           l.[Statut], l.[Anomalie]
      FROM staging.DocumentImportLigne l
     INNER JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (@DocumentTypeId IS NULL OR d.[DocumentTypeId] = @DocumentTypeId)
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     ORDER BY l.[EnteteId], l.[LigneNo];
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0784MajDocumentImport — TPS et TVQ seulement
--    Le paramètre @PartyGUID reste pour les appelants alignés sur l'ancienne
--    signature, mais il est ignoré : le tiers ne se choisit plus à la main.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0784MajDocumentImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @EnteteId    INT,
    @PartyGUID   UNIQUEIDENTIFIER = NULL,
    @TPS         DECIMAL(18,2) = NULL,
    @TVQ         DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.DocumentImport
                    WHERE [Id] = @EnteteId AND [CompanyGUID] = @CompanyGUID)
        THROW 50366, 'Document introuvable pour cette compagnie.', 1;

    UPDATE staging.DocumentImport
       SET [TPS] = @TPS,
           [TVQ] = @TVQ
     WHERE [Id] = @EnteteId
       AND [CompanyGUID] = @CompanyGUID
       AND [DocumentId] IS NULL;   -- déjà migré : on n'y touche plus
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0785CreerDocumentsDepuisImport — le tiers se résout au moment de créer
--    Même corps qu'en T224/T248 ; en plus, avant de choisir les aptes, on
--    retrouve le PartyGUID des tiers créés depuis. NbSansTiers compte ce qui
--    attend encore la création de son client ou fournisseur.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0785CreerDocumentsDepuisImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ids         NVARCHAR(MAX),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE d
       SET d.[PartyGUID] = t.[PartyGUID]
      FROM staging.DocumentImport d
      JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
      JOIN dbo.T050Party t ON t.[Id] = p.[MigratedToPartyId] AND ISNULL(t.[isDeleted], 0) = 0
     WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyGUID] IS NULL AND d.[DocumentId] IS NULL;

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
