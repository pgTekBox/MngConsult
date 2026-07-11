-- =============================================================================
-- s0687GetCompanyTrialStatus
-- Retourne l'état de l'essai gratuit de l'abonnement actif d'une compagnie.
-- Utilisée par le header (pastille « fin de l'essai ») et par la boîte de
-- bienvenue du tableau de bord (Default.aspx).
--   DaysRemaining : nombre de jours (calendaires) avant TrialEndOn (peut être négatif).
-- =============================================================================
IF OBJECT_ID('dbo.s0687GetCompanyTrialStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0687GetCompanyTrialStatus;
GO

CREATE PROCEDURE dbo.s0687GetCompanyTrialStatus
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        PlanName,
        Status,
        IsTrial,
        TrialEndOn,
        NextBillingDate,
        CASE
            WHEN TrialEndOn IS NOT NULL
            THEN DATEDIFF(DAY, CAST(GETDATE() AS date), CAST(TrialEndOn AS date))
            ELSE NULL
        END AS DaysRemaining
    FROM dbo.T020Subscription
    WHERE CompanyGUID = @CompanyGUID
      AND Status = 'active'
      AND IsDeleted = 0
    ORDER BY CreatedOn DESC;
END
GO
