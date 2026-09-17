-- =============================================================================
-- T232 — Les listes de structure : modes de paiement, catégories de suivi,
--        départements, emplacements, comptes bancaires, journaux
--
-- Six ressources, une seule table. Ce n'est pas de la paresse : ce sont six
-- listes de la même forme — un identifiant, un code, un nom, parfois un parent,
-- un statut. Six tables jumelles auraient voulu six procédures, six écrans et
-- six endroits où corriger le même défaut.
--
-- La colonne [Genre] les distingue, comme [DocumentTypeId] distingue les quatre
-- sortes de documents dans staging.DocumentImport.
--
-- Les comptes bancaires ont trois colonnes de plus (devise, numéro, solde).
-- Le NUMÉRO N'EST GARDÉ QU'EN PARTIE — les quatre derniers chiffres. Une table
-- de préparation n'est pas un endroit pour un numéro de compte complet en
-- clair, et les quatre derniers suffisent à reconnaître le compte à l'écran.
--
-- ⚠️ Deux des six — comptes bancaires et journaux — ont été RETIRÉS du catalogue
-- d'extraction : le connecteur QuickBooks d'Apideck ne les implémente pas
-- (« Spec or operation bankAccountsAll for quickbooks not found », idem pour
-- journalsAll). Proposer une case qui échoue à coup sûr n'aide personne.
--
-- La table les accepte toujours, et les colonnes bancaires restent. Le jour où
-- un connecteur les donnera — Sage, ou un QuickBooks complété — il n'y aura
-- qu'une ligne à remettre au catalogue.
--
-- Il n'existe aujourd'hui AUCUNE table de destination dans l'ERP pour ces six
-- listes. Elles s'arrêtent donc à la préparation : on les voit, on les vérifie,
-- et elles seront là le jour où la fonction correspondante existera.
--
-- Procédures : s0795 et s0796.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le registre accepte les six genres
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK
    ([TypeImport] IN ('Client', 'Fournisseur', 'Produit',
                      'PlanComptable', 'FactureClient', 'FactureFournisseur',
                      'Societe', 'Taxe',
                      'ModePaiement', 'CategorieSuivi', 'Departement',
                      'Emplacement', 'CompteBancaire', 'Journal'));
GO

-- -----------------------------------------------------------------------------
-- 2) staging.ReferenceImport
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.ReferenceImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ReferenceImport
    (
        [Id]               INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]     INT               NULL,
        [RunId]            INT               NULL,
        [CompanyGUID]      UNIQUEIDENTIFIER  NOT NULL,

        -- ModePaiement · CategorieSuivi · Departement · Emplacement ·
        -- CompteBancaire · Journal
        [Genre]            VARCHAR(30)       NOT NULL,
        [Rang]             INT               NOT NULL CONSTRAINT DF_ReferenceImport_Rang DEFAULT (0),

        [ExterneId]        NVARCHAR(100)     NULL,
        [Code]             NVARCHAR(100)     NULL,
        [Nom]              NVARCHAR(300)     NULL,
        [Description]      NVARCHAR(500)     NULL,

        -- Départements, emplacements et catégories de suivi s'emboîtent.
        [ParentExterneId]  NVARCHAR(100)     NULL,

        [TypeSource]       NVARCHAR(60)      NULL,
        [StatutSource]     NVARCHAR(40)      NULL,

        -- Comptes bancaires seulement.
        [Devise]           VARCHAR(10)       NULL,
        [NumeroMasque]     VARCHAR(20)       NULL,
        [Solde]            DECIMAL(18,2)     NULL,

        -- L'élément d'origine, pour ce que la forme commune n'a pas retenu.
        [Extra]            NVARCHAR(MAX)     NULL,

        -- NOUVEAU · DOUBLON · INVALIDE
        [Statut]           VARCHAR(20)       NOT NULL CONSTRAINT DF_ReferenceImport_Statut DEFAULT ('NOUVEAU'),
        [Anomalie]         NVARCHAR(400)     NULL,

        [Created]          DATETIME          NOT NULL CONSTRAINT DF_ReferenceImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_ReferenceImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT CK_ReferenceImport_Genre CHECK ([Genre] IN
            ('ModePaiement', 'CategorieSuivi', 'Departement',
             'Emplacement', 'CompteBancaire', 'Journal')),
        CONSTRAINT FK_ReferenceImport_ImportFile FOREIGN KEY ([ImportFileId])
            REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_ReferenceImport_Run FOREIGN KEY ([RunId])
            REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_ReferenceImport_Company ON staging.ReferenceImport ([CompanyGUID], [Genre]);
    CREATE INDEX IX_ReferenceImport_File ON staging.ReferenceImport ([ImportFileId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0795ChargerReferenceImport
--
--    Une relecture du même genre remplace la précédente : deux extractions des
--    modes de paiement ne s'empilent pas. Les autres genres ne sont pas touchés,
--    ce qui permet de n'en réimporter qu'un.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0795ChargerReferenceImport]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Genre        VARCHAR(30),
    @ImportFileId INT = NULL,
    @Elements     NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50374, 'Aucune compagnie : impossible de déposer cette liste.', 1;

    IF @Genre NOT IN ('ModePaiement', 'CategorieSuivi', 'Departement',
                      'Emplacement', 'CompteBancaire', 'Journal')
        THROW 50375, 'Genre de liste inconnu.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ReferenceImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;

    -- Les nombres sont lus en texte puis convertis : un champ vide chez la
    -- source ne doit pas faire échouer la liste entière (cf. T231).
    ;WITH Lu AS (
        SELECT j.[rang], j.[externe_id], j.[code], j.[nom], j.[description],
               j.[parent_id], j.[type], j.[statut], j.[devise], j.[numero],
               TRY_CONVERT(DECIMAL(18,2), j.[solde]) AS [solde],
               j.[extra],
               ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '')
                                      ORDER BY j.[rang]) AS [Occurrence]
          FROM OPENJSON(@Elements)
               WITH ([rang]        INT            '$.rang',
                     [externe_id]  NVARCHAR(100)  '$.externe_id',
                     [code]        NVARCHAR(100)  '$.code',
                     [nom]         NVARCHAR(300)  '$.nom',
                     [description] NVARCHAR(500)  '$.description',
                     [parent_id]   NVARCHAR(100)  '$.parent_id',
                     [type]        NVARCHAR(60)   '$.type',
                     [statut]      NVARCHAR(40)   '$.statut',
                     [devise]      VARCHAR(10)    '$.devise',
                     [numero]      NVARCHAR(40)   '$.numero',
                     [solde]       NVARCHAR(40)   '$.solde',
                     [extra]       NVARCHAR(MAX)  '$.extra' AS JSON) AS j
    )
    INSERT INTO staging.ReferenceImport
        ([ImportFileId], [RunId], [CompanyGUID], [Genre], [Rang],
         [ExterneId], [Code], [Nom], [Description], [ParentExterneId],
         [TypeSource], [StatutSource], [Devise], [NumeroMasque], [Solde], [Extra],
         [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID, @Genre, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[code], ''), NULLIF(l.[nom], ''),
           NULLIF(l.[description], ''), NULLIF(l.[parent_id], ''),
           NULLIF(l.[type], ''), NULLIF(l.[statut], ''),
           NULLIF(l.[devise], ''),
           -- Les quatre derniers chiffres suffisent à reconnaître un compte.
           CASE WHEN LEN(ISNULL(l.[numero], '')) > 4
                THEN N'••••' + RIGHT(l.[numero], 4)
                ELSE NULLIF(l.[numero], '') END,
           l.[solde], l.[extra],
           CASE
               WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL THEN 'INVALIDE'
               WHEN l.[Occurrence] > 1 THEN 'DOUBLON'
               ELSE 'NOUVEAU'
           END,
           CASE
               WHEN NULLIF(l.[nom], '') IS NULL AND NULLIF(l.[code], '') IS NULL
                   THEN N'Ni nom ni code : rien pour identifier cet élément.'
               WHEN l.[Occurrence] > 1
                   THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
               ELSE NULL
           END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbElements],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouveaux],
           SUM(CASE WHEN [Statut] = 'DOUBLON' THEN 1 ELSE 0 END)  AS [NbDoublons],
           SUM(CASE WHEN [Statut] = 'INVALIDE' THEN 1 ELSE 0 END) AS [NbInvalides]
      FROM staging.ReferenceImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0796GetReferenceImport
--    Deux jeux : le sommaire par genre pour l'onglet, puis le détail du genre
--    demandé. @Genre vide rend tout, ce qui sert à l'écran au premier affichage.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0796GetReferenceImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Genre],
           COUNT(*) AS [Nb],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbSoucis],
           MAX([Created]) AS [Dernier]
      FROM staging.ReferenceImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [Genre]
     ORDER BY [Genre];

    SELECT [Id], [ImportFileId], [RunId], [Genre], [Rang], [ExterneId], [Code],
           [Nom], [Description], [ParentExterneId], [TypeSource], [StatutSource],
           [Devise], [NumeroMasque], [Solde], [Statut], [Anomalie], [Created]
      FROM staging.ReferenceImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Genre IS NULL OR @Genre = '' OR [Genre] = @Genre)
     ORDER BY [Genre],
              CASE WHEN [Statut] <> 'NOUVEAU' THEN 0 ELSE 1 END,
              [Rang], [Nom];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0787GetImportsCompagnie — les listes de structure comptent aussi
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
           (SELECT COUNT(*) FROM staging.PartyImport pi WHERE pi.[ImportFileId] = f.[Id])      AS [NbTiers],
           (SELECT COUNT(*) FROM staging.ProductImport pr WHERE pr.[ImportFileId] = f.[Id])    AS [NbProduits],
           (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id])     AS [NbComptes],
           (SELECT COUNT(*) FROM staging.DocumentImport di WHERE di.[ImportFileId] = f.[Id])   AS [NbDocuments],
           (SELECT COUNT(*) FROM staging.SocieteImport si WHERE si.[ImportFileId] = f.[Id])    AS [NbChampsSociete],
           (SELECT COUNT(*) FROM staging.TaxeImport ti WHERE ti.[ImportFileId] = f.[Id])       AS [NbTaux],
           (SELECT COUNT(*) FROM staging.ReferenceImport ri WHERE ri.[ImportFileId] = f.[Id])  AS [NbReferences]
      FROM staging.ImportFiles f
      LEFT JOIN staging.ImportLot l ON l.[ImportFileId] = f.[Id]
     WHERE f.[CompanyGUID] = @CompanyGUID
     ORDER BY f.[UploadDate] DESC;
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0790ViderStaging — la nouvelle table part avec les autres
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0790ViderStaging]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50370, 'Aucune compagnie : refus de vider la préparation.', 1;

    DECLARE @Compte TABLE ([Ordre] INT, [Table] VARCHAR(60), [Lignes] INT);

    BEGIN TRANSACTION;

    DELETE cc FROM staging.CorrespondanceCompte cc WHERE cc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (1, 'CorrespondanceCompte', @@ROWCOUNT);

    DELETE pc FROM staging.ImportPlanComptable pc WHERE pc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (2, 'ImportPlanComptable', @@ROWCOUNT);

    DELETE l FROM staging.ImportLot l WHERE l.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (3, 'ImportLot', @@ROWCOUNT);

    DELETE dl
      FROM staging.DocumentImportLigne dl
      JOIN staging.DocumentImport di ON di.[Id] = dl.[EnteteId]
     WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (4, 'DocumentImportLigne', @@ROWCOUNT);

    DELETE di FROM staging.DocumentImport di WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (5, 'DocumentImport', @@ROWCOUNT);

    DELETE si FROM staging.SocieteImport si WHERE si.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (6, 'SocieteImport', @@ROWCOUNT);

    DELETE ti FROM staging.TaxeImport ti WHERE ti.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (7, 'TaxeImport', @@ROWCOUNT);

    DELETE ri FROM staging.ReferenceImport ri WHERE ri.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (8, 'ReferenceImport', @@ROWCOUNT);

    DELETE pi
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (9, 'PartyImport', @@ROWCOUNT);

    DELETE pr
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (10, 'ProductImport', @@ROWCOUNT);

    DELETE cd FROM staging.ConnecteurDonnee cd WHERE cd.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (11, 'ConnecteurDonnee', @@ROWCOUNT);

    DELETE cr FROM staging.ConnecteurRun cr WHERE cr.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (12, 'ConnecteurRun', @@ROWCOUNT);

    DELETE bv FROM staging.BalanceVerification bv WHERE bv.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (13, 'BalanceVerification', @@ROWCOUNT);

    DELETE f FROM staging.ImportFiles f WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (14, 'ImportFiles', @@ROWCOUNT);

    COMMIT TRANSACTION;

    SELECT [Table], [Lignes] FROM @Compte WHERE [Lignes] > 0 ORDER BY [Ordre];
    SELECT SUM([Lignes]) AS [Total] FROM @Compte;
END
GO
