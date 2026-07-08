-- =============================================================
-- T010Company : colonnes manquantes pour l'onboarding wbfNewUser.
-- LegalName, NEQ, BusinessNumber, FiscalYearEnd, TpsNumber, TvqNumber,
-- ProfileCompleted existent déjà. On ajoute :
--   IncorporationDate (Date de constitution) et HstNumber (Numéro TVH).
-- Idempotent.
-- =============================================================
IF COL_LENGTH('dbo.T010Company', 'IncorporationDate') IS NULL
    ALTER TABLE dbo.T010Company ADD IncorporationDate DATE NULL;
GO
IF COL_LENGTH('dbo.T010Company', 'HstNumber') IS NULL
    ALTER TABLE dbo.T010Company ADD HstNumber NVARCHAR(50) NULL;
GO
