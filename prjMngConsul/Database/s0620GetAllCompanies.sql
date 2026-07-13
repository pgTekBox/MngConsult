SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0620GetAllCompanies (console admin — sélecteur de compagnie)
-- Name = paramètre TRADE_NAME (T101), repli LEGAL_NAME/T010Company.Name via fCompanyName.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0620GetAllCompanies
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CompanyGUID,
        COALESCE(dbo.fParamS(CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(CompanyGUID)) AS Name
    FROM dbo.T010Company
    ORDER BY Name;
END
GO
