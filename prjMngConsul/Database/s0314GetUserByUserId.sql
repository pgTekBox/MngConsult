SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0314GetUserByUserId
-- Utilisateur par Id (utilisé par clsData/clsDataUC : isAdmin, IsAccountant,
-- CompanyName). CompanyName / CompanyLegalName proviennent du paramètre
-- LEGAL_NAME (T101) via dbo.fCompanyName (repli T010Company.Name).
-- =============================================================================
CREATE OR ALTER PROCEDURE [dbo].[s0314GetUserByUserId]
    @Id int
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
    WHERE u.Id = @Id
      AND u.IsDeleted = 0;
END
GO
