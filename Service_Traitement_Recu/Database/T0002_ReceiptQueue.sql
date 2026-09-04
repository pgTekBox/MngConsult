-- =============================================================================
-- ServiceTraitementRecu — file d'attente et journal de traitement des reçus
-- -----------------------------------------------------------------------------
-- Le service Windows reprend, à intervalle régulier, le traitement qui se fait
-- à la main dans wbfReceipt.aspx :
--     1. conversion de l'image en noir et blanc (clsReceiptImageOptimizer)
--     2. lecture du reçu par ChatGPT (OpenAiReceiptReader)  -> AI_JSON
--     3. « Process JSON » : création du marchand et du document
--
-- États de T0001Receipt.ProcessingStatus (inchangés, sauf le 4 qui est ajouté) :
--     0 / 1 = reçu reçu, rien de fait
--     2     = image optimisée pour l'IA
--     3     = JSON obtenu de ChatGPT
--     4     = JSON traité : marchand et document créés   <-- NOUVEAU
--
-- Ce script est ré-exécutable : chaque objet est créé seulement s'il manque.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) Colonnes de suivi du service sur T0001Receipt
--    Elles n'existent que pour le service : l'application web les ignore.
-- -----------------------------------------------------------------------------
IF COL_LENGTH('dbo.T0001Receipt', 'SvcAttemptCount') IS NULL
    ALTER TABLE dbo.T0001Receipt ADD SvcAttemptCount INT NULL;
GO
IF COL_LENGTH('dbo.T0001Receipt', 'SvcLastAttemptUtc') IS NULL
    ALTER TABLE dbo.T0001Receipt ADD SvcLastAttemptUtc DATETIME2(0) NULL;
GO
IF COL_LENGTH('dbo.T0001Receipt', 'SvcLastError') IS NULL
    ALTER TABLE dbo.T0001Receipt ADD SvcLastError VARCHAR(MAX) NULL;
GO
-- Verrou d'exclusion : tant que SvcLockedUntilUtc est dans le futur, aucune
-- autre instance du service ne reprend le reçu (protège d'un double appel
-- payant à OpenAI si le service tourne à deux endroits).
IF COL_LENGTH('dbo.T0001Receipt', 'SvcLockedUntilUtc') IS NULL
    ALTER TABLE dbo.T0001Receipt ADD SvcLockedUntilUtc DATETIME2(0) NULL;
GO
IF COL_LENGTH('dbo.T0001Receipt', 'SvcProcessedUtc') IS NULL
    ALTER TABLE dbo.T0001Receipt ADD SvcProcessedUtc DATETIME2(0) NULL;
GO

-- -----------------------------------------------------------------------------
-- 2) Journal de traitement : une ligne par étape et par reçu.
--    C'est la source de la grille « Résultat » de l'application du service.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.T0002ReceiptProcessLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T0002ReceiptProcessLog
    (
        [Id]               INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_T0002ReceiptProcessLog PRIMARY KEY CLUSTERED,
        [imageGUID]        UNIQUEIDENTIFIER NOT NULL,
        [ReceiptId]        INT              NULL,
        [Step]             VARCHAR(40)      NOT NULL,   -- OPTIMISATION | IA | JSON | COMPLET
        [Success]          BIT              NOT NULL,
        [Message]          VARCHAR(MAX)     NULL,
        [AI_JSON]          VARCHAR(MAX)     NULL,
        [InputToken]       INT              NULL,
        [OutputToken]      INT              NULL,
        [EstimatedCostUsd] NUMERIC(18,8)    NULL,
        [DurationMs]       INT              NULL,
        [MachineName]      VARCHAR(100)     NULL,
        [Created]          DATETIME2(0)     NOT NULL
            CONSTRAINT DF_T0002ReceiptProcessLog_Created DEFAULT (SYSUTCDATETIME())
    );

    CREATE INDEX IX_T0002ReceiptProcessLog_Image
        ON dbo.T0002ReceiptProcessLog ([imageGUID], [Id] DESC);

    CREATE INDEX IX_T0002ReceiptProcessLog_Created
        ON dbo.T0002ReceiptProcessLog ([Created] DESC);
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0729GetReceiptQueue — la liste des reçus à faire (grille du service)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0729GetReceiptQueue]
    @OnlyPending BIT = 1,      -- 1 = seulement ce qui reste à traiter
    @Top         INT = 300
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        r.[Id]                                                   AS ReceiptId,
        r.[imageGUID],
        r.[Created],
        COALESCE(r.[FileName], '(sans nom)')                     AS [FileName],
        r.[ContentType],
        r.[SourceSizeBytes],
        r.[ImageForAISizeBytes],
        r.[ReceiptTypeId],
        COALESCE(t.[Description], '?')                           AS ReceiptType,
        COALESCE(r.[ProcessingStatus], 0)                        AS ProcessingStatus,
        CASE COALESCE(r.[ProcessingStatus], 0)
             WHEN 0 THEN N'À traiter'
             WHEN 1 THEN N'À traiter'
             WHEN 2 THEN N'Image optimisée'
             WHEN 3 THEN N'JSON obtenu'
             WHEN 4 THEN N'Terminé'
             ELSE N'?' END                                       AS Etat,
        -- Prochaine étape que le service exécutera sur cette ligne
        CASE WHEN COALESCE(r.[ProcessingStatus], 0) >= 4 THEN N'—'
             WHEN COALESCE(r.[ProcessingStatus], 0) >= 3 THEN N'Process JSON'
             WHEN COALESCE(r.[ProcessingStatus], 0) >= 2 THEN N'Lecture IA'
             WHEN r.[ContentType] = 'image/jpeg'            THEN N'Noir et blanc'
             ELSE N'Lecture IA' END                              AS ProchaineEtape,
        COALESCE(r.[SvcAttemptCount], 0)                         AS Tentatives,
        r.[SvcLastAttemptUtc],
        r.[SvcLastError],
        r.[SvcProcessedUtc],
        CASE WHEN r.[SvcLockedUntilUtc] > SYSUTCDATETIME() THEN 1 ELSE 0 END AS EnTraitement,
        r.[InputToken],
        r.[OutputToken],
        r.[EstimatedCostUsd],
        CASE WHEN LEN(COALESCE(r.[AI_JSON], '')) > 0 THEN 1 ELSE 0 END       AS HasJson
    FROM dbo.T0001Receipt r
    LEFT JOIN dbo.T003ReceiptType t ON t.[Id] = r.[ReceiptTypeId]
    WHERE r.[ReceiptTypeId] IN (1, 2)
      AND (@OnlyPending = 0 OR COALESCE(r.[ProcessingStatus], 0) < 4)
    ORDER BY r.[Created] DESC, r.[Id] DESC;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0730ClaimNextReceipt — prend le prochain reçu et pose le verrou
--    UPDATE ... OUTPUT en une seule instruction : deux services concurrents ne
--    peuvent pas réserver la même ligne.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0730ClaimNextReceipt]
    @LockSeconds INT          = 300,
    @MaxAttempts INT          = 3,
    @MachineName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @claimed TABLE (imageGUID UNIQUEIDENTIFIER);

    ;WITH nxt AS (
        SELECT TOP (1) r.*
        FROM dbo.T0001Receipt r WITH (UPDLOCK, READPAST, ROWLOCK)
        WHERE r.[ReceiptTypeId] IN (1, 2)
          AND COALESCE(r.[ProcessingStatus], 0) < 4
          AND COALESCE(r.[SvcAttemptCount], 0) < @MaxAttempts
          AND (r.[SvcLockedUntilUtc] IS NULL OR r.[SvcLockedUntilUtc] <= SYSUTCDATETIME())
        ORDER BY r.[Created] ASC, r.[Id] ASC   -- le plus ancien d'abord
    )
    UPDATE nxt
       SET [SvcLockedUntilUtc] = DATEADD(SECOND, @LockSeconds, SYSUTCDATETIME()),
           [SvcLastAttemptUtc] = SYSUTCDATETIME(),
           [SvcAttemptCount]   = COALESCE([SvcAttemptCount], 0) + 1
    OUTPUT inserted.[imageGUID] INTO @claimed(imageGUID);

    SELECT
        r.[Id],
        r.[imageGUID],
        r.[FileName],
        r.[ContentType],
        r.[ReceiptTypeId],
        COALESCE(r.[ProcessingStatus], 0)  AS ProcessingStatus,
        COALESCE(r.[SvcAttemptCount], 0)   AS SvcAttemptCount,
        r.[ImageSource],
        CAST(r.[ImageSource] AS VARCHAR(MAX)) AS ImageSourceText,
        r.[ImageForAI],
        COALESCE(r.[AI_JSON], '')          AS AI_JSON
    FROM dbo.T0001Receipt r
    INNER JOIN @claimed c ON c.imageGUID = r.[imageGUID];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0731SaveReceiptProcessDone — traitement complet réussi
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0731SaveReceiptProcessDone]
    @imageGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T0001Receipt
       SET [ProcessingStatus]  = 4,
           [SvcProcessedUtc]   = SYSUTCDATETIME(),
           [SvcLockedUntilUtc] = NULL,
           [SvcLastError]      = NULL,
           [SvcAttemptCount]   = 0
     WHERE [imageGUID] = @imageGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0732SaveReceiptProcessError — échec : on relâche le verrou, on garde le
--    compteur de tentatives (au-delà de @MaxAttempts, s0730 ne reprend plus).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0732SaveReceiptProcessError]
    @imageGUID UNIQUEIDENTIFIER,
    @Message   VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T0001Receipt
       SET [SvcLastError]      = LEFT(COALESCE(@Message, ''), 4000),
           [SvcLockedUntilUtc] = NULL
     WHERE [imageGUID] = @imageGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 7) s0733LogReceiptProcess — une ligne de journal par étape
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0733LogReceiptProcess]
    @imageGUID        UNIQUEIDENTIFIER,
    @Step             VARCHAR(40),
    @Success          BIT,
    @Message          VARCHAR(MAX)  = NULL,
    @Json             VARCHAR(MAX)  = NULL,
    @InputToken       INT           = NULL,
    @OutputToken      INT           = NULL,
    @EstimatedCostUsd NUMERIC(18,8) = NULL,
    @DurationMs       INT           = NULL,
    @MachineName      VARCHAR(100)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.T0002ReceiptProcessLog
        ([imageGUID], [ReceiptId], [Step], [Success], [Message], [AI_JSON],
         [InputToken], [OutputToken], [EstimatedCostUsd], [DurationMs], [MachineName])
    SELECT
        @imageGUID,
        (SELECT TOP 1 [Id] FROM dbo.T0001Receipt WHERE [imageGUID] = @imageGUID),
        @Step, @Success, @Message, @Json,
        @InputToken, @OutputToken, @EstimatedCostUsd, @DurationMs, @MachineName;
END
GO

-- -----------------------------------------------------------------------------
-- 8) s0734GetReceiptProcessLog — grille « Résultat » (avec le JSON produit)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0734GetReceiptProcessLog]
    @Top       INT              = 500,
    @imageGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        l.[Id],
        l.[Created],
        l.[imageGUID],
        l.[ReceiptId],
        COALESCE(r.[FileName], '(sans nom)')  AS [FileName],
        l.[Step],
        l.[Success],
        CASE WHEN l.[Success] = 1 THEN N'OK' ELSE N'Erreur' END AS Resultat,
        l.[Message],
        l.[DurationMs],
        l.[InputToken],
        l.[OutputToken],
        l.[EstimatedCostUsd],
        l.[MachineName],
        -- Le JSON de l'étape si elle en a produit un, sinon celui du reçu :
        -- la grille doit toujours pouvoir montrer le JSON courant.
        COALESCE(l.[AI_JSON], r.[AI_JSON], '') AS AI_JSON
    FROM dbo.T0002ReceiptProcessLog l
    LEFT JOIN dbo.T0001Receipt r ON r.[imageGUID] = l.[imageGUID]
    WHERE (@imageGUID IS NULL OR l.[imageGUID] = @imageGUID)
    ORDER BY l.[Id] DESC;
END
GO

-- -----------------------------------------------------------------------------
-- 9) s0735ResetReceiptForRetry — bouton « Refaire » de l'application du service.
--    @FromStep : 0 = tout refaire (noir et blanc + IA + JSON)
--                3 = refaire seulement le « Process JSON »
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0735ResetReceiptForRetry]
    @imageGUID UNIQUEIDENTIFIER,
    @FromStep  INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromStep >= 3
    BEGIN
        -- On garde le JSON déjà payé, on rejoue seulement sa transformation.
        UPDATE dbo.T0001Receipt
           SET [ProcessingStatus]  = 3,
               [SvcAttemptCount]   = 0,
               [SvcLastError]      = NULL,
               [SvcLockedUntilUtc] = NULL,
               [SvcProcessedUtc]   = NULL
         WHERE [imageGUID] = @imageGUID
           AND LEN(COALESCE([AI_JSON], '')) > 0;
    END
    ELSE
    BEGIN
        -- Reprise complète : le JSON sera redemandé à ChatGPT (appel facturé).
        UPDATE dbo.T0001Receipt
           SET [ProcessingStatus]  = 1,
               [AI_JSON]           = NULL,
               [SvcAttemptCount]   = 0,
               [SvcLastError]      = NULL,
               [SvcLockedUntilUtc] = NULL,
               [SvcProcessedUtc]   = NULL
         WHERE [imageGUID] = @imageGUID;
    END
END
GO

-- -----------------------------------------------------------------------------
-- 10) s0736GetReceiptStats — compteurs affichés en haut de l'application
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0736GetReceiptStats]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SUM(CASE WHEN COALESCE(ProcessingStatus, 0) < 4 THEN 1 ELSE 0 END)  AS AFaire,
        SUM(CASE WHEN COALESCE(ProcessingStatus, 0) = 4 THEN 1 ELSE 0 END)  AS Termines,
        SUM(CASE WHEN SvcLastError IS NOT NULL THEN 1 ELSE 0 END)           AS EnErreur,
        SUM(CASE WHEN SvcLockedUntilUtc > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS EnTraitement,
        COUNT(*)                                                            AS Total
    FROM dbo.T0001Receipt
    WHERE ReceiptTypeId IN (1, 2);
END
GO

PRINT N'T0002_ReceiptQueue.sql : termine.';
GO
