SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0313GetSubscriptionForPaiement
-- Retourne les abonnements « en attente de paiement » (Status='Paiement').
-- Le login redirige vers wbfPayment si exactement 1 ligne est retournée.
--
-- CORRECTIF : ne retourne RIEN si la compagnie possède déjà un abonnement
-- actif ou en essai (Status IN 'active','trialing'). Sinon un utilisateur
-- ayant déjà payé restait bloqué sur la page de paiement à cause d'une
-- ancienne ligne 'Paiement' résiduelle.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0313GetSubscriptionForPaiement
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id, CompanyGUID, UserId, PlanCode, PlanName, Amount, Currency, BillingCycle,
        CardLast4, CardBrand, CardHolderName, TransactionId, ProcessorName,
        StartDate, EndDate, NextBillingDate, Status,
        CreatedOn, CreatedBy, ModifiedOn, ModifiedBy, IsDeleted, IsTrial, TrialEndOn
    FROM dbo.T020Subscription t
    WHERE t.CompanyGUID = @CompanyGUID
      AND t.Status = 'Paiement'
      AND ISNULL(t.IsDeleted, 0) = 0
      AND NOT EXISTS (
          SELECT 1
          FROM dbo.T020Subscription a
          WHERE a.CompanyGUID = @CompanyGUID
            AND a.Status IN ('active', 'trialing')
            AND ISNULL(a.IsDeleted, 0) = 0
      );
END
GO
