-- =============================================================================
-- T022LandingPage
-- Les pages du site vitrine (accueil, documentation, blog, contact, ...).
-- Une page contient plusieurs sections (T023LandingSection).
-- IsDefault = 1 pour la page affichée par défaut (accueil) ; les autres sont
-- rendues masquées (class "page hidden") et montrées via le routage JS.
-- =============================================================================

USE [MngConsul];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T022LandingPage', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T022LandingPage
    (
        Id            INT IDENTITY(1,1) NOT NULL,
        Code          NVARCHAR(50)      NOT NULL,   -- clé stable : accueil, documentation, blog, ...
        Name          NVARCHAR(200)     NULL,       -- libellé lisible
        DisplayOrder  INT               NOT NULL CONSTRAINT DF_T022LandingPage_DisplayOrder DEFAULT(0),
        IsDefault     BIT               NOT NULL CONSTRAINT DF_T022LandingPage_IsDefault DEFAULT(0),
        IsActive      BIT               NOT NULL CONSTRAINT DF_T022LandingPage_IsActive DEFAULT(1),
        IsDeleted     BIT               NOT NULL CONSTRAINT DF_T022LandingPage_IsDeleted DEFAULT(0),
        CreatedDate   DATETIME          NOT NULL CONSTRAINT DF_T022LandingPage_CreatedDate DEFAULT(GETDATE()),
        ModifiedDate  DATETIME          NULL,
        CONSTRAINT PK_T022LandingPage PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_T022LandingPage_Code UNIQUE (Code)
    );
END
GO

-- Ajout de IsDefault sur une table déjà existante
IF COL_LENGTH(N'dbo.T022LandingPage', N'IsDefault') IS NULL
BEGIN
    ALTER TABLE dbo.T022LandingPage
        ADD IsDefault BIT NOT NULL CONSTRAINT DF_T022LandingPage_IsDefault DEFAULT(0);
END
GO
