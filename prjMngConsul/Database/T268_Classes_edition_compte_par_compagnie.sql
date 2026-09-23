-- =============================================================================
-- T268 — La liste des classes de l'édition d'un compte ne montre que la compagnie
--
-- Vu chez Pierre : « REV - Revenus » quatre fois dans la liste des classes de
-- niveau 1, à la création du compte 4140. Même cause que T266 : les classes
-- sont propres à chaque compagnie, et s0051 les lisait toutes. Le paramètre
-- est facultatif (NULL = comme avant) ; l'écran d'édition le passe.
-- s0052 (sous-classes d'un parent) n'a pas besoin de filtre : le parent est
-- déjà celui d'une compagnie.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0051GetClassesByNiveau]
    @Niveau      INT = 1,
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Id]                           AS [Value],
           [Code] + ' - ' + [Description] AS [Name]
      FROM [dbo].[T120PlanComptable_Classe]
     WHERE [Niveau] = @Niveau
       AND [Actif] = 1
       AND (@CompanyGUID IS NULL OR [CompanyGUID] = @CompanyGUID)
     ORDER BY [Ordre];
END
GO
