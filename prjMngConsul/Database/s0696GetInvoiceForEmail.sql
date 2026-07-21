-- =============================================================================
-- s0696GetInvoiceForEmail
--   Retourne les données nécessaires pour envoyer une facture client par
--   courriel : destinataire (Email billing), numéro, GUID (lien PDF public),
--   compagnie émettrice, total et le PDF stocké (octets + type + nom de fichier).
--   Si le PDF n'existe pas encore, l'appelant le génère puis rappelle cette proc.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE dbo.s0696GetInvoiceForEmail
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.Id,
        d.DocumentNumber,
        d.DocumentGUID,
        d.CompanyGUID,
        d.Email,
        d.Total,
        (d.Total - ISNULL((SELECT SUM(rd.MontantImpute)
                           FROM dbo.T141ReglementDocument rd
                           WHERE rd.documentid = d.Id), 0)) AS ResteAPayer,
        d.PdfData,
        d.PdfContentType,
        d.PdfFileName,
        dbo.fCompanyName(d.CompanyGUID) AS CompanyName
    FROM dbo.T060Document d
    WHERE d.Id = @InvoiceId;
END
GO
