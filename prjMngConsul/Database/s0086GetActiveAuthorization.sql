-- =============================================================================
-- s0086GetActiveAuthorization
-- Retourne la (ou les) autorisation(s) active(s) pour un fournisseur donne
-- et un utilisateur donne, dans le contexte d'une Company.
--
-- Utilise par :
--   - wbfSupplierPaymentChoice (UI : afficher "auto-pay deja configure")
--   - wbfSuppliersInvoices (bouton "Programmer auto-paiement" disponible ?)
--   - AutoPayProcessor (recuperer l'autorisation pour debiter)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0086GetActiveAuthorization', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0086GetActiveAuthorization;
GO

CREATE PROCEDURE dbo.s0086GetActiveAuthorization
    @CompanyGUID            UNIQUEIDENTIFIER,
    @PartyId                INT,
    @UserGUID               UNIQUEIDENTIFIER = NULL,
    @PaymentMethodType      VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        A.Id,
        A.AuthorizationGUID,
        A.CompanyGUID,
        A.PartyId,
        A.PartyGUID,
        A.StripeAccountId,
        A.StripeCustomerId,
        A.StripePaymentMethodId,
        A.PaymentMethodType,
        A.CardBrand,
        A.CardLast4,
        A.CardExpMonth,
        A.CardExpYear,
        A.BankInstitutionNumber,
        A.BankTransitNumber,
        A.BankAccountLast4,
        A.StripeMandateId,
        A.PadAgreementUrl,
        A.MaxAmountPerCharge,
        A.MaxAmountPerMonth,
        A.AuthorizedDate,
        A.AuthorizedByUserGUID,
        A.AuthorizationLanguage,
        A.Created
    FROM dbo.T144AuthorizationAutoPay A
    WHERE A.CompanyGUID = @CompanyGUID
      AND A.PartyId = @PartyId
      AND A.RevokedDate IS NULL
      AND (@UserGUID IS NULL OR A.AuthorizedByUserGUID = @UserGUID)
      AND (@PaymentMethodType IS NULL OR A.PaymentMethodType = @PaymentMethodType)
    ORDER BY A.AuthorizedDate DESC;
END
GO
