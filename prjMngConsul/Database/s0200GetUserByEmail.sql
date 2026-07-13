SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0200GetUserByEmail
-- Utilisateur par email (login). CompanyName / CompanyLegalName proviennent
-- désormais du paramètre LEGAL_NAME (T101) via dbo.fCompanyName (repli T010Company.Name).
-- =============================================================================
CREATE OR ALTER PROCEDURE [dbo].[s0200GetUserByEmail]
    @Email NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        u.Id,
        coalesce(u.CompanyGUID, convert(uniqueidentifier,'00000000-0000-0000-0000-000000000000')) CompanyGUID,
        u.Email,
        u.PasswordHash,
        u.FirstName,
        u.LastName,
        u.IsAdmin,
        u.IsAccountant,
        u.IsActive,
        u.[ActivationToken],
        coalesce(dbo.fCompanyName(u.CompanyGUID), '') AS CompanyName,
        coalesce(dbo.fCompanyName(u.CompanyGUID), '') AS CompanyLegalName
    FROM dbo.T015User u
    WHERE u.Email = @Email
      AND u.IsDeleted = 0;
END
GO
