-- =============================================================================
-- s0705GetPlaidAutoImport
-- Retourne l'etat de l'import automatique Plaid d'une compagnie (BIT).
-- Utilise par wbfPaymentProcessors (etat de l'interrupteur).
-- =============================================================================
USE [MngConsul];
GO

CREATE OR ALTER PROCEDURE dbo.s0705GetPlaidAutoImport
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(PlaidAutoImport, 1) AS PlaidAutoImport
    FROM dbo.T010Company
    WHERE CompanyGUID = @CompanyGUID;
END
GO
