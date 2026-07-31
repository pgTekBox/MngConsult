-- =============================================================================
-- s0701GetSquareEventStats
-- Retourne des statistiques agregees sur les events Square recus.
-- Utilise par le diagnostic Square (console d'administration).
-- Calque sur s0084GetStripeEventStats.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0701GetSquareEventStats', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0701GetSquareEventStats;
GO

CREATE PROCEDURE dbo.s0701GetSquareEventStats
    @SinceHours INT = 168    -- 7 jours par defaut
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SinceDate DATETIME = DATEADD(HOUR, -@SinceHours, GETDATE());

    SELECT
        COUNT(*)                                                                                  AS TotalEvents,
        SUM(CASE WHEN ProcessingStatus = 'processed' THEN 1 ELSE 0 END)                           AS ProcessedCount,
        SUM(CASE WHEN ProcessingStatus = 'failed'    THEN 1 ELSE 0 END)                           AS FailedCount,
        SUM(CASE WHEN ProcessingStatus = 'received'  THEN 1 ELSE 0 END)                           AS PendingCount,
        SUM(CASE WHEN ProcessingStatus = 'skipped'   THEN 1 ELSE 0 END)                           AS SkippedCount,
        MAX(ReceivedOn)                                                                           AS LastEventOn,
        MIN(ReceivedOn)                                                                           AS FirstEventOn,
        AVG(CAST(DATEDIFF(MILLISECOND, ReceivedOn, ISNULL(ProcessedOn, GETDATE())) AS BIGINT))    AS AvgDurationMs
    FROM dbo.tSquareEvenement
    WHERE ReceivedOn >= @SinceDate;
END
GO
