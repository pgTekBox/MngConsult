-- =============================================================================
-- T298 — Les alias QuickBooks dans une table à part : plusieurs alias par compte
--
-- Les trois colonnes de T121 (QBOCompteFR / QBOCompteEN / QBOSousType, T292) ne
-- tenaient qu'un nom par langue. Un compte d'ici peut correspondre à plusieurs
-- comptes QuickBooks (« Rabais », « Rabais accordés », « Discounts given »…),
-- et d'autres logiciels viendront. D'où :
--
--   dbo.T122PlanComptableAlias : CompanyGUID (le modèle), Compte (numéro d'ici),
--       SystemeSource ('QBO'), Langue (FR / EN / NULL), NomSource (le nom chez la
--       source, UNIQUE par compagnie et système), SousType (sous-type QBO),
--       Created / CreatedBy. Les alias vivent sur la compagnie modèle seulement :
--       la correspondance les lit et retombe sur le compte de même numéro chez la
--       compagnie. Rien n'est copié par s0500.
--   Migration : les colonnes de T121 du modèle alimentent la table (FR et EN,
--       sous-type avec chacun). Les colonnes restent en place mais ne sont plus
--       lues ni écrites ; un script ultérieur les retirera.
--   s0878 / s0879 / s0880 : lire, enregistrer, retirer un alias (Sec60Admin).
--   s0874 : la liaison d'office lit la table (nom, puis sous-type s'il ne désigne
--       qu'un seul compte).
--   s0048 / s0049 : colonne QBOAlias (tous les alias du compte, en une ligne) à
--       la place des trois colonnes. s0054 / s0055 : sans paramètres d'alias.
--   s0875 / s0876 : « déjà au modèle » par alias lit la table ; l'ajout d'un
--       candidat pose son alias dans la table.
--   s0877 : ne touche plus aux alias (ils ne sont plus par compagnie).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T122PlanComptableAlias') IS NULL
BEGIN
    CREATE TABLE dbo.T122PlanComptableAlias
    (
        [Id]            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T122PlanComptableAlias PRIMARY KEY CLUSTERED,
        [CompanyGUID]   UNIQUEIDENTIFIER  NOT NULL,
        [Compte]        VARCHAR(10)       NOT NULL,
        [SystemeSource] VARCHAR(20)       NOT NULL CONSTRAINT DF_T122_SystemeSource DEFAULT ('QBO'),
        [Langue]        CHAR(2)           NULL,
        [NomSource]     NVARCHAR(200)     NOT NULL,
        [SousType]      NVARCHAR(100)     NULL,
        [Created]       DATETIME          NOT NULL CONSTRAINT DF_T122_Created DEFAULT (GETDATE()),
        [CreatedBy]     NVARCHAR(200)     NULL
    );
    CREATE UNIQUE INDEX UX_T122_Nom ON dbo.T122PlanComptableAlias ([CompanyGUID], [SystemeSource], [NomSource]);
    CREATE INDEX IX_T122_Compte ON dbo.T122PlanComptableAlias ([CompanyGUID], [Compte]);
END
GO

-- -----------------------------------------------------------------------------
-- Migration des colonnes de T121 (compagnie modèle) vers la table
-- -----------------------------------------------------------------------------
DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

INSERT INTO dbo.T122PlanComptableAlias ([CompanyGUID], [Compte], [SystemeSource], [Langue], [NomSource], [SousType], [CreatedBy])
SELECT @Model, m.[Compte], 'QBO', 'FR', LTRIM(RTRIM(m.[QBOCompteFR])), NULLIF(LTRIM(RTRIM(m.[QBOSousType])), ''), N'T298 (migration des colonnes)'
  FROM dbo.T121PlanComptable m
 WHERE m.[CompanyGUID] = @Model
   AND NULLIF(LTRIM(RTRIM(m.[QBOCompteFR])), '') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.T122PlanComptableAlias a
                    WHERE a.[CompanyGUID] = @Model AND a.[SystemeSource] = 'QBO'
                      AND a.[NomSource] = LTRIM(RTRIM(m.[QBOCompteFR])));
PRINT N'Alias français migrés : ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N'.';

INSERT INTO dbo.T122PlanComptableAlias ([CompanyGUID], [Compte], [SystemeSource], [Langue], [NomSource], [SousType], [CreatedBy])
SELECT @Model, m.[Compte], 'QBO', 'EN', LTRIM(RTRIM(m.[QBOCompteEN])), NULLIF(LTRIM(RTRIM(m.[QBOSousType])), ''), N'T298 (migration des colonnes)'
  FROM dbo.T121PlanComptable m
 WHERE m.[CompanyGUID] = @Model
   AND NULLIF(LTRIM(RTRIM(m.[QBOCompteEN])), '') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.T122PlanComptableAlias a
                    WHERE a.[CompanyGUID] = @Model AND a.[SystemeSource] = 'QBO'
                      AND a.[NomSource] = LTRIM(RTRIM(m.[QBOCompteEN])));
PRINT N'Alias anglais migrés : ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N'.';
GO

-- -----------------------------------------------------------------------------
-- s0878 — les alias (tous, ou ceux d'un compte)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0878GetAliasPlanComptable]
    @CompanyGUID UNIQUEIDENTIFIER = NULL,   -- NULL : la compagnie modèle
    @Compte      VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL SET @CompanyGUID = '00000000-0000-0000-0000-000000000001';
    SELECT a.[Id], a.[Compte], a.[SystemeSource], a.[Langue], a.[NomSource], a.[SousType], a.[Created], a.[CreatedBy],
           c.[Nom] AS [CompteNom]
      FROM dbo.T122PlanComptableAlias a
      LEFT JOIN dbo.T121PlanComptable c ON c.[CompanyGUID] = a.[CompanyGUID] AND c.[Compte] = a.[Compte]
     WHERE a.[CompanyGUID] = @CompanyGUID
       AND (@Compte IS NULL OR a.[Compte] = @Compte)
     ORDER BY a.[Compte], a.[SystemeSource], a.[Langue], a.[NomSource];
END
GO

-- -----------------------------------------------------------------------------
-- s0879 — ajouter ou corriger un alias
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0879SaveAliasPlanComptable]
    @CompanyGUID   UNIQUEIDENTIFIER = NULL,   -- NULL : la compagnie modèle
    @Id            INT = NULL,
    @Compte        VARCHAR(10),
    @SystemeSource VARCHAR(20) = 'QBO',
    @Langue        CHAR(2) = NULL,
    @NomSource     NVARCHAR(200),
    @SousType      NVARCHAR(100) = NULL,
    @CreatedBy     NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL SET @CompanyGUID = '00000000-0000-0000-0000-000000000001';
    SET @NomSource = NULLIF(LTRIM(RTRIM(ISNULL(@NomSource, ''))), '');
    SET @SousType  = NULLIF(LTRIM(RTRIM(ISNULL(@SousType, ''))), '');
    SET @Langue    = NULLIF(UPPER(LTRIM(RTRIM(ISNULL(@Langue, '')))), '');
    IF @Langue NOT IN ('FR', 'EN', 'ES') SET @Langue = NULL;
    SET @SystemeSource = ISNULL(NULLIF(LTRIM(RTRIM(@SystemeSource)), ''), 'QBO');

    IF @NomSource IS NULL
    BEGIN
        SELECT NULL AS [Id], 'REFUSE' AS [Action], N'Le nom chez la source est obligatoire.' AS [Message]; RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @Compte)
    BEGIN
        SELECT NULL AS [Id], 'REFUSE' AS [Action], N'Le compte ' + ISNULL(@Compte, '?') + N' n''existe pas dans ce plan.' AS [Message]; RETURN;
    END

    -- Un même nom source ne peut mener qu'à un seul compte.
    DECLARE @autreId INT, @autreCompte VARCHAR(10);
    SELECT TOP 1 @autreId = a.[Id], @autreCompte = a.[Compte]
      FROM dbo.T122PlanComptableAlias a
     WHERE a.[CompanyGUID] = @CompanyGUID AND a.[SystemeSource] = @SystemeSource
       AND a.[NomSource] = @NomSource AND (@Id IS NULL OR a.[Id] <> @Id);
    IF @autreId IS NOT NULL AND @autreCompte <> @Compte
    BEGIN
        SELECT @autreId AS [Id], 'REFUSE' AS [Action],
               N'« ' + @NomSource + N' » est déjà l''alias du compte ' + @autreCompte + N' : un nom source ne peut mener qu''à un seul compte.' AS [Message];
        RETURN;
    END
    IF @autreId IS NOT NULL AND @Id IS NULL SET @Id = @autreId;   -- même nom, même compte : on complète

    IF @Id IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.T122PlanComptableAlias WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        UPDATE dbo.T122PlanComptableAlias
           SET [Compte] = @Compte, [SystemeSource] = @SystemeSource, [Langue] = ISNULL(@Langue, [Langue]),
               [NomSource] = @NomSource, [SousType] = ISNULL(@SousType, [SousType])
         WHERE [Id] = @Id;
        SELECT @Id AS [Id], 'MODIFIE' AS [Action], N'Alias corrigé : « ' + @NomSource + N' » → ' + @Compte + N'.' AS [Message];
        RETURN;
    END

    INSERT INTO dbo.T122PlanComptableAlias ([CompanyGUID], [Compte], [SystemeSource], [Langue], [NomSource], [SousType], [CreatedBy])
    VALUES (@CompanyGUID, @Compte, @SystemeSource, @Langue, @NomSource, @SousType, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS [Id], 'CREE' AS [Action], N'Alias ajouté : « ' + @NomSource + N' » → ' + @Compte + N'.' AS [Message];
END
GO

-- -----------------------------------------------------------------------------
-- s0880 — retirer un alias
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0880DeleteAliasPlanComptable]
    @CompanyGUID UNIQUEIDENTIFIER = NULL,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL SET @CompanyGUID = '00000000-0000-0000-0000-000000000001';
    DELETE FROM dbo.T122PlanComptableAlias WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID;
    SELECT @@ROWCOUNT AS [NbSupprimes];
END
GO

-- -----------------------------------------------------------------------------
-- s0874 — la liaison d'office par alias, appelée par s0752 (lit la table)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0874ProposerParAliasQBO]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1) Par nom, quelle que soit la langue.
    UPDATE p
       SET p.[PlanComptableId] = x.[Id],
           p.[Statut]          = 'EXISTE',
           p.[ProposeParAlias] = 1,
           p.[Anomalie]        = N'Déjà au plan comptable (nom QuickBooks connu) : ' + x.[Compte] + N' - ' + x.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T122PlanComptableAlias a
          JOIN dbo.T121PlanComptable pc
            ON pc.[CompanyGUID] = p.[CompanyGUID] AND pc.[Compte] = a.[Compte] AND ISNULL(pc.[Actif], 1) = 1
         WHERE a.[CompanyGUID] = @Model AND a.[SystemeSource] = 'QBO'
           AND UPPER(LTRIM(RTRIM(a.[NomSource]))) = UPPER(LTRIM(RTRIM(p.[Nom])))
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) x
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[PlanComptableId] IS NULL
       AND NULLIF(LTRIM(RTRIM(p.[Nom])), '') IS NOT NULL;

    DECLARE @ParNom INT = @@ROWCOUNT;

    -- 2) Par sous-type, seulement quand il ne désigne qu'un seul compte d'ici,
    --    et que ce compte n'est pas déjà proposé à une autre ligne.
    UPDATE p
       SET p.[PlanComptableId] = x.[Id],
           p.[Statut]          = 'EXISTE',
           p.[ProposeParAlias] = 1,
           p.[Anomalie]        = N'Déjà au plan comptable (sous-type QuickBooks connu) : ' + x.[Compte] + N' - ' + x.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM (SELECT DISTINCT a.[Compte]
                  FROM dbo.T122PlanComptableAlias a
                 WHERE a.[CompanyGUID] = @Model AND a.[SystemeSource] = 'QBO'
                   AND a.[SousType] = LTRIM(RTRIM(p.[SousTypeSource]))) u
          JOIN dbo.T121PlanComptable pc
            ON pc.[CompanyGUID] = p.[CompanyGUID] AND pc.[Compte] = u.[Compte] AND ISNULL(pc.[Actif], 1) = 1
         WHERE (SELECT COUNT(DISTINCT a2.[Compte]) FROM dbo.T122PlanComptableAlias a2
                 WHERE a2.[CompanyGUID] = @Model AND a2.[SystemeSource] = 'QBO'
                   AND a2.[SousType] = LTRIM(RTRIM(p.[SousTypeSource]))) = 1
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) x
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[PlanComptableId] IS NULL
       AND NULLIF(LTRIM(RTRIM(p.[SousTypeSource])), '') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportPlanComptable q
                        WHERE q.[CompanyGUID] = @CompanyGUID AND q.[PlanComptableId] = x.[Id]);

    SELECT @ParNom AS [NbParNom], @@ROWCOUNT AS [NbParSousType];
END
GO

-- -----------------------------------------------------------------------------
-- s0048 / s0049 — la colonne QBOAlias remplace les trois colonnes
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0048GetPlanComptable]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      VARCHAR(100) = '',
    @Filtre      VARCHAR(20)  = 'ALL',
    @Lang        VARCHAR(2)   = 'fr'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        c.[Id],
        c.Compte [Numero],
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(c.NomEn, c.NomFr, c.[Nom])
            WHEN 'es' THEN COALESCE(c.NomEs, c.NomEn, c.[Nom])
            ELSE            COALESCE(c.NomFr, c.[Nom])
        END AS [Nom],
        c.[TypeBilan],
        c.[Sens],
        c.[Actif],
        c.[Systeme],
        c.[Description],
        c.[ClasseId],
        c.[ClasseParentId],
        sc.[Code]                AS ClasseCode,
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(sc.DescriptionEn, sc.DescriptionFr, sc.[Description])
            WHEN 'es' THEN COALESCE(sc.DescriptionEs, sc.DescriptionEn, sc.[Description])
            ELSE            COALESCE(sc.DescriptionFr, sc.[Description])
        END AS SousClasseDescription,
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(p.DescriptionEn, p.DescriptionFr, p.[Description])
            WHEN 'es' THEN COALESCE(p.DescriptionEs, p.DescriptionEn, p.[Description])
            ELSE            COALESCE(p.DescriptionFr, p.[Description])
        END AS ClasseDescription,
        p.[GroupeEtatFinancier]  AS GroupeEtatFinancier,
        (SELECT STRING_AGG(a.[NomSource] + CASE WHEN a.[Langue] IS NULL THEN '' ELSE ' (' + a.[Langue] + ')' END
                           + CASE WHEN a.[SousType] IS NULL THEN '' ELSE ' [' + a.[SousType] + ']' END, ' · ')
                    WITHIN GROUP (ORDER BY a.[Langue], a.[NomSource])
           FROM dbo.T122PlanComptableAlias a
          WHERE a.[CompanyGUID] = c.[CompanyGUID] AND a.[Compte] = c.[Compte]) AS QBOAlias
    FROM [dbo].[T121PlanComptable] c
    INNER JOIN [dbo].[T120PlanComptable_Classe] sc ON c.[ClasseId] = sc.[Id]
    INNER JOIN [dbo].[T120PlanComptable_Classe] p  ON c.[ClasseParentId] = p.[Id]
    WHERE
        c.[CompanyGUID] = @CompanyGUID
        AND (@Filtre = 'ALL' OR p.[GroupeEtatFinancier] = @Filtre)
        AND (
            @Search = ''
            OR c.Compte LIKE '%' + @Search + '%'
            OR c.[Nom]  LIKE '%' + @Search + '%'
            OR c.NomEn  LIKE '%' + @Search + '%'
            OR c.NomEs  LIKE '%' + @Search + '%'
            OR sc.[Code] LIKE '%' + @Search + '%'
            OR sc.[Description] LIKE '%' + @Search + '%'
            OR sc.DescriptionEn LIKE '%' + @Search + '%'
            OR sc.DescriptionEs LIKE '%' + @Search + '%'
            OR EXISTS (SELECT 1 FROM dbo.T122PlanComptableAlias a
                        WHERE a.[CompanyGUID] = c.[CompanyGUID] AND a.[Compte] = c.[Compte]
                          AND (a.[NomSource] LIKE '%' + @Search + '%' OR a.[SousType] LIKE '%' + @Search + '%'))
        )
    ORDER BY c.[Ordre];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0049GetOneCompte]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.[Id],
           c.[Compte]               AS [Numero],
           c.[Nom], c.[TypeBilan], c.[Sens], c.[Actif], c.[Systeme], c.[Description],
           c.[ClasseId], c.[ClasseParentId], c.[Ordre],
           sc.[Code]                AS [ClasseCode],
           sc.[Description]         AS [SousClasseDescription],
           p.[Description]          AS [ClasseDescription],
           p.[GroupeEtatFinancier],
           CAST(NULL AS DATETIME)   AS [Created],
           (SELECT STRING_AGG(a.[NomSource] + CASE WHEN a.[Langue] IS NULL THEN '' ELSE ' (' + a.[Langue] + ')' END
                              + CASE WHEN a.[SousType] IS NULL THEN '' ELSE ' [' + a.[SousType] + ']' END, ' · ')
                       WITHIN GROUP (ORDER BY a.[Langue], a.[NomSource])
              FROM dbo.T122PlanComptableAlias a
             WHERE a.[CompanyGUID] = c.[CompanyGUID] AND a.[Compte] = c.[Compte]) AS QBOAlias
      FROM [dbo].[T121PlanComptable] c
      LEFT JOIN [dbo].[T120PlanComptable_Classe] sc ON sc.[Id] = c.[ClasseId]
      LEFT JOIN [dbo].[T120PlanComptable_Classe] p  ON p.[Id]  = c.[ClasseParentId]
     WHERE c.[Id] = @Id
       AND c.[CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- s0054 / s0055 — sans paramètres d'alias (version T267)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0054InsertPlanComptableCompte]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Numero         VARCHAR(10),
    @Nom            VARCHAR(150),
    @ClasseId       INT,
    @ClasseParentId INT,
    @TypeBilan      VARCHAR(10),
    @Sens           VARCHAR(10),
    @Actif          BIT = 1,
    @Description    VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @Numero)
    BEGIN
        RAISERROR('Le numéro de compte "%s" existe déjà.', 16, 1, @Numero);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM [dbo].[T120PlanComptable_Classe]
                    WHERE [Id] = @ClasseId AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        RAISERROR('La classe choisie n''appartient pas à cette compagnie.', 16, 1);
        RETURN;
    END
    DECLARE @NewId INT;
    SELECT @NewId = ISNULL(MAX([Id]), 0) + 1 FROM [dbo].[T121PlanComptable];
    INSERT INTO [dbo].[T121PlanComptable]
        ([Id], [CompanyGUID], [Compte], [Nom], [NomFr], [ClasseId], [ClasseParentId], [TypeBilan], [Sens],
         [Ordre], [Actif], [Systeme], [Description])
    VALUES
        (@NewId, @CompanyGUID, @Numero, @Nom, @Nom, @ClasseId, @ClasseParentId, @TypeBilan, @Sens,
         TRY_CONVERT(INT, @Numero), @Actif, 0, @Description);
    SELECT @NewId AS [Id];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0055UpdatePlanComptableCompte]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Id             INT,
    @Numero         VARCHAR(10),
    @Nom            VARCHAR(150),
    @ClasseId       INT,
    @ClasseParentId INT,
    @TypeBilan      VARCHAR(10),
    @Sens           VARCHAR(10),
    @Actif          BIT = 1,
    @Description    VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                    WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        RAISERROR('Ce compte n''appartient pas à votre plan comptable.', 16, 1);
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @Numero AND [Id] <> @Id)
    BEGIN
        RAISERROR('Le numéro de compte "%s" est déjà utilisé par un autre compte.', 16, 1, @Numero);
        RETURN;
    END
    -- Un changement de numéro emmène les alias avec lui.
    DECLARE @ancien VARCHAR(10) = (SELECT [Compte] FROM [dbo].[T121PlanComptable] WHERE [Id] = @Id);
    UPDATE [dbo].[T121PlanComptable]
       SET [Compte]         = @Numero,
           [Nom]            = @Nom,
           [NomFr]          = CASE WHEN [NomFr] IS NULL OR [NomFr] = [Nom] THEN @Nom ELSE [NomFr] END,
           [ClasseId]       = @ClasseId,
           [ClasseParentId] = @ClasseParentId,
           [TypeBilan]      = @TypeBilan,
           [Sens]           = @Sens,
           [Ordre]          = ISNULL(TRY_CONVERT(INT, @Numero), [Ordre]),
           [Actif]          = @Actif,
           [Description]    = @Description
     WHERE [Id] = @Id
       AND [CompanyGUID] = @CompanyGUID;
    IF @ancien IS NOT NULL AND @ancien <> @Numero
        UPDATE dbo.T122PlanComptableAlias SET [Compte] = @Numero
         WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @ancien;
END
GO

-- -----------------------------------------------------------------------------
-- s0875 — « déjà au modèle » par alias lit la table (parties 1 et 3 inchangées, T295/T296)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0875GetCandidatsPlanDefaut]
    @CompanyGUID UNIQUEIDENTIFIER = NULL,
    @Filtre      VARCHAR(20) = 'CREER'      -- CREER | SANS_JUMEAU | TOUS
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    IF @CompanyGUID IS NULL
    BEGIN
        SELECT s.[CompanyGUID],
               COUNT(*) AS [NbEnPreparation],
               SUM(CASE WHEN c.[Action] = 'CREER' THEN 1 ELSE 0 END) AS [NbCandidats],
               SUM(CASE WHEN c.[Id] IS NULL THEN 1 ELSE 0 END) AS [NbADecider],
               SUM(CASE WHEN c.[Action] = 'LIER' THEN 1 ELSE 0 END) AS [NbLies],
               MAX(s.[Created]) AS [DernierChargement],
               MAX(c.[Created]) AS [DerniereDecision]
          FROM staging.ImportPlanComptable s
          LEFT JOIN staging.CorrespondanceCompte c
            ON c.[CompanyGUID] = s.[CompanyGUID] AND c.[SystemeSource] = s.[SystemeSource] AND c.[CleSource] = s.[CleSource]
         WHERE s.[CompanyGUID] <> @Model
           AND s.[Statut] IN ('OK', 'EXISTE')
         GROUP BY s.[CompanyGUID]
         ORDER BY SUM(CASE WHEN c.[Action] = 'CREER' THEN 1 ELSE 0 END) DESC, MAX(s.[Created]) DESC;
        RETURN;
    END

    IF @Filtre NOT IN ('CREER', 'SANS_JUMEAU', 'TOUS') SET @Filtre = 'CREER';

    SELECT s.[Id] AS [StagingId],
           s.[CleSource],
           s.[NomSource],
           ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]) AS [NomCible],
           s.[TypeSource], s.[SousTypeSource], s.[TypeNormalise],
           dbo.fTypeBilanDeNature(s.[TypeNormalise]) AS [TypeBilan],
           s.[Origine],
           s.[DescriptionSource],
           s.[Solde],
           ISNULL(c.[Action], 'A_DECIDER') AS [Decision],
           rec.[Compte] AS [ReconnuCompte],
           rec.[Nom]    AS [ReconnuNom],
           ISNULL(s.[ProposeParAlias], 0) AS [ParAlias],
           c.[CompteCible],
           c.[PlanComptableId] AS [CreeChezClientId],
           cli.[Compte]        AS [CreeChezClientCompte],
           cls.[Code]          AS [ClasseCodeClient],
           mcl.[Id]            AS [ModelClasseIdSuggere],
           dbo.fLangueNomQBO(s.[NomSource]) AS [Langue],
           dm.[Compte] AS [DejaModeleCompte],
           dm.[Nom]    AS [DejaModeleNom],
           dm.[Motif]  AS [DejaModeleMotif]
      FROM staging.ImportPlanComptable s
      LEFT JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = s.[CompanyGUID] AND c.[SystemeSource] = s.[SystemeSource] AND c.[CleSource] = s.[CleSource]
      LEFT JOIN dbo.T121PlanComptable rec ON rec.[Id] = s.[PlanComptableId]
      LEFT JOIN dbo.T121PlanComptable cli ON cli.[Id] = c.[PlanComptableId]
      LEFT JOIN dbo.T120PlanComptable_Classe cls ON cls.[Id] = COALESCE(cli.[ClasseId], rec.[ClasseId])
      LEFT JOIN dbo.T120PlanComptable_Classe mcl ON mcl.[CompanyGUID] = @Model AND mcl.[Code] = cls.[Code] AND mcl.[ParentId] IS NOT NULL
     OUTER APPLY (
        SELECT TOP 1 m.[Compte], m.[Nom],
               CASE WHEN UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN N'même nom'
                    WHEN al.[Id] IS NOT NULL THEN N'alias QuickBooks'
                    ELSE N'même numéro' END AS [Motif]
          FROM dbo.T121PlanComptable m
          LEFT JOIN dbo.T122PlanComptableAlias al
            ON al.[CompanyGUID] = @Model AND al.[Compte] = m.[Compte]
           AND UPPER(LTRIM(RTRIM(al.[NomSource]))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
         WHERE m.[CompanyGUID] = @Model
           AND (UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR al.[Id] IS NOT NULL
                OR (NULLIF(c.[CompteCible], '') IS NOT NULL AND m.[Compte] = c.[CompteCible])
                OR (rec.[Compte] IS NOT NULL AND m.[Compte] = rec.[Compte]))
         ORDER BY CASE WHEN UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN 0 WHEN al.[Id] IS NOT NULL THEN 1 ELSE 2 END, m.[Compte]
     ) dm
     WHERE s.[CompanyGUID] = @CompanyGUID
       AND s.[Statut] IN ('OK', 'EXISTE')
       AND (   (@Filtre = 'CREER' AND c.[Action] = 'CREER')
            OR (@Filtre = 'SANS_JUMEAU' AND s.[PlanComptableId] IS NULL AND ISNULL(c.[Action], '') <> 'LIER')
            OR (@Filtre = 'TOUS'))
     ORDER BY CASE WHEN s.[Origine] = 'DEFAUT' THEN 0 ELSE 1 END, s.[TypeNormalise], s.[NomSource];

    SELECT sc.[Id], sc.[Code], sc.[Description], sc.[TypeBilan], sc.[Sens],
           sc.[NumeroDebut], sc.[NumeroFin],
           p.[Code] AS [ParentCode], p.[Description] AS [ParentDescription]
      FROM dbo.T120PlanComptable_Classe sc
      JOIN dbo.T120PlanComptable_Classe p ON p.[Id] = sc.[ParentId]
     WHERE sc.[CompanyGUID] = @Model
       AND ISNULL(sc.[Actif], 1) = 1
     ORDER BY sc.[NumeroDebut], sc.[Code];
END
GO

-- -----------------------------------------------------------------------------
-- s0876 — ajouter un candidat au modèle : le compte, puis son alias dans la table
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0876AjouterCandidatAuPlanDefaut]
    @CompanyGUID UNIQUEIDENTIFIER,
    @StagingId   INT,
    @ClasseId    INT,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    DECLARE @NomSource NVARCHAR(200), @NomCible NVARCHAR(200), @SousType NVARCHAR(100),
            @CompteCible VARCHAR(20), @CodeCie NVARCHAR(50);
    SELECT @NomSource = LTRIM(RTRIM(s.[NomSource])),
           @NomCible  = LTRIM(RTRIM(ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]))),
           @SousType  = NULLIF(LTRIM(RTRIM(s.[SousTypeSource])), ''),
           @CompteCible = NULLIF(LTRIM(RTRIM(c.[CompteCible])), '')
      FROM staging.ImportPlanComptable s
      LEFT JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = s.[CompanyGUID] AND c.[SystemeSource] = s.[SystemeSource] AND c.[CleSource] = s.[CleSource]
     WHERE s.[Id] = @StagingId AND s.[CompanyGUID] = @CompanyGUID AND s.[Statut] IN ('OK', 'EXISTE');

    IF @NomSource IS NULL
    BEGIN
        SELECT 'REFUSE' AS [Action], NULL AS [Compte], NULL AS [Nom],
               N'Ce compte n''est pas (ou plus) en préparation chez cette compagnie.' AS [Message];
        RETURN;
    END
    IF @NomCible IS NULL OR @NomCible = '' SET @NomCible = @NomSource;
    SELECT @CodeCie = [CompanyCode] FROM dbo.T010Company WHERE [CompanyGUID] = @CompanyGUID;

    -- Déjà au modèle, par nom ou par alias ? On ne crée pas de doublon.
    DECLARE @dCompte VARCHAR(20), @dNom NVARCHAR(200);
    SELECT TOP 1 @dCompte = m.[Compte], @dNom = m.[Nom]
      FROM dbo.T121PlanComptable m
     WHERE m.[CompanyGUID] = @Model
       AND (UPPER(m.[Nom]) = UPPER(@NomCible) OR UPPER(m.[Nom]) = UPPER(@NomSource)
            OR EXISTS (SELECT 1 FROM dbo.T122PlanComptableAlias a
                        WHERE a.[CompanyGUID] = @Model AND a.[Compte] = m.[Compte] AND UPPER(a.[NomSource]) = UPPER(@NomSource)));
    IF @dCompte IS NOT NULL
    BEGIN
        SELECT 'EXISTE' AS [Action], @dCompte AS [Compte], @dNom AS [Nom],
               N'Le modèle porte déjà ce compte (' + @dCompte + N' - ' + @dNom + N') : rien n''est créé.' AS [Message];
        RETURN;
    END

    DECLARE @debut INT, @fin INT, @parent INT, @typeBilan VARCHAR(10), @sens VARCHAR(10), @codeClasse NVARCHAR(50);
    SELECT @debut = sc.[NumeroDebut], @fin = sc.[NumeroFin], @parent = sc.[ParentId],
           @typeBilan = sc.[TypeBilan], @sens = sc.[Sens], @codeClasse = sc.[Code]
      FROM dbo.T120PlanComptable_Classe sc
     WHERE sc.[Id] = @ClasseId AND sc.[CompanyGUID] = @Model AND sc.[ParentId] IS NOT NULL;
    IF @parent IS NULL
    BEGIN
        SELECT 'REFUSE' AS [Action], NULL AS [Compte], @NomCible AS [Nom],
               N'Choisissez une sous-classe du plan modèle.' AS [Message];
        RETURN;
    END

    DECLARE @num VARCHAR(20) = NULL;
    IF TRY_CAST(@CompteCible AS INT) BETWEEN @debut AND @fin
       AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable WHERE [CompanyGUID] = @Model AND [Compte] = @CompteCible)
        SET @num = @CompteCible;
    IF @num IS NULL
    BEGIN
        ;WITH n AS (
            SELECT TOP (@fin - @debut + 1)
                   @debut + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) - 1 AS v
              FROM sys.all_objects
        )
        SELECT TOP 1 @num = CAST(n.v AS VARCHAR(20))
          FROM n
         WHERE NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc
                            WHERE pc.[CompanyGUID] = @Model AND TRY_CAST(pc.[Compte] AS INT) = n.v)
         ORDER BY CASE WHEN n.v % 10 = 0 THEN 0 ELSE 1 END, n.v;
    END
    IF @num IS NULL
    BEGIN
        SELECT 'REFUSE' AS [Action], NULL AS [Compte], @NomCible AS [Nom],
               N'La plage ' + CAST(@debut AS NVARCHAR(10)) + N'-' + CAST(@fin AS NVARCHAR(10)) + N' de la classe ' + @codeClasse + N' est pleine au modèle.' AS [Message];
        RETURN;
    END

    DECLARE @desc VARCHAR(250) = LEFT(N'Compte QuickBooks, ajouté depuis l''import de ' + ISNULL(@CodeCie, CONVERT(NVARCHAR(36), @CompanyGUID)), 250);
    DECLARE @res TABLE ([Id] INT);
    INSERT INTO @res
    EXEC dbo.s0054InsertPlanComptableCompte
        @CompanyGUID = @Model, @Numero = @num, @Nom = @NomCible,
        @ClasseId = @ClasseId, @ClasseParentId = @parent,
        @TypeBilan = @typeBilan, @Sens = @sens, @Actif = 1, @Description = @desc;

    -- L'alias : le nom QuickBooks tel quel, sa langue, son sous-type.
    DECLARE @langue CHAR(2) = dbo.fLangueNomQBO(@NomSource);
    DECLARE @al TABLE ([Id] INT, [Action] NVARCHAR(20), [Message] NVARCHAR(400));
    INSERT INTO @al
    EXEC dbo.s0879SaveAliasPlanComptable @CompanyGUID = @Model, @Compte = @num, @SystemeSource = 'QBO',
                                        @Langue = @langue, @NomSource = @NomSource, @SousType = @SousType,
                                        @CreatedBy = N'import QBO';

    SELECT 'CREE' AS [Action], @num AS [Compte], @NomCible AS [Nom],
           N'Créé au plan par défaut : ' + @num + N' - ' + @NomCible + N' (' + @codeClasse + N'), alias QuickBooks « ' + @NomSource + N' »'
           + CASE WHEN @SousType IS NULL THEN N'' ELSE N' [' + @SousType + N']' END + N'.' AS [Message];
END
GO

-- -----------------------------------------------------------------------------
-- s0877 — resynchroniser : plus d'alias par compagnie (version T294 sans les colonnes)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0877ResyncPlanComptableDepuisModele]
    @CompanyGUID     UNIQUEIDENTIFIER,
    @SupprimerEnTrop BIT = 0,
    @Simuler         BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    IF @CompanyGUID IS NULL OR @CompanyGUID = @Model
        THROW 50380, 'Compagnie invalide : la compagnie modèle ne se resynchronise pas avec elle-même.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE [CompanyGUID] = @CompanyGUID)
        THROW 50381, 'La compagnie n''existe pas.', 1;

    DECLARE @detail TABLE ([Action] NVARCHAR(20), [Compte] VARCHAR(20), [Nom] NVARCHAR(200), [Motif] NVARCHAR(300));

    BEGIN TRANSACTION;

    DECLARE @NextId INT;
    SELECT @NextId = ISNULL(MAX([Id]), 0) + 1 FROM dbo.T121PlanComptable WITH (UPDLOCK, HOLDLOCK);

    ;WITH manquants AS (
        SELECT m.*, csc.[Id] AS ClasseCie
          FROM dbo.T121PlanComptable m
          JOIN dbo.T120PlanComptable_Classe msc ON msc.[Id] = m.[ClasseId]
          LEFT JOIN dbo.T120PlanComptable_Classe csc ON csc.[CompanyGUID] = @CompanyGUID AND csc.[Code] = msc.[Code] AND csc.[ParentId] IS NOT NULL
         WHERE m.[CompanyGUID] = @Model
           AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable d WHERE d.[CompanyGUID] = @CompanyGUID AND d.[Compte] = m.[Compte])
    )
    INSERT INTO @detail ([Action], [Compte], [Nom], [Motif])
    SELECT CASE WHEN ClasseCie IS NULL THEN N'REFUSE' ELSE N'AJOUTE' END, [Compte], [Nom],
           CASE WHEN ClasseCie IS NULL THEN N'la sous-classe « ' + ISNULL((SELECT [Code] FROM dbo.T120PlanComptable_Classe WHERE [Id] = manquants.[ClasseId]), '?') + N' » n''existe pas chez la compagnie'
                ELSE N'compte du plan par défaut absent de la compagnie' END
      FROM manquants;

    INSERT INTO dbo.T121PlanComptable
        ([Id], [Compte], [Nom], [ClasseId], [ClasseParentId], [TypeBilan], [Sens], [Ordre], [Actif], [Systeme], [Description], [CompanyGUID],
         [NomFr], [NomEn], [NomEs])
    SELECT @NextId - 1 + ROW_NUMBER() OVER (ORDER BY m.[Id]),
           m.[Compte], m.[Nom], csc.[Id], csc.[ParentId], m.[TypeBilan], m.[Sens], m.[Ordre], m.[Actif], m.[Systeme], m.[Description], @CompanyGUID,
           m.[NomFr], m.[NomEn], m.[NomEs]
      FROM dbo.T121PlanComptable m
      JOIN dbo.T120PlanComptable_Classe msc ON msc.[Id] = m.[ClasseId]
      JOIN dbo.T120PlanComptable_Classe csc ON csc.[CompanyGUID] = @CompanyGUID AND csc.[Code] = msc.[Code] AND csc.[ParentId] IS NOT NULL
     WHERE m.[CompanyGUID] = @Model
       AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable d WHERE d.[CompanyGUID] = @CompanyGUID AND d.[Compte] = m.[Compte]);
    DECLARE @NbAjoutes INT = @@ROWCOUNT;

    INSERT INTO @detail ([Action], [Compte], [Nom], [Motif])
    SELECT N'MIS_A_JOUR', d.[Compte], d.[Nom], N'noms EN-ES / description alignés sur le modèle'
      FROM dbo.T121PlanComptable d
      JOIN dbo.T121PlanComptable m ON m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (ISNULL(d.[NomEn], '') <> ISNULL(m.[NomEn], '')
            OR ISNULL(d.[NomEs], '') <> ISNULL(m.[NomEs], '')
            OR ISNULL(d.[Description], '') <> ISNULL(m.[Description], ''));

    UPDATE d
       SET d.[NomEn]       = m.[NomEn],
           d.[NomEs]       = m.[NomEs],
           d.[Description] = m.[Description]
      FROM dbo.T121PlanComptable d
      JOIN dbo.T121PlanComptable m ON m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (ISNULL(d.[NomEn], '') <> ISNULL(m.[NomEn], '')
            OR ISNULL(d.[NomEs], '') <> ISNULL(m.[NomEs], '')
            OR ISNULL(d.[Description], '') <> ISNULL(m.[Description], ''));
    DECLARE @NbMisAJour INT = @@ROWCOUNT;

    DECLARE @NbSupprimes INT = 0;
    ;WITH entrop AS (
        SELECT d.[Id], d.[Compte], d.[Nom], d.[Systeme],
               (SELECT COUNT(*) FROM dbo.T136LignesEcriture l WHERE l.[PlanComptableId] = d.[Id]) AS Ecritures,
               (SELECT COUNT(*) FROM dbo.T139TemplateLignes l WHERE l.[PlanComptableId] = d.[Id]) AS Modeles,
               (SELECT COUNT(*) FROM staging.CorrespondanceCompte c WHERE c.[PlanComptableId] = d.[Id]) AS Liaisons
          FROM dbo.T121PlanComptable d
         WHERE d.[CompanyGUID] = @CompanyGUID
           AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable m WHERE m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte])
    )
    INSERT INTO @detail ([Action], [Compte], [Nom], [Motif])
    SELECT CASE WHEN @SupprimerEnTrop = 1 AND ISNULL(Systeme, 0) = 0 AND Ecritures + Modeles + Liaisons = 0 THEN N'SUPPRIME' ELSE N'GARDE' END,
           [Compte], [Nom],
           CASE WHEN ISNULL(Systeme, 0) = 1 THEN N'absent du modèle, mais compte système'
                WHEN Ecritures + Modeles + Liaisons > 0 THEN N'absent du modèle, mais référencé (' + CAST(Ecritures AS NVARCHAR(10)) + N' écriture(s), ' + CAST(Modeles AS NVARCHAR(10)) + N' modèle(s), ' + CAST(Liaisons AS NVARCHAR(10)) + N' liaison(s) de reprise)'
                WHEN @SupprimerEnTrop = 1 THEN N'absent du modèle, non référencé : retiré'
                ELSE N'absent du modèle, non référencé : gardé (suppression non demandée)' END
      FROM entrop;

    IF @SupprimerEnTrop = 1
    BEGIN
        DELETE d
          FROM dbo.T121PlanComptable d
         WHERE d.[CompanyGUID] = @CompanyGUID
           AND ISNULL(d.[Systeme], 0) = 0
           AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable m WHERE m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte])
           AND NOT EXISTS (SELECT 1 FROM dbo.T136LignesEcriture l WHERE l.[PlanComptableId] = d.[Id])
           AND NOT EXISTS (SELECT 1 FROM dbo.T139TemplateLignes l WHERE l.[PlanComptableId] = d.[Id])
           AND NOT EXISTS (SELECT 1 FROM staging.CorrespondanceCompte c WHERE c.[PlanComptableId] = d.[Id]);
        SET @NbSupprimes = @@ROWCOUNT;
    END

    IF @Simuler = 1 ROLLBACK TRANSACTION ELSE COMMIT TRANSACTION;

    SELECT @NbAjoutes AS [NbAjoutes], @NbMisAJour AS [NbMisAJour], @NbSupprimes AS [NbSupprimes],
           (SELECT COUNT(*) FROM @detail WHERE [Action] = N'GARDE') AS [NbGardes],
           (SELECT COUNT(*) FROM @detail WHERE [Action] = N'REFUSE') AS [NbRefuses],
           @Simuler AS [Simule];
    SELECT [Action], [Compte], [Nom], [Motif] FROM @detail ORDER BY CASE [Action] WHEN N'REFUSE' THEN 0 WHEN N'AJOUTE' THEN 1 WHEN N'SUPPRIME' THEN 2 WHEN N'GARDE' THEN 3 ELSE 4 END, [Compte];
END
GO

PRINT N'T298_Alias_plan_comptable_table.sql : terminé.';
