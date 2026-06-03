-- =============================================================================
-- s0641StripeEventMarkProcessed
-- Marque un event Stripe comme traite avec succes.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0641StripeEventMarkProcessed', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0641StripeEventMarkProcessed;
GO

CREATE PROCEDURE dbo.s0641StripeEventMarkProcessed
    @StripeEventId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tStripeEvenement
    SET ProcessingStatus = 'processed',
        ProcessedOn      = GETDATE(),
        ErrorMessage     = NULL
    WHERE StripeEventId = @StripeEventId;
END
GO
