SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- s0048GetPlanComptable : liste du plan comptable.
-- @Lang (fr|en|es) choisit la langue du nom de compte (repli fr).
-- Rétrocompatible : sans paramètre => français.
-- La recherche porte sur le numéro + les noms des 3 langues.
-- =============================================================
CREATE OR ALTER PROCEDURE [dbo].[s0048GetPlanComptable]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      VARCHAR(100) = '',
    @Filtre      VARCHAR(20)  = 'ALL',
    @Lang        VARCHAR(2)   = 'fr'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.[Id],
        c.Compte [Numero],
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(c.NomEn, c.NomFr, c.[Nom])
            WHEN 'es' THEN COALESCE(c.NomEs, c.NomEn, c.[Nom])
            ELSE            COALESCE(c.NomFr, c.[Nom])
        END AS [Nom],
        c.[TypeBilan],
        c.[Sens],
        c.[Actif],
        c.[Systeme],
        c.[Description],
        c.[ClasseId],
        c.[ClasseParentId],
        sc.[Code]                AS ClasseCode,
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(sc.DescriptionEn, sc.DescriptionFr, sc.[Description])
            WHEN 'es' THEN COALESCE(sc.DescriptionEs, sc.DescriptionEn, sc.[Description])
            ELSE            COALESCE(sc.DescriptionFr, sc.[Description])
        END AS SousClasseDescription,
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(p.DescriptionEn, p.DescriptionFr, p.[Description])
            WHEN 'es' THEN COALESCE(p.DescriptionEs, p.DescriptionEn, p.[Description])
            ELSE            COALESCE(p.DescriptionFr, p.[Description])
        END AS ClasseDescription,
        p.[GroupeEtatFinancier]  AS GroupeEtatFinancier
    FROM [dbo].[T121PlanComptable] c
    INNER JOIN [dbo].[T120PlanComptable_Classe] sc ON c.[ClasseId] = sc.[Id]
    INNER JOIN [dbo].[T120PlanComptable_Classe] p  ON c.[ClasseParentId] = p.[Id]
    WHERE
        -- (comportement d'origine conservé : pas de filtre CompanyGUID)
        (@Filtre = 'ALL' OR p.[GroupeEtatFinancier] = @Filtre)
        AND (
            @Search = ''
            OR c.Compte LIKE '%' + @Search + '%'
            OR c.[Nom]  LIKE '%' + @Search + '%'
            OR c.NomEn  LIKE '%' + @Search + '%'
            OR c.NomEs  LIKE '%' + @Search + '%'
            OR sc.[Code] LIKE '%' + @Search + '%'
            OR sc.[Description] LIKE '%' + @Search + '%'
            OR sc.DescriptionEn LIKE '%' + @Search + '%'
            OR sc.DescriptionEs LIKE '%' + @Search + '%'
        )
    ORDER BY c.[Ordre];
END
GO
