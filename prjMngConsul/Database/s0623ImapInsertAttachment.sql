-- progIMAP : rattache une PJ / image inline à un courriel sortant (T402Attachments)
-- avec ContentId + ContentDisposition ('attachment' ou 'inline'). base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0623ImapInsertAttachment
    @MailId             INT,
    @FileName           VARCHAR(1000),
    @content            VARBINARY(MAX),
    @ContentType        VARCHAR(200),
    @ContentId          VARCHAR(400) = '',
    @ContentDisposition VARCHAR(200) = 'attachment'
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T402Attachments (MailId, Content, FileName, ContentType, ContentId, ContentDisposition)
    VALUES (@MailId, @content, @FileName, @ContentType, @ContentId, @ContentDisposition);
    -- Marque l'icône trombone seulement pour les vraies pièces jointes (pas les images inline).
    IF @ContentDisposition <> 'inline'
        UPDATE dbo.T400Mails SET HaveAttachment = '<img src="images\att30.png" />' WHERE Id = @MailId;
END
GO
