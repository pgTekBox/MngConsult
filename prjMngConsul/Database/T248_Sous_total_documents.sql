-- =============================================================================
-- T248 — Le sous-total des pièces reprises
--
-- s0794RepartirTaxesImport finit par compter les pièces qui ne bouclent pas :
--
--     ABS(ISNULL(SousTotal,0) + ISNULL(TPS,0) + ISNULL(TVQ,0) - Total) > 0.01
--
-- Or PERSONNE ne remplit SousTotal. QuickBooks, à travers Apideck, ne rend pas
-- « sub_total » : ni sur les factures clients, ni sur les factures
-- fournisseurs. La colonne reste NULLE, et le contrôle déclare déséquilibrée
-- CHAQUE pièce reprise — y compris celles qui sont parfaitement justes. Le
-- message porté à l'écran, « ils ne pourront pas être créés tant que la
-- répartition n'est pas faite », accusait la répartition des taxes d'un manque
-- qui n'était pas le sien.
--
-- LE SOUS-TOTAL SE DÉDUIT, il ne se devine pas : c'est le total moins les taxes.
-- Encore faut-il être sûr de connaître les taxes. D'où deux cas, et deux seuls :
--
--   1) La pièce ne porte aucune taxe. On l'exige prouvé, pas supposé : la somme
--      des lignes doit déjà égaler le total. S'il y avait une taxe quelque part,
--      les lignes tomberaient en dessous. Alors SousTotal = Total.
--
--   2) La répartition a fait son travail — TPS et TVQ sont posées — et leur
--      somme concorde avec ce que la source annonce. Alors
--      SousTotal = Total - (TPS + TVQ).
--
-- Tout le reste est laissé NUL. Une pièce dont on ignore la part de taxe doit
-- ressortir comme douteuse : c'est le rôle du compteur, et le garde-fou de
-- s0785 empêchera sa création. Mieux vaut une pièce signalée qu'un sous-total
-- inventé.
--
-- La colonne n'est jamais écrasée quand elle est déjà remplie : une source qui
-- donne son sous-total a toujours raison contre notre arithmétique.
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

    -- ── e) Le sous-total, déduit du total et des taxes ──────────────────────
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
