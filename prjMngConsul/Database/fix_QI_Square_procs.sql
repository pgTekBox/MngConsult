-- Passe s0662/s0663 en QUOTED_IDENTIFIER ON (aucun litteral "..." -> conversion sure)
-- Requis car T010Company a desormais un index FILTRE (UX_T010Company_Sec60Email) :
-- toute ecriture exige QUOTED_IDENTIFIER ON, sinon erreur 1934.
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0662SaveCompanySquareTokens
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
CREATE OR ALTER PROCEDURE dbo.s0663GetCompanySquareAuth
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
