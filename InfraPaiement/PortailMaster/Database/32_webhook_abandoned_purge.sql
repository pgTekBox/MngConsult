/* =====================================================================
   PortailMaster - Script 32 : purge des livraisons de webhooks ABANDONNÉES
   ---------------------------------------------------------------------
   Complète s0078 (qui purge les livraisons LIVRÉES à 30 j en conservant les
   Abandoned pour leur valeur diagnostique). Les livraisons ABANDONNÉES
   (échec définitif après MaxAttempts) restent utiles à court terme
   (Supervision : s0055ListWebhookIssues) mais deviennent du bruit au-delà
   d'un trimestre. Rétention plus LONGUE que les livrées (défaut 90 j vs 30).

   s0055 n'affiche que les 20 plus récentes (TOP … Id DESC) : purger les
   anciennes n'enlève rien de visible. Purge par âge (CreatedUtc).

   s0084PurgeAbandonedWebhooks + maj s0079.
   A executer APRES 10 (T042) et 31 (s0079). Procs numerotees s0084+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0084PurgeAbandonedWebhooks : supprime les livraisons ABANDONNÉES au-delà
   de la rétention (défaut 90 j, via CreatedUtc). Renvoie le nb supprimé.
   Les Pending (à renvoyer) et Delivered (gérées par s0078) sont ignorées.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0084PurgeAbandonedWebhooks
    @RetentionDays INT = 90
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 90;
    DECLARE @cutoff DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    DELETE FROM dbo.T042WebhookDelivery
    WHERE Status = N'Abandoned'
      AND CreatedUtc < @cutoff;

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des livraisons de webhooks abandonnées.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays          INT = 30,
    @BankLineRetentionDays         INT = 365,
    @EftBatchRetentionDays         INT = 365,
    @ExchangeLogRetentionDays      INT = 180,
    @EftReturnRetentionDays        INT = 365,
    @WebhookAbandonedRetentionDays INT = 90
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes TABLE (Purged INT);
    DECLARE @whRes  TABLE (Purged INT);
    DECLARE @blRes  TABLE (Purged INT);
    DECLARE @ebRes  TABLE (Purged INT);
    DECLARE @elRes  TABLE (Purged INT);
    DECLARE @erRes  TABLE (Purged INT);
    DECLARE @waRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks     @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines   @RetentionDays = @BankLineRetentionDays;
    INSERT INTO @ebRes  EXEC dbo.s0081PurgeSettledEftBatches     @RetentionDays = @EftBatchRetentionDays;
    INSERT INTO @elRes  EXEC dbo.s0082PurgeExchangeLog           @RetentionDays = @ExchangeLogRetentionDays;
    INSERT INTO @erRes  EXEC dbo.s0083PurgeProcessedEftReturns   @RetentionDays = @EftReturnRetentionDays;
    INSERT INTO @waRes  EXEC dbo.s0084PurgeAbandonedWebhooks     @RetentionDays = @WebhookAbandonedRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines,
        ISNULL((SELECT TOP 1 Purged FROM @ebRes),  0) AS PurgedEftBatches,
        ISNULL((SELECT TOP 1 Purged FROM @elRes),  0) AS PurgedExchangeLogs,
        ISNULL((SELECT TOP 1 Purged FROM @erRes),  0) AS PurgedEftReturns,
        ISNULL((SELECT TOP 1 Purged FROM @waRes),  0) AS PurgedAbandonedWebhooks;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'32_webhook_abandoned_purge.sql : termine.';
GO
