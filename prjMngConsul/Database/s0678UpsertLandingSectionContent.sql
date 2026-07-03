-- s0678UpsertLandingSectionContent : enregistre le HTML d'une section pour une
-- langue (ne touche pas aux métadonnées de page/section). Pour l'éditeur admin.
USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0678UpsertLandingSectionContent
    @PageCode    NVARCHAR(50),
    @SectionCode NVARCHAR(50),
    @Lang        NVARCHAR(5),
    @HtmlContent NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SectionId INT;
    SELECT @SectionId = s.Id
    FROM dbo.T023LandingSection AS s
        INNER JOIN dbo.T022LandingPage AS p
            ON p.Id = s.PageId AND p.Code = @PageCode
    WHERE s.Code = @SectionCode;

    IF @SectionId IS NULL
    BEGIN
        RAISERROR('Section introuvable pour cette page.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.T024LandingSectionContent WHERE SectionId = @SectionId AND Lang = @Lang)
        UPDATE dbo.T024LandingSectionContent
           SET HtmlContent = @HtmlContent, ModifiedDate = GETDATE()
         WHERE SectionId = @SectionId AND Lang = @Lang;
    ELSE
        INSERT INTO dbo.T024LandingSectionContent (SectionId, Lang, HtmlContent)
        VALUES (@SectionId, @Lang, @HtmlContent);
END
GO
