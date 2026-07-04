-- =============================================================================
-- SeedPlanDescriptionLongFromFields_v2.sql
-- Regenere T021Plan.DescriptionLong avec la CARTOUCHE COMPLETE : le <div
-- class="plan-card {PlanCardCssClass}"> (contour + couleurs + variante featured),
-- tout le contenu, ET le bouton <a class="plan-button"> avec le jeton
-- {{INSCRIPTION_URL}} (remplace au rendu par le lien d'inscription du forfait).
--
-- La LandingPage rend desormais DescriptionLong tel quel (aucune structure fixe).
-- ECRASE tous les forfaits mensuels non supprimes (la structure a change).
-- =============================================================================

USE [MngConsul];
GO
SET NOCOUNT ON;

DECLARE @svgAttrs NVARCHAR(400) = N'xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
DECLARE @fsvg NVARCHAR(MAX) = N'<svg ' + @svgAttrs + N'><path d="M20 6 9 17l-5-5"></path></svg>';

DECLARE @Id INT, @Name NVARCHAR(200), @Tagline NVARCHAR(400), @Pill NVARCHAR(200),
        @Desc NVARCHAR(1000), @Amount DECIMAL(18,2), @Badge NVARCHAR(200),
        @IconCss VARCHAR(50), @CardCss VARCHAR(50), @IconSvg NVARCHAR(MAX), @Features NVARCHAR(MAX);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT Id, Name, Tagline, EmployeeRange, Description, Amount, BadgeText,
           PlanIconCssClass, PlanCardCssClass, IconSvg, Features
    FROM dbo.T021Plan
    WHERE IsDeleted = 0 AND BillingCycle = 'monthly';

OPEN cur;
FETCH NEXT FROM cur INTO @Id, @Name, @Tagline, @Pill, @Desc, @Amount, @Badge, @IconCss, @CardCss, @IconSvg, @Features;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Features -> <li>
    DECLARE @feat NVARCHAR(MAX) = REPLACE(ISNULL(@Features, ''), CHAR(13), '');
    WHILE CHARINDEX(CHAR(10)+CHAR(10), @feat) > 0 SET @feat = REPLACE(@feat, CHAR(10)+CHAR(10), CHAR(10));
    SET @feat = TRIM(CHAR(10)+CHAR(9)+' ' FROM @feat);
    SET @feat = REPLACE(REPLACE(REPLACE(@feat,'&','&amp;'),'<','&lt;'),'>','&gt;');
    DECLARE @featHtml NVARCHAR(MAX) = CASE WHEN LEN(@feat)=0 THEN ''
        ELSE '<ul class="plan-features"><li class="plan-feature">'+@fsvg+'<span>'
             + REPLACE(@feat, CHAR(10), '</span></li><li class="plan-feature">'+@fsvg+'<span>')
             + '</span></li></ul>' END;

    DECLARE @badgeHtml NVARCHAR(MAX) = CASE WHEN NULLIF(LTRIM(RTRIM(@Badge)),'') IS NULL THEN ''
        ELSE '<div class="plan-badge-popular">'+REPLACE(REPLACE(REPLACE(@Badge,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</div>' END;

    DECLARE @cardClass NVARCHAR(100) = 'plan-card'
        + CASE WHEN NULLIF(LTRIM(RTRIM(@CardCss)),'') IS NULL THEN '' ELSE ' ' + LTRIM(RTRIM(@CardCss)) END;

    DECLARE @html NVARCHAR(MAX) =
        '<div class="' + @cardClass + '">'
      + @badgeHtml
      + '<div class="plan-icon-circle ' + ISNULL(LTRIM(RTRIM(@IconCss)),'') + '"><svg ' + @svgAttrs + '>' + ISNULL(@IconSvg,'') + '</svg></div>'
      + '<h3>' + ISNULL(@Name,'') + '</h3>'
      + CASE WHEN NULLIF(LTRIM(RTRIM(@Tagline)),'') IS NULL THEN '' ELSE '<p class="plan-tagline">'+@Tagline+'</p>' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(@Pill)),'') IS NULL THEN '' ELSE '<span class="plan-pill">'+@Pill+'</span>' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(@Desc)),'') IS NULL THEN '' ELSE '<p class="plan-desc">'+@Desc+'</p>' END
      + '<div class="plan-price"><span class="amount">'+FORMAT(@Amount,'N2','fr-CA')+' $</span><span class="period">/ mois</span></div>'
      + @featHtml
      + '<a href="{{INSCRIPTION_URL}}" class="plan-button">Commencer gratuitement</a>'
      + '</div>';

    UPDATE dbo.T021Plan SET DescriptionLong = @html, ModifiedOn = GETDATE() WHERE Id = @Id;

    FETCH NEXT FROM cur INTO @Id, @Name, @Tagline, @Pill, @Desc, @Amount, @Badge, @IconCss, @CardCss, @IconSvg, @Features;
END

CLOSE cur;
DEALLOCATE cur;

SELECT Id, Name, LEN(DescriptionLong) AS Longueur, LEFT(DescriptionLong, 90) AS Debut
FROM dbo.T021Plan WHERE IsDeleted = 0 AND BillingCycle = 'monthly' ORDER BY DisplayOrder, Id;
GO
