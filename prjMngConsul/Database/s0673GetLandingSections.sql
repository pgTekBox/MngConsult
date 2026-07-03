-- =============================================================================
-- s0673GetLandingSections  @PageCode, @Lang
-- Retourne les sections actives d'une page, dans l'ordre d'affichage, avec le
-- HTML de la langue demandée. Si la langue demandée n'a pas de contenu pour la
-- section, on retombe sur le français ('fr').
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0673GetLandingSections
    @PageCode NVARCHAR(50),
    @Lang     NVARCHAR(5) = N'fr'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.Code,
        s.Name,
        s.DisplayOrder,
        COALESCE(c.HtmlContent, cfr.HtmlContent) AS HtmlContent,
        @Lang AS Lang
    FROM dbo.T023LandingSection AS s
        INNER JOIN dbo.T022LandingPage AS p
            ON p.Id = s.PageId
           AND p.Code = @PageCode
           AND p.IsActive = 1
           AND p.IsDeleted = 0
        LEFT JOIN dbo.T024LandingSectionContent AS c
            ON c.SectionId = s.Id
           AND c.Lang = @Lang
        LEFT JOIN dbo.T024LandingSectionContent AS cfr
            ON cfr.SectionId = s.Id
           AND cfr.Lang = N'fr'
    WHERE s.IsActive = 1
      AND s.IsDeleted = 0
    ORDER BY s.DisplayOrder, s.Id;
END
GO
