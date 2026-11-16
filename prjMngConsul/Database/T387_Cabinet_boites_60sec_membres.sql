-- =============================================================================
-- T387 — Boîtes courriel @60sec.ca des membres d'un cabinet comptable
--   s1012CreerBoitesCabinet : crée, si elle n'existe pas, la boîte
--       MailService.SmtpLocalRecipient de chaque membre actif du cabinet dont
--       le courriel de connexion finit par @60sec.ca. Mot de passe de la boîte =
--       mot de passe actuel du compte (même format BCrypt) pour un compte actif ;
--       aucun pour un compte en attente d'activation (posé à l'activation).
--       @CabinetId NULL = tous les cabinets (exécution ponctuelle ci-dessous).
--       Renvoie les boîtes créées.
--   s0681ResetUserPasswordByToken : quand un membre change son mot de passe
--       (« Mot de passe oublié » ou courriel envoyé par l'administrateur), sa
--       boîte @60sec.ca reçoit le même mot de passe.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s1012CreerBoitesCabinet
    @CabinetId int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @crees TABLE (Email nvarchar(200), AvecMotDePasse bit);

    INSERT INTO MailService.dbo.SmtpLocalRecipient (Email, IsActive, CreatedAtUtc, PasswordHash, PasswordSetOn)
    OUTPUT inserted.Email, CASE WHEN inserted.PasswordHash IS NULL THEN 0 ELSE 1 END INTO @crees
    SELECT x.Email, 1, SYSUTCDATETIME(), x.Hash, CASE WHEN x.Hash IS NULL THEN NULL ELSE SYSUTCDATETIME() END
    FROM (
        SELECT DISTINCT LOWER(LTRIM(RTRIM(u.Email))) AS Email,
               CASE WHEN u.IsActive = 1 AND u.ActivationToken IS NULL THEN u.PasswordHash END AS Hash
        FROM dbo.T332CabinetMembre m
        JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0
        WHERE m.IsActive = 1
          AND (@CabinetId IS NULL OR m.CabinetId = @CabinetId)
          AND u.Email LIKE '%@60sec.ca'
    ) x
    WHERE NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient r WHERE LTRIM(RTRIM(r.Email)) = x.Email);

    SELECT Email, AvecMotDePasse FROM @crees ORDER BY Email;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0681ResetUserPasswordByToken
    @Token        UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @email nvarchar(200) = (SELECT Email FROM dbo.T015User
                                    WHERE ResetToken = @Token AND ResetTokenExpires IS NOT NULL
                                      AND ResetTokenExpires > GETDATE() AND IsActive = 1 AND IsDeleted = 0);

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

    DECLARE @n int = @@ROWCOUNT;

    -- T387 : la boîte @60sec.ca d'un membre de cabinet suit le même mot de passe
    IF @n = 1 AND @email LIKE '%@60sec.ca'
       AND EXISTS (SELECT 1 FROM dbo.T015User u JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
                   WHERE u.Email = @email AND u.IsDeleted = 0)
        UPDATE MailService.dbo.SmtpLocalRecipient
        SET PasswordHash = @PasswordHash, PasswordSetOn = SYSUTCDATETIME()
        WHERE LTRIM(RTRIM(Email)) = @email;

    SELECT @n AS Affected;
END
GO

-- Création ponctuelle : toutes les boîtes manquantes des membres de cabinet
EXEC dbo.s1012CreerBoitesCabinet NULL;
GO
