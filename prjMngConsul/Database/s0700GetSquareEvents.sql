-- =============================================================================
-- s0700GetSquareEvents
-- Retourne la liste des events Square recus avec filtres optionnels.
-- Utilise par le diagnostic Square (console d'administration).
-- Calque sur s0083GetStripeEvents.
--
-- Filtres :
--   @Status        : 'all', 'received', 'processed', 'failed', 'skipped'
--   @EventType     : nom (fragment) de l'event (LIKE) ou 'all'
--   @SinceHours    : combien d'heures en arriere (24, 168=7j, 720=30j)
--   @MaxRows       : limite (default 200)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0700GetSquareEvents', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0700GetSquareEvents;
GO

CREATE PROCEDURE dbo.s0700GetSquareEvents
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
        SquareEventId,
        EventType,
        MerchantId,
        SquareCreatedAt,
        ProcessingStatus,
        ErrorMessage,
        ReceivedOn,
        ProcessedOn,
        DATEDIFF(SECOND, ReceivedOn, ISNULL(ProcessedOn, GETDATE())) AS ProcessingDurationSec,
        Payload
    FROM dbo.tSquareEvenement
    WHERE ReceivedOn >= @SinceDate
      AND (@Status = 'all' OR ProcessingStatus = @Status)
      AND (@EventType = 'all' OR EventType LIKE '%' + @EventType + '%')
    ORDER BY ReceivedOn DESC;
END
GO
