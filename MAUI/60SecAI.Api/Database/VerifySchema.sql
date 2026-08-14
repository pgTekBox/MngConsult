/*
    Vérification du schéma MngConsul pour finaliser le mapping de l'API mobile.
    À exécuter dans SSMS sur le serveur 192.168.0.203, base MngConsul.
    Renvoie plusieurs jeux de résultats — copie-moi surtout ceux des sections 2, 3 et 5.
*/
USE MngConsul;
GO

-- 1) Les vues existent-elles ? (sinon, les pages AI utilisent peut-être des procédures)
SELECT name AS ObjectName, type_desc, create_date, modify_date
FROM sys.objects
WHERE name IN ('vwAISales', 'vwAiPaiement') AND type = 'V';

-- 2) Colonnes exactes des deux vues (nom + type + nullable)
SELECT  c.TABLE_NAME              AS ViewName,
        c.ORDINAL_POSITION        AS Pos,
        c.COLUMN_NAME             AS ColumnName,
        c.DATA_TYPE               AS DataType,
        c.CHARACTER_MAXIMUM_LENGTH AS MaxLen,
        c.NUMERIC_PRECISION       AS NumPrecision,
        c.NUMERIC_SCALE           AS NumScale,
        c.IS_NULLABLE             AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME IN ('vwAISales', 'vwAiPaiement')
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- 3) Colonne de cloisonnement par entreprise (CompanyGUID ou variante) ?
SELECT TABLE_NAME AS ViewName, COLUMN_NAME AS TenantColumn
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('vwAISales', 'vwAiPaiement')
  AND (COLUMN_NAME LIKE '%Company%' OR COLUMN_NAME LIKE '%GUID%' OR COLUMN_NAME LIKE '%Tenant%');

-- 4) Définition complète des vues (jointures/derivations exactes).
--    NULL si la vue est chiffrée (WITH ENCRYPTION) — dans ce cas, ignore.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vwAISales'))   AS vwAISales_Definition;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vwAiPaiement')) AS vwAiPaiement_Definition;

-- 5) Valeurs distinctes de statut / catégorie (pour valider le mapping)
SELECT DISTINCT StatutPaiement FROM dbo.vwAISales;
SELECT DISTINCT Category        FROM dbo.vwAiPaiement;

-- 6) (Optionnel) Échantillon — contient de vraies données financières,
--    inutile de me l'envoyer si confidentiel ; sert seulement à confirmer les colonnes.
-- SELECT TOP 5 * FROM dbo.vwAISales;
-- SELECT TOP 5 * FROM dbo.vwAiPaiement;

-- 7) Colonnes T015User utilisées pour l'authentification (confirme qu'elles existent)
SELECT  COLUMN_NAME AS ColumnName, DATA_TYPE AS DataType, IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'T015User'
  AND COLUMN_NAME IN ('Id','CompanyGUID','Email','PasswordHash','FirstName','LastName',
                      'IsAdmin','IsAccountant','IsActive','IsDeleted')
ORDER BY COLUMN_NAME;
