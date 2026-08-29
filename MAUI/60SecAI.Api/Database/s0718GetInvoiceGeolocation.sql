/*
    Renvoie la géolocalisation (Latitude/Longitude) d'une facture, pour afficher
    un lien carte dans le détail. Lecture seule. À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0718GetInvoiceGeolocation]
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Latitude], [Longitude]
    FROM dbo.T060Document
    WHERE [Id] = @InvoiceId;
END
GO
