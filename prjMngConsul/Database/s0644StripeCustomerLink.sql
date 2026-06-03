-- =============================================================================
-- s0644StripeCustomerLink
-- Associe un Stripe Customer Id (cus_xxx) a un user MngConsul.
-- Met a jour T015User.StripeCustomerId.
--
-- Appele lors du premier paiement (checkout.session.completed) ou
-- customer.created si on traite ce type d'event.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0644StripeCustomerLink', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0644StripeCustomerLink;
GO

CREATE PROCEDURE dbo.s0644StripeCustomerLink
    @UserId           INT,
    @StripeCustomerId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T015User
    SET StripeCustomerId = @StripeCustomerId,
        ModifiedOn       = GETDATE(),
        ModifiedBy       = 'StripeWebhook'
    WHERE Id = @UserId
      AND IsDeleted = 0
      AND (StripeCustomerId IS NULL OR StripeCustomerId <> @StripeCustomerId);
END
GO
