-- =============================================================================
-- T292 — Alias QuickBooks sur le plan comptable : liaison d'office à la reprise
--
-- Chaque compte du plan porte désormais le nom que QuickBooks lui donne, en
-- français et en anglais, et son sous-type QuickBooks :
--   T121PlanComptable.QBOCompteFR, QBOCompteEN, QBOSousType (NULL = aucun).
-- Ils vivent sur la compagnie modèle (00000000-…-0001), sont copiés par s0500
-- dans chaque nouvelle compagnie, et se corrigent dans Sec60Admin › Plan
-- comptable par défaut.
--
-- À la reprise d'un plan QuickBooks (s0752), après la reconnaissance par
-- numéro et par nom, un compte QBO encore sans jumeau est lié d'office quand
-- son nom (FR ou EN) ou son sous-type est connu du plan modèle, vers le compte
-- de même numéro chez la compagnie : s0874ProposerParAliasQBO. La grille de
-- l'étape 2 le montre « nom QuickBooks connu » (Origine PROPOSE_QBO,
-- staging.ImportPlanComptable.ProposeParAlias = 1) et « Accepter les
-- propositions » (s0760) le lie avec la note qui va avec.
--
-- Remplissage initial : depuis les décisions « Lier » déjà prises sur des
-- comptes QuickBooks PAR DÉFAUT (Origine = DEFAUT — un compte ajouté par un
-- client porte un nom qui n'appartient qu'à lui). Le nom va en FR ou en EN
-- d'après une heuristique simple ; le sous-type accompagne.
--
-- s0048 / s0049 renvoient les trois colonnes ; s0054 / s0055 les acceptent
-- (@QBOMaj = 1 pour qu'elles fassent foi, l'ERP appelle sans et ne les touche pas).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.T121PlanComptable', 'QBOCompteFR') IS NULL
    ALTER TABLE dbo.T121PlanComptable ADD [QBOCompteFR] NVARCHAR(200) NULL;
IF COL_LENGTH('dbo.T121PlanComptable', 'QBOCompteEN') IS NULL
    ALTER TABLE dbo.T121PlanComptable ADD [QBOCompteEN] NVARCHAR(200) NULL;
IF COL_LENGTH('dbo.T121PlanComptable', 'QBOSousType') IS NULL
    ALTER TABLE dbo.T121PlanComptable ADD [QBOSousType] NVARCHAR(100) NULL;
IF COL_LENGTH('staging.ImportPlanComptable', 'ProposeParAlias') IS NULL
    ALTER TABLE staging.ImportPlanComptable ADD [ProposeParAlias] BIT NULL;
GO

-- -----------------------------------------------------------------------------
-- Remplissage initial depuis les liaisons déjà décidées sur des comptes QBO par défaut
-- -----------------------------------------------------------------------------
DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';
;WITH lies AS (
    SELECT m.[Id] AS ModelId,
           LTRIM(RTRIM(s.[NomSource])) AS NomQBO,
           NULLIF(LTRIM(RTRIM(s.[SousTypeSource])), '') AS SousType,
           ROW_NUMBER() OVER (PARTITION BY m.[Id] ORDER BY c.[Id] DESC) AS rn
      FROM staging.CorrespondanceCompte c
      JOIN dbo.T121PlanComptable t ON t.[Id] = c.[PlanComptableId]
      JOIN dbo.T121PlanComptable m ON m.[CompanyGUID] = @Model AND m.[Compte] = t.[Compte]
      JOIN staging.ImportPlanComptable s
        ON s.[CompanyGUID] = c.[CompanyGUID] AND s.[SystemeSource] = c.[SystemeSource] AND s.[CleSource] = c.[CleSource]
     WHERE c.[Action] = 'LIER'
       AND s.[Origine] = 'DEFAUT'
       AND NULLIF(LTRIM(RTRIM(s.[NomSource])), '') IS NOT NULL
),
langue AS (
    SELECT l.*,
           CASE WHEN l.NomQBO COLLATE Latin1_General_CS_AS LIKE N'%[éèàçêôûîù]%' THEN 'FR'
                WHEN l.NomQBO LIKE N'% and %' OR l.NomQBO LIKE N'%Expense%' OR l.NomQBO LIKE N'%Income%'
                  OR l.NomQBO LIKE N'%Cost%' OR l.NomQBO LIKE N'%Fees%' OR l.NomQBO LIKE N'%Charges%'
                  OR l.NomQBO LIKE N'%Shipping%' OR l.NomQBO LIKE N'Bad debts%' OR l.NomQBO LIKE N'%Payable%'
                  OR l.NomQBO LIKE N'%Receivable%' OR l.NomQBO LIKE N'%Funds%' OR l.NomQBO LIKE N'Discount%'
                  OR l.NomQBO LIKE N'Advertising%' OR l.NomQBO LIKE N'%Sales%' OR l.NomQBO LIKE N'%Purchases%'
                  OR l.NomQBO LIKE N'%Interest%' OR l.NomQBO LIKE N'%Supplies%' OR l.NomQBO LIKE N'%Insurance%'
                  OR l.NomQBO LIKE N'%Equipment%' OR l.NomQBO LIKE N'%Inventory%' OR l.NomQBO LIKE N'Retained%'
                  OR l.NomQBO LIKE N'Opening%' OR l.NomQBO LIKE N'Uncategori%' OR l.NomQBO LIKE N'Undeposited%'
                  OR l.NomQBO LIKE N'%Utilities%' OR l.NomQBO LIKE N'%Travel%' OR l.NomQBO LIKE N'%Meals%'
                  OR l.NomQBO LIKE N'%Depreciation%' OR l.NomQBO LIKE N'%Loan%' OR l.NomQBO LIKE N'%Rent%'
                  OR l.NomQBO LIKE N'%Taxes%' OR l.NomQBO LIKE N'%Office%' OR l.NomQBO LIKE N'%Repairs%'
                  OR l.NomQBO LIKE N'%Legal%' OR l.NomQBO LIKE N'%Dues%' OR l.NomQBO LIKE N'%Wages%' THEN 'EN'
                ELSE 'FR' END AS Langue
      FROM lies l WHERE l.rn = 1
)
UPDATE m
   SET m.[QBOCompteFR] = CASE WHEN m.[QBOCompteFR] IS NULL AND l.Langue = 'FR' THEN l.NomQBO ELSE m.[QBOCompteFR] END,
       m.[QBOCompteEN] = CASE WHEN m.[QBOCompteEN] IS NULL AND l.Langue = 'EN' THEN l.NomQBO ELSE m.[QBOCompteEN] END,
       m.[QBOSousType] = COALESCE(m.[QBOSousType], l.SousType)
  FROM dbo.T121PlanComptable m
  JOIN langue l ON l.ModelId = m.[Id];
PRINT N'Alias QBO remplis depuis les liaisons décidées : ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' compte(s) du modèle.';
GO

-- -----------------------------------------------------------------------------
-- s0874ProposerParAliasQBO — la liaison d'office par alias, appelée par s0752
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0874ProposerParAliasQBO]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1) Par nom, français ou anglais.
    UPDATE p
       SET p.[PlanComptableId] = x.[Id],
           p.[Statut]          = 'EXISTE',
           p.[ProposeParAlias] = 1,
           p.[Anomalie]        = N'Déjà au plan comptable (nom QuickBooks connu) : ' + x.[Compte] + N' - ' + x.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T121PlanComptable m
          JOIN dbo.T121PlanComptable pc
            ON pc.[CompanyGUID] = p.[CompanyGUID] AND pc.[Compte] = m.[Compte] AND ISNULL(pc.[Actif], 1) = 1
         WHERE m.[CompanyGUID] = @Model
           AND (UPPER(LTRIM(RTRIM(m.[QBOCompteFR]))) = UPPER(LTRIM(RTRIM(p.[Nom])))
                OR UPPER(LTRIM(RTRIM(m.[QBOCompteEN]))) = UPPER(LTRIM(RTRIM(p.[Nom]))))
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

    -- 2) Par sous-type, seulement quand un seul compte du modèle le porte :
    --    « Insurance » ou « OfficeGeneralAdministrativeExpenses » en couvrent
    --    plusieurs, et on ne devine pas.
    UPDATE p
       SET p.[PlanComptableId] = x.[Id],
           p.[Statut]          = 'EXISTE',
           p.[ProposeParAlias] = 1,
           p.[Anomalie]        = N'Déjà au plan comptable (sous-type QuickBooks connu) : ' + x.[Compte] + N' - ' + x.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T121PlanComptable m
          JOIN dbo.T121PlanComptable pc
            ON pc.[CompanyGUID] = p.[CompanyGUID] AND pc.[Compte] = m.[Compte] AND ISNULL(pc.[Actif], 1) = 1
         WHERE m.[CompanyGUID] = @Model
           AND m.[QBOSousType] = LTRIM(RTRIM(p.[SousTypeSource]))
           AND (SELECT COUNT(*) FROM dbo.T121PlanComptable m2
                 WHERE m2.[CompanyGUID] = @Model AND m2.[QBOSousType] = LTRIM(RTRIM(p.[SousTypeSource]))) = 1
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) x
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[PlanComptableId] IS NULL
       AND NULLIF(LTRIM(RTRIM(p.[SousTypeSource])), '') IS NOT NULL
       -- le compte cible n'est pas déjà proposé à une autre ligne : le sous-type
       -- ne vient qu'en second, il ne dispute pas une liaison par nom.
       AND NOT EXISTS (SELECT 1 FROM staging.ImportPlanComptable q
                        WHERE q.[CompanyGUID] = @CompanyGUID AND q.[PlanComptableId] = x.[Id]);

    SELECT @ParNom AS [NbParNom], @@ROWCOUNT AS [NbParSousType];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0752ChargerPlanComptableStaging]
    @CompanyGUID   UNIQUEIDENTIFIER,
    @SystemeSource VARCHAR(20),
    @ImportFileId  INT = NULL,
    @Lignes        NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50302, 'Aucune compagnie : impossible de déposer un plan comptable.', 1;

    IF @ImportFileId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.ImportFiles
                        WHERE [Id] = @ImportFileId
                          AND ([CompanyGUID] IS NULL OR [CompanyGUID] = @CompanyGUID))
        THROW 50367, 'Le fichier d''importation n''appartient pas à cette compagnie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.ImportPlanComptable
        ([CompanyGUID], [SystemeSource], [ImportFileId], [LigneNo],
         [CompteSource], [NomSource], [TypeSource], [SousTypeSource], [SoldeSource], [SensSource],
         [Compte], [Nom], [TypeNormalise], [Solde], [Sens],
         [CleSource], [TypeCle],
         [CreeLe], [ModifieLe], [DescriptionSource], [SousCompte], [NomComplet])
    SELECT
        @CompanyGUID, @SystemeSource, @ImportFileId, j.LigneNo,
        j.CompteSource, j.NomSource, j.TypeSource, NULLIF(j.SousTypeSource, ''), j.SoldeSource, j.SensSource,
        NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
        NULLIF(LTRIM(RTRIM(ISNULL(j.Nom, ''))), ''),
        NULLIF(j.TypeNormalise, ''),
        j.Solde,
        j.Sens,
        COALESCE(
            NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
            NULLIF(UPPER(LTRIM(RTRIM(ISNULL(j.Nom, '')))), '')),
        CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(j.Compte, ''))), '') IS NOT NULL
             THEN 'NUMERO' ELSE 'NOM' END,
        TRY_CONVERT(DATETIME, TRY_CONVERT(DATETIMEOFFSET, NULLIF(j.CreeLe, ''))),
        TRY_CONVERT(DATETIME, TRY_CONVERT(DATETIMEOFFSET, NULLIF(j.ModifieLe, ''))),
        NULLIF(j.DescriptionSource, ''),
        dbo.fImportBit(j.SousCompte),
        NULLIF(j.NomComplet, '')
    FROM OPENJSON(@Lignes)
         WITH (
            LigneNo           INT            '$.LigneNo',
            CompteSource      NVARCHAR(50)   '$.CompteSource',
            NomSource         NVARCHAR(200)  '$.NomSource',
            TypeSource        NVARCHAR(100)  '$.TypeSource',
            SousTypeSource    NVARCHAR(100)  '$.SousTypeSource',
            SoldeSource       NVARCHAR(50)   '$.SoldeSource',
            SensSource        NVARCHAR(20)   '$.SensSource',
            Compte            NVARCHAR(50)   '$.Compte',
            Nom               NVARCHAR(200)  '$.Nom',
            TypeNormalise     VARCHAR(20)    '$.TypeNormalise',
            Solde             DECIMAL(18,2)  '$.Solde',
            Sens              VARCHAR(10)    '$.Sens',
            CreeLe            NVARCHAR(40)   '$.CreeLe',
            ModifieLe         NVARCHAR(40)   '$.ModifieLe',
            DescriptionSource NVARCHAR(500)  '$.DescriptionSource',
            SousCompte        NVARCHAR(10)   '$.SousCompte',
            NomComplet        NVARCHAR(300)  '$.NomComplet'
         ) j;

    -- ── L'origine : par défaut ou ajouté ──────────────────────────────────
    DECLARE @Naissance DATETIME =
        (SELECT MIN([CreeLe]) FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID);

    UPDATE staging.ImportPlanComptable
       SET [Origine] = CASE WHEN [CreeLe] IS NULL THEN NULL
                            WHEN [CreeLe] <= DATEADD(MINUTE, 10, @Naissance) THEN 'DEFAUT'
                            ELSE 'AJOUTE' END
     WHERE [CompanyGUID] = @CompanyGUID;

    -- ── Verdicts ──────────────────────────────────────────────────────────
    UPDATE staging.ImportPlanComptable
       SET [Statut]   = 'INVALIDE',
           [Anomalie] = N'Ligne sans numéro ni nom de compte : rien ne permet de l''identifier.'
     WHERE [CompanyGUID] = @CompanyGUID
       AND [CleSource] IS NULL;

    ;WITH d AS (
        SELECT [Id],
               ROW_NUMBER() OVER (PARTITION BY [CleSource] ORDER BY [LigneNo]) AS rn,
               MIN([LigneNo])  OVER (PARTITION BY [CleSource])                 AS PremiereLigne
          FROM staging.ImportPlanComptable
         WHERE [CompanyGUID] = @CompanyGUID AND [Statut] = 'OK'
    )
    UPDATE p
       SET p.[Statut]   = 'DOUBLON_FICHIER',
           p.[Anomalie] = N'Même clé (« ' + p.[CleSource] + N' ») que la ligne '
                        + CAST(d.PremiereLigne AS NVARCHAR(20)) + N' du fichier.'
      FROM staging.ImportPlanComptable p
     INNER JOIN d ON d.[Id] = p.[Id]
     WHERE d.rn > 1;

    UPDATE p
       SET p.[PlanComptableId] = pc.[Id],
           p.[Statut]          = 'EXISTE',
           p.[Anomalie]        = N'Déjà au plan comptable : ' + pc.[Nom]
      FROM staging.ImportPlanComptable p
     INNER JOIN dbo.T121PlanComptable pc
             ON pc.[CompanyGUID] = p.[CompanyGUID]
            AND pc.[Compte] = p.[Compte]
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NUMERO';

    UPDATE p
       SET p.[PlanComptableId] = n.[Id],
           p.[Statut]          = 'EXISTE',
           p.[Anomalie]        = N'Déjà au plan comptable : ' + n.[Compte] + N' - ' + n.[Nom]
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Id], pc.[Compte], pc.[Nom]
          FROM dbo.T121PlanComptable pc
         CROSS APPLY (VALUES (pc.[Nom]), (pc.[NomFr]), (pc.[NomEn]), (pc.[NomEs])) AS l([Libelle])
         WHERE pc.[CompanyGUID] = p.[CompanyGUID]
           AND ISNULL(pc.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = p.[CleSource]
           AND (p.[TypeNormalise] IS NULL
                OR dbo.fTypeBilanDeNature(p.[TypeNormalise]) IS NULL
                OR pc.[TypeBilan] = dbo.fTypeBilanDeNature(p.[TypeNormalise]))
         ORDER BY pc.[Compte]
     ) n
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NOM';

    -- ── Les alias QuickBooks du plan par défaut (T292) ─────────────────────
    -- Un compte QBO dont le nom (FR ou EN) ou le sous-type est connu du plan
    -- modèle est lié d'office au compte de même numéro chez la compagnie.
    EXEC dbo.s0874ProposerParAliasQBO @CompanyGUID = @CompanyGUID;

    UPDATE p
       SET p.[Anomalie] = N'Même nom que ' + n.[Compte] + N' - ' + n.[Nom]
                        + N', mais d''une autre nature (' + ISNULL(p.[TypeNormalise], N'?')
                        + N' ici, ' + n.[TypeBilan] + N' au plan) : à décider.'
      FROM staging.ImportPlanComptable p
     CROSS APPLY (
        SELECT TOP 1 pc.[Compte], pc.[Nom], pc.[TypeBilan]
          FROM dbo.T121PlanComptable pc
         CROSS APPLY (VALUES (pc.[Nom]), (pc.[NomFr]), (pc.[NomEn]), (pc.[NomEs])) AS l([Libelle])
         WHERE pc.[CompanyGUID] = p.[CompanyGUID]
           AND ISNULL(pc.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = p.[CleSource]
         ORDER BY pc.[Compte]
     ) n
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] = 'OK'
       AND p.[TypeCle] = 'NOM'
       AND p.[PlanComptableId] IS NULL
       AND p.[Anomalie] IS NULL;

    COMMIT TRANSACTION;

    SELECT COUNT(*)                                                                    AS [NbLignesLues],
           SUM(CASE WHEN [Statut] IN ('OK', 'EXISTE') THEN 1 ELSE 0 END)                AS [NbLignesRetenues],
           SUM(CASE WHEN [Statut] IN ('INVALIDE', 'DOUBLON_FICHIER') THEN 1 ELSE 0 END) AS [NbAnomalies],
           SUM(CASE WHEN [Origine] = 'AJOUTE' THEN 1 ELSE 0 END)                        AS [NbAjoutes],
           'CHARGE'                                                                     AS [Statut]
      FROM staging.ImportPlanComptable
     WHERE [CompanyGUID] = @CompanyGUID;
END

GO
CREATE OR ALTER PROCEDURE [dbo].[s0756GetCorrespondances]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = NULL,   -- DECIDE | A_DECIDER
    @Top         INT = 1000,
    @Origine     VARCHAR(20) = NULL    -- DEFAUT | AJOUTE (origine du compte source)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH src AS (
        SELECT p.[Id] AS StagingId, p.[LigneNo],
               p.[CleSource], p.[TypeCle],
               p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde],
               p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SousTypeSource],
               p.[SoldeSource], p.[SensSource], p.[SystemeSource],
               p.[CreeLe], p.[ModifieLe], p.[Origine] AS OrigineSource,
               p.[DescriptionSource], p.[SousCompte], p.[NomComplet],
               p.[Anomalie] AS AnomalieChargement,
               p.[Statut] AS StatutChargement,
               p.[PlanComptableId] AS ProposeAuChargement,
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison],
               p.[ProposeParAlias]
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND (@Origine IS NULL OR p.[Origine] = @Origine)
    )
    SELECT TOP (@Top)
        s.StagingId, s.LigneNo, s.CleSource, s.TypeCle,
        s.Compte, s.Nom, s.TypeNormalise, s.Solde, s.StatutChargement,
        s.CompteSource, s.NomSource, s.TypeSource, s.SousTypeSource,
        s.SoldeSource, s.SensSource, s.SystemeSource, s.AnomalieChargement,
        s.CreeLe, s.ModifieLe, s.OrigineSource, s.DescriptionSource, s.SousCompte, s.NomComplet,
        c.[Id]              AS CorrespondanceId,
        c.[Action],
        c.[PlanComptableId] AS DecidePlanComptableId,
        c.[CompteCible],
        c.[NomCible],
        c.[Note],
        COALESCE(c.[PlanComptableId], s.ProposeAuChargement, n.[Id], s.[ProposeIAId]) AS ProposeId,
        CASE
            WHEN c.[Id] IS NOT NULL                THEN 'DECIDE'
            WHEN s.ProposeAuChargement IS NOT NULL AND s.ProposeParAlias = 1 THEN 'PROPOSE_QBO'
            WHEN s.ProposeAuChargement IS NOT NULL AND s.TypeCle = 'NUMERO' THEN 'PROPOSE_NUMERO'
            WHEN s.ProposeAuChargement IS NOT NULL THEN 'PROPOSE_NOM'
            WHEN n.[Id] IS NOT NULL                THEN 'PROPOSE_NOM'
            WHEN s.[ProposeIAId] IS NOT NULL       THEN 'PROPOSE_IA'
            ELSE 'AUCUN'
        END AS Origine,
        pc.[Compte] AS ProposeCompte,
        pc.[Nom]    AS ProposeNom,
        pcl.[Id]          AS ProposeClasseId,
        pcl.[Code]        AS ProposeClasse,
        pcl.[Description] AS ProposeClasseNom,
        s.[ProposeIAConfiance] AS IAConfiance,
        s.[ProposeIARaison]    AS IARaison,
        ia.[Compte]            AS IACompte,
        ia.[Nom]               AS IANom,
        icl.[Code]             AS IAClasse,
        icl.[Description]      AS IAClasseNom
    FROM src s
    LEFT JOIN staging.CorrespondanceCompte c
           ON c.[CompanyGUID] = @CompanyGUID
          AND c.[SystemeSource] = @Systeme
          AND c.[CleSource] = s.CleSource
    OUTER APPLY (
        SELECT TOP 1 p2.[Id]
          FROM dbo.T121PlanComptable p2
         CROSS APPLY (VALUES (p2.[Nom]), (p2.[NomFr]), (p2.[NomEn]), (p2.[NomEs])) AS l([Libelle])
         WHERE s.ProposeAuChargement IS NULL
           AND p2.[CompanyGUID] = @CompanyGUID
           AND ISNULL(p2.[Actif], 1) = 1
           AND UPPER(LTRIM(RTRIM(l.[Libelle]))) = UPPER(LTRIM(RTRIM(s.Nom)))
           AND (s.TypeNormalise IS NULL
                OR dbo.fTypeBilanDeNature(s.TypeNormalise) IS NULL
                OR p2.[TypeBilan] = dbo.fTypeBilanDeNature(s.TypeNormalise))
         ORDER BY p2.[Compte]
    ) n
    LEFT JOIN dbo.T121PlanComptable pc
           ON pc.[Id] = COALESCE(c.[PlanComptableId], s.ProposeAuChargement, n.[Id], s.[ProposeIAId])
    LEFT JOIN dbo.T120PlanComptable_Classe pcl ON pcl.[Id] = pc.[ClasseId]
    LEFT JOIN dbo.T121PlanComptable ia
           ON ia.[Id] = s.[ProposeIAId]
    LEFT JOIN dbo.T120PlanComptable_Classe icl ON icl.[Id] = ia.[ClasseId]
    WHERE (@Filtre IS NULL
           OR (@Filtre = 'DECIDE'    AND c.[Id] IS NOT NULL)
           OR (@Filtre = 'A_DECIDER' AND c.[Id] IS NULL))
    ORDER BY s.LigneNo;
END

GO
-- ── 2) s0760 : une proposition par compte cible ───────────────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0760AccepterPropositions]
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH candidats AS (
        SELECT p.[CleSource], p.[TypeCle], p.[Compte], p.[Nom], p.[PlanComptableId], p.[ProposeParAlias],
               ROW_NUMBER() OVER (PARTITION BY p.[PlanComptableId] ORDER BY p.[LigneNo]) AS rn
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND p.[PlanComptableId] IS NOT NULL
           AND NOT EXISTS (
                SELECT 1 FROM staging.CorrespondanceCompte c
                 WHERE c.[CompanyGUID] = @CompanyGUID
                   AND c.[SystemeSource] = @Systeme
                   AND c.[CleSource] = p.[CleSource])
           -- le compte cible n'est pas déjà pris par une autre liaison
           AND NOT EXISTS (
                SELECT 1 FROM staging.CorrespondanceCompte c
                 WHERE c.[CompanyGUID] = @CompanyGUID
                   AND c.[SystemeSource] = @Systeme
                   AND c.[Action] = 'LIER'
                   AND c.[PlanComptableId] = p.[PlanComptableId])
    )
    INSERT INTO staging.CorrespondanceCompte
        ([CompanyGUID], [SystemeSource], [CleSource], [TypeCle],
         [CompteSource], [NomSource], [Action], [PlanComptableId], [Note], [CreatedBy])
    SELECT @CompanyGUID, @Systeme, c.[CleSource], c.[TypeCle],
           c.[Compte], c.[Nom], 'LIER', c.[PlanComptableId],
           CASE WHEN c.[ProposeParAlias] = 1
                THEN N'Proposition acceptée : nom QuickBooks connu du plan (alias).'
                WHEN c.[TypeCle] = 'NUMERO'
                THEN N'Proposition acceptée : même numéro de compte.'
                ELSE N'Proposition acceptée : même nom de compte.' END,
           @UserId
      FROM candidats c
     WHERE c.rn = 1;   -- deux sources vers le même compte : la première seulement

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END

GO
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
        c.[QBOCompteFR], c.[QBOCompteEN], c.[QBOSousType]
    FROM [dbo].[T121PlanComptable] c
    INNER JOIN [dbo].[T120PlanComptable_Classe] sc ON c.[ClasseId] = sc.[Id]
    INNER JOIN [dbo].[T120PlanComptable_Classe] p  ON c.[ClasseParentId] = p.[Id]
    WHERE
        -- Le plan est celui de la compagnie, et d'aucune autre.
        c.[CompanyGUID] = @CompanyGUID
        AND (@Filtre = 'ALL' OR p.[GroupeEtatFinancier] = @Filtre)
        AND (
            @Search = ''
            OR c.Compte LIKE '%' + @Search + '%'
            OR c.[Nom]  LIKE '%' + @Search + '%'
            OR c.NomEn  LIKE '%' + @Search + '%'
            OR c.NomEs  LIKE '%' + @Search + '%'
            OR c.QBOCompteFR LIKE '%' + @Search + '%'
            OR c.QBOCompteEN LIKE '%' + @Search + '%'
            OR c.QBOSousType LIKE '%' + @Search + '%'
            OR sc.[Code] LIKE '%' + @Search + '%'
            OR sc.[Description] LIKE '%' + @Search + '%'
            OR sc.DescriptionEn LIKE '%' + @Search + '%'
            OR sc.DescriptionEs LIKE '%' + @Search + '%'
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
           c.[QBOCompteFR], c.[QBOCompteEN], c.[QBOSousType]
      FROM [dbo].[T121PlanComptable] c
      LEFT JOIN [dbo].[T120PlanComptable_Classe] sc ON sc.[Id] = c.[ClasseId]
      LEFT JOIN [dbo].[T120PlanComptable_Classe] p  ON p.[Id]  = c.[ClasseParentId]
     WHERE c.[Id] = @Id
       AND c.[CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0054InsertPlanComptableCompte]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Numero         VARCHAR(10),
    @Nom            VARCHAR(150),
    @ClasseId       INT,
    @ClasseParentId INT,
    @TypeBilan      VARCHAR(10),
    @Sens           VARCHAR(10),
    @Actif          BIT = 1,
    @Description    VARCHAR(250) = NULL,
    @QBOCompteFR    NVARCHAR(200) = NULL,
    @QBOCompteEN    NVARCHAR(200) = NULL,
    @QBOSousType    NVARCHAR(100) = NULL,
    @QBOMaj         BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @Numero)
    BEGIN
        RAISERROR('Le numéro de compte "%s" existe déjà.', 16, 1, @Numero);
        RETURN;
    END
    -- La classe doit être celle de la compagnie : un Id d'une autre compagnie
    -- rangerait le compte hors de son plan.
    IF NOT EXISTS (SELECT 1 FROM [dbo].[T120PlanComptable_Classe]
                    WHERE [Id] = @ClasseId AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        RAISERROR('La classe choisie n''appartient pas à cette compagnie.', 16, 1);
        RETURN;
    END
    -- Id sans IDENTITY : le suivant, toutes compagnies confondues.
    DECLARE @NewId INT;
    SELECT @NewId = ISNULL(MAX([Id]), 0) + 1 FROM [dbo].[T121PlanComptable];
    INSERT INTO [dbo].[T121PlanComptable]
        ([Id], [CompanyGUID], [Compte], [Nom], [NomFr], [ClasseId], [ClasseParentId], [TypeBilan], [Sens],
         [Ordre], [Actif], [Systeme], [Description], [QBOCompteFR], [QBOCompteEN], [QBOSousType])
    VALUES
        (@NewId, @CompanyGUID, @Numero, @Nom, @Nom, @ClasseId, @ClasseParentId, @TypeBilan, @Sens,
         TRY_CONVERT(INT, @Numero), @Actif, 0, @Description,
         NULLIF(LTRIM(RTRIM(@QBOCompteFR)), ''), NULLIF(LTRIM(RTRIM(@QBOCompteEN)), ''), NULLIF(LTRIM(RTRIM(@QBOSousType)), ''));
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
    @Description    VARCHAR(250) = NULL,
    @QBOCompteFR    NVARCHAR(200) = NULL,
    @QBOCompteEN    NVARCHAR(200) = NULL,
    @QBOSousType    NVARCHAR(100) = NULL,
    @QBOMaj         BIT = 0            -- 1 : les trois alias font foi, vides compris (T292)
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
           [Description]    = @Description,
           [QBOCompteFR]    = CASE WHEN @QBOMaj = 1 THEN NULLIF(LTRIM(RTRIM(@QBOCompteFR)), '') ELSE [QBOCompteFR] END,
           [QBOCompteEN]    = CASE WHEN @QBOMaj = 1 THEN NULLIF(LTRIM(RTRIM(@QBOCompteEN)), '') ELSE [QBOCompteEN] END,
           [QBOSousType]    = CASE WHEN @QBOMaj = 1 THEN NULLIF(LTRIM(RTRIM(@QBOSousType)), '') ELSE [QBOSousType] END
     WHERE [Id] = @Id
       AND [CompanyGUID] = @CompanyGUID;
END
GO

PRINT N'T292_Alias_QuickBooks_plan_comptable.sql : terminé.';
