/* =====================================================================
   PortailMaster - Script 31 : purge des retours EFT TRAITÉS
   ---------------------------------------------------------------------
   T053EftReturn journalise les retours (fichiers 005 entrants E/F). Un
   retour TRAITÉ (Status=Processed) a été contre-passé au grand livre : il
   est terminal et peut être purgé au-delà d'une rétention. Les statuts
   PROBLÉMATIQUES (Unmatched / AmountMismatch / Error) sont CONSERVÉS —
   valeur diagnostique + suivi opérationnel (ils peuvent réclamer une
   intervention manuelle). AlreadyReturned est aussi conservé (rare, trace).

   Journal pur : PK seule, aucune FK (PaymentId/ReturnTxnId sont de simples
   valeurs). Purge par âge (ImportedUtc), filtrée sur Status=Processed.

   Rétention par défaut 365 j (aligné sur lots EFT / lignes de relevé).

   s0083PurgeProcessedEftReturns + maj s0079.
   A executer APRES 17 (T053) et 30 (s0079). Procs numerotees s0083+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0083PurgeProcessedEftReturns : supprime les retours TRAITÉS anciens.
   Renvoie le nombre de lignes supprimées.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0083PurgeProcessedEftReturns
    @RetentionDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 365;
    DECLARE @cutoff DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    DELETE FROM dbo.T053EftReturn
    WHERE Status = N'Processed'
      AND ImportedUtc < @cutoff;

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des retours EFT traités.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays     INT = 30,
    @BankLineRetentionDays    INT = 365,
    @EftBatchRetentionDays    INT = 365,
    @ExchangeLogRetentionDays INT = 180,
    @EftReturnRetentionDays   INT = 365
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes TABLE (Purged INT);
    DECLARE @whRes  TABLE (Purged INT);
    DECLARE @blRes  TABLE (Purged INT);
    DECLARE @ebRes  TABLE (Purged INT);
    DECLARE @elRes  TABLE (Purged INT);
    DECLARE @erRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks     @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines   @RetentionDays = @BankLineRetentionDays;
    INSERT INTO @ebRes  EXEC dbo.s0081PurgeSettledEftBatches     @RetentionDays = @EftBatchRetentionDays;
    INSERT INTO @elRes  EXEC dbo.s0082PurgeExchangeLog           @RetentionDays = @ExchangeLogRetentionDays;
    INSERT INTO @erRes  EXEC dbo.s0083PurgeProcessedEftReturns   @RetentionDays = @EftReturnRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines,
        ISNULL((SELECT TOP 1 Purged FROM @ebRes),  0) AS PurgedEftBatches,
        ISNULL((SELECT TOP 1 Purged FROM @elRes),  0) AS PurgedExchangeLogs,
        ISNULL((SELECT TOP 1 Purged FROM @erRes),  0) AS PurgedEftReturns;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'31_eft_return_purge.sql : termine.';
GO
