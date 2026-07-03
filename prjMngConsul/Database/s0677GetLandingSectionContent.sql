-- s0677GetLandingSectionContent : contenu brut d'une section pour une langue
-- (SANS repli sur fr : l'admin voit vide si la langue n'est pas traduite).
USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0677GetLandingSectionContent
    @PageCode    NVARCHAR(50),
    @SectionCode NVARCHAR(50),
    @Lang        NVARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.HtmlContent
    FROM dbo.T023LandingSection AS s
        INNER JOIN dbo.T022LandingPage AS p
            ON p.Id = s.PageId AND p.Code = @PageCode
        LEFT JOIN dbo.T024LandingSectionContent AS c
            ON c.SectionId = s.Id AND c.Lang = @Lang
    WHERE s.Code = @SectionCode;
END
GO
