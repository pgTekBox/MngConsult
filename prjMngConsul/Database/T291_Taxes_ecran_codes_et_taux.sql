-- =============================================================================
-- T291 — Écran « Valider les taxes » : codes et taux de la reprise
--
-- Les taux rapatriés (staging.TaxeImport, T230) n'avaient aucun écran : on ne
-- voyait ni ce qui était chargé, ni les codes que les lignes de factures
-- utilisent sans qu'aucun taux les décrive (« NON »…), et rien ne se corrigeait.
--
--   s0871GetTaxesImportEcran : compteurs, la liste des taux avec le nombre de
--                              lignes qui s'en servent, et les codes inconnus.
--   s0872SaveTaxeImport      : ajoute ou corrige un taux (code, nom, TPS %, TVQ %)
--                              à la main ou par fichier ; TypeSource = MANUEL / FICHIER.
--   s0873DeleteTaxeImport    : retire un taux.
--   s0792ChargerTaxesImport  : un nouveau rapatriement QuickBooks remplace les
--                              taux venus de QuickBooks, mais GARDE ceux saisis à
--                              la main ou par fichier, et ne recrée pas un code
--                              qu'une saisie manuelle porte déjà. Le reste est T230.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0871GetTaxesImportEcran]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Les lignes de factures encore en préparation, avec leur code.
    ;WITH Lignes AS (
        SELECT NULLIF(LTRIM(RTRIM(l.[TaxeCode])), '') AS [Code], l.[TPS], l.[TVQ]
          FROM staging.DocumentImportLigne l
          JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
         WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
    ),
    Inconnus AS (
        SELECT x.[Code], COUNT(*) AS [NbLignes],
               SUM(CASE WHEN x.[TPS] IS NULL AND x.[TVQ] IS NULL THEN 1 ELSE 0 END) AS [NbSansTaxes]
          FROM Lignes x
         WHERE x.[Code] IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM staging.TaxeImport t
                            WHERE t.[CompanyGUID] = @CompanyGUID
                              AND (t.[Code] = x.[Code] OR t.[ExterneId] = x.[Code]))
         GROUP BY x.[Code]
    )
    SELECT (SELECT COUNT(*) FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID) AS [NbTaux],
           (SELECT COUNT(*) FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID AND [Statut] = 'RECONNUE') AS [NbReconnues],
           (SELECT COUNT(*) FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID AND [Statut] = 'A_VERIFIER') AS [NbAVerifier],
           (SELECT COUNT(*) FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID AND [TypeSource] IN (N'MANUEL', N'FICHIER')) AS [NbManuels],
           (SELECT COUNT(*) FROM Inconnus) AS [NbCodesInconnus],
           (SELECT ISNULL(SUM([NbLignes]), 0) FROM Inconnus) AS [NbLignesInconnues],
           (SELECT MAX([Created]) FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID AND [RunId] IS NOT NULL) AS [DerniereExtraction];

    -- 2. Les taux, avec le nombre de lignes de factures qui s'en servent.
    SELECT t.[Id], t.[ExterneId], t.[Code], t.[Nom], t.[Description], t.[Pays],
           t.[TauxEffectif], t.[TauxTotal], t.[TauxTPS], t.[TauxTVQ], t.[TauxAutre],
           t.[NbComposantes], t.[Composantes], t.[TypeSource], t.[StatutSource],
           t.[Statut], t.[Anomalie], t.[Created],
           CASE WHEN t.[TypeSource] IN (N'MANUEL', N'FICHIER') THEN t.[TypeSource] ELSE N'SOURCE' END AS [Origine],
           (SELECT COUNT(*)
              FROM staging.DocumentImportLigne l
              JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
             WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
               AND (l.[TaxeCode] = t.[Code] OR l.[TaxeCode] = t.[ExterneId])) AS [NbLignes]
      FROM staging.TaxeImport t
     WHERE t.[CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN t.[Statut] = 'A_VERIFIER' THEN 0 ELSE 1 END,
              CASE WHEN t.[TauxTPS] + t.[TauxTVQ] > 0 THEN 0 ELSE 1 END,
              t.[Nom], t.[Code];

    -- 3. Les codes que les lignes portent sans qu'aucun taux ne les décrive.
    ;WITH Lignes AS (
        SELECT NULLIF(LTRIM(RTRIM(l.[TaxeCode])), '') AS [Code], l.[TPS], l.[TVQ]
          FROM staging.DocumentImportLigne l
          JOIN staging.DocumentImport d ON d.[Id] = l.[EnteteId]
         WHERE d.[CompanyGUID] = @CompanyGUID AND d.[DocumentId] IS NULL
    )
    SELECT x.[Code], COUNT(*) AS [NbLignes],
           SUM(CASE WHEN x.[TPS] IS NULL AND x.[TVQ] IS NULL THEN 1 ELSE 0 END) AS [NbSansTaxes]
      FROM Lignes x
     WHERE x.[Code] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM staging.TaxeImport t
                        WHERE t.[CompanyGUID] = @CompanyGUID
                          AND (t.[Code] = x.[Code] OR t.[ExterneId] = x.[Code]))
     GROUP BY x.[Code]
     ORDER BY COUNT(*) DESC, x.[Code];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0872SaveTaxeImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT = NULL,
    @Code        NVARCHAR(100),
    @Nom         NVARCHAR(200) = NULL,
    @TauxTPS     DECIMAL(9,4) = 0,
    @TauxTVQ     DECIMAL(9,4) = 0,
    @Origine     NVARCHAR(50) = N'MANUEL'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Code = NULLIF(LTRIM(RTRIM(ISNULL(@Code, ''))), '');
    SET @Nom  = NULLIF(LTRIM(RTRIM(ISNULL(@Nom, ''))), '');
    IF @CompanyGUID IS NULL THROW 50374, 'Aucune compagnie : impossible d''enregistrer le taux.', 1;
    IF @Code IS NULL THROW 50375, 'Le code de taxe est obligatoire : c''est lui que les lignes de factures portent.', 1;
    IF @TauxTPS IS NULL OR @TauxTVQ IS NULL OR @TauxTPS < 0 OR @TauxTVQ < 0 OR @TauxTPS > 100 OR @TauxTVQ > 100
        THROW 50376, 'Les taux doivent être des pourcentages entre 0 et 100.', 1;
    IF @Origine NOT IN (N'MANUEL', N'FICHIER') SET @Origine = N'MANUEL';
    IF @Nom IS NULL SET @Nom = @Code;

    -- Sans Id, on retrouve le taux par son code (ou son identifiant chez la source).
    IF @Id IS NULL
        SELECT TOP 1 @Id = [Id]
          FROM staging.TaxeImport
         WHERE [CompanyGUID] = @CompanyGUID AND ([Code] = @Code OR [ExterneId] = @Code)
         ORDER BY CASE WHEN [Code] = @Code THEN 0 ELSE 1 END, [Id];

    DECLARE @Composantes NVARCHAR(MAX) =
        N'[' + STUFF(
            CASE WHEN @TauxTPS > 0 THEN N',{"nom":"TPS","taux":' + CONVERT(NVARCHAR(20), @TauxTPS) + N'}' ELSE N'' END
          + CASE WHEN @TauxTVQ > 0 THEN N',{"nom":"TVQ","taux":' + CONVERT(NVARCHAR(20), @TauxTVQ) + N'}' ELSE N'' END,
          1, 1, N'') + N']';
    IF @Composantes = N'[]' OR @Composantes IS NULL SET @Composantes = N'[]';

    DECLARE @Action NVARCHAR(20);

    IF @Id IS NOT NULL AND EXISTS (SELECT 1 FROM staging.TaxeImport WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        UPDATE staging.TaxeImport
           SET [Code]          = @Code,
               [Nom]           = @Nom,
               [TauxTPS]       = @TauxTPS,
               [TauxTVQ]       = @TauxTVQ,
               [TauxTotal]     = @TauxTPS + @TauxTVQ + [TauxAutre],
               [TauxEffectif]  = @TauxTPS + @TauxTVQ + [TauxAutre],
               [NbComposantes] = CASE WHEN @TauxTPS > 0 THEN 1 ELSE 0 END + CASE WHEN @TauxTVQ > 0 THEN 1 ELSE 0 END
                               + CASE WHEN [TauxAutre] > 0 THEN 1 ELSE 0 END,
               [Composantes]   = @Composantes,
               [TypeSource]    = @Origine,
               [Statut]        = 'RECONNUE',
               [Anomalie]      = NULL
         WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID;
        SET @Action = N'MODIFIE';
    END
    ELSE
    BEGIN
        INSERT INTO staging.TaxeImport
            ([CompanyGUID], [ExterneId], [Code], [Nom], [Pays], [TauxEffectif], [TauxTotal],
             [TauxTPS], [TauxTVQ], [TauxAutre], [NbComposantes], [Composantes],
             [TypeSource], [StatutSource], [Statut], [Anomalie])
        VALUES (@CompanyGUID, NULL, @Code, @Nom, 'CA', @TauxTPS + @TauxTVQ, @TauxTPS + @TauxTVQ,
                @TauxTPS, @TauxTVQ, 0,
                CASE WHEN @TauxTPS > 0 THEN 1 ELSE 0 END + CASE WHEN @TauxTVQ > 0 THEN 1 ELSE 0 END,
                @Composantes, @Origine, N'active', 'RECONNUE', NULL);
        SET @Id = SCOPE_IDENTITY();
        SET @Action = N'CREE';
    END

    SELECT @Id AS [Id], @Action AS [Action];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0873DeleteTaxeImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM staging.TaxeImport WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID;
    SELECT @@ROWCOUNT AS [NbSupprimes];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0792ChargerTaxesImport]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Taxes        NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50372, 'Aucune compagnie : impossible de déposer les taxes.', 1;

    BEGIN TRANSACTION;

    -- Un nouveau rapatriement remplace ce qui venait de la source, et garde ce
    -- que l'utilisateur a saisi lui-même (T291).
    DELETE FROM staging.TaxeImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND ISNULL([TypeSource], N'') NOT IN (N'MANUEL', N'FICHIER');

    -- Les taux, un par ligne.
    DECLARE @Lu TABLE
    (
        [Rang]         INT,
        [ExterneId]    NVARCHAR(100),
        [Code]         NVARCHAR(100),
        [Nom]          NVARCHAR(200),
        [Description]  NVARCHAR(500),
        [Pays]         VARCHAR(10),
        [TauxEffectif] DECIMAL(9,4),
        [TauxTotal]    DECIMAL(9,4),
        [TypeSource]   NVARCHAR(50),
        [StatutSource] NVARCHAR(50),
        [Composantes]  NVARCHAR(MAX)
    );

    INSERT INTO @Lu
    SELECT j.[rang], j.[externe_id], j.[code], j.[nom], j.[description], j.[pays],
           TRY_CONVERT(DECIMAL(9,4), j.[taux_effectif]),
           TRY_CONVERT(DECIMAL(9,4), j.[taux_total]),
           j.[type], j.[statut], j.[composantes]
      FROM OPENJSON(@Taxes)
           WITH ([rang]          INT            '$.rang',
                 [externe_id]    NVARCHAR(100)  '$.externe_id',
                 [code]          NVARCHAR(100)  '$.code',
                 [nom]           NVARCHAR(200)  '$.nom',
                 [description]   NVARCHAR(500)  '$.description',
                 [pays]          VARCHAR(10)    '$.pays',
                 [taux_effectif] NVARCHAR(40)   '$.taux_effectif',
                 [taux_total]    NVARCHAR(40)   '$.taux_total',
                 [type]          NVARCHAR(50)   '$.type',
                 [statut]        NVARCHAR(50)   '$.statut',
                 [composantes]   NVARCHAR(MAX)  '$.composantes' AS JSON) AS j;

    -- Les composantes, éclatées et rangées.
    DECLARE @Comp TABLE
    (
        [Rang]  INT,
        [Nom]   NVARCHAR(200),
        [Taux]  DECIMAL(9,4),
        [Genre] VARCHAR(10)
    );

    INSERT INTO @Comp
    SELECT l.[Rang],
           c.[nom],
           ISNULL(TRY_CONVERT(DECIMAL(9,4), c.[taux]), 0),
           CASE
               WHEN UPPER(ISNULL(c.[nom], '')) LIKE '%GST%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%TPS%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%HST%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%TVH%' THEN 'TPS'
               WHEN UPPER(ISNULL(c.[nom], '')) LIKE '%QST%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%TVQ%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%PST%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%RST%'
                 OR UPPER(ISNULL(c.[nom], '')) LIKE '%TVP%' THEN 'TVQ'
               ELSE 'AUTRE'
           END
      FROM @Lu l
     CROSS APPLY OPENJSON(ISNULL(l.[Composantes], N'[]'))
           WITH ([nom]  NVARCHAR(200) '$.nom',
                 [taux] NVARCHAR(40)  '$.taux') AS c;

    INSERT INTO staging.TaxeImport
        ([ImportFileId], [RunId], [CompanyGUID], [ExterneId], [Code], [Nom],
         [Description], [Pays], [TauxEffectif], [TauxTotal],
         [TauxTPS], [TauxTVQ], [TauxAutre], [NbComposantes], [Composantes],
         [TypeSource], [StatutSource], [Statut], [Anomalie])
    SELECT @ImportFileId, @RunId, @CompanyGUID,
           l.[ExterneId],
           -- Sans code, le nom sert de clé : c'est lui que porteront les lignes.
           ISNULL(NULLIF(l.[Code], ''), l.[Nom]),
           l.[Nom], l.[Description], l.[Pays],
           l.[TauxEffectif], l.[TauxTotal],
           x.[TPS], x.[TVQ], x.[Autre], x.[Nb], l.[Composantes],
           l.[TypeSource], l.[StatutSource],
           CASE WHEN x.[TPS] + x.[TVQ] > 0 THEN 'RECONNUE' ELSE 'A_VERIFIER' END,
           CASE
               WHEN x.[Nb] = 0
                   THEN N'La source ne détaille pas les composantes : la répartition TPS/TVQ est impossible.'
               WHEN x.[TPS] + x.[TVQ] = 0
                   THEN N'Aucune composante reconnue comme TPS ou TVQ.'
               ELSE NULL
           END
      FROM @Lu l
     CROSS APPLY (
        SELECT ISNULL(SUM(CASE WHEN c.[Genre] = 'TPS' THEN c.[Taux] END), 0)   AS [TPS],
               ISNULL(SUM(CASE WHEN c.[Genre] = 'TVQ' THEN c.[Taux] END), 0)   AS [TVQ],
               ISNULL(SUM(CASE WHEN c.[Genre] = 'AUTRE' THEN c.[Taux] END), 0) AS [Autre],
               COUNT(*)                                                        AS [Nb]
          FROM @Comp c WHERE c.[Rang] = l.[Rang]
     ) AS x
     -- Un code que l'utilisateur a saisi lui-même garde sa saisie.
     WHERE NOT EXISTS (SELECT 1 FROM staging.TaxeImport m
                        WHERE m.[CompanyGUID] = @CompanyGUID
                          AND m.[TypeSource] IN (N'MANUEL', N'FICHIER')
                          AND (m.[Code] = ISNULL(NULLIF(l.[Code], ''), l.[Nom])
                               OR (l.[ExterneId] IS NOT NULL AND m.[Code] = l.[ExterneId])));

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbTaux],
           SUM(CASE WHEN [Statut] = 'RECONNUE' THEN 1 ELSE 0 END)   AS [NbReconnues],
           SUM(CASE WHEN [Statut] = 'A_VERIFIER' THEN 1 ELSE 0 END) AS [NbAVerifier]
      FROM staging.TaxeImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

PRINT N'T291_Taxes_ecran_codes_et_taux.sql : terminé.';
