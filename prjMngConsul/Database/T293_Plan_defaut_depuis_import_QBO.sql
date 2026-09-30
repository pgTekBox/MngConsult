-- =============================================================================
-- T293 — Plan comptable par défaut : ajouter les comptes QuickBooks sans équivalent
--
-- Sec60Admin › Plan comptable par défaut, bloc « Ajouter depuis un import
-- QuickBooks » : les comptes QBO qu'une compagnie a décidé de « Créer » à
-- l'étape 2 (aucun équivalent chez nous) peuvent entrer dans le plan modèle,
-- avec leur alias QuickBooks posé du même coup (T292). Le prochain client
-- QuickBooks se les voit lier d'office.
--
--   fLangueNomQBO                 : FR ou EN, d'après le nom (accents, mots anglais).
--   s0875GetCandidatsPlanDefaut   : @CompanyGUID NULL → les compagnies qui ont
--                                   des candidats ; sinon les candidats de la
--                                   compagnie (+ les sous-classes du modèle).
--   s0876AjouterCandidatAuPlanDefaut : un candidat → un compte du modèle, dans
--                                   la sous-classe choisie, au numéro décidé à
--                                   l'étape 3 s'il est libre, sinon au premier
--                                   libre de la plage (dizaines rondes d'abord,
--                                   comme s0767). Refus si le modèle a déjà ce
--                                   nom ou cet alias.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fLangueNomQBO] (@Nom NVARCHAR(200))
RETURNS CHAR(2)
AS
BEGIN
    IF @Nom IS NULL RETURN 'FR';
    IF @Nom COLLATE Latin1_General_CS_AS LIKE N'%[éèàçêôûîù]%' RETURN 'FR';
    IF @Nom LIKE N'% and %' OR @Nom LIKE N'%Expense%' OR @Nom LIKE N'%Income%'
    OR @Nom LIKE N'%Cost%' OR @Nom LIKE N'%Fees%' OR @Nom LIKE N'%Charges%'
    OR @Nom LIKE N'%Shipping%' OR @Nom LIKE N'Bad debts%' OR @Nom LIKE N'%Payable%'
    OR @Nom LIKE N'%Receivable%' OR @Nom LIKE N'%Funds%' OR @Nom LIKE N'Discount%'
    OR @Nom LIKE N'Advertising%' OR @Nom LIKE N'%Sales%' OR @Nom LIKE N'%Purchases%'
    OR @Nom LIKE N'%Interest%' OR @Nom LIKE N'%Supplies%' OR @Nom LIKE N'%Insurance%'
    OR @Nom LIKE N'%Equipment%' OR @Nom LIKE N'%Inventory%' OR @Nom LIKE N'Retained%'
    OR @Nom LIKE N'Opening%' OR @Nom LIKE N'Uncategori%' OR @Nom LIKE N'Undeposited%'
    OR @Nom LIKE N'%Utilities%' OR @Nom LIKE N'%Travel%' OR @Nom LIKE N'%Meals%'
    OR @Nom LIKE N'%Depreciation%' OR @Nom LIKE N'%Loan%' OR @Nom LIKE N'%Rent%'
    OR @Nom LIKE N'%Taxes%' OR @Nom LIKE N'%Office%' OR @Nom LIKE N'%Repairs%'
    OR @Nom LIKE N'%Legal%' OR @Nom LIKE N'%Dues%' OR @Nom LIKE N'%Wages%'
    OR @Nom LIKE N'%Billable%' OR @Nom LIKE N'%Asset%' OR @Nom LIKE N'%Liabilit%'
    OR @Nom LIKE N'%Equity%' OR @Nom LIKE N'%Cash%' OR @Nom LIKE N'%Bank%'
        RETURN 'EN';
    RETURN 'FR';
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0875GetCandidatsPlanDefaut]
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1) Sans compagnie : celles qui ont des candidats.
    IF @CompanyGUID IS NULL
    BEGIN
        SELECT c.[CompanyGUID], COUNT(*) AS [NbCandidats], MAX(c.[Created]) AS [DerniereDecision]
          FROM staging.CorrespondanceCompte c
          JOIN staging.ImportPlanComptable s
            ON s.[CompanyGUID] = c.[CompanyGUID] AND s.[SystemeSource] = c.[SystemeSource] AND s.[CleSource] = c.[CleSource]
         WHERE c.[Action] = 'CREER'
           AND s.[Statut] IN ('OK', 'EXISTE')
         GROUP BY c.[CompanyGUID]
         ORDER BY MAX(c.[Created]) DESC;
        RETURN;
    END

    -- 2) Les candidats de la compagnie.
    SELECT s.[Id] AS [StagingId],
           s.[CleSource],
           s.[NomSource],
           ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]) AS [NomCible],
           s.[TypeSource], s.[SousTypeSource], s.[TypeNormalise],
           dbo.fTypeBilanDeNature(s.[TypeNormalise]) AS [TypeBilan],
           s.[Origine],
           s.[DescriptionSource],
           c.[CompteCible],
           c.[PlanComptableId] AS [CreeChezClientId],
           cli.[Compte]        AS [CreeChezClientCompte],
           cls.[Code]          AS [ClasseCodeClient],
           mcl.[Id]            AS [ModelClasseIdSuggere],
           dbo.fLangueNomQBO(s.[NomSource]) AS [Langue],
           -- Déjà au modèle ? par nom, par alias, ou par numéro décidé chez le client.
           dm.[Compte] AS [DejaModeleCompte],
           dm.[Nom]    AS [DejaModeleNom],
           dm.[Motif]  AS [DejaModeleMotif]
      FROM staging.CorrespondanceCompte c
      JOIN staging.ImportPlanComptable s
        ON s.[CompanyGUID] = c.[CompanyGUID] AND s.[SystemeSource] = c.[SystemeSource] AND s.[CleSource] = c.[CleSource]
      LEFT JOIN dbo.T121PlanComptable cli ON cli.[Id] = c.[PlanComptableId]
      LEFT JOIN dbo.T120PlanComptable_Classe cls ON cls.[Id] = cli.[ClasseId]
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
                OR (NULLIF(c.[CompteCible], '') IS NOT NULL AND m.[Compte] = c.[CompteCible]))
         ORDER BY CASE WHEN UPPER(LTRIM(RTRIM(m.[Nom]))) = UPPER(LTRIM(RTRIM(s.[NomSource]))) THEN 0 ELSE 1 END, m.[Compte]
     ) dm
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[Action] = 'CREER'
       AND s.[Statut] IN ('OK', 'EXISTE')
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

    DECLARE @NomSource NVARCHAR(200), @NomCible NVARCHAR(200), @SousType NVARCHAR(100),
            @CompteCible VARCHAR(20), @CleSource NVARCHAR(200), @CodeCie NVARCHAR(50);
    SELECT @NomSource = LTRIM(RTRIM(s.[NomSource])),
           @NomCible  = LTRIM(RTRIM(ISNULL(NULLIF(c.[NomCible], ''), s.[Nom]))),
           @SousType  = NULLIF(LTRIM(RTRIM(s.[SousTypeSource])), ''),
           @CompteCible = NULLIF(LTRIM(RTRIM(c.[CompteCible])), ''),
           @CleSource = s.[CleSource]
      FROM staging.ImportPlanComptable s
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = s.[CompanyGUID] AND c.[SystemeSource] = s.[SystemeSource] AND c.[CleSource] = s.[CleSource]
     WHERE s.[Id] = @StagingId AND s.[CompanyGUID] = @CompanyGUID AND c.[Action] = 'CREER';

    IF @NomSource IS NULL
    BEGIN
        SELECT 'REFUSE' AS [Action], NULL AS [Compte], NULL AS [Nom],
               N'Ce compte n''est pas (ou plus) un candidat « Créer » de cette compagnie.' AS [Message];
        RETURN;
    END
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

    -- Création par la procédure du plan, alias compris.
    DECLARE @fr NVARCHAR(200) = CASE WHEN dbo.fLangueNomQBO(@NomSource) = 'FR' THEN @NomSource END;
    DECLARE @en NVARCHAR(200) = CASE WHEN dbo.fLangueNomQBO(@NomSource) = 'EN' THEN @NomSource END;
    DECLARE @desc VARCHAR(250) = LEFT(N'Compte QuickBooks par défaut, ajouté depuis l''import de ' + ISNULL(@CodeCie, CONVERT(NVARCHAR(36), @CompanyGUID)), 250);

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

PRINT N'T293_Plan_defaut_depuis_import_QBO.sql : terminé.';
