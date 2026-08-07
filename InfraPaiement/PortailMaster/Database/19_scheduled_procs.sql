/* =====================================================================
   PortailMaster - Script 19 : Procedures d'orchestration (taches planifiees)
   ---------------------------------------------------------------------
   Appelees par SQL Agent (ou le Planificateur de taches Windows) :
     - s0056RunDailySettlement : reglement quotidien SIMULE (regle les
       transactions Initie echues, entrant + sortant).
     - s0057AutoGenerateBatch : cree un lot EFT s'il y a des transactions
       initiees non batchees (sinon ne fait rien, sans erreur).
   Le dispatch des webhooks reste fait par WebhookDispatcher.ashx (POST
   sortant + HMAC), non par SQL. Procs s0056+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* --- s0056RunDailySettlement : reglement des echeances (simule). --- */
CREATE OR ALTER PROCEDURE dbo.s0056RunDailySettlement
    @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @rin TABLE (n INT);
    DECLARE @rout TABLE (n INT);
    INSERT INTO @rin  EXEC dbo.s0024RunSettlementBatch       @AbonneId = NULL, @AdminId = @AdminId;
    INSERT INTO @rout EXEC dbo.s0041RunPayoutSettlementBatch @AbonneId = NULL, @AdminId = @AdminId;
    SELECT
        (SELECT ISNULL(SUM(n),0) FROM @rin)  AS NbEntrantsRegles,
        (SELECT ISNULL(SUM(n),0) FROM @rout) AS NbSortantsRegles;
END
GO

/* --- s0057AutoGenerateBatch : genere un lot EFT si des transactions
       initiees non batchees existent. --- */
CREATE OR ALTER PROCEDURE dbo.s0057AutoGenerateBatch
    @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T030Payment WHERE Status=N'Initie' AND BatchId IS NULL)
    BEGIN
        SELECT CAST(NULL AS INT) AS BatchId, 0 AS Created;
        RETURN;
    END
    DECLARE @b INT = 0;
    EXEC dbo.s0044CreateEftBatch @AdminId = @AdminId, @BatchId = @b OUTPUT;
    SELECT @b AS BatchId, 1 AS Created;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'19_scheduled_procs.sql : termine.';
GO
