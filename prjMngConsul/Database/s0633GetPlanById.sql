SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0633GetPlanById
-- Retourne un forfait complet (tous les champs éditables) par Id.
-- Utilisé par l'écran d'édition wbfPlanEdit.aspx.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0633GetPlanById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Code,
        Name,
        Description,
        DescriptionLong,
        Amount,
        Currency,
        BillingCycle,
        ProcessorName,
        StripeProductId,
        StripePriceId,
        TrialDays,
        MaxUsers,
        MaxClients,
        MaxDocuments,
        MaxStorageMB,
        Features,
        DisplayOrder,
        IsRecommended,
        IsActive,
        Tagline,
        EmployeeRange,
        BadgeText
    FROM dbo.T021Plan
    WHERE Id = @Id
      AND IsDeleted = 0;
END
