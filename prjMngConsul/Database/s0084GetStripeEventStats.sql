-- =============================================================================
-- s0084GetStripeEventStats
-- Retourne des statistiques agregees sur les events Stripe recus.
-- Utilise par wbfStripeWebhookDiagnostic (cartes de stats en haut).
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0084GetStripeEventStats', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0084GetStripeEventStats;
GO

CREATE PROCEDURE dbo.s0084GetStripeEventStats
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
    FROM dbo.tStripeEvenement
    WHERE ReceivedOn >= @SinceDate;
END
GO
