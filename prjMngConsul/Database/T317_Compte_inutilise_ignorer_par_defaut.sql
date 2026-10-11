-- =============================================================================
-- T317 — Un compte à zéro que rien n'utilise dans les données importées :
--        la grille le dit, et propose « Ignorer » d'office
--
-- Un plan QuickBooks traîne des dizaines de comptes par défaut jamais servis.
-- Les créer un à un encombre le plan ; les repérer à la main est long. On le
-- fait pour vous : un compte « à décider » dont le solde est 0 ET qu'aucune
-- donnée importée ne mentionne — ni ligne de facture, ni produit, ni écriture
-- de journal, ni ligne de grand livre, ni balance de vérification, ni paiement,
-- mouvement bancaire, remise de DAS, pointage, budget, inventaire ou paie — est
-- marqué « inutilisé » dans la grille, et la liste Action part sur Ignorer.
-- Rien n'est décidé tant que vous n'enregistrez pas.
--
--   dbo.fComptesSourceUtilises(@CompanyGUID) — étendue (T304 ne comptait que les
--       lignes de factures et les produits) : + écritures, grand livre, balance,
--       autres (paiements, mouvements bancaires, remises, pointage, budgets,
--       inventaire, paie). Les comptes se reconnaissent par leur nom (nom, nom
--       source, nom complet) ou par leur numéro, puisque l'ancien logiciel les
--       écrit ainsi dans ses documents.
--   s0756GetCorrespondances — + NbLignesFactures, NbProduits, NbEcritures,
--       NbGrandLivre, NbBalance, NbAutres, NbUsages, Inutilise (BIT).
--   s0885GetComptesSourceUtilises (T304) continue de ne rendre que les comptes
--       utilisés par des factures ou des produits : le garde-fou « Ignorer
--       refusé » ne change pas.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fComptesSourceUtilises] (@CompanyGUID UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
    WITH noms AS (
        -- Chaque mention d'un compte PAR SON NOM dans les données importées,
        -- regroupée par nom normalisé et par famille.
        SELECT x.k, x.src, COUNT(*) AS n
          FROM (
            SELECT UPPER(LTRIM(RTRIM(l.[CompteNom]))) AS k, 'ECRITURE' AS src
              FROM staging.EcritureImportLigne l
              JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
             WHERE e.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(l.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(g.[CompteNom]))), 'GRANDLIVRE'
              FROM staging.GrandLivreImport g
             WHERE g.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(g.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(b.[Description]))), 'BALANCE'
              FROM staging.BalanceVerification b
             WHERE b.[CompanyGUID] = @CompanyGUID
               AND (ISNULL(b.[Debit], 0) <> 0 OR ISNULL(b.[Credit], 0) <> 0)
               AND NULLIF(LTRIM(RTRIM(b.[Description])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(pa.[CompteNom]))), 'AUTRE'
              FROM staging.PaiementImport pa
             WHERE pa.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(pa.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(v.[Nom]))), 'AUTRE'
              FROM staging.MouvementBancaireImport m
             CROSS APPLY (VALUES (m.[CompteVersNom]), (m.[CompteDepuisNom])) AS v([Nom])
             WHERE m.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(v.[Nom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(ml.[CompteNom]))), 'AUTRE'
              FROM staging.MouvementBancaireLigneImport ml
             WHERE ml.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(ml.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(rd.[CompteNom]))), 'AUTRE'
              FROM staging.RemiseDasImport rd
             WHERE rd.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(rd.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(rp.[CompteNom]))), 'AUTRE'
              FROM staging.RapprochementImport rp
             WHERE rp.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(rp.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(bl.[CompteNom]))), 'AUTRE'
              FROM staging.BudgetLigneImport bl
             WHERE bl.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(bl.[CompteNom])), '') IS NOT NULL
            UNION ALL
            SELECT UPPER(LTRIM(RTRIM(v.[Nom]))), 'AUTRE'
              FROM staging.InventaireImport inv
             CROSS APPLY (VALUES (inv.[CompteActifNom]), (inv.[CompteRevenuNom]), (inv.[CompteCoutNom])) AS v([Nom])
             WHERE inv.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(v.[Nom])), '') IS NOT NULL
          ) x
         GROUP BY x.k, x.src
    ), nums AS (
        -- Les mentions PAR NUMÉRO.
        SELECT x.k, x.src, COUNT(*) AS n
          FROM (
            SELECT LTRIM(RTRIM(l.[CompteNumero])) AS k, 'ECRITURE' AS src
              FROM staging.EcritureImportLigne l
              JOIN staging.EcritureImport e ON e.[Id] = l.[EnteteId]
             WHERE e.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(l.[CompteNumero])), '') IS NOT NULL
            UNION ALL
            SELECT LTRIM(RTRIM(b.[Compte])), 'BALANCE'
              FROM staging.BalanceVerification b
             WHERE b.[CompanyGUID] = @CompanyGUID
               AND (ISNULL(b.[Debit], 0) <> 0 OR ISNULL(b.[Credit], 0) <> 0)
               AND NULLIF(LTRIM(RTRIM(b.[Compte])), '') IS NOT NULL
            UNION ALL
            SELECT LTRIM(RTRIM(pl.[CompteGL])), 'AUTRE'
              FROM staging.PaieLigneImport pl
             WHERE pl.[CompanyGUID] = @CompanyGUID AND NULLIF(LTRIM(RTRIM(pl.[CompteGL])), '') IS NOT NULL
          ) x
         GROUP BY x.k, x.src
    )
    SELECT p.[CleSource],
           (SELECT COUNT(*)
              FROM staging.DocumentImportLigne l
              JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND l.[CompteImportId] = p.[Id]) AS NbLignesFactures,
           (SELECT COUNT(*)
              FROM staging.ProductImport pi
              JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
             WHERE f.[CompanyGUID] = @CompanyGUID
               AND pi.[Status] <> 'Error'
               AND pi.[MigratedToProductId] IS NULL
               AND (   (ISNULL(p.[Nom], N'') <> N''
                        AND p.[Nom] IN (pi.[IncomeAccountName], pi.[ExpenseAccountName], pi.[AssetAccountName]))
                    OR (ISNULL(p.[Compte], '') <> ''
                        AND p.[Compte] IN (pi.[IncomeAccountCode], pi.[ExpenseAccountCode], pi.[AssetAccountCode])))) AS NbProduits,
           ISNULL(u.NbEcritures, 0)  AS NbEcritures,
           ISNULL(u.NbGrandLivre, 0) AS NbGrandLivre,
           ISNULL(u.NbBalance, 0)    AS NbBalance,
           ISNULL(u.NbAutres, 0)     AS NbAutres
      FROM staging.ImportPlanComptable p
     OUTER APPLY (
        SELECT SUM(CASE WHEN z.src = 'ECRITURE'   THEN z.n ELSE 0 END) AS NbEcritures,
               SUM(CASE WHEN z.src = 'GRANDLIVRE' THEN z.n ELSE 0 END) AS NbGrandLivre,
               SUM(CASE WHEN z.src = 'BALANCE'    THEN z.n ELSE 0 END) AS NbBalance,
               SUM(CASE WHEN z.src = 'AUTRE'      THEN z.n ELSE 0 END) AS NbAutres
          FROM (
            SELECT nm.src, nm.n FROM noms nm
             WHERE nm.k IN (UPPER(LTRIM(RTRIM(p.[Nom]))), UPPER(LTRIM(RTRIM(p.[NomSource]))), UPPER(LTRIM(RTRIM(p.[NomComplet]))))
            UNION ALL
            SELECT nu.src, nu.n FROM nums nu
             WHERE nu.k IN (NULLIF(LTRIM(RTRIM(p.[Compte])), ''), NULLIF(LTRIM(RTRIM(p.[CompteSource])), ''))
          ) z
     ) u
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[CleSource] IS NOT NULL;
GO

-- -----------------------------------------------------------------------------
-- s0756GetCorrespondances — la grille de l'étape 2, + les usages et « Inutilise »
-- (solde 0 et aucune mention dans les données importées). La page part alors
-- sur Ignorer pour les comptes encore à décider.
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

    -- Les usages de chaque compte dans les données importées (T317), calculés
    -- une fois pour toute la grille.
    SELECT u.[CleSource],
           MAX(u.NbLignesFactures) AS NbLignesFactures, MAX(u.NbProduits) AS NbProduits,
           MAX(u.NbEcritures) AS NbEcritures, MAX(u.NbGrandLivre) AS NbGrandLivre,
           MAX(u.NbBalance) AS NbBalance, MAX(u.NbAutres) AS NbAutres
      INTO #u
      FROM dbo.fComptesSourceUtilises(@CompanyGUID) u
     GROUP BY u.[CleSource];

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
        ISNULL(u.NbLignesFactures, 0) AS NbLignesFactures, ISNULL(u.NbProduits, 0) AS NbProduits,
        ISNULL(u.NbEcritures, 0) AS NbEcritures, ISNULL(u.NbGrandLivre, 0) AS NbGrandLivre,
        ISNULL(u.NbBalance, 0) AS NbBalance, ISNULL(u.NbAutres, 0) AS NbAutres,
        ISNULL(u.NbLignesFactures, 0) + ISNULL(u.NbProduits, 0) + ISNULL(u.NbEcritures, 0)
          + ISNULL(u.NbGrandLivre, 0) + ISNULL(u.NbBalance, 0) + ISNULL(u.NbAutres, 0) AS NbUsages,
        -- Solde 0 et aucune mention nulle part : la grille le dit, et propose Ignorer.
        CASE WHEN ISNULL(s.Solde, 0) = 0
              AND ISNULL(u.NbLignesFactures, 0) + ISNULL(u.NbProduits, 0) + ISNULL(u.NbEcritures, 0)
                + ISNULL(u.NbGrandLivre, 0) + ISNULL(u.NbBalance, 0) + ISNULL(u.NbAutres, 0) = 0
             THEN 1 ELSE 0 END AS Inutilise,
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
    LEFT JOIN #u u ON u.[CleSource] = s.CleSource
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
