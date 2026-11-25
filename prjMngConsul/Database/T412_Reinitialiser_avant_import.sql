-- =============================================================================
-- T412 — Importation 2 : chaque import repart d'une comptabilité vide
--
-- Demande du 2026-11-24 : quand on fait un import, toutes les données
-- comptables sont réinitialisées, car les nouvelles données de QuickBooks
-- prennent la place des anciennes.
--
-- s1035 est la porte officielle : elle efface exactement ce qu'efface
-- s1026ReinitialiserReprise (T402), qui devient donc nécessaire en production :
--   · factures et documents, règlements, toutes les écritures ;
--   · rendez-vous, clients et fournisseurs, produits ;
--   · plan comptable ramené au plan par défaut ;
--   · décisions de correspondance remises « à décider ».
-- Garde : exercices et périodes, journaux, taxes, paramètres, usagers, et la
-- date de début de l'exercice mémorisée (T411).
--
-- Appelée par Importation2.Extraire, juste avant l'extraction, après la
-- confirmation de l'usager (@Confirmation = 'IMPORTER').
--
--   s1035ReinitialiserAvantImport @CompanyGUID, @Confirmation → Quoi, Nb
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1035ReinitialiserAvantImport]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Confirmation VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Confirmation IS NULL OR @Confirmation <> 'IMPORTER'
        THROW 51080, N'Réinitialisation avant import non confirmée.', 1;

    EXEC dbo.s1026ReinitialiserReprise @CompanyGUID = @CompanyGUID, @Confirmation = 'REINITIALISER';
END
GO
