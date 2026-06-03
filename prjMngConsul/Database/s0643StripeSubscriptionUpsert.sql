-- =============================================================================
-- s0643StripeSubscriptionUpsert
-- Insere ou met a jour une ligne T020Subscription a partir des donnees Stripe.
-- Identifiant unique = TransactionId (= sub_xxx).
--
-- Le webhook handler passe les donnees apres avoir resolu UserId + CompanyGUID
-- via lookup sur T015User.StripeCustomerId.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0643StripeSubscriptionUpsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0643StripeSubscriptionUpsert;
GO

CREATE PROCEDURE dbo.s0643StripeSubscriptionUpsert
    @StripeSubscriptionId   VARCHAR(50),                    -- sub_xxx (TransactionId)
    @UserId                 INT,
    @CompanyGUID            UNIQUEIDENTIFIER,
    @PlanCode               VARCHAR(50),
    @PlanName               NVARCHAR(100),
    @Amount                 DECIMAL(10,2),
    @Currency               VARCHAR(10)     = 'CAD',
    @BillingCycle           VARCHAR(20)     = 'monthly',
    @Status                 VARCHAR(20),                    -- 'active', 'past_due', 'cancelled', 'trial', etc.
    @StartDate              DATETIME,
    @NextBillingDate        DATETIME        = NULL,
    @EndDate                DATETIME        = NULL,
    @IsTrial                BIT             = 0,
    @TrialEndOn             DATETIME        = NULL,
    @ModifiedBy             NVARCHAR(200)   = 'StripeWebhook'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExistingId INT = NULL;

    SELECT TOP 1 @ExistingId = Id
    FROM dbo.T020Subscription
    WHERE TransactionId = @StripeSubscriptionId
      AND ProcessorName = 'Stripe';

    IF @ExistingId IS NULL
    BEGIN
        -- INSERT (nouvelle subscription)
        INSERT INTO dbo.T020Subscription (
            CompanyGUID, UserId,
            PlanCode, PlanName, Amount, Currency, BillingCycle,
            TransactionId, ProcessorName,
            StartDate, EndDate, NextBillingDate, Status,
            IsTrial, TrialEndOn,
            CreatedOn, CreatedBy, IsDeleted
        )
        VALUES (
            @CompanyGUID, @UserId,
            @PlanCode, @PlanName, @Amount, @Currency, @BillingCycle,
            @StripeSubscriptionId, 'Stripe',
            @StartDate, @EndDate, @NextBillingDate, @Status,
            @IsTrial, @TrialEndOn,
            GETDATE(), @ModifiedBy, 0
        );

        SELECT CAST(1 AS BIT) AS WasInserted, SCOPE_IDENTITY() AS Id;
    END
    ELSE
    BEGIN
        -- UPDATE (mise a jour de subscription existante)
        UPDATE dbo.T020Subscription
        SET PlanCode        = @PlanCode,
            PlanName        = @PlanName,
            Amount          = @Amount,
            Currency        = @Currency,
            BillingCycle    = @BillingCycle,
            EndDate         = @EndDate,
            NextBillingDate = @NextBillingDate,
            Status          = @Status,
            IsTrial         = @IsTrial,
            TrialEndOn      = @TrialEndOn,
            ModifiedOn      = GETDATE(),
            ModifiedBy      = @ModifiedBy
        WHERE Id = @ExistingId;

        SELECT CAST(0 AS BIT) AS WasInserted, @ExistingId AS Id;
    END
END
GO
