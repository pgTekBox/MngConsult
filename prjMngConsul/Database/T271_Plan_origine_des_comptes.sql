-- =============================================================================
-- T271 — Le plan importé dit quels comptes l'utilisateur a ajoutés lui-même
--
-- QuickBooks ne marque pas ses comptes par défaut. Mais il date chacun :
-- ceux qu'il crée à l'ouverture de la société arrivent tous dans la même
-- minute (chez Pierre : 54 comptes le 2026-04-08 entre 09:29 et 09:30), et
-- ceux que l'utilisateur ajoute — ou que QuickBooks crée à la première
-- utilisation, comme Comptes fournisseurs ou la taxe à payer — s'étalent sur
-- les mois qui suivent. La date de création suffit donc à distinguer les
-- deux, sans rien deviner au nom.
--
--   Origine = DEFAUT  : créé dans les dix minutes qui suivent le premier
--                       compte de la société ;
--             AJOUTE  : créé plus tard — par l'utilisateur, ou par QuickBooks
--                       au fil de l'usage.
--
-- Au passage, ce que la source dit encore et qu'on ne gardait pas : la date
-- de création et de modification, la description, si c'est un sous-compte,
-- et le nom complet « Parent:Enfant ».
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('staging.ImportPlanComptable', 'CreeLe')            IS NULL ALTER TABLE staging.ImportPlanComptable ADD [CreeLe]            DATETIME      NULL;
IF COL_LENGTH('staging.ImportPlanComptable', 'ModifieLe')         IS NULL ALTER TABLE staging.ImportPlanComptable ADD [ModifieLe]         DATETIME      NULL;
IF COL_LENGTH('staging.ImportPlanComptable', 'Origine')           IS NULL ALTER TABLE staging.ImportPlanComptable ADD [Origine]           VARCHAR(20)   NULL;   -- DEFAUT | AJOUTE
IF COL_LENGTH('staging.ImportPlanComptable', 'DescriptionSource') IS NULL ALTER TABLE staging.ImportPlanComptable ADD [DescriptionSource] NVARCHAR(500) NULL;
IF COL_LENGTH('staging.ImportPlanComptable', 'SousCompte')        IS NULL ALTER TABLE staging.ImportPlanComptable ADD [SousCompte]        BIT           NULL;
IF COL_LENGTH('staging.ImportPlanComptable', 'NomComplet')        IS NULL ALTER TABLE staging.ImportPlanComptable ADD [NomComplet]        NVARCHAR(300) NULL;
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

CREATE OR ALTER PROCEDURE [dbo].[s0753GetPlanComptableStaging]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Statut      VARCHAR(20) = NULL,
    @Origine     VARCHAR(20) = NULL,   -- DEFAUT | AJOUTE
    @Top         INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        p.[Id], p.[LigneNo],
        p.[CompteSource], p.[NomSource], p.[TypeSource], p.[SousTypeSource], p.[SoldeSource], p.[SensSource],
        p.[Compte], p.[Nom], p.[TypeNormalise], p.[Solde], p.[Sens],
        p.[CleSource], p.[TypeCle],
        p.[CreeLe], p.[ModifieLe], p.[Origine], p.[DescriptionSource], p.[SousCompte], p.[NomComplet],
        CASE p.[Origine] WHEN 'DEFAUT' THEN N'Défaut QuickBooks' WHEN 'AJOUTE' THEN N'Ajouté' ELSE N'' END AS [OrigineTexte],
        p.[Statut], p.[Anomalie],
        p.[PlanComptableId],
        pc.[Nom] AS NomAuPlan
    FROM staging.ImportPlanComptable p
    LEFT JOIN dbo.T121PlanComptable pc ON pc.[Id] = p.[PlanComptableId]
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND (@Statut IS NULL OR p.[Statut] = @Statut)
      AND (@Origine IS NULL OR p.[Origine] = @Origine)
    ORDER BY p.[LigneNo];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0756GetCorrespondances]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = NULL,
    @Top         INT = 1000
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
               p.[CreeLe], p.[ModifieLe], p.[Origine], p.[DescriptionSource], p.[SousCompte], p.[NomComplet],
               p.[Anomalie] AS AnomalieChargement,
               p.[Statut] AS StatutChargement,
               p.[PlanComptableId] AS ProposeAuChargement,
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison]
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
    )
    SELECT TOP (@Top)
        s.StagingId, s.LigneNo, s.CleSource, s.TypeCle,
        s.Compte, s.Nom, s.TypeNormalise, s.Solde, s.StatutChargement,
        s.CompteSource, s.NomSource, s.TypeSource, s.SousTypeSource,
        s.SoldeSource, s.SensSource, s.SystemeSource, s.AnomalieChargement,
        s.CreeLe, s.ModifieLe, s.Origine, s.DescriptionSource, s.SousCompte, s.NomComplet,
        c.[Id]              AS CorrespondanceId,
        c.[Action],
        c.[PlanComptableId] AS DecidePlanComptableId,
        c.[CompteCible],
        c.[NomCible],
        c.[Note],
        COALESCE(c.[PlanComptableId], s.ProposeAuChargement, n.[Id], s.[ProposeIAId]) AS ProposeId,
        CASE
            WHEN c.[Id] IS NOT NULL                THEN 'DECIDE'
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
