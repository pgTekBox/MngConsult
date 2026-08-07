-- Retourne l'adresse @60sec.ca de la compagnie (NULL si non encore attribuee).
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0713GetCompanyMailbox
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Sec60Email FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID;
END
GO
