-- =============================================================================
-- Numérotation des factures clients — 5 paramètres ajoutés au CATALOGUE MODÈLE
-- (T100ParamComptable, CompanyGUID sentinelle), catégorie PDF, + traductions
-- (T102ParamI18n) + valeurs par défaut du modèle (T101ParamValues).
--
--   INV_NUM_START        (INT)    Début du numéro                 défaut 1
--   INV_NUM_PREFIX       (STRING) Préfixe du numéro de facture    défaut (vide)
--   INV_NUM_DIGITS       (INT)    Nombre de chiffres              défaut 4
--   INV_NUM_FORMAT       (STRING) Format (menu déroulant)         défaut {PREFIXE}-{AAAA}-{NUMERO}
--   INV_NUM_RESET_YEARLY (BOOL)   Réinitialiser chaque année      défaut 0 (Non)
--
-- Les compagnies existantes reçoivent ces paramètres au prochain
-- provisionnement (s0150GetParamsForCompany à l'ouverture de wbfSetting).
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- 1) Définitions (catalogue modèle)
INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT v.ShortName, v.Name, v.ParamType, v.Categorie, v.Ordre, @Model
FROM (VALUES
    ('INV_NUM_START',        N'Début du numéro',                        'INT',    'PDF', 410),
    ('INV_NUM_PREFIX',       N'Préfixe du numéro de facture',           'STRING', 'PDF', 411),
    ('INV_NUM_DIGITS',       N'Nombre de chiffres',                     'INT',    'PDF', 412),
    ('INV_NUM_FORMAT',       N'Format du numéro',                       'STRING', 'PDF', 413),
    ('INV_NUM_RESET_YEARLY', N'Réinitialiser le compteur chaque année', 'BOOL',   'PDF', 414)
) v(ShortName, Name, ParamType, Categorie, Ordre)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T100ParamComptable p
    WHERE p.CompanyGUID = @Model AND p.ShortName = v.ShortName);

-- 2) Valeurs par défaut du modèle (héritées par chaque compagnie via s0150)
INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal)
SELECT t.Id, @Model,
       CASE t.ShortName WHEN 'INV_NUM_START' THEN 1
                        WHEN 'INV_NUM_DIGITS' THEN 4
                        WHEN 'INV_NUM_RESET_YEARLY' THEN 0
                        ELSE NULL END,
       CASE t.ShortName WHEN 'INV_NUM_FORMAT' THEN '{PREFIXE}-{AAAA}-{NUMERO}'
                        ELSE NULL END
FROM dbo.T100ParamComptable t
WHERE t.CompanyGUID = @Model
  AND t.ShortName IN ('INV_NUM_START','INV_NUM_PREFIX','INV_NUM_DIGITS','INV_NUM_FORMAT','INV_NUM_RESET_YEARLY')
  AND NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues x WHERE x.T100Id = t.Id AND x.CompanyGUID = @Model);
GO

-- 3) Traductions
;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT * FROM (VALUES
        ('INV_NUM_START',        N'Début du numéro',                        N'Starting number',                 N'Número inicial'),
        ('INV_NUM_PREFIX',       N'Préfixe du numéro de facture',           N'Invoice number prefix',           N'Prefijo del número de factura'),
        ('INV_NUM_DIGITS',       N'Nombre de chiffres',                     N'Number of digits',                N'Cantidad de dígitos'),
        ('INV_NUM_FORMAT',       N'Format du numéro',                       N'Number format',                   N'Formato del número'),
        ('INV_NUM_RESET_YEARLY', N'Réinitialiser le compteur chaque année', N'Reset the counter every year',    N'Reiniciar el contador cada año')
    ) v(ShortName, NameFr, NameEn, NameEs)
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN INSERT (ShortName, NameFr, NameEn, NameEs) VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO
