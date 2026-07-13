-- =============================================================================
-- Suppression de T010Company.Name (dernier champ « métier » — le nom d'entreprise
-- vit désormais 100 % dans T101 : LEGAL_NAME / TRADE_NAME).
--
-- 1) Migration : pour les compagnies existantes qui ont un Name mais pas encore
--    de valeur LEGAL_NAME/TRADE_NAME, on provisionne (si besoin) puis on copie
--    Name -> LEGAL_NAME et TRADE_NAME.
-- 2) Sauvegarde de Name.
-- 3) DROP COLUMN Name.
--
-- Prérequis : fCompanyName / s0210 / s0220 déjà mis à jour pour ne plus lire Name.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- 1a) Provisionner les définitions manquantes (compagnies ayant un Name)
INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
SELECT m.ShortName, m.Name, m.ParamType, m.Categorie, m.Ordre, co.CompanyGUID
FROM dbo.T010Company co
CROSS JOIN dbo.T100ParamComptable m
WHERE co.CompanyGUID <> @Model AND co.Name IS NOT NULL
  AND m.CompanyGUID = @Model AND m.ShortName IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable c
                  WHERE c.CompanyGUID = co.CompanyGUID AND c.ShortName = m.ShortName);

-- 1b) Créer les valeurs manquantes
INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
SELECT c.Id, c.CompanyGUID, vm.iVal, vm.sVal, vm.dVal, vm.fVal
FROM dbo.T100ParamComptable c
JOIN dbo.T010Company co ON co.CompanyGUID = c.CompanyGUID AND co.Name IS NOT NULL
LEFT JOIN dbo.T100ParamComptable m ON m.CompanyGUID = @Model AND m.ShortName = c.ShortName
LEFT JOIN dbo.T101ParamValues   vm ON vm.T100Id = m.Id AND vm.CompanyGUID = @Model
WHERE c.CompanyGUID <> @Model AND c.ShortName IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues t
                  WHERE t.T100Id = c.Id AND t.CompanyGUID = c.CompanyGUID);

-- 1c) Copier Name -> LEGAL_NAME et TRADE_NAME (uniquement là où le param est vide)
UPDATE v SET v.sVal = co.Name
FROM dbo.T101ParamValues v
JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
JOIN dbo.T010Company co ON co.CompanyGUID = v.CompanyGUID
WHERE p.ShortName IN ('LEGAL_NAME', 'TRADE_NAME')
  AND co.Name IS NOT NULL AND LTRIM(RTRIM(co.Name)) <> ''
  AND (v.sVal IS NULL OR LTRIM(RTRIM(v.sVal)) = '');
GO

-- 2) Sauvegarde
IF OBJECT_ID('dbo.T010Company_bak_Name','U') IS NOT NULL DROP TABLE dbo.T010Company_bak_Name;
SELECT CompanyGUID, Name INTO dbo.T010Company_bak_Name FROM dbo.T010Company;
GO

-- 3) Suppression de la colonne
ALTER TABLE dbo.T010Company DROP COLUMN Name;
GO
