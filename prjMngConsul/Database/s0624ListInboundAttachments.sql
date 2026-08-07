-- Pièces jointes d'un courriel ENTRANT (métadonnées) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0624ListInboundAttachments
    @Id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, FileName, ContentType,
           ISNULL(FileSizeBytes, DATALENGTH(Content)) AS SizeBytes,
           ISNULL(IsInline, 0) AS IsInline
    FROM dbo.T991SmtpInboundAttachment
    WHERE SmtpInboundMessageId = @Id
    ORDER BY Id;
END
GO
