-- Attribue (si absente) une adresse @60sec.ca unique a la compagnie :
--   slug du nom commercial, deduplique, ecrit dans T010Company.Sec60Email
--   ET enregistre l'adresse locale dans MailService.dbo.SmtpLocalRecipient
--   (sinon le MTA SrvAI n'accepte pas le courrier entrant). Idempotent.
-- Retourne l'adresse (colonne Email).
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0712AssignMailbox
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cur VARCHAR(150) = (SELECT Sec60Email FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID);
    IF @cur IS NOT NULL AND @cur <> ''
    BEGIN
        -- s'assurer que l'adresse locale est bien enregistree
        IF NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @cur)
            INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc) VALUES(@cur, 1, SYSUTCDATETIME());
        SELECT @cur AS Email;
        RETURN;
    END

    DECLARE @trade NVARCHAR(200) =
        (SELECT TOP 1 v.sVal FROM dbo.T101ParamValues v
         JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
         WHERE v.CompanyGUID = @CompanyGUID AND p.ShortName = 'TRADE_NAME');

    DECLARE @base VARCHAR(100) = dbo.fnSlugify(@trade);
    DECLARE @cand VARCHAR(120) = @base, @email VARCHAR(150), @n INT = 1;

    WHILE 1 = 1
    BEGIN
        SET @email = @cand + '@60sec.ca';
        IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE Sec60Email = @email)
           AND NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @email)
            BREAK;
        SET @n = @n + 1;
        SET @cand = @base + '-' + CAST(@n AS VARCHAR(10));
    END

    UPDATE dbo.T010Company SET Sec60Email = @email WHERE CompanyGUID = @CompanyGUID;
    INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc) VALUES(@email, 1, SYSUTCDATETIME());

    SELECT @email AS Email;
END
GO
