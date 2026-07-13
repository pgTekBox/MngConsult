-- =============================================================================
-- T101ParamValues : ajout des colonnes typées dVal (DATETIME) et fVal (FLOAT)
--
-- Objectif : stocker en plus de sVal (chaîne, conservée pour les nombreux
-- lecteurs existants : s0160GetParamValue, v_Parameters, sp_FermerExerciceFiscal,
-- sp_GenererRapportTaxe, sp_VerifierPreCloture…) une valeur TYPÉE :
--   - dVal : pour les paramètres de type DATE
--   - fVal : pour les paramètres de type DECIMAL — DECIMAL(18,6) (valeur exacte)
-- Les colonnes sont alimentées EN MIROIR de sVal (voir s0151/s0150/s0500 et
-- wbfSetting) ; sVal reste la source des lecteurs existants.
-- =============================================================================

IF COL_LENGTH('dbo.T101ParamValues', 'dVal') IS NULL
    ALTER TABLE dbo.T101ParamValues ADD dVal DATETIME NULL;
GO

IF COL_LENGTH('dbo.T101ParamValues', 'fVal') IS NULL
    ALTER TABLE dbo.T101ParamValues ADD fVal DECIMAL(18,6) NULL;
GO

-- Si fVal avait été créé en FLOAT auparavant, le convertir en DECIMAL(18,6)
-- (valeur exacte, ex. 9.975 au lieu de 9.97499999…).
IF EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID('dbo.T101ParamValues')
      AND c.name = 'fVal' AND t.name = 'float')
    ALTER TABLE dbo.T101ParamValues ALTER COLUMN fVal DECIMAL(18,6) NULL;
GO

-- Migration des valeurs existantes -------------------------------------------

-- DATE : sVal est stocké au format ISO 'yyyy-MM-dd'
UPDATE v
   SET v.dVal = TRY_CONVERT(DATETIME, v.sVal)
FROM dbo.T101ParamValues v
INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
WHERE UPPER(p.ParamType) = 'DATE'
  AND v.sVal IS NOT NULL
  AND LTRIM(RTRIM(v.sVal)) <> ''
  AND TRY_CONVERT(DATETIME, v.sVal) IS NOT NULL;

-- Les paramètres DATE ne vivent QUE dans dVal : vider sVal une fois dVal rempli.
UPDATE v
   SET v.sVal = NULL
FROM dbo.T101ParamValues v
INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
WHERE UPPER(p.ParamType) = 'DATE'
  AND v.dVal IS NOT NULL
  AND v.sVal IS NOT NULL;

-- DECIMAL : sVal est stocké en culture invariante (séparateur '.')
UPDATE v
   SET v.fVal = TRY_CONVERT(DECIMAL(18,6), v.sVal)
FROM dbo.T101ParamValues v
INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
WHERE UPPER(p.ParamType) = 'DECIMAL'
  AND v.sVal IS NOT NULL
  AND LTRIM(RTRIM(v.sVal)) <> ''
  AND TRY_CONVERT(DECIMAL(18,6), v.sVal) IS NOT NULL;

-- Les paramètres DECIMAL ne vivent QUE dans fVal : vider sVal une fois fVal rempli.
UPDATE v
   SET v.sVal = NULL
FROM dbo.T101ParamValues v
INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
WHERE UPPER(p.ParamType) = 'DECIMAL'
  AND v.fVal IS NOT NULL
  AND v.sVal IS NOT NULL;
GO
