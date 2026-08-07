/* =====================================================================
   PortailMaster - Infrastructure de paiement 60secPaiement
   Script 01 : Table des administrateurs du portail + acces applicatif
   ---------------------------------------------------------------------
   A EXECUTER avec un compte admin SQL (sysadmin ou db_owner sur
   60secPaiement), car il cree l'utilisateur de base de donnee mappe
   au login applicatif [MngConsul] (meme login que MailService).

   Ordre d'execution : 01 -> 02 (procs) -> 03 (seed admin).
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   1) Table des administrateurs du portail maitre.
   Ce sont les employes de la plateforme (nous) qui gerent les abonnes.
   Ce n'est PAS la table des abonnes ni de leurs utilisateurs.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.T001PortalAdmin', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T001PortalAdmin
    (
        Id               INT            IDENTITY(1,1) NOT NULL,
        Email            NVARCHAR(256)  NOT NULL,
        PasswordHash     NVARCHAR(100)  NOT NULL,      -- BCrypt
        FirstName        NVARCHAR(100)  NULL,
        LastName         NVARCHAR(100)  NULL,
        IsActive         BIT            NOT NULL CONSTRAINT DF_T001_IsActive     DEFAULT (1),
        IsSuperAdmin     BIT            NOT NULL CONSTRAINT DF_T001_IsSuper      DEFAULT (0),
        FailedLoginCount INT            NOT NULL CONSTRAINT DF_T001_FailedCount  DEFAULT (0),
        LockoutUntilUtc  DATETIME2(0)   NULL,
        LastLoginUtc     DATETIME2(0)   NULL,
        CreatedUtc       DATETIME2(0)   NOT NULL CONSTRAINT DF_T001_CreatedUtc   DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T001PortalAdmin PRIMARY KEY CLUSTERED (Id)
    );

    -- Email unique (insensible a la casse via collation par defaut de la base)
    CREATE UNIQUE INDEX UX_T001PortalAdmin_Email
        ON dbo.T001PortalAdmin (Email);
END
GO

/* ---------------------------------------------------------------------
   2) Acces applicatif : mapper le login serveur [MngConsul] a un
   utilisateur de cette base. L'app se connecte avec ce meme login
   (voir Web.config, comme pour MailService).
   --------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'MngConsul')
BEGIN
    RAISERROR(N'Le login serveur [MngConsul] est introuvable. Creez-le d''abord au niveau du serveur.', 16, 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
BEGIN
    CREATE USER [MngConsul] FOR LOGIN [MngConsul];
END
GO

-- Les acces aux tables passent par les procedures stockees (chainage de
-- proprietaire). On accorde donc EXECUTE sur le schema dbo. Le GRANT est
-- reexecute en fin de script 02 pour couvrir les procs creees ensuite.
GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'01_setup_admin_tables.sql : termine.';
GO
