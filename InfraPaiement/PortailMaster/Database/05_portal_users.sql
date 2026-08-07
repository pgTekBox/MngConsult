/* =====================================================================
   PortailMaster - Script 05 : Gestion des utilisateurs du portail
   ---------------------------------------------------------------------
   Procedures de gestion des administrateurs (staff plateforme) stockes
   dans T001PortalAdmin (creee au script 01). Reservees en pratique aux
   super-administrateurs (controle applicatif).

   A executer APRES 01/02. Procs numerotees s0008+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0008ListAdmins : liste filtrable des administrateurs du portail.
   @Search : filtre sur courriel / prenom / nom. NULL/'' = tous.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0008ListAdmins
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            Email,
            FirstName,
            LastName,
            IsActive,
            IsSuperAdmin,
            LastLoginUtc,
            CreatedUtc
    FROM    dbo.T001PortalAdmin
    WHERE   (@Search IS NULL OR @Search = N''
             OR Email     LIKE N'%' + @Search + N'%'
             OR FirstName LIKE N'%' + @Search + N'%'
             OR LastName  LIKE N'%' + @Search + N'%')
    ORDER BY IsActive DESC, LastName, FirstName, Email;
END
GO

/* ---------------------------------------------------------------------
   s0009GetAdmin : fiche d'un administrateur (sans le hash).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0009GetAdmin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id, Email, FirstName, LastName, IsActive, IsSuperAdmin,
            LastLoginUtc, CreatedUtc
    FROM    dbo.T001PortalAdmin
    WHERE   Id = @Id;
END
GO

/* ---------------------------------------------------------------------
   s0010SaveAdmin : upsert d'un administrateur.
     @Id = 0  -> insertion ; @PasswordHash OBLIGATOIRE (non NULL).
     @Id > 0  -> mise a jour ; @PasswordHash NULL = mot de passe inchange.
   Le hash BCrypt est calcule cote application (jamais le mot de passe clair).
   L'unicite du courriel est garantie par l'index UX_T001PortalAdmin_Email
   (l'app intercepte la violation 2601/2627 pour un message convivial).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0010SaveAdmin
    @Id           INT OUTPUT,
    @Email        NVARCHAR(256),
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @IsActive     BIT           = 1,
    @IsSuperAdmin BIT           = 0,
    @PasswordHash NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id IS NULL OR @Id = 0
    BEGIN
        IF @PasswordHash IS NULL OR LEN(@PasswordHash) = 0
        BEGIN
            RAISERROR(N'Un mot de passe est requis pour un nouvel utilisateur.', 16, 1);
            RETURN;
        END

        INSERT INTO dbo.T001PortalAdmin
            (Email, PasswordHash, FirstName, LastName, IsActive, IsSuperAdmin)
        VALUES
            (@Email, @PasswordHash, @FirstName, @LastName, @IsActive, @IsSuperAdmin);

        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
    BEGIN
        UPDATE dbo.T001PortalAdmin
        SET Email        = @Email,
            FirstName    = @FirstName,
            LastName     = @LastName,
            IsActive     = @IsActive,
            IsSuperAdmin = @IsSuperAdmin,
            PasswordHash = CASE WHEN @PasswordHash IS NULL OR LEN(@PasswordHash) = 0
                                THEN PasswordHash
                                ELSE @PasswordHash END
        WHERE Id = @Id;
    END

    SELECT @Id AS Id;
END
GO

/* Rappel du GRANT pour les nouvelles procs. */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'05_portal_users.sql : termine.';
GO
