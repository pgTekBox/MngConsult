-- =============================================================================
-- T301 — Un nom QuickBooks connu du plan ne se propose plus : il LIE d'office
--
-- À l'étape 2, un compte QuickBooks reconnu par alias (T298) restait une
-- proposition « nom QuickBooks connu » à accepter. Un alias est posé par le
-- personnel de 60Sec, aussi sûr qu'un numéro : la liaison se fait d'elle-même
-- au chargement du plan, et reste modifiable dans la grille comme toute décision.
--
--   s0883LierParAliasQBO : pour chaque compte en préparation reconnu par alias
--       (ProposeParAlias = 1) sans décision, et dont le compte d'ici n'est pas
--       déjà pris par une autre liaison, une décision LIER avec la note
--       « Lié d'office : nom QuickBooks connu du plan (alias). »
--   s0874 l'appelle à la fin (donc s0752 au chargement).
--   s0756 renvoie LieDOffice (1 quand la décision porte cette note) pour que la
--       grille montre d'où vient la liaison.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0883LierParAliasQBO]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH candidats AS (
        SELECT p.[CleSource], p.[TypeCle], p.[Compte], p.[Nom], p.[PlanComptableId],
               ROW_NUMBER() OVER (PARTITION BY p.[PlanComptableId] ORDER BY p.[LigneNo]) AS rn
          FROM staging.ImportPlanComptable p
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND p.[ProposeParAlias] = 1
           AND p.[PlanComptableId] IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM staging.CorrespondanceCompte c
                            WHERE c.[CompanyGUID] = @CompanyGUID AND c.[SystemeSource] = @Systeme AND c.[CleSource] = p.[CleSource])
           AND NOT EXISTS (SELECT 1 FROM staging.CorrespondanceCompte c
                            WHERE c.[CompanyGUID] = @CompanyGUID AND c.[SystemeSource] = @Systeme
                              AND c.[Action] = 'LIER' AND c.[PlanComptableId] = p.[PlanComptableId])
    )
    INSERT INTO staging.CorrespondanceCompte
        ([CompanyGUID], [SystemeSource], [CleSource], [TypeCle], [CompteSource], [NomSource], [Action], [PlanComptableId], [Note], [CreatedBy])
    SELECT @CompanyGUID, @Systeme, c.[CleSource], c.[TypeCle], c.[Compte], c.[Nom], 'LIER', c.[PlanComptableId],
           N'Lié d''office : nom QuickBooks connu du plan (alias).', NULL
      FROM candidats c
     WHERE c.rn = 1;

    SELECT @@ROWCOUNT AS [NbLies];
END
GO

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

    DECLARE @ParSousType INT = @@ROWCOUNT;

    -- 3) La liaison d'office (T301).
    DECLARE @lies TABLE ([NbLies] INT);
    INSERT INTO @lies EXEC dbo.s0883LierParAliasQBO @CompanyGUID = @CompanyGUID;

    SELECT @ParNom AS [NbParNom], @ParSousType AS [NbParSousType], (SELECT TOP 1 [NbLies] FROM @lies) AS [NbLiesDOffice];
END
GO

-- -----------------------------------------------------------------------------
-- s0756 — LieDOffice : la grille montre d'où vient la liaison
-- -----------------------------------------------------------------------------
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
        CASE WHEN c.[Note] LIKE N'Lié d''office%' THEN 1 ELSE 0 END AS LieDOffice,
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

PRINT N'T301_Alias_QBO_liaison_d_office.sql : terminé.';
