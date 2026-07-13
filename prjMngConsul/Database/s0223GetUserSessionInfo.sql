SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0223GetUserSessionInfo
-- Infos de session. CompanyName vient du paramètre LEGAL_NAME (T101) via
-- dbo.fCompanyName (repli T010Company.Name).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0223GetUserSessionInfo
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.Id,
        u.CompanyGUID,
        u.Email,
        u.FirstName,
        u.LastName,
        u.IsAdmin,
        u.IsAccountant,
        dbo.fCompanyName(u.CompanyGUID) AS CompanyName
    FROM dbo.T015User u
    INNER JOIN dbo.T010Company c ON c.CompanyGUID = u.CompanyGUID
    WHERE u.Id = @UserId
      AND u.IsDeleted = 0;
END
GO
