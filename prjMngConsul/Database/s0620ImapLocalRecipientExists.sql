-- IMAP (progIMAP) : l'adresse est-elle une boite locale active ? (base MailService)
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0620ImapLocalRecipientExists
    @Addr NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(CASE WHEN EXISTS (
        SELECT 1 FROM dbo.SmtpLocalRecipient
        WHERE LTRIM(RTRIM(Email)) = @Addr AND IsActive = 1
    ) THEN 1 ELSE 0 END AS INT) AS IsLocal;
END
GO
