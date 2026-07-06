-- =============================================================================
-- s0631GetPlanByCode
-- Retourne UN forfait T021Plan par Code + BillingCycle (actif + non supprimé).
-- Utilisé par wbfPayment.aspx.vb pour afficher le résumé du forfait choisi.
--
-- Paramètres :
--   @Code         : 'solo', 'comsolo', 'com119'
--   @BillingCycle : 'monthly' (défaut) ou 'annual'
--   @Lang         : fr|en|es (défaut fr) — champs texte dans la langue demandée,
--                   repli fr via COALESCE(NULLIF(col_xx,''),col). Alias inchangés.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0631GetPlanByCode
    @Code         VARCHAR(50),
    @BillingCycle VARCHAR(20) = 'monthly',
    @Lang         VARCHAR(5)  = 'fr'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id,
        Code,
        Name = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(Name_en, ''), Name)
                   WHEN 'es' THEN COALESCE(NULLIF(Name_es, ''), Name)
                   ELSE Name END,
        Description = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(Description_en, ''), Description)
                   WHEN 'es' THEN COALESCE(NULLIF(Description_es, ''), Description)
                   ELSE Description END,
        Tagline = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(Tagline_en, ''), Tagline)
                   WHEN 'es' THEN COALESCE(NULLIF(Tagline_es, ''), Tagline)
                   ELSE Tagline END,
        EmployeeRange = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(EmployeeRange_en, ''), EmployeeRange)
                   WHEN 'es' THEN COALESCE(NULLIF(EmployeeRange_es, ''), EmployeeRange)
                   ELSE EmployeeRange END,
        Amount,
        Currency,
        BillingCycle,
        ProcessorName,
        StripeProductId,
        StripePriceId,
        TrialDays,
        PlanIconCssClass,
        PlanCardCssClass,
        BadgeText = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(BadgeText_en, ''), BadgeText)
                   WHEN 'es' THEN COALESCE(NULLIF(BadgeText_es, ''), BadgeText)
                   ELSE BadgeText END,
        IconSvg,
        Features = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(Features_en, ''), Features)
                   WHEN 'es' THEN COALESCE(NULLIF(Features_es, ''), Features)
                   ELSE Features END,
        IsRecommended,
        DisplayOrder
    FROM dbo.T021Plan
    WHERE Code = @Code
      AND BillingCycle = @BillingCycle
      AND IsActive = 1
      AND IsDeleted = 0;
END
GO
