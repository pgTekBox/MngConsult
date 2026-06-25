SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0655SaveCompany
-- Met à jour les champs cœur d'une compagnie (édition admin).
-- La création de compagnie se fait via l'inscription, pas ici.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0655SaveCompany
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Name           NVARCHAR(200),
    @LegalName      NVARCHAR(200) = NULL,
    @CompanyCode    NVARCHAR(50)  = NULL,
    @Structure      NVARCHAR(50)  = NULL,
    @BusinessNumber NVARCHAR(50)  = NULL,
    @NEQ            NVARCHAR(50)  = NULL,
    @ModifiedBy     NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T010Company
    SET Name           = @Name,
        LegalName      = @LegalName,
        CompanyCode    = @CompanyCode,
        Structure      = @Structure,
        BusinessNumber = @BusinessNumber,
        NEQ            = @NEQ,
        ModifiedOn     = GETDATE(),
        ModifiedBy     = @ModifiedBy
    WHERE CompanyGUID = @CompanyGUID;
END
