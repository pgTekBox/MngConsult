-- =============================================================================
-- s0071GetPartyForPayment
-- Retourne les infos d'un fournisseur pour la page wbfSupplierPaymentChoice :
-- Nom, derniere methode de paiement, et Stripe Account Id pour Direct Charge.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0071GetPartyForPayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0071GetPartyForPayment;
GO

CREATE PROCEDURE dbo.s0071GetPartyForPayment
    @PartyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id,
        Name,
        DisplayName,
        StripeAccountId,
        LastPaymentMethod
    FROM dbo.T050Party
    WHERE Id = @PartyId
      AND ISNULL(isDeleted, 0) = 0;
END
GO
