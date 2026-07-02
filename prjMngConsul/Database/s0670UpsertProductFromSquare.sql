-- =============================================================================
-- s0670UpsertProductFromSquare
-- Insere ou met a jour un produit/service MngConsul (T075Products) a partir
-- d'un ITEM du catalogue Square. Sens ENTRANT (Square -> app). Utilise par le
-- webhook (catalog.version.updated) ET par l'import a la demande.
--
-- Cle de rapprochement : SquareItemId (dans la compagnie). Sinon -> creation.
-- @PriceCents : prix en cents (entier). Prix = @PriceCents / 100.
-- @Action OUTPUT : 'created' | 'updated'.
-- COALESCE : ne pas ecraser une valeur locale avec NULL si non fournie.
-- =============================================================================

USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0670UpsertProductFromSquare', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0670UpsertProductFromSquare;
GO

CREATE PROCEDURE dbo.s0670UpsertProductFromSquare
    @CompanyGUID            UNIQUEIDENTIFIER,
    @SquareItemId           VARCHAR(100),
    @SquareVariationId      VARCHAR(100) = NULL,
    @SquareItemVersion      BIGINT       = NULL,
    @SquareVariationVersion BIGINT       = NULL,
    @Name                   NVARCHAR(500) = NULL,
    @Description            NVARCHAR(2000) = NULL,
    @PriceCents             BIGINT       = NULL,
    @Action                 VARCHAR(20)  = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductId INT = NULL;
    DECLARE @Prix NUMERIC(18,2) = CASE WHEN @PriceCents IS NULL THEN NULL ELSE @PriceCents / 100.0 END;

    -- 1. par SquareItemId (lien etabli)
    SELECT TOP 1 @ProductId = Id FROM dbo.T075Products
    WHERE SquareItemId = @SquareItemId AND CompanyGUID = @CompanyGUID
    ORDER BY Id;

    -- 2. repli par nom (evite de recreer un doublon quand le lien est casse,
    --    ex. apres une purge des SquareItemId). On relie alors le produit existant.
    IF @ProductId IS NULL AND @Name IS NOT NULL AND LEN(LTRIM(RTRIM(@Name))) > 0
        SELECT TOP 1 @ProductId = Id FROM dbo.T075Products
        WHERE CompanyGUID = @CompanyGUID AND ISNULL(Actif, 0) = 1
          AND LOWER(LTRIM(RTRIM(Name))) = LOWER(LTRIM(RTRIM(@Name)))
        ORDER BY Id;

    IF @ProductId IS NULL
    BEGIN
        INSERT INTO dbo.T075Products
            (CompanyGUID, Name, Description, Prix, DefaultQty, AddToNewInvoice, Actif, Created,
             SquareItemId, SquareVariationId, SquareItemVersion, SquareVariationVersion,
             SquareSyncStatus, SquareSyncDate)
        VALUES
            (@CompanyGUID, ISNULL(@Name, N'(Sans nom)'), @Description, ISNULL(@Prix, 0), 1, 0, 1, GETDATE(),
             @SquareItemId, @SquareVariationId, @SquareItemVersion, @SquareVariationVersion,
             'IMPORT', GETDATE());
        SET @ProductId = SCOPE_IDENTITY();
        SET @Action = 'created';
    END
    ELSE
    BEGIN
        UPDATE dbo.T075Products
        SET Name                   = COALESCE(@Name, Name),
            Description            = COALESCE(@Description, Description),
            Prix                   = COALESCE(@Prix, Prix),
            SquareVariationId      = COALESCE(@SquareVariationId, SquareVariationId),
            SquareItemVersion      = COALESCE(@SquareItemVersion, SquareItemVersion),
            SquareVariationVersion = COALESCE(@SquareVariationVersion, SquareVariationVersion),
            SquareSyncStatus       = 'IMPORT',
            SquareSyncDate         = GETDATE()
        WHERE Id = @ProductId AND CompanyGUID = @CompanyGUID;
        SET @Action = 'updated';
    END

    SELECT @ProductId AS ProductId, @Action AS Action;
END
GO
