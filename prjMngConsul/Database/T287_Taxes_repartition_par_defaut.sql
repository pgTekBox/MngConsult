-- =============================================================================
-- T287 — Répartition des taxes : les taux du Québec quand la source n'en donne pas
--
-- s0794 coupe TotalTaxes en TPS et TVQ d'après les taux rapatriés de la source
-- (staging.TaxeImport, T230). Quand l'écran Factures rapatriait seulement les
-- factures, aucun taux n'était chargé : TPS et TVQ restaient vides et « Créer »
-- refusait les documents (sous-total + 0 + 0 ≠ total).
--
-- Nouvelle étape (e), après le cent qui manque et avant le sous-total déduit :
-- un document encore sans répartition dont le rapport taxes / base colle à un
-- taux du Québec (à 0,15 point près) est coupé d'office :
--   14,975 % → TPS 5 % + TVQ 9,975 %     5 % → TPS seule     9,975 % → TVQ seule
-- Le résultat porte un compteur de plus, NbParDefaut. Le reste de s0794 est
-- celui de T248.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0794RepartirTaxesImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50373, 'Aucune compagnie : impossible de répartir les taxes.', 1;

    BEGIN TRANSACTION;

    -- ── a) Ligne par ligne, quand la source donne le montant ────────────────
    UPDATE l
       SET l.[TPS] = ROUND(l.[TaxeMontant] * t.[TauxTPS] / (t.[TauxTPS] + t.[TauxTVQ]), 2),
           l.[TVQ] = l.[TaxeMontant]
                     - ROUND(l.[TaxeMontant] * t.[TauxTPS] / (t.[TauxTPS] + t.[TauxTVQ]), 2)
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.TaxeImport t
        ON t.[CompanyGUID] = d.[CompanyGUID]
       AND (t.[Code] = l.[TaxeCode] OR t.[ExterneId] = l.[TaxeCode])
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND l.[TaxeMontant] IS NOT NULL
       AND t.[TauxTPS] + t.[TauxTVQ] > 0;

    DECLARE @NbLignes INT = @@ROWCOUNT;

    -- ── b) Le document entier, quand un seul code le couvre ─────────────────
    -- On ne tente ce raccourci que si aucune ligne n'a été coupée : mélanger
    -- les deux méthodes sur un même document ferait un total faux.
    ;WITH UnSeulCode AS (
        SELECT d.[Id],
               MIN(NULLIF(l.[TaxeCode], '')) AS [Code],
               COUNT(DISTINCT NULLIF(l.[TaxeCode], '')) AS [NbCodes],
               SUM(CASE WHEN l.[TPS] IS NOT NULL OR l.[TVQ] IS NOT NULL THEN 1 ELSE 0 END) AS [DejaCoupe]
          FROM staging.DocumentImport d
          JOIN staging.DocumentImportLigne l ON l.[EnteteId] = d.[Id]
         WHERE d.[CompanyGUID] = @CompanyGUID
           AND d.[DocumentId] IS NULL
         GROUP BY d.[Id]
    )
    UPDATE d
       SET d.[TPS] = ROUND(d.[TotalTaxes] * t.[TauxTPS] / (t.[TauxTPS] + t.[TauxTVQ]), 2),
           d.[TVQ] = d.[TotalTaxes]
                     - ROUND(d.[TotalTaxes] * t.[TauxTPS] / (t.[TauxTPS] + t.[TauxTVQ]), 2)
      FROM staging.DocumentImport d
      JOIN UnSeulCode u ON u.[Id] = d.[Id]
      JOIN staging.TaxeImport t
        ON t.[CompanyGUID] = @CompanyGUID
       AND (t.[Code] = u.[Code] OR t.[ExterneId] = u.[Code])
     WHERE u.[NbCodes] = 1
       AND u.[DejaCoupe] = 0
       AND d.[TotalTaxes] IS NOT NULL
       AND d.[TotalTaxes] <> 0
       AND t.[TauxTPS] + t.[TauxTVQ] > 0;

    DECLARE @NbParTotal INT = @@ROWCOUNT;

    -- ── c) L'entête reçoit la somme de ses lignes ───────────────────────────
    UPDATE d
       SET d.[TPS] = s.[TPS],
           d.[TVQ] = s.[TVQ]
      FROM staging.DocumentImport d
     CROSS APPLY (
        SELECT SUM(l.[TPS]) AS [TPS], SUM(l.[TVQ]) AS [TVQ], COUNT(l.[TPS]) AS [Nb]
          FROM staging.DocumentImportLigne l WHERE l.[EnteteId] = d.[Id]
     ) AS s
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND s.[Nb] > 0;

    -- ── d) Le cent qui manque ───────────────────────────────────────────────
    -- Couper ligne par ligne laisse une poussière d'arrondi. Quand la source
    -- donne le total des taxes et que l'écart tient dans quelques cents, on le
    -- pose sur la TVQ plutôt que de laisser le document refusé pour si peu.
    UPDATE staging.DocumentImport
       SET [TVQ] = [TVQ] + ([TotalTaxes] - ([TPS] + [TVQ]))
     WHERE [CompanyGUID] = @CompanyGUID
       AND [DocumentId] IS NULL
       AND [TotalTaxes] IS NOT NULL
       AND [TPS] IS NOT NULL AND [TVQ] IS NOT NULL
       AND ABS([TotalTaxes] - ([TPS] + [TVQ])) > 0
       AND ABS([TotalTaxes] - ([TPS] + [TVQ])) <= 0.05;
    -- ── e) Les taux du Québec, quand la source n'a rien dit (T287) ──────────
    -- Un document toujours sans TPS ni TVQ, dont taxes / base colle à un taux
    -- du Québec (à 0,15 point près), est coupé d'office. La base est le
    -- sous-total, ou à défaut total − taxes. La tolérance est serrée exprès :
    -- un document d'une autre province, ou partiellement taxable, n'y entre pas
    -- et reste à répartir à la main.
    UPDATE d
       SET d.[TPS] = CASE WHEN r.[Ratio] BETWEEN 0.14825 AND 0.15125 THEN ROUND(d.[TotalTaxes] * 5.0 / 14.975, 2)
                          WHEN r.[Ratio] BETWEEN 0.04850 AND 0.05150 THEN d.[TotalTaxes]
                          ELSE 0 END,
           d.[TVQ] = CASE WHEN r.[Ratio] BETWEEN 0.14825 AND 0.15125 THEN d.[TotalTaxes] - ROUND(d.[TotalTaxes] * 5.0 / 14.975, 2)
                          WHEN r.[Ratio] BETWEEN 0.04850 AND 0.05150 THEN 0
                          ELSE d.[TotalTaxes] END
      FROM staging.DocumentImport d
     CROSS APPLY (SELECT d.[TotalTaxes] / NULLIF(COALESCE(d.[SousTotal], d.[Total] - d.[TotalTaxes]), 0) AS [Ratio]) r
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[TPS] IS NULL AND d.[TVQ] IS NULL
       AND d.[TotalTaxes] IS NOT NULL AND d.[TotalTaxes] > 0
       AND (r.[Ratio] BETWEEN 0.14825 AND 0.15125
            OR r.[Ratio] BETWEEN 0.04850 AND 0.05150
            OR r.[Ratio] BETWEEN 0.09825 AND 0.10125);

    DECLARE @NbParDefaut INT = @@ROWCOUNT;

    -- ── f) Le sous-total, déduit du total et des taxes ──────────────────────
    -- Voir l'entête du script : la source ne le donne pas, et sans lui aucune
    -- pièce ne boucle. Deux cas sûrs, et rien d'autre.
    UPDATE d
       SET d.[SousTotal] = d.[Total] - (ISNULL(d.[TPS], 0) + ISNULL(d.[TVQ], 0))
      FROM staging.DocumentImport d
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[SousTotal] IS NULL
       AND d.[Total] IS NOT NULL
       AND (
            -- 1) Aucune taxe, et les lignes le prouvent en totalisant la pièce.
            (   ISNULL(d.[TotalTaxes], 0) = 0
            AND d.[TPS] IS NULL AND d.[TVQ] IS NULL
            AND EXISTS (SELECT 1
                          FROM staging.DocumentImportLigne l
                         WHERE l.[EnteteId] = d.[Id]
                        HAVING ABS(SUM(ISNULL(l.[Montant], 0)) - d.[Total]) <= 0.01))
            -- 2) La répartition est faite et concorde avec la source.
         OR (   d.[TPS] IS NOT NULL AND d.[TVQ] IS NOT NULL
            AND ABS(ISNULL(d.[TotalTaxes], d.[TPS] + d.[TVQ]) - (d.[TPS] + d.[TVQ])) <= 0.01)
       );

    DECLARE @NbSousTotaux INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @NbLignes AS [NbLignesCoupees],
           @NbParTotal AS [NbDocumentsParTotal],
           @NbSousTotaux AS [NbSousTotaux],
           @NbParDefaut AS [NbParDefaut],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
               AND d.[TotalTaxes] IS NOT NULL AND d.[TotalTaxes] <> 0
               AND (d.[TPS] IS NULL OR d.[TVQ] IS NULL)) AS [NbSansRepartition],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
               AND d.[Total] IS NOT NULL
               AND ABS(ISNULL(d.[SousTotal], 0) + ISNULL(d.[TPS], 0)
                       + ISNULL(d.[TVQ], 0) - d.[Total]) > 0.01) AS [NbDesequilibres];
END
GO

PRINT N'T287_Taxes_repartition_par_defaut.sql : terminé.';
