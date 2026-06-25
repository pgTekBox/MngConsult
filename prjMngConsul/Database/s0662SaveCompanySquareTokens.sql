-- =============================================================================
-- s0662SaveCompanySquareTokens
-- Enregistre (UPDATE) la connexion OAuth Square d'une compagnie.
-- COALESCE : un refresh ne renvoie pas toujours le refresh_token ni le
-- merchant/location -> on ne les ecrase pas avec NULL.
-- SquareConnectedDate : posee une seule fois (premiere connexion).
-- =============================================================================

IF OBJECT_ID('dbo.s0662SaveCompanySquareTokens', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0662SaveCompanySquareTokens;
GO

CREATE PROCEDURE dbo.s0662SaveCompanySquareTokens
    @CompanyGUID      UNIQUEIDENTIFIER,
    @MerchantId       VARCHAR(64)  = NULL,
    @AccessTokenEnc   VARCHAR(MAX) = NULL,
    @RefreshTokenEnc  VARCHAR(MAX) = NULL,
    @ExpiresAt        DATETIME     = NULL,
    @LocationId       VARCHAR(64)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T010Company
    SET SquareMerchantId      = COALESCE(@MerchantId, SquareMerchantId),
        SquareAccessTokenEnc  = COALESCE(@AccessTokenEnc, SquareAccessTokenEnc),
        SquareRefreshTokenEnc = COALESCE(@RefreshTokenEnc, SquareRefreshTokenEnc),
        SquareTokenExpiresAt  = COALESCE(@ExpiresAt, SquareTokenExpiresAt),
        SquareLocationId      = COALESCE(@LocationId, SquareLocationId),
        SquareConnectedDate   = ISNULL(SquareConnectedDate, GETDATE())
    WHERE CompanyGUID = @CompanyGUID;
END
GO
