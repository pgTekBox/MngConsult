-- =============================================================
-- T016UserRememberToken : jetons « Se souvenir de moi » (login persistant).
-- Patron « split token » : le cookie contient Selector:Validator ;
-- la base ne stocke que le HASH du validator (jamais le validator en clair).
-- Un utilisateur peut avoir plusieurs jetons (plusieurs appareils).
-- Idempotent.
-- =============================================================
IF OBJECT_ID('dbo.T016UserRememberToken', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T016UserRememberToken (
        Id            INT IDENTITY(1,1) PRIMARY KEY,
        UserId        INT NOT NULL,
        Selector      VARCHAR(64) NOT NULL,
        ValidatorHash VARCHAR(100) NOT NULL,
        ExpiresOn     DATETIME NOT NULL,
        CreatedOn     DATETIME NOT NULL CONSTRAINT DF_T016_CreatedOn DEFAULT(GETDATE())
    );
    CREATE UNIQUE INDEX UX_T016_Selector ON dbo.T016UserRememberToken(Selector);
    CREATE INDEX IX_T016_UserId ON dbo.T016UserRememberToken(UserId);
END
GO
