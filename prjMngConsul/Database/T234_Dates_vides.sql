-- =============================================================================
-- T234 — Une chaîne vide n'est pas une date
--
-- TRY_CONVERT(DATE, '') ne rend PAS NULL : SQL Server convertit la chaîne vide
-- en 1900-01-01. La conversion réussit, donc TRY_CONVERT n'a rien à rattraper.
--
-- Le côté VB envoie "" pour tout champ absent chez la source. Une facture sans
-- date d'échéance arrivait donc en base avec une échéance au 1er janvier 1900 —
-- une valeur qui a l'air d'une donnée, se trie, s'affiche, et fait paraître la
-- facture en retard de cent-vingt-six ans.
--
-- Le remède tient en un mot : NULLIF avant la conversion. Corrigé partout où une
-- date vient d'un JSON externe — s0781 (documents, défaut présent depuis
-- l'origine) et s0802 (comptes bancaires, introduit par T233).
--
-- À retenir : TRY_CONVERT protège d'une valeur ILLISIBLE, pas d'une valeur VIDE.
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


CREATE OR ALTER PROCEDURE [dbo].[s0802ChargerComptesBancairesImport]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @ImportFileId INT = NULL, @Elements NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @CompanyGUID IS NULL THROW 50381, 'Aucune compagnie : impossible de déposer les comptes bancaires.', 1;

    BEGIN TRANSACTION;
    DELETE FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Elements)
               WITH ([rang] INT '$.rang', [externe_id] NVARCHAR(100) '$.externe_id',
                     [nom] NVARCHAR(300) '$.nom', [numero] NVARCHAR(60) '$.numero',
                     [institution] NVARCHAR(200) '$.institution', [type] NVARCHAR(60) '$.type',
                     [devise] VARCHAR(10) '$.devise',
                     [solde] NVARCHAR(40) '$.solde', [solde_dispo] NVARCHAR(40) '$.solde_dispo',
                     [date_solde] NVARCHAR(40) '$.date_solde',
                     [compte_gl_id] NVARCHAR(100) '$.compte_gl_id',
                     [compte_gl_nom] NVARCHAR(300) '$.compte_gl_nom',
                     [statut] NVARCHAR(40) '$.statut',
                     [extra] NVARCHAR(MAX) '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.CompteBancaireImport
        ([ImportFileId], [RunId], [CompanyGUID], [Rang], [ExterneId], [Nom], [NumeroMasque],
         [InstitutionNom], [TypeCompte], [Devise], [Solde], [SoldeDisponible], [DateSolde],
         [CompteGLExterneId], [CompteGLNom], [StatutSource], [Extra], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[nom], ''),
           -- 🔒 Le masquage se fait ICI, avant l'écriture : le numéro complet
           --    ne se trouve à aucun moment dans la table.
           CASE WHEN LEN(ISNULL(l.[numero], '')) > 4
                THEN N'••••' + RIGHT(l.[numero], 4)
                ELSE NULLIF(l.[numero], '') END,
           NULLIF(l.[institution], ''), NULLIF(l.[type], ''), NULLIF(l.[devise], ''),
           TRY_CONVERT(DECIMAL(18,2), l.[solde]),
           TRY_CONVERT(DECIMAL(18,2), l.[solde_dispo]),
           TRY_CONVERT(DATE, NULLIF(l.[date_solde], '')),
           NULLIF(l.[compte_gl_id], ''), NULLIF(l.[compte_gl_nom], ''),
           NULLIF(l.[statut], ''), l.[extra],
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[numero], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[numero], '') IS NULL
                     THEN N'Ni nom ni numéro : rien pour identifier ce compte.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.CompteBancaireImport WHERE [CompanyGUID] = @CompanyGUID;
END

GO

