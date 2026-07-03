-- =============================================================================
-- T024LandingSectionContent
-- Le contenu HTML d'une section, par langue (fr / en / es).
-- Une ligne = (section, langue). Le rendu retombe sur 'fr' si la langue
-- demandée n'existe pas encore.
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T024LandingSectionContent', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T024LandingSectionContent
    (
        Id            INT IDENTITY(1,1) NOT NULL,
        SectionId     INT               NOT NULL,   -- FK -> T023LandingSection
        Lang          NVARCHAR(5)       NOT NULL,   -- 'fr', 'en', 'es'
        HtmlContent   NVARCHAR(MAX)     NULL,
        CreatedDate   DATETIME          NOT NULL CONSTRAINT DF_T024LandingSectionContent_CreatedDate DEFAULT(GETDATE()),
        ModifiedDate  DATETIME          NULL,
        CONSTRAINT PK_T024LandingSectionContent PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_T024LandingSectionContent_Section_Lang UNIQUE (SectionId, Lang),
        CONSTRAINT FK_T024LandingSectionContent_Section FOREIGN KEY (SectionId)
            REFERENCES dbo.T023LandingSection (Id)
    );
END
GO
