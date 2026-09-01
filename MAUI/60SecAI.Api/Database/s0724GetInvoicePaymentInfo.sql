-- =============================================================================
-- s0724GetInvoicePaymentInfo
--   Données minimales pour générer un lien de paiement Square et l'envoyer
--   (courriel, téléphone, solde restant, numéro, compagnie). À exécuter sur MngConsul.
-- =============================================================================
USE MngConsul;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0724GetInvoicePaymentInfo
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.Id,
        d.DocumentNumber,
        d.CompanyGUID,
        d.Email,
        d.Phone,
        d.Total,
        (d.Total - ISNULL((SELECT SUM(rd.MontantImpute)
                           FROM dbo.T141ReglementDocument rd
                           WHERE rd.documentid = d.Id), 0)) AS ResteAPayer,
        dbo.fCompanyName(d.CompanyGUID) AS CompanyName
    FROM dbo.T060Document d
    WHERE d.Id = @InvoiceId;
END
GO
