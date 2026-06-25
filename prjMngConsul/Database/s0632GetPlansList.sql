SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0632GetPlansList
-- Liste des forfaits (T021Plan) pour l'écran d'administration.
-- Inclut les forfaits inactifs ; exclut les supprimés (IsDeleted=1).
-- @Search : filtre optionnel sur Code ou Name.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0632GetPlansList
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Code,
        Name,
        Tagline,
        Amount,
        Currency,
        BillingCycle,
        TrialDays,
        MaxUsers,
        DisplayOrder,
        IsRecommended,
        IsActive
    FROM dbo.T021Plan
    WHERE IsDeleted = 0
      AND (@Search IS NULL OR @Search = ''
           OR Code LIKE '%' + @Search + '%'
           OR Name LIKE '%' + @Search + '%')
    ORDER BY DisplayOrder, BillingCycle, Id;
END
