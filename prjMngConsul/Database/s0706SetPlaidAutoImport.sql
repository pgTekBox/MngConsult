-- =============================================================================
-- s0706SetPlaidAutoImport
-- Active (@Enabled=1) ou desactive (@Enabled=0) l'import automatique Plaid
-- pour une compagnie. Utilise par wbfPaymentProcessors (interrupteur).
-- =============================================================================
USE [MngConsul];
GO

CREATE OR ALTER PROCEDURE dbo.s0706SetPlaidAutoImport
    @CompanyGUID UNIQUEIDENTIFIER,
    @Enabled     BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T010Company
    SET PlaidAutoImport = @Enabled
    WHERE CompanyGUID = @CompanyGUID;
END
GO
