-- s0675GetLandingPages : liste des pages du site vitrine (pour l'éditeur admin).
USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0675GetLandingPages
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Code, Name, DisplayOrder, IsDefault
    FROM dbo.T022LandingPage
    WHERE IsActive = 1 AND IsDeleted = 0
    ORDER BY DisplayOrder, Id;
END
GO
