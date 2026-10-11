-- =============================================================================
-- T318 — Étape 2 : lier d'un coup les comptes à décider dont la proposition de
--        l'IA atteint un seuil de confiance (90, 80 ou 70 %)
--
-- « Accepter les correspondances par numéro » (s0760) ne retient que les
-- propositions sûres : même numéro, même nom, alias. Les propositions de l'IA
-- (s0761 : ProposeIAId, ProposeIAConfiance, ProposeIARaison) restaient à
-- accepter ligne par ligne. Le nouveau bouton de la grille les lie en masse
-- au-dessus d'un seuil que l'utilisateur choisit — Aucun, 90, 80 ou 70 % —
-- avec les mêmes garde-fous que l'enregistrement : le compte source encore à
-- décider, le compte cible actif, d'ici, et pas déjà pris par une autre liaison
-- (deux sources vers le même compte : la plus confiante seulement). La nature
-- a déjà été vérifiée par s0761 au moment de retenir la proposition.
--
--   s0899LierParConfianceIA (@CompanyGUID, @UserId, @Seuil) → 1er jeu : Liees,
--       Candidates ; 2e jeu : les décomptes de l'étape (s0758).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0899LierParConfianceIA]
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL,
    @Seuil       TINYINT = 90
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Seuil IS NULL OR @Seuil < 50 OR @Seuil > 100
        THROW 50348, 'Le seuil de confiance doit être entre 50 et 100 %.', 1;

    DECLARE @Systeme VARCHAR(20) =
        (SELECT TOP 1 [SystemeSource] FROM staging.ImportPlanComptable
          WHERE [CompanyGUID] = @CompanyGUID);

    ;WITH candidats AS (
        SELECT p.[CleSource], p.[TypeCle], p.[Compte], p.[Nom],
               p.[ProposeIAId], p.[ProposeIAConfiance], p.[ProposeIARaison],
               ROW_NUMBER() OVER (PARTITION BY p.[ProposeIAId]
                                  ORDER BY p.[ProposeIAConfiance] DESC, p.[LigneNo]) AS rn
          FROM staging.ImportPlanComptable p
          JOIN dbo.T121PlanComptable pc
            ON pc.[Id] = p.[ProposeIAId]
           AND pc.[CompanyGUID] = @CompanyGUID
           AND ISNULL(pc.[Actif], 1) = 1
         WHERE p.[CompanyGUID] = @CompanyGUID
           AND p.[Statut] IN ('OK', 'EXISTE')
           AND p.[ProposeIAId] IS NOT NULL
           AND p.[ProposeIAConfiance] >= @Seuil
           -- encore à décider
           AND NOT EXISTS (
                SELECT 1 FROM staging.CorrespondanceCompte c
                 WHERE c.[CompanyGUID] = @CompanyGUID
                   AND c.[SystemeSource] = @Systeme
                   AND c.[CleSource] = p.[CleSource])
           -- le compte cible n'est pas déjà pris par une autre liaison
           AND NOT EXISTS (
                SELECT 1 FROM staging.CorrespondanceCompte c
                 WHERE c.[CompanyGUID] = @CompanyGUID
                   AND c.[SystemeSource] = @Systeme
                   AND c.[Action] = 'LIER'
                   AND c.[PlanComptableId] = p.[ProposeIAId])
    )
    SELECT * INTO #c FROM candidats;

    DECLARE @Candidates INT = (SELECT COUNT(*) FROM #c);

    INSERT INTO staging.CorrespondanceCompte
        ([CompanyGUID], [SystemeSource], [CleSource], [TypeCle],
         [CompteSource], [NomSource], [Action], [PlanComptableId], [Note], [CreatedBy])
    SELECT @CompanyGUID, @Systeme, c.[CleSource], c.[TypeCle],
           c.[Compte], c.[Nom], 'LIER', c.[ProposeIAId],
           LEFT(N'Proposition de l''IA acceptée : confiance ' + CAST(c.[ProposeIAConfiance] AS NVARCHAR(3))
                + N' % (seuil ' + CAST(@Seuil AS NVARCHAR(3)) + N' %).'
                + CASE WHEN ISNULL(c.[ProposeIARaison], N'') <> N'' THEN N' ' + c.[ProposeIARaison] ELSE N'' END, 500),
           @UserId
      FROM #c c
     WHERE c.rn = 1;   -- deux sources vers le même compte : la plus confiante seulement

    DECLARE @Liees INT = @@ROWCOUNT;

    SELECT @Liees AS Liees, @Candidates AS Candidates, @Seuil AS Seuil;

    EXEC dbo.s0758StatsCorrespondance @CompanyGUID = @CompanyGUID;
END
GO
