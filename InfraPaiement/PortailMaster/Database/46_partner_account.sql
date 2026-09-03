/* =====================================================================
   PortailPartenaire - Script 46 : page « Mon compte »
   ---------------------------------------------------------------------
   Permet a un utilisateur partenaire (T046PartenaireUser) de consulter
   son compte et de changer lui-meme son mot de passe depuis le portail
   partenaire, sans passer par le staff.

     s0123ChangePartnerUserPassword : remplace le hash BCrypt, remet a zero
       le compteur d'echecs et leve un eventuel verrouillage.
     s0124GetPartnerUserById : fiche de l'utilisateur connecte (avec le hash,
       necessaire a la verification du mot de passe actuel).

   Le hachage BCrypt est fait par l'application ; la base ne voit jamais le
   mot de passe en clair.

   A executer APRES 45. Procs libres ensuite : s0125+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* --- s0124GetPartnerUserById : l'utilisateur et son partenaire. --- */
CREATE OR ALTER PROCEDURE dbo.s0124GetPartnerUserById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  u.Id, u.PartenaireId, u.Email, u.PasswordHash, u.FirstName, u.LastName,
            u.IsAdmin, u.IsActive, u.LockoutUntilUtc, u.LastLoginUtc, u.CreatedUtc,
            p.RaisonSociale, p.NomAffichage, p.Statut AS PartenaireStatut
    FROM    dbo.T046PartenaireUser u
    JOIN    dbo.T045Partenaire p ON p.Id = u.PartenaireId
    WHERE   u.Id = @Id;
END
GO

/* --- s0123ChangePartnerUserPassword : nouveau hash + deverrouillage.
       Refuse un compte inconnu ou desactive. --- */
CREATE OR ALTER PROCEDURE dbo.s0123ChangePartnerUserPassword
    @Id           INT,
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PasswordHash IS NULL OR LEN(@PasswordHash) < 20
    BEGIN RAISERROR(N'Hash de mot de passe invalide.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM dbo.T046PartenaireUser WHERE Id = @Id)
    BEGIN RAISERROR(N'Utilisateur introuvable.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM dbo.T046PartenaireUser WHERE Id = @Id AND IsActive = 1)
    BEGIN RAISERROR(N'Ce compte est desactive.', 16, 1); RETURN; END

    UPDATE dbo.T046PartenaireUser
    SET PasswordHash    = @PasswordHash,
        FailedAttempts  = 0,
        LockoutUntilUtc = NULL,
        ModifiedUtc     = SYSUTCDATETIME()
    WHERE Id = @Id;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'46_partner_account.sql : termine.';
GO
