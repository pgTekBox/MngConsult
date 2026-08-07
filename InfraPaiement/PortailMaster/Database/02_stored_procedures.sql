/* =====================================================================
   PortailMaster - Script 02 : Procedures stockees d'authentification
   ---------------------------------------------------------------------
   Convention du groupe : tous les acces BD passent par des procedures
   stockees nommees sNNNN. Numerotation propre a la base 60secPaiement,
   demarrant a s0001.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0001GetAdminByEmail : retourne l'administrateur du portail par courriel.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0001GetAdminByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
           Id,
           Email,
           PasswordHash,
           FirstName,
           LastName,
           IsActive,
           IsSuperAdmin,
           FailedLoginCount,
           LockoutUntilUtc,
           LastLoginUtc
    FROM   dbo.T001PortalAdmin
    WHERE  Email = @Email;
END
GO

/* ---------------------------------------------------------------------
   s0002UpdateAdminLastLogin : connexion reussie -> horodate et remet a
   zero le compteur d'echecs / le verrouillage.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0002UpdateAdminLastLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T001PortalAdmin
    SET    LastLoginUtc     = SYSUTCDATETIME(),
           FailedLoginCount = 0,
           LockoutUntilUtc  = NULL
    WHERE  Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   s0003RegisterFailedLogin : incremente le compteur d'echecs et pose un
   verrou temporaire de 15 min au-dela de 5 tentatives.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0003RegisterFailedLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T001PortalAdmin
    SET    FailedLoginCount = FailedLoginCount + 1,
           LockoutUntilUtc  = CASE
                                  WHEN FailedLoginCount + 1 >= 5
                                  THEN DATEADD(MINUTE, 15, SYSUTCDATETIME())
                                  ELSE LockoutUntilUtc
                               END
    WHERE  Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   Rappel du GRANT (procs creees apres le GRANT du script 01).
   --------------------------------------------------------------------- */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'02_stored_procedures.sql : termine.';
GO
