-- =============================================================================
-- check_existing_outbound_mail_proc.sql
-- Diagnostique : vérifier s'il existe déjà une stored procedure dans la BD
-- MailService qui insère des courriels sortants dans T400Mails.
--
-- À exécuter MANUELLEMENT par l'utilisateur (besoin de droits SELECT sur
-- sys.procedures et sys.sql_modules, pas accessibles au user MngConsulMail).
--
-- Si une proc existe, l'utiliser plutôt que de créer s0610InsertOutboundMail.
-- =============================================================================

USE [MailService];
GO
return
-- 1. Lister toutes les procs qui touchent T400Mails et font un INSERT
SELECT
    p.name AS proc_name,
    p.create_date,
    p.modify_date,
    LEFT(m.definition, 200) AS definition_preview
FROM sys.procedures p
JOIN sys.sql_modules m ON p.object_id = m.object_id
WHERE m.definition LIKE '%INSERT%T400Mails%'
   OR m.definition LIKE '%insert%T400Mails%'
   OR m.definition LIKE '%INSERT INTO%[T400Mails]%'
ORDER BY p.name;

-- 2. Lister toutes les procs dont le nom suggère un envoi de mail sortant
SELECT
    name,
    create_date,
    modify_date
FROM sys.procedures
WHERE name LIKE '%Outbound%Mail%'
   OR name LIKE '%InsertMail%'
   OR name LIKE '%SendMail%'
   OR name LIKE '%CreateMail%'
   OR name LIKE '%AddMail%'
   OR name LIKE '%NewMail%'
ORDER BY name;

-- 3. Structure complète de T400Mails (pour validation des colonnes)
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'T400Mails'
ORDER BY ORDINAL_POSITION;
GO
