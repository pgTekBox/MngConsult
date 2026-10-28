-- =============================================================================
-- s0918GetCompanyName
-- Nom d'une compagnie par son GUID (via dbo.fCompanyName = LEGAL_NAME T101,
-- repli T010Company.Name). Utilise par clsData/clsDataUC.CompanyName pour
-- afficher la compagnie COURANTE (celle de session), et non la compagnie
-- maison de l'utilisateur -- essentiel pour le comptable qui change de dossier.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE dbo.s0918GetCompanyName
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dbo.fCompanyName(@CompanyGUID) AS Name;
END
GO
