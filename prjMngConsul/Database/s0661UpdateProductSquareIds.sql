-- =============================================================================
-- s0661UpdateProductSquareIds
-- Enregistre, sur T075Products, les identifiants/versions Square d'un produit
-- apres un BatchUpsertCatalogObjects reussi. Les versions sont indispensables
-- pour les mises a jour futures (l'API les exige).
--
-- COALESCE : ne pas ecraser une valeur existante avec NULL si non fournie.
-- =============================================================================

IF OBJECT_ID('dbo.s0661UpdateProductSquareIds', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0661UpdateProductSquareIds;
GO

CREATE PROCEDURE dbo.s0661UpdateProductSquareIds
    @CompanyGUID            UNIQUEIDENTIFIER,
    @ProductId              INT,
    @SquareItemId           VARCHAR(100) = NULL,
    @SquareVariationId      VARCHAR(100) = NULL,
    @SquareItemVersion      BIGINT       = NULL,
    @SquareVariationVersion BIGINT       = NULL,
    @Status                 VARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T075Products
    SET SquareItemId           = COALESCE(@SquareItemId, SquareItemId),
        SquareVariationId      = COALESCE(@SquareVariationId, SquareVariationId),
        SquareItemVersion      = COALESCE(@SquareItemVersion, SquareItemVersion),
        SquareVariationVersion = COALESCE(@SquareVariationVersion, SquareVariationVersion),
        SquareSyncStatus       = @Status,
        SquareSyncDate         = GETDATE()
    WHERE CompanyGUID = @CompanyGUID
      AND Id = @ProductId;
END
GO
