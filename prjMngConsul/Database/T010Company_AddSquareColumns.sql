-- =============================================================================
-- T010Company_AddSquareColumns
-- Stocke la connexion OAuth Square de chaque abonne (compagnie).
-- Les jetons sont stockes CHIFFRES (AES via clsCrypto) ; jamais en clair.
-- =============================================================================

IF COL_LENGTH('dbo.T010Company', 'SquareMerchantId') IS NULL
BEGIN
    ALTER TABLE dbo.T010Company ADD
        SquareMerchantId       VARCHAR(64)    NULL,
        SquareAccessTokenEnc   VARCHAR(MAX)   NULL,
        SquareRefreshTokenEnc  VARCHAR(MAX)   NULL,
        SquareTokenExpiresAt   DATETIME       NULL,
        SquareLocationId       VARCHAR(64)    NULL,
        SquareConnectedDate    DATETIME       NULL;
END
GO
