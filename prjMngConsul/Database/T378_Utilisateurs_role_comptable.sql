-- =============================================================================
-- T378 — Liste des utilisateurs : renvoyer la case « comptable »
--
-- s0202GetUsersList renvoie en plus IsAccountant (T015User.isAccountant) : la
-- liste Administration › Utilisateurs (wbfUsers) affiche alors le rôle
-- « Comptable » ou « Comptable · Admin », comme l'en-tête du site, et ajoute
-- un indicateur « Comptables » qui filtre la liste.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0202GetUsersList
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        FirstName,
        LastName,
        ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS FullName,
        IsAdmin,
        CAST(ISNULL(isAccountant, 0) AS BIT) AS IsAccountant,
        IsActive,
        LastLoginOn,
        CreatedOn
    FROM dbo.T015User
    WHERE CompanyGUID = @CompanyGUID
      AND IsDeleted = 0
      AND (@Search IS NULL OR @Search = ''
           OR Email LIKE '%' + @Search + '%'
           OR FirstName LIKE '%' + @Search + '%'
           OR LastName LIKE '%' + @Search + '%')
    ORDER BY IsActive DESC, LastName, FirstName;
END
GO
