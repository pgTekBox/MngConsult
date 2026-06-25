-- =============================================================
-- T900AdminUser
-- Comptes administrateurs de la console d'administration (prjSec60Admin).
-- Distincts des utilisateurs métier (T015User, rattachés à une compagnie).
-- Authentification : courriel + mot de passe haché bcrypt.
-- Script idempotent (création table + index + amorçage 1er admin).
-- NB : QUOTED_IDENTIFIER/ANSI_NULLS doivent être ON pour l'index filtré.
-- =============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T900AdminUser', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T900AdminUser
    (
        Id           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T900AdminUser PRIMARY KEY,
        Email        NVARCHAR(200)  NOT NULL,
        PasswordHash NVARCHAR(500)  NOT NULL,
        FirstName    NVARCHAR(100)  NULL,
        LastName     NVARCHAR(100)  NULL,
        IsActive     BIT            NOT NULL CONSTRAINT DF_T900AdminUser_IsActive  DEFAULT(1),
        LastLoginOn  DATETIME       NULL,
        CreatedOn    DATETIME       NOT NULL CONSTRAINT DF_T900AdminUser_CreatedOn DEFAULT(GETDATE()),
        CreatedBy    NVARCHAR(200)  NULL,
        ModifiedOn   DATETIME       NULL,
        ModifiedBy   NVARCHAR(200)  NULL,
        IsDeleted    BIT            NOT NULL CONSTRAINT DF_T900AdminUser_IsDeleted DEFAULT(0)
    );

    -- Courriel unique parmi les comptes non supprimés
    CREATE UNIQUE INDEX UX_T900AdminUser_Email
        ON dbo.T900AdminUser(Email)
        WHERE IsDeleted = 0;
END
GO

-- Amorçage du premier administrateur (idempotent).
-- Mot de passe : Admin@1234  (bcrypt, work factor 11) — À CHANGER.
IF NOT EXISTS (SELECT 1 FROM dbo.T900AdminUser WHERE Email = 'admin@sec60admin.local')
BEGIN
    INSERT INTO dbo.T900AdminUser (Email, PasswordHash, FirstName, LastName, IsActive, CreatedBy)
    VALUES
    (
        'admin@sec60admin.local',
        '$2a$11$sPKBDsJZzZYqps/De083G.9sCFNUx8fwdRbZF8A2zdPv2zPMUb0hu',
        'Super', 'Admin', 1, 'seed'
    );
END
GO
