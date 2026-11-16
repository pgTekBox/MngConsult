-- =============================================================================
-- T388 — Page Utilisateurs de l'ERP : la boîte @60sec.ca suit le mot de passe
-- Quand s0204SaveUser change le mot de passe d'un utilisateur (champ mot de
-- passe rempli dans wbfUserEdit) qui est membre actif d'un cabinet comptable
-- et dont le courriel finit par @60sec.ca, sa boîte MailService
-- (SmtpLocalRecipient, créée par T387) reçoit le même mot de passe.
-- Reprend s0204 de T384 (garde du dernier administrateur, IsAccountant conservé).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0204SaveUser
    @Id              INT,
    @CompanyGUID     UNIQUEIDENTIFIER,
    @Email           NVARCHAR(200),
    @PasswordHash    NVARCHAR(500) = NULL,
    @FirstName       NVARCHAR(100) = NULL,
    @LastName        NVARCHAR(100) = NULL,
    @IsAdmin         BIT = 0,
    @IsAccountant    BIT = NULL,          -- NULL = conserver la valeur actuelle (T384)
    @IsActive        BIT = 1,
    @ModifiedBy      NVARCHAR(200) = NULL,
    @NewId           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Id, 0) = 0
    BEGIN
        IF @PasswordHash IS NULL
        BEGIN
            RAISERROR('Le mot de passe est obligatoire à la création.', 16, 1);
            RETURN;
        END

        INSERT INTO dbo.T015User
            (CompanyGUID, Email, PasswordHash, FirstName, LastName,
             IsAdmin, IsAccountant, IsActive, CreatedBy)
        VALUES
            (@CompanyGUID, @Email, @PasswordHash, @FirstName, @LastName,
             @IsAdmin, ISNULL(@IsAccountant, 0), @IsActive, @ModifiedBy);

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- Le dernier administrateur actif d'un cabinet ne peut pas être désactivé
        IF @IsActive = 0
        BEGIN
            DECLARE @g uniqueidentifier = (SELECT UserGUID FROM dbo.T015User
                                           WHERE Id = @Id AND CompanyGUID = @CompanyGUID AND IsActive = 1);
            IF @g IS NOT NULL AND dbo.fDernierAdminCabinet(@g) = 1
                THROW 51140, N'DERNIER_ADMIN_CABINET', 1;
        END

        UPDATE dbo.T015User
        SET Email        = @Email,
            FirstName    = @FirstName,
            LastName     = @LastName,
            IsAdmin      = @IsAdmin,
            IsAccountant = ISNULL(@IsAccountant, IsAccountant),
            IsActive     = @IsActive,
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),
            ModifiedOn   = GETDATE(),
            ModifiedBy   = @ModifiedBy
        WHERE Id = @Id
          AND CompanyGUID = @CompanyGUID;

        SET @NewId = @Id;

        -- T388 : la boîte @60sec.ca d'un membre de cabinet suit le nouveau mot de passe
        IF @PasswordHash IS NOT NULL
        BEGIN
            DECLARE @mail nvarchar(200), @ug uniqueidentifier;
            SELECT @mail = LTRIM(RTRIM(Email)), @ug = UserGUID
            FROM dbo.T015User WHERE Id = @Id AND CompanyGUID = @CompanyGUID AND IsDeleted = 0;
            IF @mail LIKE '%@60sec.ca'
               AND EXISTS (SELECT 1 FROM dbo.T332CabinetMembre WHERE UserGUID = @ug AND IsActive = 1)
                UPDATE MailService.dbo.SmtpLocalRecipient
                SET PasswordHash = @PasswordHash, PasswordSetOn = SYSUTCDATETIME()
                WHERE LTRIM(RTRIM(Email)) = @mail;
        END
    END
END
GO
