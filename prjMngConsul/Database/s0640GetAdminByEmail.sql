SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0640GetAdminByEmail
-- Récupère un administrateur de console par courriel (pour le login).
-- Retourne le hash bcrypt pour vérification côté application.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0640GetAdminByEmail
    @Email NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        PasswordHash,
        FirstName,
        LastName,
        IsActive
    FROM dbo.T900AdminUser
    WHERE Email = @Email
      AND IsDeleted = 0;
END
