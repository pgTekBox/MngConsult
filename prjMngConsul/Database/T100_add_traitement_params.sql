-- =============================================================================
-- Onglet « Traitement » — nouvelle catégorie de paramètres (TRAITEMENT)
-- ajoutée au CATALOGUE MODÈLE (T100ParamComptable, CompanyGUID sentinelle),
-- + traduction (T102ParamI18n) + valeur par défaut (T101ParamValues).
--
--   RECEIPT_AUTO_POST (BOOL) Reçu comptabilisé automatiquement   défaut 0 (non)
--
-- Les compagnies existantes reçoivent le paramètre au prochain
-- provisionnement (s0150GetParamsForCompany, à l'ouverture de wbfSetting).
--
-- Note : aucun traitement ne consomme encore ce paramètre ; il est pour
-- l'instant uniquement saisissable dans l'onglet « Traitement ».
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- 1) Définition (catalogue modèle). Ordre 600 : après COMPTABLE (500), la
--    catégorie occupe donc sa propre plage.
INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT v.ShortName, v.Name, v.ParamType, v.Categorie, v.Ordre, @Model
FROM (VALUES
    ('RECEIPT_AUTO_POST', N'Reçu comptabilisé automatiquement', 'BOOL', 'TRAITEMENT', 600)
) v(ShortName, Name, ParamType, Categorie, Ordre)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T100ParamComptable p
    WHERE p.CompanyGUID = @Model AND p.ShortName = v.ShortName);

-- 2) Valeur par défaut du modèle (héritée par chaque compagnie via s0150).
--    Un BOOL est stocké dans iVal : 0 = non, 1 = oui.
INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal)
SELECT t.Id, @Model, 0
FROM dbo.T100ParamComptable t
WHERE t.CompanyGUID = @Model
  AND t.ShortName = 'RECEIPT_AUTO_POST'
  AND NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues x WHERE x.T100Id = t.Id AND x.CompanyGUID = @Model);
GO

-- 3) Traductions
;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT * FROM (VALUES
        ('RECEIPT_AUTO_POST', N'Reçu comptabilisé automatiquement', N'Post receipts automatically', N'Contabilizar recibos automáticamente')
    ) v(ShortName, NameFr, NameEn, NameEs)
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN INSERT (ShortName, NameFr, NameEn, NameEs) VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO

PRINT N'T100_add_traitement_params.sql : termine.';
GO
