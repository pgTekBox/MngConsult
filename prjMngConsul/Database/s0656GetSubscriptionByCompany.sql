SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0656GetSubscriptionByCompany
-- Retourne l'abonnement courant d'une compagnie (actif en priorité,
-- sinon le plus récent non supprimé) pour l'écran d'édition.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0656GetSubscriptionByCompany
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id,
        CompanyGUID,
        PlanCode,
        PlanName,
        Amount,
        Currency,
        BillingCycle,
        Status,
        StartDate,
        EndDate,
        NextBillingDate,
        IsTrial,
        TrialEndOn
    FROM dbo.T020Subscription
    WHERE CompanyGUID = @CompanyGUID
      AND IsDeleted = 0
    ORDER BY CASE WHEN Status = 'active' THEN 0 ELSE 1 END, CreatedOn DESC;
END
