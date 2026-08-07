-- MISE À JOUR de s1578GetAttachment : renvoie AUSSI ContentId + ContentDisposition
-- pour que SrvAI (patché) reconstruise les images inline en linked resources.
-- Rétro-compatible : SrvAI lit FileName/content par nom, les colonnes en plus sont ignorées.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s1578GetAttachment
    @MailId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Content], [FileName], [ContentType], [ContentId], [ContentDisposition]
    FROM dbo.T402Attachments
    WHERE MailId = @MailId;
END
GO
