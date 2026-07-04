SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0681ResetUserPasswordByToken
-- Réinitialise le mot de passe via un jeton valide, puis consomme le jeton.
-- Retourne Affected = 1 si réussi (jeton valide & non expiré), sinon 0.
-- Calqué sur s0652ResetAdminPasswordByToken (T900AdminUser).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0681ResetUserPasswordByToken
    @Token        UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T015User
    SET PasswordHash      = @PasswordHash,
        ResetToken        = NULL,
        ResetTokenExpires = NULL,
        ModifiedOn        = GETDATE(),
        ModifiedBy        = 'password-reset'
    WHERE ResetToken = @Token
      AND ResetTokenExpires IS NOT NULL
      AND ResetTokenExpires > GETDATE()
      AND IsActive = 1
      AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS Affected;
END
