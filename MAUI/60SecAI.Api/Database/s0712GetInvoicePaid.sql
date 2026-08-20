/*
    Montant déjà encaissé (Payé) pour une facture client.
    Somme des imputations de règlements (ENCAISSEMENT), hors règlements annulés.
    Utilisé par l'API mobile 60SecAI (détail d'une facture → Payé / Reste à payer).
    Lecture seule. À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0712GetInvoicePaid]
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(SUM(rd.[MontantImpute]), 0) AS DejaRecu
    FROM [dbo].[T141ReglementDocument] rd
    INNER JOIN [dbo].[T140Reglement] r ON r.[Id] = rd.[ReglementId]
    WHERE rd.[DocumentId] = @InvoiceId
      AND r.[Statut] <> 'ANNULE'
      AND r.[Sens]   = 'ENCAISSEMENT';
END
GO
