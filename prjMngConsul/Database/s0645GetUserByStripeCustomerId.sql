-- =============================================================================
-- s0645GetUserByStripeCustomerId
-- Retourne le UserId + CompanyGUID + Email associes a un Stripe Customer Id.
-- Utilise par StripeWebhook quand metadata est absent (ex: invoice events).
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0645GetUserByStripeCustomerId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0645GetUserByStripeCustomerId;
GO

CREATE PROCEDURE dbo.s0645GetUserByStripeCustomerId
    @StripeCustomerId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id              AS UserId,
        CompanyGUID,
        Email,
        FirstName,
        LastName,
        StripeCustomerId
    FROM dbo.T015User
    WHERE StripeCustomerId = @StripeCustomerId
      AND IsDeleted = 0;
END
GO
