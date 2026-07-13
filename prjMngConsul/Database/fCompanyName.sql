SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- fCompanyName(@CompanyGUID)
-- Nom d'entreprise à afficher, 100 % T101 (source unique) :
--   LEGAL_NAME, à défaut TRADE_NAME. Plus aucun repli sur T010Company.Name
--   (colonne supprimée ; le nom saisi à l'inscription va dans LEGAL_NAME/TRADE_NAME).
-- Utilisée par les procs de session/affichage (s0200, s0223, s0230, s0314, s0210…).
-- =============================================================================
CREATE OR ALTER FUNCTION dbo.fCompanyName(@CompanyGUID UNIQUEIDENTIFIER)
RETURNS NVARCHAR(200)
AS
BEGIN
    RETURN COALESCE(
        dbo.fParamS(@CompanyGUID, 'LEGAL_NAME'),
        dbo.fParamS(@CompanyGUID, 'TRADE_NAME')
    );
END
GO
