SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0654GetCompanyById
-- Retourne les champs cœur d'une compagnie (pour l'édition admin).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0654GetCompanyById
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CompanyGUID,
        CompanyCode,
        Name,
        LegalName,
        Structure,
        BusinessNumber,
        NEQ
    FROM dbo.T010Company
    WHERE CompanyGUID = @CompanyGUID;
END
