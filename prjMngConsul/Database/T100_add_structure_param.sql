-- =============================================================================
-- Ajoute au CATALOGUE MODÈLE le paramètre STRUCTURE (forme juridique), utilisé
-- par la console d'admin (édition compagnie). + traduction T102ParamI18n.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT 'STRUCTURE', N'Structure juridique', 'STRING', 'ENTREPRISE', 115, @Model
WHERE NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable p
                  WHERE p.CompanyGUID = @Model AND p.ShortName = 'STRUCTURE');
GO

;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT 'STRUCTURE', N'Structure juridique', N'Legal structure', N'Estructura jurídica'
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN INSERT (ShortName, NameFr, NameEn, NameEs) VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO
