SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0685GetOnboardingProfile
-- Charge les 12 champs de la page d'onboarding (wbfNewUser) :
-- identité (T015User) + infos entreprise (T010Company) + ProfileCompleted.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0685GetOnboardingProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.CompanyGUID,
        u.FirstName,
        u.LastName,
        u.Email,
        u.Phone,
        c.LegalName,
        c.NEQ,
        c.IncorporationDate,
        c.BusinessNumber,
        c.FiscalYearEnd,
        c.TpsNumber,
        c.TvqNumber,
        c.HstNumber,
        ISNULL(c.ProfileCompleted, 0) AS ProfileCompleted
    FROM dbo.T015User u
    LEFT JOIN dbo.T010Company c ON c.CompanyGUID = u.CompanyGUID
    WHERE u.Id = @UserId;
END
GO
