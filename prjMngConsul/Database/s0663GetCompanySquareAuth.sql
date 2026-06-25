-- =============================================================================
-- s0663GetCompanySquareAuth
-- Retourne la connexion Square d'une compagnie (jetons chiffres + expiration
-- + location). Sert a recuperer/rafraichir le jeton pour les appels API.
-- =============================================================================

IF OBJECT_ID('dbo.s0663GetCompanySquareAuth', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0663GetCompanySquareAuth;
GO

CREATE PROCEDURE dbo.s0663GetCompanySquareAuth
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SquareMerchantId,
        SquareAccessTokenEnc,
        SquareRefreshTokenEnc,
        SquareTokenExpiresAt,
        SquareLocationId,
        SquareConnectedDate
    FROM dbo.T010Company
    WHERE CompanyGUID = @CompanyGUID;
END
GO
