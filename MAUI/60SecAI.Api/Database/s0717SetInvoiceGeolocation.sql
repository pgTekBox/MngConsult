/*
    Géolocalisation d'une facture. Ajoute (si besoin) les colonnes Latitude/
    Longitude/GeoCapturedAt à T060Document, puis crée la procédure qui les
    renseigne pour une facture donnée. À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

IF COL_LENGTH('dbo.T060Document', 'Latitude') IS NULL
    ALTER TABLE dbo.T060Document ADD Latitude FLOAT NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'Longitude') IS NULL
    ALTER TABLE dbo.T060Document ADD Longitude FLOAT NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'GeoCapturedAt') IS NULL
    ALTER TABLE dbo.T060Document ADD GeoCapturedAt DATETIME NULL;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0717SetInvoiceGeolocation]
    @InvoiceId INT,
    @Latitude  FLOAT,
    @Longitude FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T060Document
    SET Latitude = @Latitude,
        Longitude = @Longitude,
        GeoCapturedAt = GETDATE()
    WHERE Id = @InvoiceId;
END
GO
