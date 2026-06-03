-- =============================================================================
-- s0630GetPlansForLanding
-- Retourne les forfaits MENSUELS actifs pour affichage sur LandingPage.aspx.
-- Filtre : IsActive = 1, IsDeleted = 0, BillingCycle = 'monthly'
-- Tri    : DisplayOrder ascendant
--
-- Utilisé par : LandingPage.aspx.vb (binding sur asp:Repeater rptPlans)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0630GetPlansForLanding', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0630GetPlansForLanding;
GO

CREATE PROCEDURE dbo.s0630GetPlansForLanding
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Code,
        Name,
        Description,
        Tagline,
        EmployeeRange,
        Amount,
        Currency,
        BillingCycle,
        PlanIconCssClass,
        PlanCardCssClass,
        BadgeText,
        IconSvg,
        Features,
        IsRecommended,
        DisplayOrder
    FROM dbo.T021Plan
    WHERE IsActive = 1
      AND IsDeleted = 0
      AND BillingCycle = 'monthly'
    ORDER BY DisplayOrder, Id;
END
GO
