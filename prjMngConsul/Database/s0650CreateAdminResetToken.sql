SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0650CreateAdminResetToken
-- Génère un jeton de réinitialisation de mot de passe pour un admin actif.
-- @ExpiresMinutes : durée de validité (défaut 60 min).
-- Retourne (Token, Email, FirstName) si un compte actif existe, sinon rien.
-- Le message générique côté application évite de révéler l'existence du compte.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0650CreateAdminResetToken
    @Email          NVARCHAR(200),
    @ExpiresMinutes INT = 60
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id INT, @Token UNIQUEIDENTIFIER = NEWID();

    SELECT @Id = Id
    FROM dbo.T900AdminUser
    WHERE Email = @Email
      AND IsActive = 1
      AND IsDeleted = 0;

    IF @Id IS NULL
        RETURN;  -- aucun compte : aucun résultat

    UPDATE dbo.T900AdminUser
    SET ResetToken        = @Token,
        ResetTokenExpires = DATEADD(MINUTE, @ExpiresMinutes, GETDATE())
    WHERE Id = @Id;

    SELECT
        ResetToken AS Token,
        Email,
        FirstName
    FROM dbo.T900AdminUser
    WHERE Id = @Id;
END
