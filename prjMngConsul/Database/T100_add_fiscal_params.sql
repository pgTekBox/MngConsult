-- =============================================================================
-- Ajoute au CATALOGUE MODÈLE (T100ParamComptable, sentinelle) 4 paramètres
-- fiscaux qui vivaient dans T010Company :
--   SIN          (STRING) - NAS / numéro d'assurance sociale
--   TPS_REG_DATE (DATE)   - Date d'inscription TPS
--   TVQ_REG_DATE (DATE)   - Date d'inscription TVQ
--   CAE          (STRING) - Code d'activité économique
-- + traductions dans T102ParamI18n.
-- Les compagnies les reçoivent au prochain provisionnement (s0150 / s0686).
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT v.ShortName, v.Name, v.ParamType, v.Categorie, v.Ordre, @Model
FROM (VALUES
    ('SIN',            N'NAS (Numéro d''assurance sociale)', 'STRING', 'ENTREPRISE', 113),
    ('CAE',            N'Code d''activité économique (CAE)',  'STRING', 'ENTREPRISE', 114),
    ('TPS_REG_DATE',   N'Date d''inscription TPS',            'DATE',   'TAXES',      261),
    ('TVQ_REG_DATE',   N'Date d''inscription TVQ',            'DATE',   'TAXES',      262),
    ('PAYMENT_REGIME', N'Régime de versement des taxes',      'STRING', 'TAXES',      263)
) v(ShortName, Name, ParamType, Categorie, Ordre)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T100ParamComptable p
    WHERE p.CompanyGUID = @Model AND p.ShortName = v.ShortName);
GO

;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT * FROM (VALUES
        ('SIN',          N'NAS (Numéro d''assurance sociale)', N'SIN (Social Insurance Number)', N'NSS (Número de Seguro Social)'),
        ('CAE',          N'Code d''activité économique (CAE)',  N'Economic activity code (CAE)',   N'Código de actividad económica (CAE)'),
        ('TPS_REG_DATE',   N'Date d''inscription TPS',       N'GST registration date',    N'Fecha de registro GST'),
        ('TVQ_REG_DATE',   N'Date d''inscription TVQ',       N'QST registration date',    N'Fecha de registro QST'),
        ('PAYMENT_REGIME', N'Régime de versement des taxes', N'Tax remittance regime',    N'Régimen de remesa de impuestos')
    ) v(ShortName, NameFr, NameEn, NameEs)
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN INSERT (ShortName, NameFr, NameEn, NameEs) VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO
