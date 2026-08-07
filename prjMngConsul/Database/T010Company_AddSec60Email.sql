-- Adresse courriel @60sec.ca propre a chaque compagnie (boite du service 60Sec).
USE [MngConsul];
GO
IF COL_LENGTH('dbo.T010Company','Sec60Email') IS NULL
    ALTER TABLE dbo.T010Company ADD Sec60Email VARCHAR(150) NULL;
GO
