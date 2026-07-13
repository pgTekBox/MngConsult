-- =============================================================================
-- Ajoute au CATALOGUE MODÈLE (T100ParamComptable, CompanyGUID sentinelle) les 3
-- paramètres d'onboarding qui manquaient (ils vivaient dans T010Company) :
--   INCORP_DATE (DATE)  - Date de constitution
--   FED_BN      (STRING)- Numéro d'entreprise fédéral (BN)
--   HST_NO      (STRING)- Numéro de TVH (HST)
-- + traductions dans T102ParamI18n.
-- Les compagnies existantes les reçoivent au prochain provisionnement
-- (s0150GetParamsForCompany ou s0686SaveOnboardingProfile).
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT v.ShortName, v.Name, v.ParamType, v.Categorie, v.Ordre, @Model
FROM (VALUES
    ('INCORP_DATE', N'Date de constitution',            'DATE',   'ENTREPRISE', 111),
    ('FED_BN',      N'Numéro d''entreprise fédéral (BN)', 'STRING', 'ENTREPRISE', 112),
    ('HST_NO',      N'No TVH (HST)',                     'STRING', 'TAXES',      260)
) v(ShortName, Name, ParamType, Categorie, Ordre)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T100ParamComptable p
    WHERE p.CompanyGUID = @Model AND p.ShortName = v.ShortName);
GO

-- Traductions
;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT * FROM (VALUES
        ('INCORP_DATE', N'Date de constitution',              N'Incorporation date',            N'Fecha de constitución'),
        ('FED_BN',      N'Numéro d''entreprise fédéral (BN)', N'Federal business number (BN)',  N'Número de empresa federal (BN)'),
        ('HST_NO',      N'No TVH (HST)',                      N'HST number',                    N'Número HST')
    ) v(ShortName, NameFr, NameEn, NameEs)
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN INSERT (ShortName, NameFr, NameEn, NameEs) VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO
