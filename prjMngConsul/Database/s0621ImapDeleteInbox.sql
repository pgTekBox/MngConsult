-- IMAP (progIMAP) : supprime un message ENTRANT, seulement s'il appartient a @Addr.
-- Supprime d'abord les pieces jointes liees (T991). base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0621ImapDeleteInbox
    @Id   BIGINT,
    @Addr NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.T990SmtpInboundMessage
               WHERE Id = @Id AND CAST(RcptTo AS NVARCHAR(4000)) LIKE '%' + @Addr + '%')
    BEGIN
        DELETE FROM dbo.T991SmtpInboundAttachment WHERE SmtpInboundMessageId = @Id;
        DELETE FROM dbo.T990SmtpInboundMessage     WHERE Id = @Id;
    END
    SELECT @@ROWCOUNT AS Deleted;
END
GO
