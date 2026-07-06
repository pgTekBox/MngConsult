-- =============================================================================
-- s0630GetPlansForLanding
-- Retourne les forfaits MENSUELS actifs pour affichage sur LandingPage.aspx.
-- Filtre : IsActive = 1, IsDeleted = 0, BillingCycle = 'monthly'
-- Tri    : DisplayOrder ascendant
--
-- @Lang (fr|en|es, défaut fr) : renvoie les champs texte dans la langue demandée.
--   Repli automatique sur le français si la traduction est NULL/vide (COALESCE).
--   Les alias de colonnes restent identiques (Name, Tagline, ...) pour ne rien
--   changer côté application (RenderPlanCard).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0630GetPlansForLanding
    @Lang VARCHAR(5) = 'fr'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
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
        DescriptionLong = CASE @Lang
                   WHEN 'en' THEN COALESCE(NULLIF(DescriptionLong_en, ''), DescriptionLong)
                   WHEN 'es' THEN COALESCE(NULLIF(DescriptionLong_es, ''), DescriptionLong)
                   ELSE DescriptionLong END,
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
    WHERE IsActive = 1
      AND IsDeleted = 0
      AND BillingCycle = 'monthly'
    ORDER BY DisplayOrder, Id;
END
GO
