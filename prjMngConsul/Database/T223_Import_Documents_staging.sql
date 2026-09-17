-- =============================================================================
-- T223 — Préparation des documents importés : factures clients et fournisseurs
--
-- Les listes — comptes, clients, produits — se valident ligne par ligne, et
-- leurs tables de préparation existaient déjà. Les documents, eux, n'avaient
-- rien : ils se déposaient en JSON brut dans staging.ConnecteurDonnee, où
-- personne ne pouvait les lire ni les approuver.
--
-- Ces deux tables comblent ce trou. Elles reprennent la forme de la destination
-- — dbo.T060Document et dbo.T061DocumentLine — pour que la promotion soit une
-- copie, pas une traduction :
--
--   staging.DocumentImport        l'entête : numéro, dates, tiers, totaux
--   staging.DocumentImportLigne   le détail : description, quantité, prix
--
-- Un seul couple de tables pour les quatre types, distingués par
-- [DocumentTypeId] comme en comptabilité : 1 facture client, 2 facture
-- fournisseur, 3 et 4 les avoirs. Deux tables par type auraient doublé le
-- schéma pour la même chose — et l'écran de validation, lui, filtre.
--
-- Ce qui est déposé n'est PAS comptabilisé. Chaque entête porte son verdict et,
-- quand il se laisse deviner, le tiers reconnu chez nous. Le client valide,
-- corrige, et c'est seulement ensuite que le document est créé.
--
-- Procédures : s0781 à s0783.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) staging.DocumentImport — l'entête
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.DocumentImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.DocumentImport
    (
        [Id]             INT IDENTITY(1,1) NOT NULL,

        -- L'extraction d'où il vient. NULL : déposé autrement qu'un connecteur.
        [RunId]          INT               NULL,
        [CompanyGUID]    UNIQUEIDENTIFIER  NOT NULL,

        -- Le même code qu'en comptabilité : 1 client, 2 fournisseur, 3 et 4 avoirs.
        [DocumentTypeId] INT               NOT NULL,

        [Rang]           INT               NOT NULL,

        -- L'identifiant chez la source : ce qui permet de reconnaître le même
        -- document d'une extraction à l'autre, quand le numéro change.
        [ExterneId]      NVARCHAR(100)     NULL,

        [Numero]         NVARCHAR(60)      NULL,
        [DateDocument]   DATE              NULL,
        [DateEcheance]   DATE              NULL,

        -- ── Le tiers ──────────────────────────────────────────────────────
        [TiersExterneId] NVARCHAR(100)     NULL,
        [TiersNom]       NVARCHAR(500)     NULL,

        -- Rempli quand le nom retrouve un tiers de la compagnie. NULL : à
        -- rapprocher à la main, et c'est justement l'objet de la validation.
        [PartyGUID]      UNIQUEIDENTIFIER  NULL,

        -- ── Les montants ──────────────────────────────────────────────────
        [Devise]         VARCHAR(10)       NULL,
        [SousTotal]      DECIMAL(18,2)     NULL,

        -- Le total des taxes tel que la source le donne. La répartition entre
        -- TPS et TVQ n'est pas déductible de façon fiable : la source ne nomme
        -- pas toujours ses taxes. On garde donc le total, et les deux colonnes
        -- suivantes restent vides jusqu'à ce que quelqu'un tranche.
        [TotalTaxes]     DECIMAL(18,2)     NULL,
        [TPS]            DECIMAL(18,2)     NULL,
        [TVQ]            DECIMAL(18,2)     NULL,

        [Total]          DECIMAL(18,2)     NULL,
        [Solde]          DECIMAL(18,2)     NULL,

        -- Le statut chez la source (« paid », « authorised »…), tel quel.
        [StatutSource]   NVARCHAR(50)      NULL,
        [NbLignes]       INT               NOT NULL CONSTRAINT DF_DocImport_NbLignes DEFAULT (0),

        -- ── Le verdict ────────────────────────────────────────────────────
        -- OK · EXISTE · DOUBLON_FICHIER · INVALIDE
        [Statut]         VARCHAR(20)       NOT NULL CONSTRAINT DF_DocImport_Statut DEFAULT ('OK'),
        [Anomalie]       NVARCHAR(1000)    NULL,

        -- ── Après validation ──────────────────────────────────────────────
        [DocumentId]     INT               NULL,
        [MigratedDate]   DATETIME          NULL,

        [Created]        DATETIME          NOT NULL CONSTRAINT DF_DocImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_DocumentImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_DocumentImport_Run FOREIGN KEY ([RunId])
            REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_DocImport_Company ON staging.DocumentImport ([CompanyGUID], [DocumentTypeId], [Statut]);
    CREATE INDEX IX_DocImport_Run ON staging.DocumentImport ([RunId], [Rang]);
    CREATE INDEX IX_DocImport_Externe ON staging.DocumentImport ([CompanyGUID], [ExterneId]);
END
GO

-- -----------------------------------------------------------------------------
-- 2) staging.DocumentImportLigne — le détail
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.DocumentImportLigne', 'U') IS NULL
BEGIN
    CREATE TABLE staging.DocumentImportLigne
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [EnteteId]         INT               NOT NULL,
        [LigneNo]          INT               NOT NULL,

        [Description]      NVARCHAR(1000)    NULL,

        -- ── L'article ─────────────────────────────────────────────────────
        [ProduitExterneId] NVARCHAR(100)     NULL,
        [ProduitNom]       NVARCHAR(500)     NULL,

        -- Rempli quand le nom retrouve un produit de la compagnie.
        [ProductId]        INT               NULL,

        [Quantite]         DECIMAL(18,4)     NULL,
        [PrixUnitaire]     DECIMAL(18,4)     NULL,
        [Montant]          DECIMAL(18,2)     NULL,

        -- ── Taxes et imputation ───────────────────────────────────────────
        [TaxeCode]         NVARCHAR(50)      NULL,
        [TPS]              DECIMAL(18,2)     NULL,
        [TVQ]              DECIMAL(18,2)     NULL,

        -- Le compte tel que la source le nomme. La correspondance avec notre
        -- plan comptable se fait ailleurs — c'est le travail de l'écran du plan.
        [CompteSource]     NVARCHAR(100)     NULL,
        [CompteNom]        NVARCHAR(400)     NULL,

        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_DocImportLigne_Statut DEFAULT ('OK'),
        [Anomalie]         NVARCHAR(1000)    NULL,
        [Created]          DATETIME          NOT NULL CONSTRAINT DF_DocImportLigne_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_DocumentImportLigne PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_DocumentImportLigne_Entete FOREIGN KEY ([EnteteId])
            REFERENCES staging.DocumentImport ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_DocImportLigne_Entete ON staging.DocumentImportLigne ([EnteteId], [LigneNo]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0781ChargerDocumentsImport
--    Dépose une fournée de documents, entêtes et lignes en un seul appel. Le
--    JSON porte les lignes imbriquées dans chaque entête : les séparer en deux
--    appels obligerait à inventer une clé provisoire pour les raccorder.
--
--    Recharger la même extraction et le même type remplace ce qui s'y trouvait :
--    on ne cumule pas deux lectures des mêmes factures.
--
--    Trois verdicts, posés ici plutôt que dans le code : on voit tout le lot
--    d'un coup, ce qu'un aller-retour par document ne permet pas.
--
--      INVALIDE        ni numéro ni identifiant source — rien pour l'identifier
--      DOUBLON_FICHIER le même numéro apparaît plus haut dans la fournée
--      EXISTE          un document de ce numéro existe déjà en comptabilité ;
--                      ce n'est pas une erreur, c'est ce qu'on veut savoir
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0781ChargerDocumentsImport]
    @RunId          INT,
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT,
    @Documents      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50364, 'Aucune compagnie : impossible de déposer des documents.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.DocumentImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND [DocumentTypeId] = @DocumentTypeId
       AND (([RunId] IS NULL AND @RunId IS NULL) OR [RunId] = @RunId);

    -- ── Les entêtes ──────────────────────────────────────────────────────
    DECLARE @Entetes TABLE ([Id] INT, [Rang] INT);

    INSERT INTO staging.DocumentImport
        ([RunId], [CompanyGUID], [DocumentTypeId], [Rang], [ExterneId], [Numero],
         [DateDocument], [DateEcheance], [TiersExterneId], [TiersNom],
         [Devise], [SousTotal], [TotalTaxes], [Total], [Solde], [StatutSource])
    OUTPUT INSERTED.[Id], INSERTED.[Rang] INTO @Entetes
    SELECT @RunId, @CompanyGUID, @DocumentTypeId,
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

    -- ── Les lignes ───────────────────────────────────────────────────────
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

    -- ── Le tiers, quand son nom suffit à le retrouver ─────────────────────
    UPDATE d
       SET d.[PartyGUID] = p.[PartyGUID]
      FROM staging.DocumentImport d
     INNER JOIN dbo.T050Party p
             ON p.[CompanyGUID] = d.[CompanyGUID]
            AND (p.[Name] = d.[TiersNom] OR p.[DisplayName] = d.[TiersNom])
     WHERE d.[Id] IN (SELECT [Id] FROM @Entetes)
       AND d.[TiersNom] IS NOT NULL;

    -- ── Les verdicts ─────────────────────────────────────────────────────
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
-- 4) s0782GetDocumentsImport
--    Ce que l'écran de validation affiche : les entêtes, puis toutes leurs
--    lignes. Deux jeux de résultats plutôt qu'une jointure — sinon l'entête se
--    répète autant de fois qu'il a de lignes.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0782GetDocumentsImport]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT = NULL,
    @RunId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT d.[Id], d.[RunId], d.[DocumentTypeId], d.[Rang], d.[ExterneId], d.[Numero],
           d.[DateDocument], d.[DateEcheance], d.[TiersExterneId], d.[TiersNom], d.[PartyGUID],
           p.[Name] AS [TiersReconnu],
           d.[Devise], d.[SousTotal], d.[TotalTaxes], d.[TPS], d.[TVQ], d.[Total], d.[Solde],
           d.[StatutSource], d.[NbLignes], d.[Statut], d.[Anomalie],
           d.[DocumentId], d.[MigratedDate], d.[Created]
      FROM staging.DocumentImport d
      LEFT JOIN dbo.T050Party p ON p.[PartyGUID] = d.[PartyGUID]
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
-- 5) s0783SupprimerDocumentsImport
--    Abandonne une fournée, ou un seul document qu'on ne veut pas reprendre.
--    Les lignes suivent par cascade. Rien n'ayant été comptabilisé, la
--    suppression est sans conséquence.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0783SupprimerDocumentsImport]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @RunId          INT = NULL,
    @DocumentTypeId INT = NULL,
    @EnteteId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @EnteteId IS NULL AND @RunId IS NULL AND @DocumentTypeId IS NULL
        THROW 50365, 'Précisez ce qu''il faut supprimer : une extraction, un type ou un document.', 1;

    DELETE FROM staging.DocumentImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@EnteteId IS NULL OR [Id] = @EnteteId)
       AND (@RunId IS NULL OR [RunId] = @RunId)
       AND (@DocumentTypeId IS NULL OR [DocumentTypeId] = @DocumentTypeId);

    SELECT @@ROWCOUNT AS [NbSupprimes];
END
GO
