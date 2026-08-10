/* =====================================================================
   PortailMaster - Script 29 : purge des lots EFT RÉGLÉS
   ---------------------------------------------------------------------
   Les lots EFT (T050EftBatch) une fois RÉGLÉS (Status=Settled) sont
   terminaux : le fichier CPA-005 a été soumis et la banque a confirmé.
   Au-delà d'une rétention, le lot + ses lignes (T051EftBatchItem) peuvent
   être purgés. Les lots Open/Generated/Submitted (en cours) sont CONSERVÉS.

   Ce qui reste intact :
     - T030Payment (état des paiements, SettledUtc, etc.) : NON supprimé ;
       on remet seulement BatchId à NULL (colonne informative, sans FK ;
       ne sert qu'à éviter de re-batcher un paiement Initie — or les
       paiements d'un lot réglé sont Regle, donc aucun effet de bord).
     - Le grand livre immuable (T101/T102) et les retours (T053).

   ⚠️ Ordre : détacher T030Payment.BatchId -> supprimer T051 (FK vers T050,
   sans cascade) -> supprimer T050.

   s0081PurgeSettledEftBatches + maj s0079.
   A executer APRES 16 (T050/T051) et 28 (s0079). Procs numerotees s0081+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0081PurgeSettledEftBatches : purge des lots réglés au-delà de la
   rétention (défaut 365 j, via SettledUtc). Renvoie le nombre de lots
   supprimés.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0081PurgeSettledEftBatches
    @RetentionDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;
    IF @RetentionDays IS NULL OR @RetentionDays < 0 SET @RetentionDays = 365;
    DECLARE @cutoff DATETIME2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());

    -- Lots éligibles : réglés depuis plus longtemps que la rétention.
    DECLARE @ids TABLE (Id INT PRIMARY KEY);
    INSERT INTO @ids
    SELECT Id FROM dbo.T050EftBatch
    WHERE Status = N'Settled' AND SettledUtc IS NOT NULL AND SettledUtc < @cutoff;

    IF NOT EXISTS (SELECT 1 FROM @ids)
    BEGIN
        SELECT 0 AS Purged;
        RETURN;
    END

    -- Détache les paiements (évite une référence pendante ; sans effet sur leur cycle).
    UPDATE p SET p.BatchId = NULL
    FROM dbo.T030Payment p JOIN @ids b ON b.Id = p.BatchId;

    -- Supprime les lignes de lot, puis les lots.
    DELETE it FROM dbo.T051EftBatchItem it JOIN @ids b ON b.Id = it.BatchId;
    DELETE bt FROM dbo.T050EftBatch     bt JOIN @ids b ON b.Id = bt.Id;

    SELECT @@ROWCOUNT AS Purged;
END
GO

/* ---------------------------------------------------------------------
   s0079RunDailyMaintenance : + purge des lots EFT réglés.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0079RunDailyMaintenance
    @WebhookRetentionDays  INT = 30,
    @BankLineRetentionDays INT = 365,
    @EftBatchRetentionDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tokRes TABLE (Purged INT);
    DECLARE @whRes  TABLE (Purged INT);
    DECLARE @blRes  TABLE (Purged INT);
    DECLARE @ebRes  TABLE (Purged INT);

    INSERT INTO @tokRes EXEC dbo.s0077PurgeExpiredRememberTokens;
    INSERT INTO @whRes  EXEC dbo.s0078PurgeDeliveredWebhooks     @RetentionDays = @WebhookRetentionDays;
    INSERT INTO @blRes  EXEC dbo.s0080PurgeReconciledBankLines   @RetentionDays = @BankLineRetentionDays;
    INSERT INTO @ebRes  EXEC dbo.s0081PurgeSettledEftBatches     @RetentionDays = @EftBatchRetentionDays;

    SELECT
        ISNULL((SELECT TOP 1 Purged FROM @tokRes), 0) AS PurgedTokens,
        ISNULL((SELECT TOP 1 Purged FROM @whRes),  0) AS PurgedWebhooks,
        ISNULL((SELECT TOP 1 Purged FROM @blRes),  0) AS PurgedBankLines,
        ISNULL((SELECT TOP 1 Purged FROM @ebRes),  0) AS PurgedEftBatches;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'29_eft_batch_purge.sql : termine.';
GO
