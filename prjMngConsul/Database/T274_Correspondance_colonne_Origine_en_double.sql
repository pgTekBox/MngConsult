-- =============================================================================
-- T274 — La grille de correspondance disait « aucune proposition » à tort
--
-- Depuis T271, s0756 rendait deux colonnes nommées Origine : celle du staging
-- (DEFAUT / AJOUTE, d'où vient le compte QuickBooks) et celle, calculée, qui
-- dit d'où vient la proposition (DECIDE / PROPOSE_NUMERO / PROPOSE_NOM /
-- PROPOSE_IA / AUCUN). ADO.NET renomme la seconde « Origine1 » : la page
-- lisait la première, ne reconnaissait aucune de ses valeurs, et affichait
-- « aucune proposition » sous chaque compte — avec, juste à côté, « l'IA
-- suggère plutôt … », puisque l'avis de l'IA, lui, arrivait bien.
--
-- L'origine du compte source s'appelle désormais OrigineSource ; Origine
-- redevient celle de la proposition, comme avant T271.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison]
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

PRINT 'T274_Correspondance_colonne_Origine_en_double.sql : terminé.';
