-- =============================================================================
-- s0631GetPlanByCode
-- Retourne UN forfait T021Plan par Code + BillingCycle (active + non supprime).
-- Utilise par wbfPayment.aspx.vb pour afficher le resume du forfait choisi.
--
-- Parametres :
--   @Code         : 'solo', 'comsolo', 'com119'
--   @BillingCycle : 'monthly' (default) ou 'annual'
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0631GetPlanByCode', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0631GetPlanByCode;
GO

CREATE PROCEDURE dbo.s0631GetPlanByCode
    @Code         VARCHAR(50),
    @BillingCycle VARCHAR(20) = 'monthly'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id,
        Code,
        Name,
        Description,
        Tagline,
        EmployeeRange,
        Amount,
        Currency,
        BillingCycle,
        ProcessorName,
        StripeProductId,
        StripePriceId,
        TrialDays,
        PlanIconCssClass,
        PlanCardCssClass,
        BadgeText,
        IconSvg,
        Features,
        IsRecommended,
        DisplayOrder
    FROM dbo.T021Plan
    WHERE Code = @Code
      AND BillingCycle = @BillingCycle
      AND IsActive = 1
      AND IsDeleted = 0;
END
GO
