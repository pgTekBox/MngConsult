/* =====================================================================
   PortailABN - Script 22 : Utilisateurs du portail des abonnes
   ---------------------------------------------------------------------
   Le portail des abonnes (PortailABN) est l'interface libre-service que
   chaque abonne (tenant) utilise pour gerer SON compte : clients,
   fournisseurs, encaissements, decaissements, releve, cles d'API,
   webhooks. Chaque utilisateur appartient a UN abonne (T010Abonne).

   Auth : courriel + mot de passe BCrypt, avec verrouillage temporaire
   apres plusieurs echecs (memes regles que T001PortalAdmin cote maitre).

   A executer APRES 01-21. Procs numerotees s0067+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   Table des utilisateurs abonnes
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T011AbonneUser', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T011AbonneUser
    (
        Id                 INT              IDENTITY(1,1) NOT NULL,
        AbonneId           INT              NOT NULL,   -- tenant (T010Abonne.Id)
        Email              NVARCHAR(256)    NOT NULL,
        PasswordHash       NVARCHAR(100)    NOT NULL,   -- BCrypt
        FirstName          NVARCHAR(100)    NULL,
        LastName           NVARCHAR(100)    NULL,
        -- Admin de l'abonne (peut gerer cles d'API / webhooks / autres users) ?
        IsAdmin            BIT              NOT NULL CONSTRAINT DF_T011_Admin   DEFAULT (1),
        IsActive           BIT              NOT NULL CONSTRAINT DF_T011_Active  DEFAULT (1),
        FailedAttempts     INT              NOT NULL CONSTRAINT DF_T011_Failed  DEFAULT (0),
        LockoutUntilUtc    DATETIME2(0)     NULL,
        LastLoginUtc       DATETIME2(0)     NULL,
        CreatedUtc         DATETIME2(0)     NOT NULL CONSTRAINT DF_T011_Created DEFAULT (SYSUTCDATETIME()),
        ModifiedUtc        DATETIME2(0)     NULL,
        CONSTRAINT PK_T011AbonneUser PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T011AbonneUser_Email UNIQUE (Email),
        CONSTRAINT FK_T011_Abonne FOREIGN KEY (AbonneId) REFERENCES dbo.T010Abonne(Id)
    );

    CREATE INDEX IX_T011AbonneUser_Abonne ON dbo.T011AbonneUser (AbonneId);
END
GO

/* ---------------------------------------------------------------------
   s0067GetAbonneUserByEmail : recupere un utilisateur abonne actif par
   courriel, en joignant la raison sociale et le statut de l'abonne
   (pour bloquer l'acces si l'abonne est suspendu/ferme).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0067GetAbonneUserByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  u.Id, u.AbonneId, u.Email, u.PasswordHash, u.FirstName, u.LastName,
            u.IsAdmin, u.IsActive, u.LockoutUntilUtc,
            a.RaisonSociale, a.NomAffichage, a.Statut AS AbonneStatut
    FROM    dbo.T011AbonneUser u
    JOIN    dbo.T010Abonne a ON a.Id = u.AbonneId
    WHERE   u.Email = @Email;
END
GO

/* ---------------------------------------------------------------------
   s0068UpdateAbonneUserLastLogin : connexion reussie (raz compteur).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0068UpdateAbonneUserLastLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T011AbonneUser
    SET LastLoginUtc    = SYSUTCDATETIME(),
        FailedAttempts  = 0,
        LockoutUntilUtc = NULL
    WHERE Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   s0069RegisterAbonneUserFailedLogin : incremente le compteur d'echecs
   et verrouille 15 min au-dela de 5 tentatives.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0069RegisterAbonneUserFailedLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T011AbonneUser
    SET FailedAttempts  = FailedAttempts + 1,
        LockoutUntilUtc = CASE WHEN FailedAttempts + 1 >= 5
                               THEN DATEADD(MINUTE, 15, SYSUTCDATETIME())
                               ELSE LockoutUntilUtc END
    WHERE Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   s0070SaveAbonneUser : upsert d'un utilisateur abonne (gestion interne
   ou seed). @Id = 0 -> insertion. Le hash doit etre calcule cote appli.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0070SaveAbonneUser
    @Id           INT OUTPUT,
    @AbonneId     INT,
    @Email        NVARCHAR(256),
    @PasswordHash NVARCHAR(100) = NULL,
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @IsAdmin      BIT           = 1,
    @IsActive     BIT           = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T011AbonneUser (AbonneId, Email, PasswordHash, FirstName, LastName, IsAdmin, IsActive)
        VALUES (@AbonneId, @Email, @PasswordHash, @FirstName, @LastName, @IsAdmin, @IsActive);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T011AbonneUser
        SET AbonneId     = @AbonneId,
            Email        = @Email,
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),
            FirstName    = @FirstName,
            LastName     = @LastName,
            IsAdmin      = @IsAdmin,
            IsActive     = @IsActive,
            ModifiedUtc  = SYSUTCDATETIME()
        WHERE Id = @Id;
    END

    SELECT @Id AS Id;
END
GO

/* ---------------------------------------------------------------------
   Seed d'un utilisateur de demonstration rattache au premier abonne actif
   (ou, a defaut, au premier abonne existant). Le hash correspond au mot
   de passe « Abonne2026 » (BCrypt, cost 11).
   Idempotent : ne cree l'utilisateur que s'il n'existe pas deja.
   --------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.T011AbonneUser WHERE Email = N'demo@abonne.ca')
   AND EXISTS (SELECT 1 FROM dbo.T010Abonne)
BEGIN
    DECLARE @seedAbonne INT =
        COALESCE(
            (SELECT TOP 1 Id FROM dbo.T010Abonne WHERE Statut = N'Actif' ORDER BY Id),
            (SELECT TOP 1 Id FROM dbo.T010Abonne ORDER BY Id));

    INSERT INTO dbo.T011AbonneUser (AbonneId, Email, PasswordHash, FirstName, LastName, IsAdmin, IsActive)
    VALUES (@seedAbonne, N'demo@abonne.ca',
            N'$2a$11$Runtx5XUgAjQTzj6zNvsseAewPRiw9.4hp2rvctoEcYfkDvnI83O6', -- Abonne2026 (remplacer si besoin)
            N'Démo', N'Abonné', 1, 1);

    PRINT N'Utilisateur de démonstration créé : demo@abonne.ca (abonné Id ' + CAST(@seedAbonne AS NVARCHAR(10)) + N').';
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'22_abonne_users.sql : termine.';
GO
