-- =============================================================================
-- T231 — s0781 : le montant de taxe par ligne, et des nombres qui ne cassent pas
--
-- Deux changements.
--
-- 1. La source donne tax_amount sur chaque ligne de facture. On le jetait.
--    Sans lui, la repartition TPS/TVQ ne peut travailler qu'au prorata du total
--    du document — faux des qu'une facture melange lignes taxables et exonerees.
--    La colonne staging.DocumentImportLigne.TaxeMontant (creee par T230) est
--    desormais remplie.
--
-- 2. Tous les nombres sont lus en TEXTE puis convertis par TRY_CONVERT.
--    OPENJSON ... WITH ([Montant] DECIMAL(18,2)) leve « Error converting data
--    type nvarchar to decimal » des qu'un champ arrive vide — et le cote VB
--    envoie "" pour tout champ absent chez la source. Le defaut etait latent :
--    il ne s'est vu qu'en ajoutant le montant de taxe, que QuickBooks omet
--    souvent. Les dates suivaient deja ce patron ; les montants le suivent
--    maintenant. Une valeur illisible devient NULL au lieu de faire echouer
--    l'import entier.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
