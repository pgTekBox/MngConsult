-- =============================================================================
-- T224 — Validation des documents importés : de la préparation à la comptabilité
--
-- Les documents déposés par T223 attendaient quelqu'un pour les approuver. Ces
-- procédures font ce pas — et un seul pas :
--
--   staging.DocumentImport  ──►  dbo.T060Document  (StatusId = 1, Draft)
--                                dbo.T061DocumentLine
--
-- Ils sont créés EN BROUILLON, et c'est délibéré. Le déclencheur
-- trg_T060_Comptabiliser ne se réveille que lorsque [StatusId] change : insérer
-- en Draft n'écrit donc aucune écriture au grand livre. Rien n'est comptabilisé
-- sans qu'un humain le décide ensuite, depuis les écrans habituels.
--
-- Ce qui refuse de passer :
--   · un document sans tiers reconnu — on ne devine pas à qui appartient une
--     facture ;
--   · un document déjà migré, déjà en comptabilité, ou en anomalie.
--
-- La procédure ne s'arrête pas au premier refus : elle traite ce qu'elle peut
-- et rend le compte de ce qui est passé, de ce qui ne l'est pas et pourquoi.
--
-- Procédures : s0784 à s0786.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) s0784MajDocumentImport
--    Ce que l'écran corrige avant de valider : le tiers, et la répartition des
--    taxes. Le reste vient de la source et ne se retouche pas ici — si le
--    montant est faux, c'est la source qu'il faut corriger, pas la copie.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0784MajDocumentImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @EnteteId    INT,
    @PartyGUID   UNIQUEIDENTIFIER = NULL,
    @TPS         DECIMAL(18,2) = NULL,
    @TVQ         DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.DocumentImport
                    WHERE [Id] = @EnteteId AND [CompanyGUID] = @CompanyGUID)
        THROW 50366, 'Document introuvable pour cette compagnie.', 1;

    UPDATE staging.DocumentImport
       SET [PartyGUID] = ISNULL(@PartyGUID, [PartyGUID]),
           [TPS]       = @TPS,
           [TVQ]       = @TVQ
     WHERE [Id] = @EnteteId
       AND [CompanyGUID] = @CompanyGUID
       AND [DocumentId] IS NULL;   -- déjà migré : on n'y touche plus
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0785CreerDocumentsDepuisImport
--    Crée en comptabilité les documents choisis. @Ids est une liste séparée par
--    des virgules : l'écran coche, la procédure exécute.
--
--    Chaque document est créé dans sa propre transaction implicite du lot : un
--    refus n'annule pas ceux qui ont réussi. Sur une reprise de deux cents
--    factures, tout perdre pour une seule serait intenable.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0785CreerDocumentsDepuisImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ids         NVARCHAR(MAX),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Ce qu'on a le droit de créer, et rien d'autre.
    DECLARE @Aptes TABLE ([Id] INT PRIMARY KEY);

    INSERT INTO @Aptes ([Id])
    SELECT d.[Id]
      FROM staging.DocumentImport d
     INNER JOIN (SELECT TRY_CONVERT(INT, LTRIM(RTRIM([value]))) AS [Id]
                   FROM STRING_SPLIT(@Ids, ',')) x ON x.[Id] = d.[Id]
     WHERE d.[CompanyGUID] = @CompanyGUID
       AND d.[DocumentId] IS NULL
       AND d.[Statut] = 'OK'
       AND d.[PartyGUID] IS NOT NULL;

    -- Le statut de taxe de la compagnie : chaque compagnie a les siens.
    DECLARE @TaxableId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'TAXABLE' ORDER BY [Id]);
    DECLARE @ExemptId INT =
        (SELECT TOP 1 [Id] FROM dbo.T068TaxeStatus
          WHERE [CompanyGUID] = @CompanyGUID AND [TaxStatus] = 'EXEMPT' ORDER BY [Id]);

    BEGIN TRANSACTION;

    DECLARE @Crees TABLE ([EnteteId] INT, [DocumentId] INT);

    -- ── Les entêtes ──────────────────────────────────────────────────────
    -- Draft (StatusId = 1) et NON_COMPTABILISE : le déclencheur de
    -- comptabilisation ne réagit qu'au changement de statut, donc rien ne part
    -- au grand livre tant qu'un humain ne l'a pas décidé.
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

    -- ── Les lignes ───────────────────────────────────────────────────────
    -- Le compte n'est repris que s'il existe au plan de la compagnie : un
    -- compte inventé ferait échouer la comptabilisation plus tard, loin d'ici.
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

    -- ── La préparation garde la trace ────────────────────────────────────
    UPDATE d
       SET d.[DocumentId]   = c.[DocumentId],
           d.[MigratedDate] = GETDATE(),
           d.[Statut]       = 'MIGRE',
           d.[Anomalie]     = NULL
      FROM staging.DocumentImport d
     INNER JOIN @Crees c ON c.[EnteteId] = d.[Id];

    COMMIT TRANSACTION;

    -- ── Le compte rendu ──────────────────────────────────────────────────
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
               AND d.[Statut] <> 'OK') AS [NbEcartes];
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0786GetTiersPourImport
--    Les tiers de la compagnie, pour que l'écran propose un rapprochement quand
--    le nom de la source n'a rien retrouvé. Filtré par type : un fournisseur ne
--    se propose pas sur une facture client.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0786GetTiersPourImport]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [PartyGUID], [Name], [DisplayName], [Type]
      FROM dbo.T050Party
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [Name];
END
GO
