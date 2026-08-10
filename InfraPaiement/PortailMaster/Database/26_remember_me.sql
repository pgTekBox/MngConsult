/* =====================================================================
   PortailABN - Script 26 : « Se souvenir de moi » (login persistant)
   ---------------------------------------------------------------------
   Patron « split token » : le cookie AbnRemember = Selector:Validator.
   La base ne stocke que SHA-256(Validator) (jamais le validateur en clair).
   Un vol de la table ne permet donc pas de forger un cookie.

   Table T012AbonneRememberToken + procs s0074-s0077.
   A executer APRES 22 (T011AbonneUser). Procs numerotees s0074+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   Table des jetons de connexion persistante
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T012AbonneRememberToken', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T012AbonneRememberToken
    (
        Id            INT           IDENTITY(1,1) NOT NULL,
        AbonneUserId  INT           NOT NULL,
        Selector      CHAR(24)      NOT NULL,   -- 12 octets hex (identifiant public du jeton)
        ValidatorHash CHAR(64)      NOT NULL,   -- SHA-256 hex du validateur
        ExpiresUtc    DATETIME2(0)  NOT NULL,
        CreatedUtc    DATETIME2(0)  NOT NULL CONSTRAINT DF_T012_Created DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T012AbonneRememberToken PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T012_Selector UNIQUE (Selector),
        CONSTRAINT FK_T012_User FOREIGN KEY (AbonneUserId)
            REFERENCES dbo.T011AbonneUser(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_T012_User    ON dbo.T012AbonneRememberToken (AbonneUserId);
    CREATE INDEX IX_T012_Expires ON dbo.T012AbonneRememberToken (ExpiresUtc);
END
GO

/* ---------------------------------------------------------------------
   s0074InsertRememberToken : cree un jeton (a l'emission d'un cookie).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0074InsertRememberToken
    @AbonneUserId  INT,
    @Selector      CHAR(24),
    @ValidatorHash CHAR(64),
    @ExpiresUtc    DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T012AbonneRememberToken (AbonneUserId, Selector, ValidatorHash, ExpiresUtc)
    VALUES (@AbonneUserId, @Selector, @ValidatorHash, @ExpiresUtc);
END
GO

/* ---------------------------------------------------------------------
   s0075GetRememberToken : recupere un jeton par selecteur, avec le contexte
   utilisateur/abonne necessaire a la restauration de session. L'application
   verifie ensuite l'expiration, le hash du validateur (temps constant),
   l'etat actif et le statut de l'abonne.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0075GetRememberToken
    @Selector CHAR(24)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  t.Selector, t.ValidatorHash, t.ExpiresUtc,
            u.Id AS AbonneUserId, u.AbonneId, u.Email, u.FirstName, u.LastName,
            u.IsAdmin, u.IsActive,
            a.RaisonSociale, a.NomAffichage, a.Statut AS AbonneStatut
    FROM    dbo.T012AbonneRememberToken t
    JOIN    dbo.T011AbonneUser u ON u.Id = t.AbonneUserId
    JOIN    dbo.T010Abonne     a ON a.Id = u.AbonneId
    WHERE   t.Selector = @Selector;
END
GO

/* ---------------------------------------------------------------------
   s0076DeleteRememberToken : supprime un jeton (rotation / deconnexion).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0076DeleteRememberToken
    @Selector CHAR(24)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T012AbonneRememberToken WHERE Selector = @Selector;
END
GO

/* ---------------------------------------------------------------------
   s0077PurgeExpiredRememberTokens : hygiene (a appeler par le planificateur).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0077PurgeExpiredRememberTokens
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T012AbonneRememberToken WHERE ExpiresUtc < SYSUTCDATETIME();
    SELECT @@ROWCOUNT AS Purged;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'26_remember_me.sql : termine.';
GO
