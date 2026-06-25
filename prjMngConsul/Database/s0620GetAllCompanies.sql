SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0620GetAllCompanies
-- Retourne toutes les compagnies (GUID + nom) pour le sélecteur
-- de compagnie de la console d'administration (prjSec60Admin).
-- Utilisé par wbfUsers.aspx pour choisir le contexte de compagnie.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0620GetAllCompanies
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CompanyGUID,
        Name
    FROM dbo.T010Company
    ORDER BY Name;
END
