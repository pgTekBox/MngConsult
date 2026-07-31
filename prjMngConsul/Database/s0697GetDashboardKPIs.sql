SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- s0697GetDashboardKPIs
-- Renvoie les 4 indicateurs du tableau de bord (Default.aspx) pour une compagnie :
--   CustomerCount        : nombre de clients          (T050Party, Type 1 ou 3)
--   SupplierInvoiceCount : nombre de factures fournisseur (T060Document, DocumentTypeId 2 ou 5)
--   ProductCount         : nombre de produits         (T075Products)
--   RevenueMonth         : revenu du mois courant     (factures clients comptabilisées, DocumentTypeId 1)
-- =============================================================
CREATE OR ALTER PROCEDURE [dbo].[s0697GetDashboardKPIs]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    DECLARE @NextMonth  DATE = DATEADD(MONTH, 1, @MonthStart);

    SELECT
        (SELECT COUNT(*)
           FROM dbo.T050Party
          WHERE CompanyGUID = @CompanyGUID
            AND [Type] IN (1, 3))                                   AS CustomerCount,

        (SELECT COUNT(*)
           FROM dbo.T060Document
          WHERE CompanyGUID = @CompanyGUID
            AND DocumentTypeId IN (2, 5))                           AS SupplierInvoiceCount,

        (SELECT COUNT(*)
           FROM dbo.T075Products
          WHERE CompanyGUID = @CompanyGUID)                        AS ProductCount,

        (SELECT ISNULL(SUM(ISNULL(d.Total, 0)), 0)
           FROM dbo.T060Document d
          WHERE d.CompanyGUID = @CompanyGUID
            AND d.DocumentTypeId = 1
            AND d.ComptabilisationStatus = 'COMPTABILISE'
            AND d.DocumentDate >= @MonthStart
            AND d.DocumentDate <  @NextMonth)                       AS RevenueMonth;
END
GO
