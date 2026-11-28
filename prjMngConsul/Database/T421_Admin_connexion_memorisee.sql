-- =============================================================================
-- T421 : « Se souvenir de moi » de la console Sec60Admin, en base
-- Le cookie Forms persistant dépendait de la clé de chiffrement (machineKey) du
-- serveur, régénérée au redémarrage du pool : la connexion mémorisée se perdait.
-- Même patron que l'ERP (T016 / clsRememberMe) : cookie « sélecteur:validateur »,
-- la base ne garde que SHA-256(validateur) ; rotation à chaque reprise (30 jours).
--   T901AdminRememberToken
--   s1040InsertAdminRememberToken  : enregistre un jeton (purge les expirés)
--   s1041GetAdminRememberToken     : jeton valide + administrateur actif
--   s1042DeleteAdminRememberToken  : révoque un jeton (rotation, déconnexion)
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.T901AdminRememberToken', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T901AdminRememberToken (
        Id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T901AdminRememberToken PRIMARY KEY,
        AdminId       INT           NOT NULL,
        Selector      VARCHAR(64)   NOT NULL,
        ValidatorHash VARCHAR(100)  NOT NULL,
        ExpiresOn     DATETIME      NOT NULL,
        CreatedOn     DATETIME      NOT NULL CONSTRAINT DF_T901AdminRememberToken_CreatedOn DEFAULT (GETDATE())
    );
    CREATE UNIQUE INDEX UX_T901AdminRememberToken_Selector ON dbo.T901AdminRememberToken (Selector);
    CREATE INDEX IX_T901AdminRememberToken_AdminId ON dbo.T901AdminRememberToken (AdminId);
END
GO

CREATE OR ALTER PROCEDURE dbo.s1040InsertAdminRememberToken
    @AdminId       INT,
    @Selector      VARCHAR(64),
    @ValidatorHash VARCHAR(100),
    @ExpiresOn     DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T901AdminRememberToken WHERE ExpiresOn <= GETDATE();
    INSERT INTO dbo.T901AdminRememberToken (AdminId, Selector, ValidatorHash, ExpiresOn)
    VALUES (@AdminId, @Selector, @ValidatorHash, @ExpiresOn);
END
GO

CREATE OR ALTER PROCEDURE dbo.s1041GetAdminRememberToken
    @Selector VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.AdminId, t.ValidatorHash, t.ExpiresOn, a.Email
    FROM dbo.T901AdminRememberToken t
    INNER JOIN dbo.T900AdminUser a ON a.Id = t.AdminId
    WHERE t.Selector = @Selector
      AND t.ExpiresOn > GETDATE()
      AND a.IsActive = 1
      AND ISNULL(a.IsDeleted, 0) = 0;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1042DeleteAdminRememberToken
    @Selector VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T901AdminRememberToken WHERE Selector = @Selector;
END
GO
