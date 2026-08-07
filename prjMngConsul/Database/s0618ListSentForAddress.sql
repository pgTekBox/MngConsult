-- Envoyes DEPUIS une adresse (@60sec.ca) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0618ListSentForAddress
    @Addr NVARCHAR(320),
    @Top  INT = 300
AS
BEGIN
    SET NOCOUNT ON;
    IF @Addr IS NULL OR @Addr = '' RETURN;
    SELECT TOP (@Top)
        Id, [From], [To], CC, Subject, Created, SendAt, Sended,
        ToSend, SendWithSuccess, HaveAttachment
    FROM dbo.T400Mails
    WHERE ISNULL(SMTPMail,0) = 0 AND [From] = @Addr
    ORDER BY Id DESC;
END
GO
