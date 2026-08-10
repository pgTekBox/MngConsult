/* =====================================================================
   PortailMaster - Script 30 : purge des journaux d'échange bancaire
   ---------------------------------------------------------------------
   T054FileExchangeLog est un pur JOURNAL des échanges de fichiers avec la
   banque (envois .005, réceptions retours/relevés). Aucune FK entrante ;
   la colonne BatchId n'est qu'informative (et devient de toute façon
   pendante après la purge des lots EFT, script 29). Purge simple par âge
   (colonne Utc), tous statuts confondus (Sent/Received/Processed/Error) —
   au-delà de la rétention un log n'a plus de valeur opérationnelle.

   Rétention par défaut 180 j (journal ; l'UF n'affiche que les 50 derniers).

   s0082PurgeExchangeLog + maj s0079.
   A executer APRES 21 (T054) et 29 (s0079). Procs numerotees s0082+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0082PurgeExchangeLog : supprime les entrées de journal plus anciennes
   que la rétention (défaut 180 j). Renvoie le nombre de lignes supprimées.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0082PurgeExchangeLog
    @RetentionDays INT = 180
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 180;
    DECLARE @cutoff DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    DELETE FROM dbo.T054FileExchangeLog
    WHERE Utc < @cutoff;

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des journaux d'échange bancaire.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays     INT = 30,
    @BankLineRetentionDays    INT = 365,
    @EftBatchRetentionDays    INT = 365,
    @ExchangeLogRetentionDays INT = 180
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes TABLE (Purged INT);
    DECLARE @whRes  TABLE (Purged INT);
    DECLARE @blRes  TABLE (Purged INT);
    DECLARE @ebRes  TABLE (Purged INT);
    DECLARE @elRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks     @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines   @RetentionDays = @BankLineRetentionDays;
    INSERT INTO @ebRes  EXEC dbo.s0081PurgeSettledEftBatches     @RetentionDays = @EftBatchRetentionDays;
    INSERT INTO @elRes  EXEC dbo.s0082PurgeExchangeLog           @RetentionDays = @ExchangeLogRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines,
        ISNULL((SELECT TOP 1 Purged FROM @ebRes),  0) AS PurgedEftBatches,
        ISNULL((SELECT TOP 1 Purged FROM @elRes),  0) AS PurgedExchangeLogs;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'30_exchange_log_purge.sql : termine.';
GO
