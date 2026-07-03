-- s0676GetLandingSectionsForPage : sections d'une page (pour l'éditeur admin).
USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0676GetLandingSectionsForPage
    @PageCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.Id, s.Code, s.Name, s.DisplayOrder
    FROM dbo.T023LandingSection AS s
        INNER JOIN dbo.T022LandingPage AS p
            ON p.Id = s.PageId AND p.Code = @PageCode
    WHERE s.IsActive = 1 AND s.IsDeleted = 0
    ORDER BY s.DisplayOrder, s.Id;
END
GO
