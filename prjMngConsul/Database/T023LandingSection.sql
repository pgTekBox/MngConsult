-- =============================================================================
-- T023LandingSection
-- Les sections d'une page (hero, problem, solution, ...). Le contenu HTML est
-- porté par langue dans T024LandingSectionContent.
-- La section des forfaits contient le jeton {{PLANS}} dans son contenu, remplacé
-- au rendu par les cartes de T021Plan.
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T023LandingSection', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T023LandingSection
    (
        Id            INT IDENTITY(1,1) NOT NULL,
        PageId        INT               NOT NULL,   -- FK -> T022LandingPage
        Code          NVARCHAR(50)      NOT NULL,   -- clé stable dans la page : hero, problem, ...
        Name          NVARCHAR(200)     NULL,
        DisplayOrder  INT               NOT NULL CONSTRAINT DF_T023LandingSection_DisplayOrder DEFAULT(0),
        IsActive      BIT               NOT NULL CONSTRAINT DF_T023LandingSection_IsActive DEFAULT(1),
        IsDeleted     BIT               NOT NULL CONSTRAINT DF_T023LandingSection_IsDeleted DEFAULT(0),
        CreatedDate   DATETIME          NOT NULL CONSTRAINT DF_T023LandingSection_CreatedDate DEFAULT(GETDATE()),
        ModifiedDate  DATETIME          NULL,
        CONSTRAINT PK_T023LandingSection PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_T023LandingSection_Page_Code UNIQUE (PageId, Code),
        CONSTRAINT FK_T023LandingSection_Page FOREIGN KEY (PageId)
            REFERENCES dbo.T022LandingPage (Id)
    );
END
GO
