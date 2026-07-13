SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0654GetCompanyById (édition admin)
-- Name/LegalName/Structure/BusinessNumber/NEQ proviennent de T101 (source unique) :
--   Name←TRADE_NAME, LegalName←LEGAL_NAME, Structure←STRUCTURE,
--   BusinessNumber←FED_BN, NEQ←NEQ. CompanyCode reste l'identité (T010Company).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0654GetCompanyById
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CompanyGUID,
        CompanyCode,
        COALESCE(dbo.fParamS(CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(CompanyGUID)) AS Name,
        dbo.fParamS(CompanyGUID, 'LEGAL_NAME')     AS LegalName,
        dbo.fParamS(CompanyGUID, 'STRUCTURE')      AS Structure,
        dbo.fParamS(CompanyGUID, 'FED_BN')         AS BusinessNumber,
        dbo.fParamS(CompanyGUID, 'NEQ')            AS NEQ
    FROM dbo.T010Company
    WHERE CompanyGUID = @CompanyGUID;
END
GO
