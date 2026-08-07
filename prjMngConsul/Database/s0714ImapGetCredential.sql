-- Auth IMAP (progIMAP) : retourne le hash BCrypt + l'adresse de boite (Sec60Email)
-- pour un identifiant = courriel de LOGIN (T015User.Email) OU adresse de boite.
-- Appelee en cross-DB depuis MailStore (connexion MailService) : EXEC MngConsul.dbo.s0714...
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0714ImapGetCredential
    @Login NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.PasswordHash, c.Sec60Email
    FROM dbo.T015User u
    JOIN dbo.T010Company c ON c.CompanyGUID = u.CompanyGUID
    WHERE u.IsActive = 1 AND ISNULL(u.IsDeleted, 0) = 0
      AND (u.Email = @Login OR c.Sec60Email = @Login)
      AND c.Sec60Email IS NOT NULL;
END
GO
