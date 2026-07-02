-- =============================================================================
-- s0667GetCompanyBySquareMerchantId
-- Retourne le CompanyGUID de l'abonne associe a un merchant_id Square.
-- Utilise par le webhook pour router l'evenement vers la bonne compagnie.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0667GetCompanyBySquareMerchantId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0667GetCompanyBySquareMerchantId;
GO

CREATE PROCEDURE dbo.s0667GetCompanyBySquareMerchantId
    @SquareMerchantId VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 CompanyGUID
    FROM dbo.T010Company
    WHERE SquareMerchantId = @SquareMerchantId;
END
GO
