-- =============================================================================
-- T417 : synchronisation des prix des forfaits depuis Stripe
-- Bouton « Synchroniser avec Stripe » de Sec60Admin › Forfaits (wbfPlans).
--   s1038GetPlansForStripeSync  : forfaits non supprimés avec leurs id Stripe
--   s1039UpdatePlanFromStripe   : reporte montant, devise et Product Id lus dans Stripe
-- Stripe est la référence de ce qui est facturé : la base suit Stripe, jamais l'inverse.
-- =============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s1038GetPlansForStripeSync
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Code, Name, Amount, Currency, BillingCycle, IsActive,
           StripeProductId, StripePriceId
    FROM dbo.T021Plan
    WHERE IsDeleted = 0
    ORDER BY DisplayOrder, BillingCycle, Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1039UpdatePlanFromStripe
    @Id              INT,
    @Amount          DECIMAL(10, 2),
    @Currency        VARCHAR(10),
    @StripeProductId VARCHAR(50)  = NULL,
    @ModifiedBy      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T021Plan
       SET Amount          = @Amount,
           Currency        = UPPER(@Currency),
           StripeProductId = COALESCE(NULLIF(@StripeProductId, ''), StripeProductId),
           ModifiedOn      = GETDATE(),
           ModifiedBy      = @ModifiedBy
     WHERE Id = @Id
       AND IsDeleted = 0;
END
GO
