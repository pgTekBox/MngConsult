-- =============================================================================
-- s0630GetPlansForLanding  (v2)
-- Ajoute DescriptionLong au SELECT : contenu HTML mis en forme (RadEditor cote
-- admin prjSec60Admin/wbfPlanEdit) affiche sur la carte du forfait de la
-- LandingPage (div.plan-longdesc).
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0630GetPlansForLanding
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Code,
        Name,
        Description,
        DescriptionLong,
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
