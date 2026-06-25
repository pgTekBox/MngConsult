SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0651GetAdminByResetToken
-- Valide un jeton de réinitialisation (existe, non expiré, compte actif).
-- Retourne (Id, Email, FirstName) si valide, sinon rien.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0651GetAdminByResetToken
    @Token UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        FirstName
    FROM dbo.T900AdminUser
    WHERE ResetToken = @Token
      AND ResetTokenExpires IS NOT NULL
      AND ResetTokenExpires > GETDATE()
      AND IsActive = 1
      AND IsDeleted = 0;
END
