-- ============================================================================
-- Procédure : s0115GetInvoiceForPdf
-- Description :
--   Retourne l'entête + les lignes d'une facture pour la génération du PDF.
--   MODIF : ajoute les informations de la COMPAGNIE émettrice (nom légal,
--   adresse, téléphone, courriel, numéros de taxe, logo) lues depuis les
--   paramètres par compagnie (T101 via dbo.fParamS / dbo.fCompanyName) et
--   depuis T010Company pour le logo. Ainsi le PDF n'utilise plus d'infos
--   codées en dur.
-- ============================================================================
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE [dbo].[s0115GetInvoiceForPdf]
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Table 1 : entête de facture + infos client + infos compagnie émettrice
    SELECT
        d.Id,
        d.DocumentNumber,
        d.DocumentDate,
        d.DueDate,
        d.Name,
        d.DisplayName,
        d.Address1,
        d.Address2,
        d.City,
        d.State,
        d.Country,
        d.PostalCode,
        d.Phone,
        d.Email,
        d.SubTotal,
        d.TPS,
        d.TVQ,
        d.Total,
        d.ComptabilisationStatus,
        (d.Total - ISNULL((
            SELECT SUM([MontantImpute])
            FROM [T141ReglementDocument]
            WHERE documentid = d.Id
        ), 0)) AS ResteAPayer,

        -- === Compagnie émettrice (paramètres par compagnie) ===
        d.CompanyGUID,
        dbo.fCompanyName(d.CompanyGUID)              AS CoName,
        dbo.fParamS(d.CompanyGUID, 'TRADE_NAME')     AS CoTradeName,
        dbo.fParamS(d.CompanyGUID, 'ADDR1')          AS CoAddr1,
        dbo.fParamS(d.CompanyGUID, 'ADDR2')          AS CoAddr2,
        dbo.fParamS(d.CompanyGUID, 'CITY')           AS CoCity,
        dbo.fParamS(d.CompanyGUID, 'PROVINCE')       AS CoProvince,
        dbo.fParamS(d.CompanyGUID, 'POSTAL')         AS CoPostal,
        dbo.fParamS(d.CompanyGUID, 'COUNTRY')        AS CoCountry,
        dbo.fParamS(d.CompanyGUID, 'PHONE')          AS CoPhone,
        dbo.fParamS(d.CompanyGUID, 'MAIL_FROM_EMAIL') AS CoEmail,
        dbo.fParamS(d.CompanyGUID, 'GST_NO')         AS CoGstNo,
        dbo.fParamS(d.CompanyGUID, 'QST_NO')         AS CoQstNo,
        dbo.fParamS(d.CompanyGUID, 'HST_NO')         AS CoHstNo,
        dbo.fParamS(d.CompanyGUID, 'PDF_PAYMENT_TERMS') AS CoPaymentTerms,
        dbo.fParamS(d.CompanyGUID, 'PDF_NOTES')      AS CoNotes,
        (SELECT TOP 1 c.Logo FROM dbo.T010Company c
          WHERE c.CompanyGUID = d.CompanyGUID)       AS CoLogo

    FROM dbo.T060Document d
    WHERE d.Id = @InvoiceId;

    -- Table 2 : lignes de facture
    SELECT
        l.Id,
        l.Ordre,
        ISNULL(p.Name, '') AS ProductName,
        l.[Description],
        l.Qty,
        l.UnitPrice,
        l.Amount
    FROM dbo.T061DocumentLine l
    LEFT JOIN dbo.T075Products p ON p.Id = l.ProductId
    WHERE l.DocumentId = @InvoiceId
    ORDER BY l.Ordre, l.Id;
END;
GO
