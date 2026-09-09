-- =============================================================================
-- T213 — Le plan comptable appartient a une compagnie
--
-- Constat : T121PlanComptable porte une colonne CompanyGUID et chaque
-- compagnie possede sa propre copie du plan (227 comptes chacune). Or
-- s0048GetPlanComptable ne filtrait pas sur la compagnie -- un commentaire
-- dans la procedure disait meme conserver ce « comportement d'origine ».
--
-- Deux consequences :
--
--   1. la page affiche les comptes de TOUTES les compagnies. Avec quatre
--      plans en base, chaque numero de compte apparait quatre fois ;
--   2. une compagnie voit le plan comptable des autres -- noms, descriptions,
--      classes. C'est une fuite entre locataires.
--
-- s0050DeletePlanComptableCompte recevait deja @CompanyGUID et l'ignorait de
-- la meme facon : la suppression se faisait sur le seul Id, donc sur le
-- compte d'une autre compagnie si la ligne venait de la liste non filtree.
--
-- Note : les compagnies sans plan (aucune ligne dans T121PlanComptable)
-- voyaient jusqu'ici celui des autres. Elles verront desormais une page
-- vide -- ce qui est exact : elles n'ont pas de plan. Leur en provisionner
-- un depuis la compagnie modele est une decision distincte, pas traitee ici.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) s0048GetPlanComptable — la liste, bornee a la compagnie
-- -----------------------------------------------------------------------------
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
        -- Le plan est celui de la compagnie, et d'aucune autre.
        c.[CompanyGUID] = @CompanyGUID
        AND (@Filtre = 'ALL' OR p.[GroupeEtatFinancier] = @Filtre)
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

-- -----------------------------------------------------------------------------
-- 2) s0050DeletePlanComptableCompte — on ne supprime que chez soi
--
--    La procedure recevait @CompanyGUID depuis la page mais supprimait sur
--    le seul Id. Un compte d'une autre compagnie disparaissait sans un mot.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0050DeletePlanComptableCompte]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Id             INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                    WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        RAISERROR('Ce compte n''appartient pas à votre plan comptable.', 16, 1)
        RETURN
    END

    -- Ne pas supprimer les comptes système
    IF EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                WHERE [Id] = @Id AND [Systeme] = 1)
    BEGIN
        RAISERROR('Ce compte est un compte système et ne peut pas être supprimé.', 16, 1)
        RETURN
    END

    DELETE FROM [dbo].[T121PlanComptable]
     WHERE [Id] = @Id
       AND [CompanyGUID] = @CompanyGUID;
END
GO

PRINT 'T213_PlanComptable_par_compagnie.sql : termine.';
GO
