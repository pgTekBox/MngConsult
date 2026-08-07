-- IMAP (progIMAP) : supprime un message ENVOYE, seulement s'il provient de @Addr.
-- Supprime d'abord les enfants (T402 pieces jointes, T404 statuts destinataires).
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0622ImapDeleteSent
    @Id   INT,
    @Addr NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.T400Mails WHERE Id = @Id AND [From] = @Addr)
    BEGIN
        DELETE FROM dbo.T402Attachments        WHERE MailId = @Id;
        DELETE FROM dbo.T404MailRecipientStatus WHERE MailId = @Id;
        DELETE FROM dbo.T400Mails               WHERE Id = @Id;
    END
    SELECT @@ROWCOUNT AS Deleted;
END
GO
