SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- s0699GetStripeSupplierCount : nombre de fournisseurs (Type 2 ou 3) d'une
-- compagnie ayant un compte Stripe Connect (StripeAccountId non vide).
-- Utilisé par la pastille du header.
-- =============================================================
CREATE OR ALTER PROCEDURE [dbo].[s0699GetStripeSupplierCount]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*) AS StripeSupplierCount
    FROM dbo.T050Party
    WHERE CompanyGUID = @CompanyGUID
      AND [Type] IN (2, 3)
      AND StripeAccountId IS NOT NULL
      AND StripeAccountId <> '';
END
GO
