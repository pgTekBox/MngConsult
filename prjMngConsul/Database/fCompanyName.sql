SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- fCompanyName(@CompanyGUID)
-- Nom d'entreprise à afficher = paramètre LEGAL_NAME (T101, source unique),
-- avec repli sur T010Company.Name si le paramètre est vide.
-- Utilisée par les procs de session/affichage du main app (s0200, s0223,
-- s0230, s0314, s0210…).
-- =============================================================================
CREATE OR ALTER FUNCTION dbo.fCompanyName(@CompanyGUID UNIQUEIDENTIFIER)
RETURNS NVARCHAR(200)
AS
BEGIN
    RETURN COALESCE(
        (SELECT v.sVal
         FROM dbo.T101ParamValues v
         INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
         WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'LEGAL_NAME'),
        (SELECT Name FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID)
    );
END
GO
