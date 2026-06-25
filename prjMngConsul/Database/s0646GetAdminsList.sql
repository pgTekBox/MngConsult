SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0646GetAdminsList
-- Liste des administrateurs de la console (T900AdminUser).
-- @Search : filtre optionnel sur courriel / prénom / nom.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0646GetAdminsList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        FirstName,
        LastName,
        ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS FullName,
        IsActive,
        LastLoginOn
    FROM dbo.T900AdminUser
    WHERE IsDeleted = 0
      AND (@Search IS NULL OR @Search = ''
           OR Email LIKE '%' + @Search + '%'
           OR FirstName LIKE '%' + @Search + '%'
           OR LastName LIKE '%' + @Search + '%')
    ORDER BY IsActive DESC, LastName, FirstName, Email;
END
