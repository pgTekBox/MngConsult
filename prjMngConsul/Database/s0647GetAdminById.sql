SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0647GetAdminById
-- Retourne un administrateur par Id (pour l'écran d'édition).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0647GetAdminById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        FirstName,
        LastName,
        IsActive
    FROM dbo.T900AdminUser
    WHERE Id = @Id
      AND IsDeleted = 0;
END
