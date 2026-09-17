-- =============================================================================
-- T230 — Les taxes de l'import
--
-- Jusqu'ici l'import des factures laissait les taxes en tas. La source donne un
-- total de taxes et, sur chaque ligne, un code — « TPS/TVQ QC », « HST ON » —
-- mais ce code ne voulait rien dire chez nous : la ressource `tax-rates`
-- n'était jamais interprétée. Résultat, TPS et TVQ restaient vides et le
-- document créé ne bouclait pas : SousTotal + 0 + 0 ≠ Total.
--
-- Trois pièces, dans cet ordre.
--
--  1. `staging.TaxeImport` — les taux de la source, avec leurs composantes.
--     C'est là que se joue tout le problème canadien : une taxe québécoise
--     arrive comme UN taux composé de DEUX composantes (« GST » 5 %, « QST »
--     9,975 %). Le chargement les range dans deux colonnes, TauxTPS et TauxTVQ.
--
--  2. `s0794RepartirTaxesImport` — applique ces taux aux documents déjà en
--     préparation : chaque ligne porte son montant de taxe, on le coupe selon
--     le ratio du code, et l'entête reçoit la somme.
--
--  3. Le garde-fou qui manquait dans `s0785` : un document dont
--     SousTotal + TPS + TVQ s'écarte du Total de plus d'un cent n'est plus créé.
--     Mieux vaut un refus visible qu'une facture fausse en comptabilité.
--
-- L'ordre du catalogue compte : `tax-rates` est dans « Structure », donc extrait
-- avant les factures. Dans une même extraction, les taux sont là quand les
-- documents arrivent.
--
-- Procédures : s0792, s0793, s0794 — et s0785 modifiée.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Le registre accepte les taxes
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK
    ([TypeImport] IN ('Client', 'Fournisseur', 'Produit',
                      'PlanComptable', 'FactureClient', 'FactureFournisseur',
                      'Societe', 'Taxe'));
GO

-- -----------------------------------------------------------------------------
-- 2) staging.TaxeImport
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.TaxeImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.TaxeImport
    (
        [Id]            INT IDENTITY(1,1) NOT NULL,
        [ImportFileId]  INT               NULL,
        [RunId]         INT               NULL,
        [CompanyGUID]   UNIQUEIDENTIFIER  NOT NULL,

        [ExterneId]     NVARCHAR(100)     NULL,
        [Code]          NVARCHAR(100)     NULL,
        [Nom]           NVARCHAR(200)     NULL,
        [Description]   NVARCHAR(500)     NULL,
        [Pays]          VARCHAR(10)       NULL,

        -- Le taux global tel que la source le donne.
        [TauxEffectif]  DECIMAL(9,4)      NULL,
        [TauxTotal]     DECIMAL(9,4)      NULL,

        -- La répartition, déduite des composantes. C'est ce que le reste lit.
        [TauxTPS]       DECIMAL(9,4)      NOT NULL CONSTRAINT DF_TaxeImport_TPS DEFAULT (0),
        [TauxTVQ]       DECIMAL(9,4)      NOT NULL CONSTRAINT DF_TaxeImport_TVQ DEFAULT (0),
        [TauxAutre]     DECIMAL(9,4)      NOT NULL CONSTRAINT DF_TaxeImport_Autre DEFAULT (0),
        [NbComposantes] INT               NOT NULL CONSTRAINT DF_TaxeImport_NbComp DEFAULT (0),

        -- Les composantes brutes : quand une taxe ne se laisse pas ranger, on
        -- veut pouvoir regarder ce que la source disait vraiment.
        [Composantes]   NVARCHAR(MAX)     NULL,

        [TypeSource]    NVARCHAR(50)      NULL,
        [StatutSource]  NVARCHAR(50)      NULL,

        -- RECONNUE quand la répartition tient, A_VERIFIER sinon.
        [Statut]        VARCHAR(20)       NOT NULL CONSTRAINT DF_TaxeImport_Statut DEFAULT ('RECONNUE'),
        [Anomalie]      NVARCHAR(400)     NULL,

        [Created]       DATETIME          NOT NULL CONSTRAINT DF_TaxeImport_Created DEFAULT (GETDATE()),

        CONSTRAINT PK_TaxeImport PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_TaxeImport_ImportFile FOREIGN KEY ([ImportFileId])
            REFERENCES staging.ImportFiles ([Id]),
        CONSTRAINT FK_TaxeImport_Run FOREIGN KEY ([RunId])
            REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_TaxeImport_Company ON staging.TaxeImport ([CompanyGUID]);
    CREATE INDEX IX_TaxeImport_Code ON staging.TaxeImport ([CompanyGUID], [Code]);
    CREATE INDEX IX_TaxeImport_File ON staging.TaxeImport ([ImportFileId]);
END
GO

-- -----------------------------------------------------------------------------
-- 3) La ligne de document retient le montant de taxe de la source
--    Sans lui, on ne peut répartir qu'au prorata du total — moins fidèle quand
--    une facture mélange des lignes taxables et exonérées.
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.DocumentImportLigne', 'TaxeMontant') IS NULL
    ALTER TABLE staging.DocumentImportLigne ADD [TaxeMontant] DECIMAL(18,2) NULL;
GO

-- -----------------------------------------------------------------------------
-- 4) s0792ChargerTaxesImport
--
--    Le classement des composantes se fait ici, en SQL, pour qu'il soit
--    inspectable : on doit pouvoir demander « pourquoi ce taux a-t-il été rangé
--    en TVQ ? » et lire la réponse.
--
--    Les noms reconnus sont ceux des taxes canadiennes, dans les deux langues :
--      TPS  ← GST, TPS, HST, TVH   (la TVH est une taxe unique : elle va du côté
--                                   fédéral, faute de meilleur endroit)
--      TVQ  ← QST, TVQ, PST, RST, TVP
-- -----------------------------------------------------------------------------
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

    DELETE FROM staging.TaxeImport WHERE [CompanyGUID] = @CompanyGUID;

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
     ) AS x;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbTaux],
           SUM(CASE WHEN [Statut] = 'RECONNUE' THEN 1 ELSE 0 END)   AS [NbReconnues],
           SUM(CASE WHEN [Statut] = 'A_VERIFIER' THEN 1 ELSE 0 END) AS [NbAVerifier]
      FROM staging.TaxeImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0793GetTaxesImport — pour l'affichage
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0793GetTaxesImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [ImportFileId], [RunId], [ExterneId], [Code], [Nom], [Description],
           [Pays], [TauxEffectif], [TauxTotal], [TauxTPS], [TauxTVQ], [TauxAutre],
           [NbComposantes], [TypeSource], [StatutSource], [Statut], [Anomalie], [Created]
      FROM staging.TaxeImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY CASE WHEN [Statut] = 'A_VERIFIER' THEN 0 ELSE 1 END, [Code], [Nom];
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0794RepartirTaxesImport
--
--    Coupe les taxes des documents en préparation selon les taux importés.
--    Se relance sans dommage : elle ne touche que ce qui n'est pas encore
--    migré, et recalcule à partir des montants de la source.
--
--    Deux chemins, du plus fidèle au plus grossier :
--      · la ligne porte son propre montant de taxe → on coupe ligne par ligne ;
--      · sinon, si tout le document partage un seul code → on coupe le total.
--    Ce qui ne rentre dans aucun des deux reste vide, et le garde-fou de s0785
--    empêchera la création.
-- -----------------------------------------------------------------------------
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

    COMMIT TRANSACTION;

    SELECT @NbLignes AS [NbLignesCoupees],
           @NbParTotal AS [NbDocumentsParTotal],
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

-- -----------------------------------------------------------------------------
-- 7) s0785CreerDocumentsDepuisImport — le garde-fou de l'equilibre
--
--    Identique a la version precedente, a une condition pres : un document dont
--    SousTotal + TPS + TVQ s'ecarte du Total de plus d'un cent n'est plus cree.
--
--    C'etait le defaut connu depuis l'essai de bout en bout : faute de
--    repartition des taxes, on ecrivait en comptabilite des factures dont les
--    montants ne s'additionnaient pas. Un refus se voit et se corrige ; une
--    facture fausse se decouvre au rapprochement, des mois plus tard.
--
--    Le cent de tolerance n'est pas de la complaisance : c'est la poussiere
--    d'arrondi d'une repartition ligne par ligne.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0785CreerDocumentsDepuisImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ids         NVARCHAR(MAX),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Ce qu'on a le droit de creer, et rien d'autre.
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

    -- Le statut de taxe de la compagnie : chaque compagnie a les siens.
    DECLARE @TaxableId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'TAXABLE' ORDER BY [Id]);
    DECLARE @ExemptId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'EXEMPT' ORDER BY [Id]);

    BEGIN TRANSACTION;

    DECLARE @Crees TABLE ([EnteteId] INT, [DocumentId] INT);

    -- Les entetes. Draft (StatusId = 1) et NON_COMPTABILISE : le declencheur de
    -- comptabilisation ne reagit qu'au changement de statut, donc rien ne part
    -- au grand livre tant qu'un humain ne l'a pas decide.
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

    -- Les lignes. Le compte n'est repris que s'il existe au plan de la
    -- compagnie : un compte invente ferait echouer la comptabilisation plus
    -- tard, loin d'ici.
    INSERT INTO dbo.T061DocumentLine
        ([Created], [DocumentId], [ProductId], [Description], [Qty], [UnitPrice],
         [Amount], [TaxeStatus], [TPS], [TVQ], [CompteComptable], [Ordre], [Total])
    SELECT GETDATE(), c.[DocumentId], l.[ProductId], l.[Description],
           ISNULL(l.[Quantite], 1), ISNULL(l.[PrixUnitaire], 0),
           ISNULL(l.[Montant], 0),
           CASE WHEN ISNULL(l.[TaxeCode], '') <> '' THEN @TaxableId ELSE @ExemptId END,
           ISNULL(l.[TPS], 0), ISNULL(l.[TVQ], 0),
           pc.[Compte],
           l.[LigneNo],
           ISNULL(l.[Montant], 0)
      FROM staging.DocumentImportLigne l
     INNER JOIN @Crees c ON c.[EnteteId] = l.[EnteteId]
      LEFT JOIN dbo.T121PlanComptable pc
             ON pc.[CompanyGUID] = @CompanyGUID
            AND pc.[Compte] = l.[CompteSource]
     ORDER BY l.[EnteteId], l.[LigneNo];

    -- La preparation garde la trace.
    UPDATE d
       SET d.[DocumentId]   = c.[DocumentId],
           d.[MigratedDate] = GETDATE(),
           d.[Statut]       = 'MIGRE',
           d.[Anomalie]     = NULL
      FROM staging.DocumentImport d
     INNER JOIN @Crees c ON c.[EnteteId] = d.[Id];

    COMMIT TRANSACTION;

    -- Le compte rendu. NbDesequilibres est nouveau : sans lui, un document
    -- refuse pour cause de totaux incoherents disparaitrait sans explication.
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
