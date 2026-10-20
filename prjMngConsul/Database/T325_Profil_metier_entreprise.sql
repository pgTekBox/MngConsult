-- =============================================================================
-- T325 — Profil et métier de l'entreprise (Paramètres › Entreprise)
--
-- Deux paramètres de la catégorie ENTREPRISE, lus par « Qui fait quoi »
-- (QuiFaitQuoi.aspx) pour choisir les actions qui concernent l'entreprise :
--
--   PROFIL  (STRING)  « TA » (travailleur autonome), « Cie 0 » (société sans
--                     employé) ou « Cie 1-4 » (société avec employés)
--   METIER  (STRING)  nom exact d'un métier de l'inventaire « Qui fait quoi »
--                     (js/qui-fait-quoi-data.js, DATA.M), ex. « Électricien »
--
-- Définis sur la compagnie modèle ; s0150GetParamsForCompany les clone pour
-- chaque compagnie (valeur vide), wbfSetting les affiche en listes déroulantes.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @Modele UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

IF NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable WHERE CompanyGUID = @Modele AND ShortName = 'PROFIL')
    INSERT dbo.T100ParamComptable (Created, ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
    VALUES (GETDATE(), 'PROFIL', 'Profil de l''entreprise', 'STRING', 'ENTREPRISE', 116, @Modele);

IF NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable WHERE CompanyGUID = @Modele AND ShortName = 'METIER')
    INSERT dbo.T100ParamComptable (Created, ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
    VALUES (GETDATE(), 'METIER', 'Métier', 'STRING', 'ENTREPRISE', 117, @Modele);

INSERT dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
SELECT t.Id, @Modele, NULL, NULL, NULL, NULL
FROM dbo.T100ParamComptable t
WHERE t.CompanyGUID = @Modele AND t.ShortName IN ('PROFIL', 'METIER')
  AND NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues v WHERE v.T100Id = t.Id AND v.CompanyGUID = @Modele);

IF NOT EXISTS (SELECT 1 FROM dbo.T102ParamI18n WHERE ShortName = 'PROFIL')
    INSERT dbo.T102ParamI18n (ShortName, NameFr, NameEn, NameEs)
    VALUES ('PROFIL', N'Profil de l''entreprise', N'Business profile', N'Perfil de la empresa');

IF NOT EXISTS (SELECT 1 FROM dbo.T102ParamI18n WHERE ShortName = 'METIER')
    INSERT dbo.T102ParamI18n (ShortName, NameFr, NameEn, NameEs)
    VALUES ('METIER', N'Métier', N'Trade', N'Oficio');
GO
