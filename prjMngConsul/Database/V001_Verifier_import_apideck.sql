-- =============================================================================
-- V001 — Vérifier une extraction Apideck
--
-- À lancer APRÈS une extraction, pour répondre à quatre questions dans l'ordre :
--
--   1. l'extraction est-elle allée au bout, et qu'a-t-elle rapporté ?
--   2. chaque ressource est-elle arrivée dans une table typée, ou dort-elle
--      encore en JSON faute d'écran pour la lire ?
--   3. combien de lignes exploitables, et combien à corriger ?
--   4. les factures bouclent-elles ?
--
-- Ce n'est pas un script de migration : il ne modifie rien et se relance autant
-- de fois qu'on veut.
--
-- ⚠️ Mettez le bon CompanyGUID ci-dessous, sinon tout paraîtra vide.
--
-- Conseil : videz la préparation AVANT l'extraction (bouton en bas de l'écran
-- Importations). Le dépôt brut se remplace par extraction, pas globalement —
-- sans le vidage, les lignes de la précédente restent à côté et les décomptes
-- de l'étape 2 additionneraient deux lectures.
-- =============================================================================

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @CompanyGUID UNIQUEIDENTIFIER = 'D89EB638-6B05-443D-B1C9-01A6316443BF';

-- -----------------------------------------------------------------------------
-- 1) Les extractions, la plus récente en tête
-- -----------------------------------------------------------------------------
SELECT TOP 5
       '1. EXTRACTIONS' AS [Etape],
       r.[Id] AS [Run], r.[Statut], r.[Debut], r.[Fin],
       r.[NbRessources] AS [Ressources], r.[NbEnregistrements] AS [Enreg],
       r.[Note]
  FROM staging.ConnecteurRun r
 WHERE r.[CompanyGUID] = @CompanyGUID
 ORDER BY r.[Id] DESC;

-- -----------------------------------------------------------------------------
-- 2) Ce que la dernière extraction a rapporté, ressource par ressource
-- -----------------------------------------------------------------------------
DECLARE @Run INT =
    (SELECT MAX([Id]) FROM staging.ConnecteurRun WHERE [CompanyGUID] = @CompanyGUID);

SELECT '2. RESSOURCES' AS [Etape],
       d.[Ressource],
       COUNT(*) AS [Enregistrements],
       -- Depuis T236, les vingt-six ressources du catalogue sont toutes
       -- interpretees. La colonne reste : elle redeviendra utile si une
       -- ressource nouvelle arrive sans destination.
       'interpretee' AS [Traitement]
  FROM staging.ConnecteurDonnee d
 WHERE d.[RunId] = @Run
 GROUP BY d.[Ressource]
 ORDER BY d.[Ressource];

-- -----------------------------------------------------------------------------
-- 3) Les tables typées — ce qui est réellement exploitable
-- -----------------------------------------------------------------------------
SELECT '3. TABLES TYPEES' AS [Etape], [Table], [Lignes], [A corriger] FROM (
    SELECT 'SocieteImport' AS [Table], COUNT(*) AS [Lignes],
           SUM(CASE WHEN [Statut] = 'DIFFERENT' THEN 1 ELSE 0 END) AS [A corriger], 1 AS [Ordre]
      FROM staging.SocieteImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    -- Le plan comptable emprunte le rail des LOTS : chaque extraction ouvre
    -- son lot et les précédents restent. On ne compte donc que le dernier,
    -- sinon 58 comptes relus trois fois donneraient 174.
    SELECT 'ImportPlanComptable (dernier lot)', COUNT(*), 0, 2
      FROM staging.ImportPlanComptable pc
     WHERE pc.[CompanyGUID] = @CompanyGUID
       AND pc.[LotId] = (SELECT MAX([Id]) FROM staging.ImportLot
                          WHERE [CompanyGUID] = @CompanyGUID)
    UNION ALL
    SELECT 'TaxeImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'RECONNUE' THEN 1 ELSE 0 END), 3
      FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'ModePaiementImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END), 4
      FROM staging.ModePaiementImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'CategorieSuiviImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END), 5
      FROM staging.CategorieSuiviImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'DepartementImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END), 6
      FROM staging.DepartementImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'EmplacementImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END), 7
      FROM staging.EmplacementImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'PartyImport', COUNT(*), 0, 8
      FROM staging.PartyImport pi
     WHERE EXISTS (SELECT 1 FROM staging.ImportFiles f
                    WHERE f.[Id] = pi.[ImportFileId] AND f.[CompanyGUID] = @CompanyGUID)
    UNION ALL
    SELECT 'ProductImport', COUNT(*), 0, 9
      FROM staging.ProductImport pr
     WHERE EXISTS (SELECT 1 FROM staging.ImportFiles f
                    WHERE f.[Id] = pr.[ImportFileId] AND f.[CompanyGUID] = @CompanyGUID)
    UNION ALL
    SELECT 'DocumentImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END), 10
      FROM staging.DocumentImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'PieceCommercialeImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END), 11
      FROM staging.PieceCommercialeImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'PaiementImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END), 12
      FROM staging.PaiementImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    -- Les ecritures sont les seules dont on juge l'equilibre.
    SELECT 'EcritureImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END), 13
      FROM staging.EcritureImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'RapportImport', COUNT(*), 0, 14
      FROM staging.RapportImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'BalanceAgeeImport', COUNT(*), 0, 15
      FROM staging.BalanceAgeeImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'PieceJointeImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END), 16
      FROM staging.PieceJointeImport WHERE [CompanyGUID] = @CompanyGUID
    UNION ALL
    SELECT 'ConditionPaiementImport', COUNT(*),
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END), 17
      FROM staging.ConditionPaiementImport WHERE [CompanyGUID] = @CompanyGUID
) x
 ORDER BY [Ordre];

-- -----------------------------------------------------------------------------
-- 3 bis) Les lots du plan comptable
--    Une ligne par extraction. Plusieurs lots ne sont pas une anomalie — c'est
--    l'historique — mais il faut savoir lequel l'écran du plan comptable lit.
-- -----------------------------------------------------------------------------
SELECT '3bis. LOTS PLAN COMPTABLE' AS [Etape],
       l.[Id] AS [Lot], l.[SystemeSource], l.[Statut], l.[Created],
       l.[NbLignesLues], l.[ImportFileId],
       (SELECT COUNT(*) FROM staging.ImportPlanComptable pc WHERE pc.[LotId] = l.[Id]) AS [Comptes]
  FROM staging.ImportLot l
 WHERE l.[CompanyGUID] = @CompanyGUID
 ORDER BY l.[Id] DESC;

-- -----------------------------------------------------------------------------
-- 4) Les factures qui ne bouclent pas
--    s0785 refuse de créer un document dont SousTotal + TPS + TVQ s'écarte du
--    Total de plus d'un cent. Mieux vaut le voir ici qu'au moment de créer.
--
--    ⚠️ Un SousTotal absent vient de QuickBooks, qui le met dans une ligne du
--       détail et non sur l'entête. Sans taxes, l'écart est nul et tout va bien ;
--       AVEC des taxes, la colonne [Reserve] le signale — l'équilibre serait
--       alors faussement vrai, puisqu'on comparerait le total à lui-même.
-- -----------------------------------------------------------------------------
SELECT '4. EQUILIBRE' AS [Etape],
       d.[Numero], d.[DateDocument],
       d.[SousTotal], d.[TotalTaxes], d.[TPS], d.[TVQ], d.[Total],
       CAST(ISNULL(d.[SousTotal], ISNULL(d.[Total], 0)) + ISNULL(d.[TPS], 0)
            + ISNULL(d.[TVQ], 0) - ISNULL(d.[Total], 0) AS DECIMAL(18,2)) AS [Ecart],
       CASE WHEN d.[SousTotal] IS NULL AND ISNULL(d.[TotalTaxes], 0) <> 0
            THEN 'sous-total absent ALORS QUE la facture porte des taxes'
            WHEN d.[SousTotal] IS NULL THEN 'sous-total absent (sans taxes : sans effet)'
            ELSE '' END AS [Reserve]
  FROM staging.DocumentImport d
 WHERE d.[CompanyGUID] = @CompanyGUID
   AND d.[DocumentId] IS NULL
 ORDER BY ABS(ISNULL(d.[SousTotal], ISNULL(d.[Total], 0)) + ISNULL(d.[TPS], 0)
              + ISNULL(d.[TVQ], 0) - ISNULL(d.[Total], 0)) DESC,
          d.[Numero];

-- -----------------------------------------------------------------------------
-- 4 bis) Les ecritures qui ne bouclent pas
--    Des debits qui ne font pas les credits, c'est faux — sans appel.
-- -----------------------------------------------------------------------------
SELECT '4bis. ECRITURES' AS [Etape],
       [Numero], [DateEcriture], [Libelle], [TotalDebit], [TotalCredit],
       [NbLignes], [Statut], [Anomalie]
  FROM staging.EcritureImport
 WHERE [CompanyGUID] = @CompanyGUID AND [Statut] <> 'OK'
 ORDER BY [DateEcriture] DESC, [Numero];

-- -----------------------------------------------------------------------------
-- 5) Le registre : une ligne par import, avec ce qu'il a produit
-- -----------------------------------------------------------------------------
EXEC dbo.s0787GetImportsCompagnie @CompanyGUID = @CompanyGUID;
