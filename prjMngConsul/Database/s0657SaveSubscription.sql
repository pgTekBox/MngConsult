SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0657SaveSubscription
-- Insert (si @Id=0) ou Update d'un abonnement (T020Subscription).
-- Édition admin : on gère forfait, statut, montant, cycle et dates.
-- @UserId : conservé en édition ; 0 par défaut à la création (admin).
-- Retourne @NewId.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0657SaveSubscription
    @Id              INT,
    @CompanyGUID     UNIQUEIDENTIFIER,
    @PlanCode        NVARCHAR(50),
    @PlanName        NVARCHAR(100) = NULL,
    @Amount          DECIMAL(18,2),
    @Currency        NVARCHAR(10),
    @BillingCycle    NVARCHAR(20),
    @Status          NVARCHAR(20),
    @StartDate       DATETIME      = NULL,
    @EndDate         DATETIME      = NULL,
    @NextBillingDate DATETIME      = NULL,
    @IsTrial         BIT           = 0,
    @TrialEndOn      DATETIME      = NULL,
    @UserId          INT           = 0,
    @ModifiedBy      NVARCHAR(200) = NULL,
    @NewId           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Id, 0) = 0
    BEGIN
        INSERT INTO dbo.T020Subscription
            (CompanyGUID, UserId, PlanCode, PlanName, Amount, Currency, BillingCycle,
             Status, StartDate, EndDate, NextBillingDate, IsTrial, TrialEndOn,
             CreatedOn, CreatedBy, IsDeleted)
        VALUES
            (@CompanyGUID, @UserId, @PlanCode, @PlanName, @Amount, @Currency, @BillingCycle,
             @Status, ISNULL(@StartDate, GETDATE()), @EndDate, @NextBillingDate, @IsTrial, @TrialEndOn,
             GETDATE(), @ModifiedBy, 0);

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T020Subscription
        SET PlanCode        = @PlanCode,
            PlanName        = @PlanName,
            Amount          = @Amount,
            Currency        = @Currency,
            BillingCycle    = @BillingCycle,
            Status          = @Status,
            StartDate       = @StartDate,
            EndDate         = @EndDate,
            NextBillingDate = @NextBillingDate,
            IsTrial         = @IsTrial,
            TrialEndOn      = @TrialEndOn,
            ModifiedOn      = GETDATE(),
            ModifiedBy      = @ModifiedBy
        WHERE Id = @Id;

        SET @NewId = @Id;
    END
END
