-- =============================================================================
-- s0660GetProductsForSquareSync
-- Retourne les produits/services actifs d'une compagnie a exporter vers Square,
-- avec leurs identifiants Square existants (colonnes sur T075Products) pour
-- permettre une MISE A JOUR plutot qu'une creation.
--
-- Filtre : Actif = 1 et Name non vide (Square exige un nom + un prix).
-- =============================================================================

IF OBJECT_ID('dbo.s0660GetProductsForSquareSync', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0660GetProductsForSquareSync;
GO

CREATE PROCEDURE dbo.s0660GetProductsForSquareSync
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[Id],
        p.[Name],
        p.[Description],
        p.[Prix],
        p.[SquareItemId],
        p.[SquareVariationId],
        p.[SquareItemVersion],
        p.[SquareVariationVersion]
    FROM dbo.T075Products p
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND ISNULL(p.[Actif], 0) = 1
      AND p.[Name] IS NOT NULL
      AND LEN(LTRIM(RTRIM(p.[Name]))) > 0
    ORDER BY p.[Name];
END
GO
