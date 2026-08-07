-- Garantit l'unicite de l'adresse @60sec.ca au niveau BASE.
-- Index filtre (NULL autorises en multiple) -> exige QUOTED_IDENTIFIER ON.
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_T010Company_Sec60Email' AND object_id=OBJECT_ID('dbo.T010Company'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_T010Company_Sec60Email
        ON dbo.T010Company(Sec60Email)
        WHERE Sec60Email IS NOT NULL;
GO
