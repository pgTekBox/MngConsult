-- =============================================================================
-- T289 — Les lignes suivent l'entête coupée d'office
--
-- T287 coupe l'entête aux taux du Québec quand la source n'a donné aucun taux ;
-- T288 calcule les lignes d'après leur code quand les taux sont connus. Entre
-- les deux, un trou : entête répartie, lignes vides (« — » dans l'écran).
-- Nouvelle étape (e2) : quand l'entête porte ses taxes, qu'aucune ligne n'a
-- les siennes et que toutes les lignes ont le même code (ou aucun), chaque
-- ligne reçoit montant × le taux que l'entête révèle (5 % et/ou 9,975 %).
-- Compteur NbLignesParDefaut. Le reste de s0794 est celui de T288.
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

    -- ── a2) Ligne par ligne, d'après le code de la ligne (T288) ─────────────
    -- QuickBooks ne donne pas le montant de taxe de chaque ligne, mais son
    -- code. Quand ce code est connu des taux rapatriés, la ligne se calcule
    -- toute seule : montant × taux. C'est ce qui distingue, dans une même
    -- facture, une ligne à TPS seule d'une ligne à TPS + TVQ, ou d'une ligne
    -- exonérée (taux 0 → 0 et 0). L'entête recevra la somme à l'étape c.
    UPDATE l
       SET l.[TPS] = ROUND(ISNULL(l.[Montant], 0) * t.[TauxTPS] / 100.0, 2),
           l.[TVQ] = ROUND(ISNULL(l.[Montant], 0) * t.[TauxTVQ] / 100.0, 2)
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
      JOIN staging.TaxeImport t
        ON t.[CompanyGUID] = d.[CompanyGUID]
       AND (t.[Code] = l.[TaxeCode] OR t.[ExterneId] = l.[TaxeCode])
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND l.[TaxeMontant] IS NULL
       AND l.[TPS] IS NULL AND l.[TVQ] IS NULL
       AND NULLIF(l.[TaxeCode], '') IS NOT NULL
       AND t.[TauxTPS] IS NOT NULL AND t.[TauxTVQ] IS NOT NULL;

    DECLARE @NbLignesParCode INT = @@ROWCOUNT;

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
    -- Couper ligne par ligne laisse une poussière d'arrondi : au plus un demi-
    -- cent par ligne et par taxe. Quand la source donne le total des taxes et
    -- que l'écart tient dans cette poussière, on le pose sur la TVQ plutôt que
    -- de laisser le document refusé pour si peu.
    UPDATE d
       SET d.[TVQ] = d.[TVQ] + (d.[TotalTaxes] - (d.[TPS] + d.[TVQ]))
      FROM staging.DocumentImport d
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[TotalTaxes] IS NOT NULL
       AND d.[TPS] IS NOT NULL AND d.[TVQ] IS NOT NULL
       AND ABS(d.[TotalTaxes] - (d.[TPS] + d.[TVQ])) > 0
       AND ABS(d.[TotalTaxes] - (d.[TPS] + d.[TVQ]))
           <= 0.05 + 0.01 * (SELECT COUNT(*) FROM staging.DocumentImportLigne l WHERE l.[EnteteId] = d.[Id]);
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

    -- ── e2) Les lignes suivent l'entête coupée d'office (T289) ──────────────
    -- Quand l'entête vient d'être coupée aux taux du Québec (ou l'était déjà
    -- par le total de la source) et qu'aucune ligne ne porte encore ses taxes,
    -- chaque ligne reçoit montant × le taux que l'entête révèle : TPS si
    -- TPS / sous-total ≈ 5 %, TVQ si TVQ / sous-total ≈ 9,975 %, 0 sinon.
    -- Seulement si toutes les lignes portent le même code (ou aucun) : avec
    -- des codes différents on ne saurait pas laquelle est exonérée.
    UPDATE l
       SET l.[TPS] = CASE WHEN e.[TauxTPS] BETWEEN 0.0485 AND 0.0515 THEN ROUND(ISNULL(l.[Montant], 0) * 0.05, 2) ELSE 0 END,
           l.[TVQ] = CASE WHEN e.[TauxTVQ] BETWEEN 0.0983 AND 0.1013 THEN ROUND(ISNULL(l.[Montant], 0) * 0.09975, 2) ELSE 0 END
      FROM staging.DocumentImportLigne l
      JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
     CROSS APPLY (SELECT d.[TPS] / NULLIF(d.[SousTotal], 0) AS [TauxTPS],
                         d.[TVQ] / NULLIF(d.[SousTotal], 0) AS [TauxTVQ]) e
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[TPS] IS NOT NULL AND d.[TVQ] IS NOT NULL
       AND d.[TPS] + d.[TVQ] > 0
       AND d.[SousTotal] > 0
       AND (e.[TauxTPS] BETWEEN 0.0485 AND 0.0515 OR e.[TauxTPS] = 0)
       AND (e.[TauxTVQ] BETWEEN 0.0983 AND 0.1013 OR e.[TauxTVQ] = 0)
       AND NOT EXISTS (SELECT 1 FROM staging.DocumentImportLigne x
                        WHERE x.[EnteteId] = d.[Id] AND (x.[TPS] IS NOT NULL OR x.[TVQ] IS NOT NULL))
       AND (SELECT COUNT(DISTINCT ISNULL(x.[TaxeCode], '')) FROM staging.DocumentImportLigne x
             WHERE x.[EnteteId] = d.[Id] AND ISNULL(x.[Montant], 0) <> 0) <= 1
       AND ISNULL(l.[Montant], 0) <> 0;

    DECLARE @NbLignesParDefaut INT = @@ROWCOUNT;

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
           @NbLignesParCode AS [NbLignesParCode],
           @NbParTotal AS [NbDocumentsParTotal],
           @NbSousTotaux AS [NbSousTotaux],
           @NbParDefaut AS [NbParDefaut],
           @NbLignesParDefaut AS [NbLignesParDefaut],
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

PRINT N'T289_Taxes_lignes_apres_entete_par_defaut.sql : terminé.';
