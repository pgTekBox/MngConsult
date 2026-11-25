-- =============================================================================
-- T407 — « Décider d'un compte » : un compte créé pour un autre compte source
--        n'est pas non plus un choix
--
-- T405 ne retirait des choix que les comptes de 60secondes déjà LIÉS. Or un
-- compte que la reprise a CRÉÉ pour un compte de l'ancien logiciel (ex. 5060
-- « Location local », créé pour « LOCATION LOCAL ») appartient aussi à ce
-- compte-là : s0757 refuse de lui lier un second compte source (50342). La
-- fenêtre le proposait quand même, et « Lier automatiquement » échouait.
--
-- La règle suit maintenant exactement celle de s0757 : tout compte du plan
-- rattaché (PlanComptableId) à une correspondance, quelle que soit l'action,
-- plus les liaisons encore sans PlanComptableId (par numéro).
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

    SELECT DISTINCT pc.[Id] AS PlanComptableId, pc.[Compte], c.[CleSource]
      FROM staging.CorrespondanceCompte c
      JOIN dbo.T121PlanComptable pc
        ON pc.[CompanyGUID] = @CompanyGUID
       AND (pc.[Id] = c.[PlanComptableId]
            OR (c.[PlanComptableId] IS NULL AND c.[Action] = 'LIER'
                AND pc.[Compte] = NULLIF(c.[CompteCible], '')))
     WHERE c.[CompanyGUID] = @CompanyGUID;
END
GO
