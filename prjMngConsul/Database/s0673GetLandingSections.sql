-- =============================================================================
-- s0673GetLandingSections  @PageCode = NULL, @Lang = 'fr'
-- Retourne les sections actives, dans l'ordre (page puis section), avec le HTML
-- de la langue demandée (repli sur 'fr' si absent).
--   @PageCode NULL  -> toutes les pages (rendu de tout le site vitrine)
--   @PageCode fourni -> une seule page
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0673GetLandingSections
    @PageCode NVARCHAR(50) = NULL,
    @Lang     NVARCHAR(5)  = N'fr'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Code         AS PageCode,
        p.IsDefault,
        p.DisplayOrder AS PageOrder,
        s.Id,
        s.Code,
        s.Name,
        s.DisplayOrder,
        COALESCE(c.HtmlContent, cfr.HtmlContent) AS HtmlContent,
        @Lang AS Lang
    FROM dbo.T023LandingSection AS s
        INNER JOIN dbo.T022LandingPage AS p
            ON p.Id = s.PageId
           AND p.IsActive = 1
           AND p.IsDeleted = 0
           AND (@PageCode IS NULL OR p.Code = @PageCode)
        LEFT JOIN dbo.T024LandingSectionContent AS c
            ON c.SectionId = s.Id
           AND c.Lang = @Lang
        LEFT JOIN dbo.T024LandingSectionContent AS cfr
            ON cfr.SectionId = s.Id
           AND cfr.Lang = N'fr'
    WHERE s.IsActive = 1
      AND s.IsDeleted = 0
    ORDER BY p.DisplayOrder, p.Id, s.DisplayOrder, s.Id;
END
GO
