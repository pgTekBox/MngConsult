-- Pièces jointes d'un courriel ENVOYÉ (métadonnées) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0626ListSentAttachments
    @MailId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, FileName, ContentType,
           DATALENGTH(Content) AS SizeBytes,
           ISNULL(ContentDisposition, 'attachment') AS ContentDisposition
    FROM dbo.T402Attachments
    WHERE MailId = @MailId
    ORDER BY Id;
END
GO
