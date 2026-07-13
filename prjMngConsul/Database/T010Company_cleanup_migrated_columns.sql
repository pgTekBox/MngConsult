-- =============================================================================
-- Nettoyage T010Company : suppression des colonnes « métier » migrées vers T101.
-- (Environnement de DÉVELOPPEMENT — pas encore en production.)
--
-- 1) Supprime les procédures MORTES qui référençaient encore ces colonnes
--    (aucun appelant applicatif) : s0310SaveUserProfile, s0311SaveCompanyInfo,
--    s0315GetProfileCompleted.
-- 2) Sauvegarde les valeurs dans dbo.T010Company_bak_migration (filet de sécurité).
-- 3) DROP des colonnes migrées.
--
-- Conservées : Id, CompanyGUID, CompanyCode, Name (repli fCompanyName),
-- ComptableGUID, Square*, métadonnées.
-- =============================================================================

-- 1) Procédures mortes
IF OBJECT_ID('dbo.s0310SaveUserProfile','P')   IS NOT NULL DROP PROCEDURE dbo.s0310SaveUserProfile;
IF OBJECT_ID('dbo.s0311SaveCompanyInfo','P')   IS NOT NULL DROP PROCEDURE dbo.s0311SaveCompanyInfo;
IF OBJECT_ID('dbo.s0315GetProfileCompleted','P') IS NOT NULL DROP PROCEDURE dbo.s0315GetProfileCompleted;
GO

-- 2) Sauvegarde des valeurs avant suppression
IF OBJECT_ID('dbo.T010Company_bak_migration','U') IS NOT NULL
    DROP TABLE dbo.T010Company_bak_migration;

SELECT
    CompanyGUID,
    LegalName, Structure, BusinessNumber, SIN,
    TpsNumber, TpsRegDate, NEQ, TvqNumber, TvqRegDate, CAE,
    TpsFrequency, TvqFrequency, FiscalYearEnd, PaymentRegime,
    IncorporationDate, HstNumber, ProfileCompleted
INTO dbo.T010Company_bak_migration
FROM dbo.T010Company;
GO

-- 3) Suppression des colonnes migrées
ALTER TABLE dbo.T010Company DROP COLUMN
    LegalName, Structure, BusinessNumber, SIN,
    TpsNumber, TpsRegDate, NEQ, TvqNumber, TvqRegDate, CAE,
    TpsFrequency, TvqFrequency, FiscalYearEnd, PaymentRegime,
    IncorporationDate, HstNumber, ProfileCompleted;
GO
