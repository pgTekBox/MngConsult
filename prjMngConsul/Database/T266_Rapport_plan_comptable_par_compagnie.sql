-- =============================================================================
-- T266 — Le rapport du plan comptable ne montre que la compagnie courante
--
-- Vu chez Pierre : wbfRapportPlanComptable affichait le même plan quatre fois.
-- Depuis que les classes (T120PlanComptable_Classe) sont propres à chaque
-- compagnie — 65 classes × 4 compagnies — les trois procédures du rapport,
-- écrites quand la table était unique, lisaient toutes les compagnies :
--   · s0082 et s0083 n'avaient pas de paramètre de compagnie ;
--   · s0084 recevait @CompanyGUID mais ne s'en servait pas.
--
-- Les trois filtrent désormais. Le paramètre est facultatif (NULL = comme
-- avant) pour ne casser aucun appelant ; le rapport, seul appelant connu,
-- le passe.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0082GetClassesForReport]
    @Filtre      VARCHAR(20) = 'ALL',
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Id], [Code], [Description], [TypeBilan], [Sens], [NumeroDebut], [NumeroFin],
           [GroupeEtatFinancier], [Ordre]
      FROM [dbo].[T120PlanComptable_Classe]
     WHERE [Niveau] = 1
       AND [Actif] = 1
       AND (@Filtre = 'ALL' OR [GroupeEtatFinancier] = @Filtre)
       AND (@CompanyGUID IS NULL OR [CompanyGUID] = @CompanyGUID)
     ORDER BY [Ordre];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0083GetSousClassesForReport]
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Id], [ParentId], [Code], [Description], [NumeroDebut], [NumeroFin], [Ordre]
      FROM [dbo].[T120PlanComptable_Classe]
     WHERE [Niveau] = 2
       AND [Actif] = 1
       AND (@CompanyGUID IS NULL OR [CompanyGUID] = @CompanyGUID)
     ORDER BY [Ordre];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0084GetComptesForReport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Filtre      VARCHAR(20) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.[Id], c.[Compte] AS [Numero], c.[Nom], c.[Description], c.[TypeBilan], c.[Sens],
           c.[Actif], c.[Systeme], c.[ClasseId], c.[ClasseParentId], c.[Ordre]
      FROM [dbo].[T121PlanComptable] c
     INNER JOIN [dbo].[T120PlanComptable_Classe] p ON c.[ClasseParentId] = p.[Id]
     WHERE (@CompanyGUID IS NULL OR c.[CompanyGUID] = @CompanyGUID)
       AND (@Filtre = 'ALL' OR p.[GroupeEtatFinancier] = @Filtre)
     ORDER BY c.[Ordre];
END
GO
