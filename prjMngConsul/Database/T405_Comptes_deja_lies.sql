-- =============================================================================
-- T405 — « Décider d'un compte » : ne plus proposer un compte de 60secondes
--        déjà lié à un autre compte de l'ancien logiciel
--
-- Un compte d'ici ne reçoit qu'un seul compte source (index UX_Corresp_Cible,
-- T275) : le proposer à nouveau ne mène qu'à un refus. La fenêtre lit la liste
-- des comptes déjà pris et les retire des choix (recommandation, proposition,
-- comptes proches).
--
--   s1029GetComptesDejaLies @CompanyGUID → PlanComptableId, Compte, CleSource
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1029GetComptesDejaLies]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT pc.[Id] AS PlanComptableId, pc.[Compte], c.[CleSource]
      FROM staging.CorrespondanceCompte c
      JOIN dbo.T121PlanComptable pc
        ON pc.[CompanyGUID] = @CompanyGUID
       AND (pc.[Id] = c.[PlanComptableId]
            OR (c.[PlanComptableId] IS NULL AND pc.[Compte] = NULLIF(c.[CompteCible], '')))
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[Action] = 'LIER';
END
GO
