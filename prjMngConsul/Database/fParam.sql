SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- fParamS / fParamD : lecture d'un paramètre de compagnie par ShortName (T101).
--   fParamS → valeur chaîne (sVal)   |   fParamD → valeur date (dVal)
-- Permettent de sourcer les champs entreprise depuis T101 (source unique).
-- =============================================================================
CREATE OR ALTER FUNCTION dbo.fParamS(@CompanyGUID UNIQUEIDENTIFIER, @ShortName VARCHAR(50))
RETURNS VARCHAR(8000)
AS
BEGIN
    RETURN (SELECT v.sVal
            FROM dbo.T101ParamValues v
            INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = @ShortName);
END
GO

CREATE OR ALTER FUNCTION dbo.fParamD(@CompanyGUID UNIQUEIDENTIFIER, @ShortName VARCHAR(50))
RETURNS DATETIME
AS
BEGIN
    RETURN (SELECT v.dVal
            FROM dbo.T101ParamValues v
            INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = @ShortName);
END
GO
