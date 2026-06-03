-- =============================================================================
-- setup_MailService_user.sql
-- Crée un LOGIN SQL Server et un USER dans la BD MailService permettant à
-- l'application MngConsul d'INSÉRER des courriels sortants dans T400Mails.
--
-- DROITS ACCORDÉS : INSERT seulement sur dbo.T400Mails + EXECUTE sur la
-- stored procedure s0610InsertOutboundMail. Aucun SELECT, UPDATE ou DELETE.
--
-- IMPORTANT : à exécuter en tant que sysadmin (sa) sur le serveur SQL.
-- Le user MngConsul standard n'a pas les droits nécessaires.
--
-- Mot de passe : à remplacer par une valeur forte avant exécution.
-- =============================================================================

USE [master];
GO
return
-- 1. Créer le LOGIN au niveau serveur
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'MngConsulMail')
BEGIN
    CREATE LOGIN [MngConsulMail]
        WITH PASSWORD = N'CHANGE_ME_BEFORE_RUNNING',
             CHECK_POLICY = ON,
             DEFAULT_DATABASE = [MailService];
    PRINT 'Login MngConsulMail créé.';
END
ELSE
BEGIN
    PRINT 'Login MngConsulMail existe déjà - skip CREATE LOGIN.';
END
GO

-- 2. Créer le USER dans la BD MailService
USE [MailService];
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'MngConsulMail')
BEGIN
    CREATE USER [MngConsulMail] FOR LOGIN [MngConsulMail];
    PRINT 'User MngConsulMail créé dans MailService.';
END
ELSE
BEGIN
    PRINT 'User MngConsulMail existe déjà dans MailService - skip CREATE USER.';
END
GO

-- 3. Accorder les permissions minimales (principe du moindre privilège)

-- INSERT sur la table cible
GRANT INSERT ON dbo.T400Mails TO [MngConsulMail];
PRINT 'GRANT INSERT sur dbo.T400Mails accordé.';
GO

-- EXECUTE sur la stored procedure d'insertion (créée par s0610InsertOutboundMail.sql)
-- Décommenter après avoir déployé s0610InsertOutboundMail.sql
-- GRANT EXECUTE ON dbo.s0610InsertOutboundMail TO [MngConsulMail];
-- PRINT 'GRANT EXECUTE sur s0610InsertOutboundMail accordé.';
-- GO

-- 4. Vérification : lister les permissions effectives du user
SELECT
    pr.name AS principal_name,
    pe.permission_name,
    pe.state_desc,
    OBJECT_SCHEMA_NAME(pe.major_id) + '.' + OBJECT_NAME(pe.major_id) AS object_name
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = 'MngConsulMail';
GO
