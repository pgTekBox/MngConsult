-- =============================================================================
-- s0642StripeEventMarkFailed
-- Marque un event Stripe comme echec (avec message d'erreur).
-- Stripe retentera l'envoi du webhook automatiquement.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0642StripeEventMarkFailed', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0642StripeEventMarkFailed;
GO

CREATE PROCEDURE dbo.s0642StripeEventMarkFailed
    @StripeEventId VARCHAR(50),
    @ErrorMessage  NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tStripeEvenement
    SET ProcessingStatus = 'failed',
        ProcessedOn      = GETDATE(),
        ErrorMessage     = @ErrorMessage
    WHERE StripeEventId = @StripeEventId;
END
GO
