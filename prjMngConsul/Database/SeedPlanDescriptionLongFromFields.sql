-- =============================================================================
-- SeedPlanDescriptionLongFromFields.sql
-- Migration ponctuelle : reconstitue dans T021Plan.DescriptionLong le HTML
-- complet de l'ancienne cartouche (badge, icone, nom, tagline, pill, desc,
-- prix formate, liste des features) a partir des champs structures existants.
--
-- Contexte : la LandingPage rend desormais TOUTE la cartouche depuis
-- DescriptionLong (editee via RadEditor cote admin). Les classes CSS d'origine
-- sont conservees, donc ce HTML redonne exactement l'apparence actuelle.
--
-- Ne touche QUE les forfaits mensuels affiches, non supprimes, dont
-- DescriptionLong est vide (re-executable sans ecraser un contenu deja saisi).
-- =============================================================================

USE [MngConsul];
GO
SET NOCOUNT ON;

DECLARE @svgAttrs NVARCHAR(400) =
    N'xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
DECLARE @fsvg NVARCHAR(MAX) = N'<svg ' + @svgAttrs + N'><path d="M20 6 9 17l-5-5"></path></svg>';

DECLARE @Id INT, @Name NVARCHAR(200), @Tagline NVARCHAR(400), @Pill NVARCHAR(200),
        @Desc NVARCHAR(1000), @Amount DECIMAL(18,2), @Badge NVARCHAR(200),
        @IconCss VARCHAR(50), @IconSvg NVARCHAR(MAX), @Features NVARCHAR(MAX);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT Id, Name, Tagline, EmployeeRange, Description, Amount, BadgeText,
           PlanIconCssClass, IconSvg, Features
    FROM dbo.T021Plan
    WHERE IsDeleted = 0
      AND BillingCycle = 'monthly'
      AND (DescriptionLong IS NULL OR LTRIM(RTRIM(DescriptionLong)) = '');

OPEN cur;
FETCH NEXT FROM cur INTO @Id, @Name, @Tagline, @Pill, @Desc, @Amount, @Badge, @IconCss, @IconSvg, @Features;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- ---- Features -> <li> (encode &<>, enleve CR, collapse et trim les sauts) ----
    DECLARE @feat NVARCHAR(MAX) = REPLACE(ISNULL(@Features, ''), CHAR(13), '');
    WHILE CHARINDEX(CHAR(10) + CHAR(10), @feat) > 0
        SET @feat = REPLACE(@feat, CHAR(10) + CHAR(10), CHAR(10));
    SET @feat = TRIM(CHAR(10) + CHAR(9) + ' ' FROM @feat);
    SET @feat = REPLACE(REPLACE(REPLACE(@feat, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');

    DECLARE @featHtml NVARCHAR(MAX) =
        CASE WHEN LEN(@feat) = 0 THEN ''
             ELSE '<ul class="plan-features"><li class="plan-feature">' + @fsvg + '<span>'
                  + REPLACE(@feat, CHAR(10), '</span></li><li class="plan-feature">' + @fsvg + '<span>')
                  + '</span></li></ul>'
        END;

    DECLARE @badgeHtml NVARCHAR(MAX) =
        CASE WHEN NULLIF(LTRIM(RTRIM(@Badge)), '') IS NULL THEN ''
             ELSE '<div class="plan-badge-popular">'
                  + REPLACE(REPLACE(REPLACE(@Badge, '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
                  + '</div>'
        END;

    DECLARE @html NVARCHAR(MAX) =
        @badgeHtml
      + '<div class="plan-icon-circle ' + ISNULL(LTRIM(RTRIM(@IconCss)), '') + '"><svg ' + @svgAttrs + '>'
            + ISNULL(@IconSvg, '') + '</svg></div>'
      + '<h3>' + ISNULL(@Name, '') + '</h3>'
      + CASE WHEN NULLIF(LTRIM(RTRIM(@Tagline)), '') IS NULL THEN ''
             ELSE '<p class="plan-tagline">' + @Tagline + '</p>' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(@Pill)), '') IS NULL THEN ''
             ELSE '<span class="plan-pill">' + @Pill + '</span>' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(@Desc)), '') IS NULL THEN ''
             ELSE '<p class="plan-desc">' + @Desc + '</p>' END
      + '<div class="plan-price"><span class="amount">' + FORMAT(@Amount, 'N2', 'fr-CA')
            + ' $</span><span class="period">/ mois</span></div>'
      + @featHtml;

    UPDATE dbo.T021Plan
    SET DescriptionLong = @html,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    FETCH NEXT FROM cur INTO @Id, @Name, @Tagline, @Pill, @Desc, @Amount, @Badge, @IconCss, @IconSvg, @Features;
END

CLOSE cur;
DEALLOCATE cur;

-- Apercu
SELECT Id, Name, LEFT(DescriptionLong, 200) AS DescriptionLong_Debut, LEN(DescriptionLong) AS Longueur
FROM dbo.T021Plan
WHERE IsDeleted = 0 AND BillingCycle = 'monthly'
ORDER BY DisplayOrder, Id;
GO
