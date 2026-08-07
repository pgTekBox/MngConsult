-- Contenu d'une pièce jointe entrante (téléchargement) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0625GetInboundAttachment
    @AttId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Content, FileName, ContentType
    FROM dbo.T991SmtpInboundAttachment WHERE Id = @AttId;
END
GO
