-- Adresses locales acceptees (@60sec.ca) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0615ListLocalRecipients
AS
BEGIN
    SET NOCOUNT ON;
    SELECT LTRIM(RTRIM(Email)) AS Email
    FROM dbo.SmtpLocalRecipient
    WHERE IsActive = 1
    ORDER BY Email;
END
GO
