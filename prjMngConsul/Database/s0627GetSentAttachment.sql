-- Contenu d'une pièce jointe envoyée (téléchargement) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0627GetSentAttachment
    @AttId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Content, FileName, ContentType
    FROM dbo.T402Attachments WHERE Id = @AttId;
END
GO
