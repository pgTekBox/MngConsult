/* =====================================================================
   PortailPartenaire - Script 47 : acces au portail abonne, gere par le
   partenaire
   ---------------------------------------------------------------------
   Un partenaire provisionne ses abonnes, mais s0115CreateAbonneForPartner
   ne cree AUCUN utilisateur : le locataire n'avait donc pas d'acces au
   portail abonne tant que le staff n'en creait pas un.

   Ces trois procedures permettent au partenaire de gerer lui-meme les
   acces de SES abonnes, avec la meme garde d'isolation partout : chaque
   appel verifie que l'abonne vise appartient bien au partenaire appelant.

     s0125ResetAbonneUserPassword    : nouveau mot de passe (hash BCrypt
                                       calcule par l'application), remise a
                                       zero des echecs et deverrouillage.
     s0126ListAbonneUsersForPartner  : utilisateurs d'un abonne du partenaire.
     s0127CreateAbonneUserForPartner : premier (ou nieme) utilisateur.

   A executer APRES 46. Procs libres ensuite : s0128+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* --- s0126ListAbonneUsersForPartner --- */
CREATE OR ALTER PROCEDURE dbo.s0126ListAbonneUsersForPartner
    @AbonneId     INT,
    @PartenaireId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  u.Id, u.AbonneId, u.Email, u.FirstName, u.LastName,
            u.IsAdmin, u.IsActive, u.LockoutUntilUtc, u.LastLoginUtc, u.CreatedUtc
    FROM    dbo.T011AbonneUser u
    JOIN    dbo.T010Abonne a ON a.Id = u.AbonneId
    WHERE   u.AbonneId = @AbonneId
      AND   a.PartenaireId = @PartenaireId
    ORDER BY u.IsActive DESC, u.Email;
END
GO

/* --- s0125ResetAbonneUserPassword --- */
CREATE OR ALTER PROCEDURE dbo.s0125ResetAbonneUserPassword
    @UserId       INT,
    @PartenaireId INT,
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PasswordHash IS NULL OR LEN(@PasswordHash) < 20
    BEGIN RAISERROR(N'Hash de mot de passe invalide.', 16, 1); RETURN; END

    /* Garde d'isolation : l'utilisateur doit appartenir a un abonne du partenaire. */
    IF NOT EXISTS (SELECT 1
                   FROM dbo.T011AbonneUser u
                   JOIN dbo.T010Abonne a ON a.Id = u.AbonneId
                   WHERE u.Id = @UserId AND a.PartenaireId = @PartenaireId)
    BEGIN RAISERROR(N'Utilisateur introuvable pour ce partenaire.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM dbo.T011AbonneUser WHERE Id = @UserId AND IsActive = 1)
    BEGIN RAISERROR(N'Ce compte est desactive.', 16, 1); RETURN; END

    UPDATE dbo.T011AbonneUser
    SET PasswordHash    = @PasswordHash,
        FailedAttempts  = 0,
        LockoutUntilUtc = NULL,
        ModifiedUtc     = SYSUTCDATETIME()
    WHERE Id = @UserId;
END
GO

/* --- s0127CreateAbonneUserForPartner --- */
CREATE OR ALTER PROCEDURE dbo.s0127CreateAbonneUserForPartner
    @AbonneId     INT,
    @PartenaireId INT,
    @Email        NVARCHAR(256),
    @PasswordHash NVARCHAR(100),
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @IsAdmin      BIT           = 1,
    @Id           INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Email IS NULL OR LEN(LTRIM(RTRIM(@Email))) = 0
    BEGIN RAISERROR(N'Le courriel est requis.', 16, 1); RETURN; END

    IF @PasswordHash IS NULL OR LEN(@PasswordHash) < 20
    BEGIN RAISERROR(N'Hash de mot de passe invalide.', 16, 1); RETURN; END

    /* Garde d'isolation : l'abonne doit appartenir au partenaire. */
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId AND PartenaireId = @PartenaireId)
    BEGIN RAISERROR(N'Abonne introuvable pour ce partenaire.', 16, 1); RETURN; END

    INSERT INTO dbo.T011AbonneUser (AbonneId, Email, PasswordHash, FirstName, LastName, IsAdmin, IsActive)
    VALUES (@AbonneId, LTRIM(RTRIM(@Email)), @PasswordHash, @FirstName, @LastName, @IsAdmin, 1);

    SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    SELECT @Id AS Id;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'47_partner_abonne_users.sql : termine.';
GO
