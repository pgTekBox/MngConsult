-- =============================================================================
-- Retrait complet du paramètre PAYMENT_REGIME (« Régime de versement des taxes »)
-- — champ hérité jamais utilisé ni renseigné. Supprimé de T101/T100/T102 pour
-- toutes les compagnies + modèle. (Décâblé aussi de s0230GetUserAndCompanyInfo.)
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DELETE FROM dbo.T101ParamValues
WHERE T100Id IN (SELECT Id FROM dbo.T100ParamComptable WHERE ShortName = 'PAYMENT_REGIME');

DELETE FROM dbo.T100ParamComptable WHERE ShortName = 'PAYMENT_REGIME';

DELETE FROM dbo.T102ParamI18n WHERE ShortName = 'PAYMENT_REGIME';
GO
