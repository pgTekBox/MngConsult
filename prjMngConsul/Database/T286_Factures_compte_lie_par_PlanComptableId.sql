-- =============================================================================
-- T286 — Factures en préparation : un compte « Lié » se reconnaît par PlanComptableId
--
-- La décision « Lier » de l'étape 2 range le compte d'ici dans
-- staging.CorrespondanceCompte.PlanComptableId (s0757), jamais dans CompteCible.
-- T285 ne lisait que CompteCible : toutes les lignes ressortaient « lié sans
-- cible », donc « sans compte lié » sur l'icône de conformité. Désormais :
--   LIE  : Action = LIER avec PlanComptableId (ou, à défaut, CompteCible)
--   CREE : compte appliqué (pc.PlanComptableId + AppliqueLe) ou « Créer » qui
--          porte déjà son PlanComptableId (compte né à l'étape 3, cf. T277)
-- Le numéro et le nom du compte d'ici viennent de T121 via ce PlanComptableId.
-- Le reste de s0782 est celui de T285.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0782GetDocumentsImport]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT = NULL,
    @RunId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.s0855ResoudreDocumentsImport @CompanyGUID = @CompanyGUID;

    SELECT d.[Id], d.[RunId], d.[DocumentTypeId], d.[Rang], d.[ExterneId], d.[Numero],
           d.[DateDocument], d.[DateEcheance], d.[TiersExterneId], d.[TiersNom], d.[PartyGUID],
           d.[PartyImportId],
           p.[Name] AS [TiersReconnu],
           CASE WHEN d.[PartyGUID] IS NOT NULL THEN 1 ELSE 0 END AS [TiersCree],
           d.[Devise], d.[SousTotal], d.[TotalTaxes], d.[TPS], d.[TVQ], d.[Total], d.[Solde],
           d.[StatutSource], d.[NbLignes], d.[Statut], d.[Anomalie],
           d.[DocumentId], d.[MigratedDate], d.[Created]
      FROM staging.DocumentImport d
      LEFT JOIN staging.PartyImport p ON p.[Id] = d.[PartyImportId]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (@DocumentTypeId IS NULL OR d.[DocumentTypeId] = @DocumentTypeId)
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     ORDER BY d.[DocumentTypeId], d.[Rang];

    SELECT l.[Id], l.[EnteteId], l.[LigneNo], l.[Description],
           l.[ProduitExterneId], l.[ProduitNom], l.[ProductId], l.[ProductImportId],
           pi.[Name] AS [ProduitReconnu],
           CASE WHEN l.[ProductId] IS NOT NULL THEN 1 ELSE 0 END AS [ProduitCree],
           CASE WHEN l.[ProductId] IS NOT NULL THEN 'CREE'
                WHEN l.[ProductImportId] IS NOT NULL THEN 'A_CREER'
                WHEN NULLIF(LTRIM(RTRIM(ISNULL(l.[ProduitNom], ''))), '') IS NULL
                     AND NULLIF(LTRIM(RTRIM(ISNULL(l.[ProduitExterneId], ''))), '') IS NULL THEN 'AUCUN'
                ELSE 'ABSENT' END AS [ProduitEtat],
           l.[Quantite], l.[PrixUnitaire], l.[Montant],
           l.[TaxeCode], l.[TPS], l.[TVQ], l.[CompteSource], l.[CompteNom],
           l.[CompteImportId], l.[CompteCible],
           pc.[NomSource] AS [CompteReconnu], pc.[Statut] AS [CompteStatut],
           cc.[Action] AS [CorrespAction],
           CASE WHEN l.[CompteImportId] IS NULL THEN
                     CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(l.[CompteNom], ''))), '') IS NULL
                               AND NULLIF(LTRIM(RTRIM(ISNULL(l.[CompteSource], ''))), '') IS NULL THEN 'AUCUN' ELSE 'ABSENT' END
                WHEN pc.[PlanComptableId] IS NOT NULL AND pc.[AppliqueLe] IS NOT NULL THEN 'CREE'
                WHEN pc.[PlanComptableId] IS NOT NULL THEN 'EXISTE'
                WHEN cc.[Action] = 'CREER' AND cc.[PlanComptableId] IS NOT NULL THEN 'CREE'
                WHEN cc.[Action] = 'LIER' AND (cc.[PlanComptableId] IS NOT NULL OR NULLIF(cc.[CompteCible], '') IS NOT NULL) THEN 'LIE'
                WHEN cc.[Action] = 'LIER' THEN 'LIE_SANS_CIBLE'
                WHEN cc.[Action] = 'CREER' THEN 'A_CREER'
                WHEN cc.[Action] = 'IGNORER' THEN 'IGNORE'
                ELSE 'A_DECIDER' END AS [CompteEtat],
           COALESCE(t.[Compte], tc.[Compte], NULLIF(l.[CompteCible], ''), NULLIF(cc.[CompteCible], '')) AS [CompteEtatNumero],
           COALESCE(t.[Nom], tc.[Nom], tl.[Nom], NULLIF(cc.[NomCible], '')) AS [CompteEtatNom],
           l.[Statut], l.[Anomalie]
      FROM staging.DocumentImportLigne l
     INNER JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      LEFT JOIN staging.ProductImport pi ON pi.[Id] = l.[ProductImportId]
      LEFT JOIN staging.ImportPlanComptable pc ON pc.[Id] = l.[CompteImportId]
      LEFT JOIN dbo.T121PlanComptable t ON t.[Id] = pc.[PlanComptableId]
      LEFT JOIN dbo.T121PlanComptable tl ON tl.[CompanyGUID] = @CompanyGUID AND tl.[Compte] = l.[CompteCible] AND t.[Id] IS NULL
     OUTER APPLY (SELECT TOP 1 c.[Action], c.[PlanComptableId], c.[CompteCible], c.[NomCible]
                    FROM staging.CorrespondanceCompte c
                   WHERE c.[CompanyGUID] = @CompanyGUID AND pc.[Id] IS NOT NULL
                     AND ((NULLIF(pc.[CleSource], '') IS NOT NULL AND c.[CleSource] = pc.[CleSource])
                          OR (NULLIF(pc.[CompteSource], '') IS NOT NULL AND c.[CompteSource] = pc.[CompteSource]))
                   ORDER BY c.[Id] DESC) cc
      LEFT JOIN dbo.T121PlanComptable tc ON tc.[Id] = cc.[PlanComptableId]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND (@DocumentTypeId IS NULL OR d.[DocumentTypeId] = @DocumentTypeId)
       AND (@RunId IS NULL OR d.[RunId] = @RunId)
     ORDER BY l.[EnteteId], l.[LigneNo];
END
GO

PRINT N'T286_Factures_compte_lie_par_PlanComptableId.sql : terminé.';
