-- =============================================================================
-- s0674UpsertLandingSection
--   @PageCode, @PageName, @SectionCode, @SectionName, @DisplayOrder, @Lang, @HtmlContent
-- Upsert complet en un appel : garantit la page (par Code), la section (par
-- Page+Code) et enregistre le contenu HTML pour la langue donnée.
-- Sert au seed initial et à un futur éditeur admin.
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0674UpsertLandingSection
    @PageCode     NVARCHAR(50),
    @PageName     NVARCHAR(200),
    @SectionCode  NVARCHAR(50),
    @SectionName  NVARCHAR(200),
    @DisplayOrder INT,
    @Lang         NVARCHAR(5),
    @HtmlContent  NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Page
    DECLARE @PageId INT;
    SELECT @PageId = Id FROM dbo.T022LandingPage WHERE Code = @PageCode;
    IF @PageId IS NULL
    BEGIN
        INSERT INTO dbo.T022LandingPage (Code, Name) VALUES (@PageCode, @PageName);
        SET @PageId = SCOPE_IDENTITY();
    END

    -- 2) Section (dans la page)
    DECLARE @SectionId INT;
    SELECT @SectionId = Id
      FROM dbo.T023LandingSection
     WHERE PageId = @PageId AND Code = @SectionCode;
    IF @SectionId IS NULL
    BEGIN
        INSERT INTO dbo.T023LandingSection (PageId, Code, Name, DisplayOrder)
        VALUES (@PageId, @SectionCode, @SectionName, @DisplayOrder);
        SET @SectionId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T023LandingSection
           SET Name = @SectionName,
               DisplayOrder = @DisplayOrder,
               ModifiedDate = GETDATE(),
               IsDeleted = 0
         WHERE Id = @SectionId;
    END

    -- 3) Contenu (par langue)
    IF EXISTS (SELECT 1 FROM dbo.T024LandingSectionContent WHERE SectionId = @SectionId AND Lang = @Lang)
        UPDATE dbo.T024LandingSectionContent
           SET HtmlContent = @HtmlContent,
               ModifiedDate = GETDATE()
         WHERE SectionId = @SectionId AND Lang = @Lang;
    ELSE
        INSERT INTO dbo.T024LandingSectionContent (SectionId, Lang, HtmlContent)
        VALUES (@SectionId, @Lang, @HtmlContent);
END
GO
