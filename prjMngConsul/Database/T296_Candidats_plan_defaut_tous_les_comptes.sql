-- =============================================================================
-- T296 — Sec60Admin › Ajouter depuis un import QuickBooks : tous les comptes en préparation
--
-- Le bloc ne montrait que les comptes décidés « Créer » à l'étape 2. On veut
-- pouvoir regarder TOUT le plan QuickBooks en préparation d'une compagnie et en
-- retenir n'importe quel compte pour le plan par défaut.
--
--   s0875 (@CompanyGUID, @Filtre) : CREER (défaut) = décidés « Créer » ;
--       SANS_JUMEAU = sans compte reconnu chez la compagnie et sans décision
--       « Lier » ; TOUS = tout le plan en préparation. Chaque ligne dit ce que
--       la compagnie en a fait : reconnu (numéro), par alias, décision, et ce
--       que le modèle en sait déjà.
--   s0876 : accepte tout compte en préparation, décidé « Créer » ou non.
-- La partie 1 (liste des compagnies) et la partie 3 (sous-classes) sont celles de T295.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0875GetCandidatsPlanDefaut]
    @CompanyGUID UNIQUEIDENTIFIER = NULL,
    @Filtre      VARCHAR(20) = 'CREER'      -- CREER | SANS_JUMEAU | TOUS
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1) Sans compagnie : toutes celles qui ont un plan en préparation.
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

    -- 2) Les comptes en préparation de la compagnie, selon le filtre.
    SELECT s.[Id] AS [StagingId],
           s.[CleSource],
           s.[NomSource],
           ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]) AS [NomCible],
           s.[TypeSource], s.[SousTypeSource], s.[TypeNormalise],
           dbo.fTypeBilanDeNature(s.[TypeNormalise]) AS [TypeBilan],
           s.[Origine],
           s.[DescriptionSource],
           s.[Solde],
           -- ce que la compagnie en a fait
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
           -- ce que le modèle en sait déjà
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
                    WHEN UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteFR], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                      OR UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteEN], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN N'alias QuickBooks'
                    ELSE N'même numéro' END AS [Motif]
          FROM dbo.T121PlanComptable m
         WHERE m.[CompanyGUID] = @Model
           AND (UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteFR], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR UPPER(LTRIM(RTRIM(ISNULL(m.[QBOCompteEN], '')))) = UPPER(LTRIM(RTRIM(s.[NomSource])))
                OR (NULLIF(c.[CompteCible], '') IS NOT NULL AND m.[Compte] = c.[CompteCible])
                OR (rec.[Compte] IS NOT NULL AND m.[Compte] = rec.[Compte]))
         ORDER BY CASE WHEN UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN 0 ELSE 1 END, m.[Compte]
     ) dm
     WHERE s.[CompanyGUID] = @CompanyGUID
       AND s.[Statut] IN ('OK', 'EXISTE')
       AND (   (@Filtre = 'CREER' AND c.[Action] = 'CREER')
            OR (@Filtre = 'SANS_JUMEAU' AND s.[PlanComptableId] IS NULL AND ISNULL(c.[Action], '') <> 'LIER')
            OR (@Filtre = 'TOUS'))
     ORDER BY CASE WHEN s.[Origine] = 'DEFAUT' THEN 0 ELSE 1 END, s.[TypeNormalise], s.[NomSource];

    -- 3) Les sous-classes du modèle, pour le choix par ligne.
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

CREATE OR ALTER PROCEDURE [dbo].[s0876AjouterCandidatAuPlanDefaut]
    @CompanyGUID UNIQUEIDENTIFIER,   -- la compagnie d'où vient le compte QBO
    @StagingId   INT,
    @ClasseId    INT,                -- une sous-classe du MODÈLE
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- Tout compte en préparation est admis, décidé « Créer » ou non (T296).
    DECLARE @NomSource NVARCHAR(200), @NomCible NVARCHAR(200), @SousType NVARCHAR(100),
            @CompteCible VARCHAR(20), @CleSource NVARCHAR(200), @CodeCie NVARCHAR(50);
    SELECT @NomSource = LTRIM(RTRIM(s.[NomSource])),
           @NomCible  = LTRIM(RTRIM(ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]))),
           @SousType  = NULLIF(LTRIM(RTRIM(s.[SousTypeSource])), ''),
           @CompteCible = NULLIF(LTRIM(RTRIM(c.[CompteCible])), ''),
           @CleSource = s.[CleSource]
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

    -- Déjà au modèle ? On ne crée pas de doublon.
    DECLARE @dCompte VARCHAR(20), @dNom NVARCHAR(200);
    SELECT TOP 1 @dCompte = m.[Compte], @dNom = m.[Nom]
      FROM dbo.T121PlanComptable m
     WHERE m.[CompanyGUID] = @Model
       AND (UPPER(m.[Nom]) = UPPER(@NomCible) OR UPPER(m.[Nom]) = UPPER(@NomSource)
            OR UPPER(ISNULL(m.[QBOCompteFR], '')) = UPPER(@NomSource)
            OR UPPER(ISNULL(m.[QBOCompteEN], '')) = UPPER(@NomSource));
    IF @dCompte IS NOT NULL
    BEGIN
        SELECT 'EXISTE' AS [Action], @dCompte AS [Compte], @dNom AS [Nom],
               N'Le modèle porte déjà ce compte (' + @dCompte + N' - ' + @dNom + N') : rien n''est créé.' AS [Message];
        RETURN;
    END

    -- La sous-classe du modèle.
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

    -- Le numéro : celui décidé chez le client s'il tombe dans la plage et qu'il
    -- est libre au modèle ; sinon le premier libre, dizaines rondes d'abord.
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

    DECLARE @fr NVARCHAR(200) = CASE WHEN dbo.fLangueNomQBO(@NomSource) = 'FR' THEN @NomSource END;
    DECLARE @en NVARCHAR(200) = CASE WHEN dbo.fLangueNomQBO(@NomSource) = 'EN' THEN @NomSource END;
    DECLARE @desc VARCHAR(250) = LEFT(N'Compte QuickBooks, ajouté depuis l''import de ' + ISNULL(@CodeCie, CONVERT(NVARCHAR(36), @CompanyGUID)), 250);

    DECLARE @res TABLE ([Id] INT);
    INSERT INTO @res
    EXEC dbo.s0054InsertPlanComptableCompte
        @CompanyGUID = @Model, @Numero = @num, @Nom = @NomCible,
        @ClasseId = @ClasseId, @ClasseParentId = @parent,
        @TypeBilan = @typeBilan, @Sens = @sens, @Actif = 1, @Description = @desc,
        @QBOCompteFR = @fr, @QBOCompteEN = @en, @QBOSousType = @SousType, @QBOMaj = 1;

    SELECT 'CREE' AS [Action], @num AS [Compte], @NomCible AS [Nom],
           N'Créé au plan par défaut : ' + @num + N' - ' + @NomCible + N' (' + @codeClasse + N'), alias QuickBooks « ' + @NomSource + N' »'
           + CASE WHEN @SousType IS NULL THEN N'' ELSE N' [' + @SousType + N']' END + N'.' AS [Message];
END
GO

PRINT N'T296_Candidats_plan_defaut_tous_les_comptes.sql : terminé.';
