-- Un courriel sortant (corps HTML/texte) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0614GetSentMail
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, [From], Sender, [To], CC, BCC, ReplyTo, Subject,
           HTMLBody, TextBody, Created, SendAt, Sended, ToSend, SendWithSuccess
    FROM dbo.T400Mails
    WHERE Id = @Id;
END
GO
