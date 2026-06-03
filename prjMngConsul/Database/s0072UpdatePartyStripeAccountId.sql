-- =============================================================================
-- s0072UpdatePartyStripeAccountId
-- Stocke le acct_xxx Stripe Connect du fournisseur dans T050Party.
-- Appele apres CreateConnectExpressAccount cote MngConsul.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0072UpdatePartyStripeAccountId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0072UpdatePartyStripeAccountId;
GO

CREATE PROCEDURE dbo.s0072UpdatePartyStripeAccountId
    @PartyId         INT,
    @StripeAccountId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T050Party
    SET StripeAccountId = @StripeAccountId
    WHERE Id = @PartyId
      AND ISNULL(isDeleted, 0) = 0;
END
GO
