-- =============================================================================
-- T226 — Le registre accepte les nouveaux genres d'import
--
-- T225 a fait de staging.ImportFiles le registre de tout ce qui entre. Une
-- contrainte posée du temps où il n'existait que trois genres l'en empêchait :
--
--   CK_staging_ImportFiles_TypeImport : Client · Fournisseur · Produit
--
-- Le plan comptable s'y heurtait. Elle est remplacée par une liste élargie —
-- toujours une liste fermée, pour qu'une faute de frappe reste une erreur
-- plutôt qu'un genre inventé en silence.
--
-- Le script rattache aussi les documents au registre : les factures importées
-- étaient reliées à l'extraction (RunId) mais pas au fichier. Elles le sont
-- désormais, par le même chemin que le reste.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Les genres admis au registre
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK
    ([TypeImport] IN ('Client', 'Fournisseur', 'Produit',
                      'PlanComptable', 'FactureClient', 'FactureFournisseur'));
GO

-- -----------------------------------------------------------------------------
-- 2) Le lien des documents vers le fichier
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.DocumentImport', 'ImportFileId') IS NULL
    ALTER TABLE staging.DocumentImport ADD [ImportFileId] INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DocumentImport_ImportFile')
BEGIN
    -- Comme pour les lots : pas de cascade. Un document déjà créé en
    -- comptabilité ne doit pas s'effacer parce qu'on nettoie un fichier.
    ALTER TABLE staging.DocumentImport
        ADD CONSTRAINT FK_DocumentImport_ImportFile FOREIGN KEY ([ImportFileId])
            REFERENCES staging.ImportFiles ([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DocImport_ImportFile')
    CREATE INDEX IX_DocImport_ImportFile ON staging.DocumentImport ([ImportFileId]);
GO

-- -----------------------------------------------------------------------------
-- 3) s0781ChargerDocumentsImport — le fichier d'origine, en plus
--
--    Paramètre facultatif, comme pour s0751 : ce qui appelle sans lui continue
--    de fonctionner.
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
           TRY_CONVERT(DATE, j.[DateDocument]), TRY_CONVERT(DATE, j.[DateEcheance]),
           LEFT(j.[TiersExterneId], 100), j.[TiersNom],
           LEFT(j.[Devise], 10), j.[SousTotal], j.[TotalTaxes], j.[Total], j.[Solde],
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
                 [SousTotal]      DECIMAL(18,2)  '$.sous_total',
                 [TotalTaxes]     DECIMAL(18,2)  '$.taxes',
                 [Total]          DECIMAL(18,2)  '$.total',
                 [Solde]          DECIMAL(18,2)  '$.solde',
                 [StatutSource]   NVARCHAR(100)  '$.statut') AS j;

    INSERT INTO staging.DocumentImportLigne
        ([EnteteId], [LigneNo], [Description], [ProduitExterneId], [ProduitNom],
         [Quantite], [PrixUnitaire], [Montant], [TaxeCode], [CompteSource], [CompteNom])
    SELECT e.[Id], l.[LigneNo], l.[Description],
           LEFT(l.[ProduitExterneId], 100), l.[ProduitNom],
           l.[Quantite], l.[PrixUnitaire], l.[Montant],
           LEFT(l.[TaxeCode], 50), LEFT(l.[CompteSource], 100), l.[CompteNom]
      FROM OPENJSON(@Documents)
           WITH ([Rang]   INT            '$.rang',
                 [Lignes] NVARCHAR(MAX)  '$.lignes' AS JSON) AS d
     CROSS APPLY OPENJSON(d.[Lignes])
           WITH ([LigneNo]          INT            '$.no',
                 [Description]      NVARCHAR(1000) '$.description',
                 [ProduitExterneId] NVARCHAR(200)  '$.produit_id',
                 [ProduitNom]       NVARCHAR(500)  '$.produit',
                 [Quantite]         DECIMAL(18,4)  '$.qte',
                 [PrixUnitaire]     DECIMAL(18,4)  '$.prix',
                 [Montant]          DECIMAL(18,2)  '$.montant',
                 [TaxeCode]         NVARCHAR(100)  '$.taxe',
                 [CompteSource]     NVARCHAR(200)  '$.compte',
                 [CompteNom]        NVARCHAR(400)  '$.compte_nom') AS l
     INNER JOIN @Entetes e ON e.[Rang] = d.[Rang];

    UPDATE d
       SET [NbLignes] = x.[Nb]
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT COUNT(*) AS [Nb] FROM staging.DocumentImportLigne l
                   WHERE l.[EnteteId] = d.[Id]) x
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes);

    UPDATE d
       SET d.[PartyGUID] = p.[PartyGUID]
      FROM staging.DocumentImport d
     INNER JOIN dbo.T050Party p
             ON p.[CompanyGUID] = d.[CompanyGUID]
            AND (p.[Name] = d.[TiersNom] OR p.[DisplayName] = d.[TiersNom])
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes)
       AND d.[TiersNom] IS NOT NULL;

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
           SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS [NbAnomalies]
      FROM staging.DocumentImport
     WHERE [Id] IN (SELECT [Id] FROM @Entetes);
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0787GetImportsCompagnie — les documents comptent aussi
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0787GetImportsCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 100
           f.[Id], f.[TypeImport], f.[OriginalName], f.[FileExtension], f.[FileSize],
           f.[UploadDate], f.[Status], f.[ProcessedRows], f.[ModelUsed],
           l.[Id]            AS [LotId],
           l.[SystemeSource],
           l.[NbLignesLues], l.[NbLignesRetenues], l.[NbAnomalies],
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])     AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id])   AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id])    AS [NbComptes],
           (SELECT COUNT(*) FROM staging.DocumentImport di WHERE di.[ImportFileId] = f.[Id])  AS [NbDocuments]
      FROM staging.ImportFiles f
      LEFT JOIN staging.ImportLot l ON l.[ImportFileId] = f.[Id]
     WHERE f.[CompanyGUID] = @CompanyGUID
     ORDER BY f.[UploadDate] DESC;
END
GO
