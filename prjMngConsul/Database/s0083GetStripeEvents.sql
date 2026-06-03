-- =============================================================================
-- s0083GetStripeEvents
-- Retourne la liste des events Stripe recus avec filtres optionnels.
-- Utilise par wbfStripeWebhookDiagnostic.
--
-- Filtres :
--   @Status        : 'all', 'received', 'processed', 'failed', 'skipped'
--   @EventType     : nom de l'event (LIKE) ou 'all'
--   @SinceHours    : combien d'heures en arriere (24, 168=7j, 720=30j)
--   @MaxRows       : limite (default 200)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0083GetStripeEvents', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0083GetStripeEvents;
GO

CREATE PROCEDURE dbo.s0083GetStripeEvents
    @Status     VARCHAR(20)  = 'all',
    @EventType  VARCHAR(100) = 'all',
    @SinceHours INT          = 168,    -- 7 jours par defaut
    @MaxRows    INT          = 200
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SinceDate DATETIME = DATEADD(HOUR, -@SinceHours, GETDATE());

    SELECT TOP (@MaxRows)
        Id,
        StripeEventId,
        EventType,
        StripeCreated,
        ProcessingStatus,
        ErrorMessage,
        StripeCustomerId,
        StripeSubscriptionId,
        UserId,
        ReceivedOn,
        ProcessedOn,
        DATEDIFF(SECOND, ReceivedOn, ISNULL(ProcessedOn, GETDATE())) AS ProcessingDurationSec,
        Payload
    FROM dbo.tStripeEvenement
    WHERE ReceivedOn >= @SinceDate
      AND (@Status = 'all' OR ProcessingStatus = @Status)
      AND (@EventType = 'all' OR EventType LIKE '%' + @EventType + '%')
    ORDER BY ReceivedOn DESC;
END
GO
