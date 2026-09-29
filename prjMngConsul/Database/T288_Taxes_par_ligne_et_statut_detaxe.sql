-- =============================================================================
-- T288 — Taxes ligne par ligne d'après le code, et statut « Détaxé » à la création
--
-- QuickBooks ne donne pas le montant de taxe de chaque ligne, seulement son
-- code (« TPS/TVQ QC », « TPS », « TVQ », « Exonéré », « Détaxé »…). Jusqu'ici
-- s0794 ne coupait ligne par ligne que si la source donnait le montant, et
-- sinon coupait le total du document quand UN SEUL code le couvrait : une
-- facture qui mêle une ligne à TPS seule et une ligne à TPS + TVQ restait
-- sans répartition.
--
-- 1. s0794 — nouvelle étape (a2) : chaque ligne dont le code est connu des
--    taux rapatriés (staging.TaxeImport) reçoit montant × taux, TPS et TVQ
--    séparément (0 et 0 pour un code à taux nul). L'entête reçoit la somme
--    (étape c), et la poussière d'arrondi (au plus un demi-cent par ligne et
--    par taxe) va sur la TVQ (étape d, tolérance élargie en conséquence).
--    Compteur NbLignesParCode ajouté au résultat. Le reste est celui de T287.
-- 2. s0785 — le statut de taxe de la ligne créée (T061DocumentLine.TaxeStatus)
--    suit le code de la source : taux > 0 → Taxable ; taux 0 nommé Détaxé /
--    Zero-rated → Détaxé (ZERO_RATED) ; taux 0 autrement → Exempt ; sans
--    code → Exempt. Le reste est celui de T265.
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

CREATE OR ALTER PROCEDURE [dbo].[s0785CreerDocumentsDepuisImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ids         NVARCHAR(MAX),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.s0855ResoudreDocumentsImport @CompanyGUID = @CompanyGUID;

    DECLARE @Aptes TABLE ([Id] INT PRIMARY KEY);
    INSERT INTO @Aptes ([Id])
    SELECT d.[Id]
      FROM staging.DocumentImport d
     INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                   FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[Statut] = 'OK'
       AND d.[PartyGUID] IS NOT NULL
       AND (d.[Total] IS NULL
            OR ABS(ISNULL(d.[SousTotal], ISNULL(d.[Total], 0))
                   + ISNULL(d.[TPS], 0) + ISNULL(d.[TVQ], 0)
                   - d.[Total]) <= 0.01);

    DECLARE @TaxableId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'TAXABLE' ORDER BY [Id]);
    DECLARE @ExemptId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'EXEMPT' ORDER BY [Id]);
    -- Détaxé (taux 0 %, mais dans le champ de la taxe) : le code de la source
    -- le dit par son nom — « Détaxé », « Zero-rated » (T288). À défaut, Exempt.
    DECLARE @ZeroId INT = ISNULL(
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'ZERO_RATED' ORDER BY [Id]), @ExemptId);

    BEGIN TRANSACTION;

    DECLARE @Crees TABLE ([EnteteId] INT, [DocumentId] INT);

    MERGE dbo.T060Document AS cible
    USING (
        SELECT d.[Id] AS [EnteteId], d.[CompanyGUID], d.[PartyGUID], d.[DocumentTypeId],
               d.[DateDocument], d.[DateEcheance], d.[Numero],
               ISNULL(d.[SousTotal], ISNULL(d.[Total], 0)) AS [SousTotal],
               ISNULL(d.[TPS], 0) AS [TPS],
               ISNULL(d.[TVQ], 0) AS [TVQ],
               ISNULL(d.[Total], 0) AS [Total],
               p.[Name], p.[DisplayName]
          FROM staging.DocumentImport d
         INNER JOIN @Aptes a ON a.[Id] = d.[Id]
          LEFT JOIN dbo.T050Party p ON p.[PartyGUID] = d.[PartyGUID]
    ) AS src ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT ([DocumentGUID], [CompanyGUID], [PartyGUID], [DocumentTypeId], [StatusId],
                [DocumentDate], [DueDate], [DocumentNumber],
                [SubTotal], [TPS], [TVQ], [Total],
                [Name], [DisplayName], [ComptabilisationStatus], [Created])
        VALUES (NEWID(), src.[CompanyGUID], src.[PartyGUID], src.[DocumentTypeId], 1,
                ISNULL(src.[DateDocument], GETDATE()), src.[DateEcheance], src.[Numero],
                src.[SousTotal], src.[TPS], src.[TVQ], src.[Total],
                src.[Name], src.[DisplayName], 'NON_COMPTABILISE', GETDATE())
    OUTPUT src.[EnteteId], INSERTED.[Id] INTO @Crees;

    INSERT INTO dbo.T061DocumentLine
        ([Created], [DocumentId], [ProductId], [Description], [Qty], [UnitPrice],
         [Amount], [TaxeStatus], [TPS], [TVQ], [CompteComptable], [Ordre], [Total])
    SELECT GETDATE(), c.[DocumentId], l.[ProductId], l.[Description],
           ISNULL(l.[Quantite], 1), ISNULL(l.[PrixUnitaire], 0),
           ISNULL(l.[Montant], 0),
           -- Le statut de taxe de la ligne, d'après son code chez la source :
           -- taux > 0 → Taxable ; taux 0 nommé Détaxé / Zero-rated → Détaxé ;
           -- taux 0 autrement → Exempt ; sans code → Exempt (T288).
           CASE WHEN ISNULL(l.[TaxeCode], '') = '' THEN @ExemptId
                WHEN tx.[Id] IS NULL THEN @TaxableId
                WHEN ISNULL(tx.[TauxTPS], 0) + ISNULL(tx.[TauxTVQ], 0) + ISNULL(tx.[TauxAutre], 0) > 0 THEN @TaxableId
                WHEN tx.[Nom] LIKE N'%détax%' OR tx.[Nom] LIKE N'%detax%' OR tx.[Nom] LIKE N'%zero%' OR tx.[Code] LIKE N'%zero%' THEN @ZeroId
                ELSE @ExemptId END,
           ISNULL(l.[TPS], 0), ISNULL(l.[TVQ], 0),
           l.[CompteCible],
           l.[LigneNo],
           ISNULL(l.[Montant], 0)
      FROM staging.DocumentImportLigne l
     INNER JOIN @Crees c ON c.[EnteteId] = l.[EnteteId]
     OUTER APPLY (SELECT TOP 1 t.[Id], t.[Code], t.[Nom], t.[TauxTPS], t.[TauxTVQ], t.[TauxAutre]
                    FROM staging.TaxeImport t
                   WHERE t.[CompanyGUID] = @CompanyGUID
                     AND (t.[Code] = l.[TaxeCode] OR t.[ExterneId] = l.[TaxeCode])
                   ORDER BY t.[Id] DESC) tx
     ORDER BY l.[EnteteId], l.[LigneNo];

    UPDATE d
       SET d.[DocumentId]   = c.[DocumentId],
           d.[MigratedDate] = GETDATE(),
           d.[Statut]       = 'MIGRE',
           d.[Anomalie]     = NULL
      FROM staging.DocumentImport d
     INNER JOIN @Crees c ON c.[EnteteId] = d.[Id];

    COMMIT TRANSACTION;

    SELECT (SELECT COUNT(*) FROM @Crees) AS [NbCrees],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                           FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND d.[PartyGUID] IS NULL) AS [NbSansTiers],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                           FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND d.[PartyGUID] IS NOT NULL
               AND d.[Statut] <> 'OK') AS [NbEcartes],
           (SELECT COUNT(*) FROM staging.DocumentImport d
             INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                           FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
             WHERE d.[CompanyGUID] = @CompanyGUID
               AND d.[DocumentId] IS NULL
               AND d.[Statut] = 'OK'
               AND d.[PartyGUID] IS NOT NULL
               AND d.[Total] IS NOT NULL
               AND ABS(ISNULL(d.[SousTotal], ISNULL(d.[Total], 0))
                       + ISNULL(d.[TPS], 0) + ISNULL(d.[TVQ], 0)
                       - d.[Total]) > 0.01) AS [NbDesequilibres];
END
GO

PRINT N'T288_Taxes_par_ligne_et_statut_detaxe.sql : terminé.';
