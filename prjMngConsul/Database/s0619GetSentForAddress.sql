-- Un envoye, SEULEMENT s'il provient de @Addr (securite) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0619GetSentForAddress
    @Id   INT,
    @Addr NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, [From], Sender, [To], CC, BCC, ReplyTo, Subject,
           HTMLBody, TextBody, Created, SendAt, Sended, ToSend, SendWithSuccess
    FROM dbo.T400Mails
    WHERE Id = @Id AND [From] = @Addr;
END
GO
