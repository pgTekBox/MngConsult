-- =============================================================================
-- Préfixe de brouillon — 1 paramètre ajouté au CATALOGUE MODÈLE
-- (T100ParamComptable, CompanyGUID sentinelle), catégorie PDF (onglet
-- « Facture »), + traduction (T102ParamI18n) + valeur par défaut (T101ParamValues).
--
--   INV_DRAFT_PREFIX (STRING) Préfixe de brouillon   défaut 'BRO'
--
-- Utilisé par s0040SaveInvoiceItems à la création d'une facture NON
-- COMPTABILISÉE : le numéro provisoire devient «<préfixe>-<Id>» au lieu du
-- « BROUILLON-<Id> » codé en dur. sp_ComptabiliserDocument reconnaît ce
-- préfixe (et l'ancien « BROUILLON- », pour les documents déjà en base) comme
-- numéro provisoire à remplacer par le numéro officiel.
--
-- Les compagnies existantes reçoivent le paramètre au prochain
-- provisionnement (s0150GetParamsForCompany à l'ouverture de wbfSetting) ;
-- d'ici là, les procédures retombent sur 'BRO'.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- 1) Définition (catalogue modèle)
INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT v.ShortName, v.Name, v.ParamType, v.Categorie, v.Ordre, @Model
FROM (VALUES
    ('INV_DRAFT_PREFIX', N'Préfixe de brouillon', 'STRING', 'PDF', 415)
) v(ShortName, Name, ParamType, Categorie, Ordre)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T100ParamComptable p
    WHERE p.CompanyGUID = @Model AND p.ShortName = v.ShortName);

-- 2) Valeur par défaut du modèle (héritée par chaque compagnie via s0150)
INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, sVal)
SELECT t.Id, @Model, 'BRO'
FROM dbo.T100ParamComptable t
WHERE t.CompanyGUID = @Model
  AND t.ShortName = 'INV_DRAFT_PREFIX'
  AND NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues x WHERE x.T100Id = t.Id AND x.CompanyGUID = @Model);
GO

-- 3) Traductions
;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT * FROM (VALUES
        ('INV_DRAFT_PREFIX', N'Préfixe de brouillon', N'Draft prefix', N'Prefijo de borrador')
    ) v(ShortName, NameFr, NameEn, NameEs)
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN INSERT (ShortName, NameFr, NameEn, NameEs) VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO

PRINT N'T100_add_draft_prefix_param.sql : termine.';
GO
