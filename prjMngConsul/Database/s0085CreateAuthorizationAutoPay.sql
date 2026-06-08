-- =============================================================================
-- s0085CreateAuthorizationAutoPay
-- Cree une nouvelle autorisation d'auto-paiement pour un fournisseur.
--
-- Appele par StripeWebhook.ashx apres checkout.session.completed lorsque
-- la metadata MngConsul_AuthorizeAutoPay = 'true' et qu'une PaymentMethod
-- a ete sauvegardee (setup_future_usage = off_session).
--
-- Idempotent : si une autorisation active existe deja pour le couple
-- (Company, Party, User, MethodType), elle est revoked et remplacee.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0085CreateAuthorizationAutoPay', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0085CreateAuthorizationAutoPay;
GO

CREATE PROCEDURE dbo.s0085CreateAuthorizationAutoPay
    @CompanyGUID                UNIQUEIDENTIFIER,
    @PartyId                    INT,
    @PartyGUID                  UNIQUEIDENTIFIER,
    @StripeAccountId            VARCHAR(50),
    @StripeCustomerId           VARCHAR(100),
    @StripePaymentMethodId      VARCHAR(100),
    @PaymentMethodType          VARCHAR(20),
    @CardBrand                  VARCHAR(20)   = NULL,
    @CardLast4                  VARCHAR(4)    = NULL,
    @CardExpMonth               INT           = NULL,
    @CardExpYear                INT           = NULL,
    @BankInstitutionNumber      VARCHAR(10)   = NULL,
    @BankTransitNumber          VARCHAR(10)   = NULL,
    @BankAccountLast4           VARCHAR(4)    = NULL,
    @StripeMandateId            VARCHAR(100)  = NULL,
    @PadAgreementUrl            VARCHAR(500)  = NULL,
    @MaxAmountPerCharge         DECIMAL(15,2) = NULL,
    @MaxAmountPerMonth          DECIMAL(15,2) = NULL,
    @AuthorizedByUserGUID       UNIQUEIDENTIFIER,
    @AuthorizedIpAddress        VARCHAR(45)   = NULL,
    @AuthorizedUserAgent        VARCHAR(500)  = NULL,
    @AuthorizationText          NVARCHAR(MAX),
    @AuthorizationLanguage      VARCHAR(5)    = 'fr-CA'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Revoquer toute autorisation active existante pour ce triplet
        UPDATE dbo.T144AuthorizationAutoPay
        SET RevokedDate = GETDATE(),
            RevokedByUserGUID = @AuthorizedByUserGUID,
            RevokedReason = 'Remplacee par nouvelle autorisation'
        WHERE CompanyGUID = @CompanyGUID
          AND PartyId = @PartyId
          AND AuthorizedByUserGUID = @AuthorizedByUserGUID
          AND PaymentMethodType = @PaymentMethodType
          AND RevokedDate IS NULL;

        DECLARE @NewId INT;

        INSERT INTO dbo.T144AuthorizationAutoPay (
            CompanyGUID, PartyId, PartyGUID,
            StripeAccountId, StripeCustomerId, StripePaymentMethodId,
            PaymentMethodType,
            CardBrand, CardLast4, CardExpMonth, CardExpYear,
            BankInstitutionNumber, BankTransitNumber, BankAccountLast4,
            StripeMandateId, PadAgreementUrl,
            MaxAmountPerCharge, MaxAmountPerMonth,
            AuthorizedByUserGUID, AuthorizedIpAddress, AuthorizedUserAgent,
            AuthorizationText, AuthorizationLanguage
        )
        VALUES (
            @CompanyGUID, @PartyId, @PartyGUID,
            @StripeAccountId, @StripeCustomerId, @StripePaymentMethodId,
            @PaymentMethodType,
            @CardBrand, @CardLast4, @CardExpMonth, @CardExpYear,
            @BankInstitutionNumber, @BankTransitNumber, @BankAccountLast4,
            @StripeMandateId, @PadAgreementUrl,
            @MaxAmountPerCharge, @MaxAmountPerMonth,
            @AuthorizedByUserGUID, @AuthorizedIpAddress, @AuthorizedUserAgent,
            @AuthorizationText, @AuthorizationLanguage
        );

        SET @NewId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NewId AS AuthorizationId,
               (SELECT AuthorizationGUID FROM dbo.T144AuthorizationAutoPay WHERE Id = @NewId) AS AuthorizationGUID,
               CAST(1 AS BIT) AS WasInserted;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END
GO
