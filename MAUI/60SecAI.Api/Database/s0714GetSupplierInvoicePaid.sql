/*
    Montant déjà payé pour une facture fournisseur.
    Somme des imputations de règlements (DECAISSEMENT), hors règlements annulés.
    Utilisé par l'API mobile 60SecAI (détail d'une facture fournisseur → Payé / Reste à payer).
    Lecture seule. À exécuter sur la base MngConsul.
    Miroir de s0712GetInvoicePaid (côté client / ENCAISSEMENT).
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0714GetSupplierInvoicePaid]
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(SUM(rd.[MontantImpute]), 0) AS DejaPaye
    FROM [dbo].[T141ReglementDocument] rd
    INNER JOIN [dbo].[T140Reglement] r ON r.[Id] = rd.[ReglementId]
    WHERE rd.[DocumentId] = @InvoiceId
      AND r.[Statut] <> 'ANNULE'
      AND r.[Sens]   = 'DECAISSEMENT';
END
GO
