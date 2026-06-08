-- =============================================================================
-- s0089RecordAutoPayAttempt
-- Enregistre le resultat d'une tentative d'auto-paiement et met a jour T060.
--
-- Resultats possibles :
--   SUCCESS         : paiement effectue par Stripe (PI confirme)
--   FAILED          : echec definitif (carte refusee, etc.)
--   REQUIRES_ACTION : 3DS requis ou autre action client necessaire
--   BLOCKED_CAP     : bloque par plafond mensuel
--
-- Met a jour T060Document.AutoPayStatus en consequence :
--   SUCCESS         -> PAYE
--   FAILED + attempts < max -> PLANIFIE (nouveau essai demain)
--   FAILED + attempts >= max -> ECHEC
--   REQUIRES_ACTION -> REQUIRES_3DS
--   BLOCKED_CAP     -> ECHEC
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0089RecordAutoPayAttempt', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0089RecordAutoPayAttempt;
GO

CREATE PROCEDURE dbo.s0089RecordAutoPayAttempt
    @CompanyGUID            UNIQUEIDENTIFIER,
    @DocumentId             INT,
    @AuthorizationId        INT,
    @PartyId                INT,
    @AttemptNumber          INT,
    @Amount                 DECIMAL(15,2),
    @AmountGross            DECIMAL(15,2),
    @FeeAmount              DECIMAL(15,2),
    @Currency               VARCHAR(3) = 'cad',
    @PaymentMethodType      VARCHAR(20),
    @Result                 VARCHAR(30),
    @StripePaymentIntentId  VARCHAR(100) = NULL,
    @StripeChargeId         VARCHAR(100) = NULL,
    @FailureCode            VARCHAR(50) = NULL,
    @FailureMessage         NVARCHAR(MAX) = NULL,
    @Requires3DSUrl         VARCHAR(500) = NULL,
    @ReglementId            INT = NULL,
    @MaxAttempts            INT = 3,
    @RetryIntervalHours     INT = 24
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @AttemptId INT;
        DECLARE @NextRetryDate DATE = NULL;
        DECLARE @NewAutoPayStatus VARCHAR(20);

        -- INSERT T145
        INSERT INTO dbo.T145AutoPayAttempt (
            CompanyGUID, DocumentId, AuthorizationId, PartyId,
            AttemptNumber, Amount, AmountGross, FeeAmount, Currency,
            PaymentMethodType,
            Result, StripePaymentIntentId, StripeChargeId,
            FailureCode, FailureMessage, Requires3DSUrl,
            ProcessedDate, ReglementId
        )
        VALUES (
            @CompanyGUID, @DocumentId, @AuthorizationId, @PartyId,
            @AttemptNumber, @Amount, @AmountGross, @FeeAmount, @Currency,
            @PaymentMethodType,
            @Result, @StripePaymentIntentId, @StripeChargeId,
            @FailureCode, @FailureMessage, @Requires3DSUrl,
            GETDATE(), @ReglementId
        );

        SET @AttemptId = SCOPE_IDENTITY();

        -- Determiner nouveau status T060
        IF @Result = 'SUCCESS'
            SET @NewAutoPayStatus = 'PAYE';
        ELSE IF @Result = 'REQUIRES_ACTION'
            SET @NewAutoPayStatus = 'REQUIRES_3DS';
        ELSE IF @Result = 'BLOCKED_CAP'
            SET @NewAutoPayStatus = 'ECHEC';
        ELSE IF @Result = 'FAILED'
        BEGIN
            IF @AttemptNumber >= @MaxAttempts
                SET @NewAutoPayStatus = 'ECHEC';
            ELSE
            BEGIN
                SET @NewAutoPayStatus = 'PLANIFIE';
                SET @NextRetryDate = CAST(DATEADD(HOUR, @RetryIntervalHours, GETDATE()) AS DATE);
            END
        END
        ELSE
            SET @NewAutoPayStatus = 'PLANIFIE'; -- safety fallback

        UPDATE dbo.T060Document
        SET AutoPayStatus = @NewAutoPayStatus,
            AutoPayAttempts = @AttemptNumber,
            AutoPayDate = COALESCE(@NextRetryDate, AutoPayDate)
        WHERE Id = @DocumentId
          AND CompanyGUID = @CompanyGUID;

        COMMIT TRANSACTION;

        SELECT @AttemptId AS AttemptId,
               @NewAutoPayStatus AS NewAutoPayStatus,
               @NextRetryDate AS NextRetryDate;
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
