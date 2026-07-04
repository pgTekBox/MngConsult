SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0680GetUserByResetToken
-- Valide un jeton de réinitialisation (existe, non expiré, compte actif).
-- Retourne (Id, Email, FirstName) si valide, sinon rien.
-- Calqué sur s0651GetAdminByResetToken (T900AdminUser).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0680GetUserByResetToken
    @Token UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Email,
        FirstName
    FROM dbo.T015User
    WHERE ResetToken = @Token
      AND ResetTokenExpires IS NOT NULL
      AND ResetTokenExpires > GETDATE()
      AND IsActive = 1
      AND IsDeleted = 0;
END
