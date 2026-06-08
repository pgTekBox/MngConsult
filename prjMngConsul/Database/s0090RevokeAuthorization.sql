-- =============================================================================
-- s0090RevokeAuthorization
-- Revoque une autorisation d'auto-paiement (soft delete via RevokedDate).
--
-- Effet en cascade :
--   - Toutes les factures programmees pour ce fournisseur via cette autorisation
--     basculent en AutoPayStatus = 'ANNULE'
--   - Une nouvelle autorisation devra etre creee pour reactiver
--
-- Cote Stripe, il faut aussi detacher le PaymentMethod (a faire dans le code
-- VB.NET appelant, pas ici - sequence : SP revoke -> Stripe detach).
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0090RevokeAuthorization', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0090RevokeAuthorization;
GO

CREATE PROCEDURE dbo.s0090RevokeAuthorization
    @CompanyGUID            UNIQUEIDENTIFIER,
    @AuthorizationId        INT,
    @RevokedByUserGUID      UNIQUEIDENTIFIER,
    @RevokedReason          NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verifier que l'autorisation existe et appartient a la company
        DECLARE @Exists BIT = 0;
        DECLARE @StripePaymentMethodId VARCHAR(100);
        DECLARE @StripeAccountId VARCHAR(50);

        SELECT @Exists = 1,
               @StripePaymentMethodId = StripePaymentMethodId,
               @StripeAccountId = StripeAccountId
        FROM dbo.T144AuthorizationAutoPay
        WHERE Id = @AuthorizationId
          AND CompanyGUID = @CompanyGUID
          AND RevokedDate IS NULL;

        IF @Exists = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 1 AS RetCode, 'Autorisation introuvable ou deja revoked' AS ErrorMessage,
                   NULL AS StripePaymentMethodId, NULL AS StripeAccountId;
            RETURN;
        END

        -- Revoke
        UPDATE dbo.T144AuthorizationAutoPay
        SET RevokedDate = GETDATE(),
            RevokedByUserGUID = @RevokedByUserGUID,
            RevokedReason = ISNULL(@RevokedReason, 'Revoked par utilisateur')
        WHERE Id = @AuthorizationId;

        -- Annuler les factures programmees qui dependaient de cette autorisation
        DECLARE @CancelCount INT;
        UPDATE dbo.T060Document
        SET AutoPayStatus = 'ANNULE',
            AutoPay = 0
        WHERE CompanyGUID = @CompanyGUID
          AND AutoPayAuthorizationId = @AuthorizationId
          AND AutoPayStatus IN ('PLANIFIE','REQUIRES_3DS');

        SET @CancelCount = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT 0 AS RetCode,
               '' AS ErrorMessage,
               @StripePaymentMethodId AS StripePaymentMethodId,
               @StripeAccountId AS StripeAccountId,
               @CancelCount AS CancelledScheduledCount;
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
