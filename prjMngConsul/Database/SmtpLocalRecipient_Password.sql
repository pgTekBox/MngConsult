-- =============================================================================
-- Mot de passe par compte de courriel (MailService.dbo.SmtpLocalRecipient)
--   Chaque boîte locale porte son propre hash BCrypt. Utilisé par progIMAP
--   pour l'auth IMAP/SMTP : la boîte servie = l'adresse elle-même.
--   s0628ImapGetLocalCredential   : lecture (hash + email) pour progIMAP
--   s0629SetLocalRecipientPassword: écriture du hash (console Admin) ; '' => retire
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.SmtpLocalRecipient', 'PasswordHash') IS NULL
    ALTER TABLE dbo.SmtpLocalRecipient ADD PasswordHash NVARCHAR(255) NULL;
GO
IF COL_LENGTH('dbo.SmtpLocalRecipient', 'PasswordSetOn') IS NULL
    ALTER TABLE dbo.SmtpLocalRecipient ADD PasswordSetOn DATETIME2 NULL;
GO

CREATE OR ALTER PROCEDURE dbo.s0628ImapGetLocalCredential
    @Login NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PasswordHash, Email
    FROM dbo.SmtpLocalRecipient
    WHERE Email = @Login
      AND IsActive = 1
      AND PasswordHash IS NOT NULL AND PasswordHash <> '';
END
GO

CREATE OR ALTER PROCEDURE dbo.s0629SetLocalRecipientPassword
    @Email        NVARCHAR(320),
    @PasswordHash NVARCHAR(255)   -- NULL ou '' pour retirer le mot de passe
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.SmtpLocalRecipient
       SET PasswordHash  = NULLIF(@PasswordHash, ''),
           PasswordSetOn = CASE WHEN NULLIF(@PasswordHash, '') IS NULL
                                THEN NULL ELSE SYSUTCDATETIME() END
     WHERE Email = @Email;
    SELECT @@ROWCOUNT AS Affected;
END
GO
