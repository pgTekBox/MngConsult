-- =============================================================================
-- Retrait complet du paramètre PDF_LOGO_PATH (« Logo (URL/chemin) »).
-- Obsolète : le logo du PDF provient désormais de T010Company.Logo (octets),
-- plus d'un chemin/URL. Supprimé de T101/T100/T102 pour toutes les compagnies
-- + modèle. Aucun code (VB/SQL) ne lit ce paramètre.
-- Patron : remove_PAYMENT_REGIME_param.sql
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DELETE FROM dbo.T101ParamValues
WHERE T100Id IN (SELECT Id FROM dbo.T100ParamComptable WHERE ShortName = 'PDF_LOGO_PATH');

DELETE FROM dbo.T100ParamComptable WHERE ShortName = 'PDF_LOGO_PATH';

DELETE FROM dbo.T102ParamI18n WHERE ShortName = 'PDF_LOGO_PATH';
GO
