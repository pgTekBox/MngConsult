-- Liste les courriels sortants (envoyes / en file) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0613ListSentMail
    @Top INT = 300
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        Id, [From], [To], CC, Subject, Created, SendAt, Sended,
        ToSend, SendWithSuccess, HaveAttachment
    FROM dbo.T400Mails
    WHERE ISNULL(SMTPMail,0) = 0
    ORDER BY Id DESC;
END
GO
