-- =============================================================================
-- T384 — Un cabinet garde toujours au moins un administrateur actif
-- Les chemins du portail (s0924, s1004, s1006) refusaient déjà de retirer le
-- dernier administrateur (ErrorCode 3). Restait la page Utilisateurs de l'ERP :
--   s0204SaveUser   (décocher « Actif »)  et  s0205DeleteUser (supprimer)
-- pouvaient désactiver le compte du dernier administrateur d'un cabinet.
--   fDernierAdminCabinet : 1 si l'utilisateur est le seul administrateur
--                          (admin / solo) ACTIF d'un cabinet
--   s0204 / s0205        : THROW 51140 dans ce cas
-- Corrige aussi s0204 : @IsAccountant non transmis (page wbfUserEdit) remettait
-- T015User.IsAccountant à 0 à chaque enregistrement — il est maintenant conservé.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION dbo.fDernierAdminCabinet(@UserGUID uniqueidentifier)
RETURNS bit
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dbo.T332CabinetMembre m
        WHERE m.UserGUID = @UserGUID AND m.IsActive = 1 AND m.Role IN ('admin', 'solo')
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.T332CabinetMembre a
              JOIN dbo.T015User u ON u.UserGUID = a.UserGUID AND u.IsDeleted = 0 AND u.IsActive = 1
              WHERE a.CabinetId = m.CabinetId AND a.IsActive = 1 AND a.Role IN ('admin', 'solo')
                AND a.UserGUID <> @UserGUID))
        RETURN 1;
    RETURN 0;
END
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
    END
END
GO

CREATE OR ALTER PROCEDURE dbo.s0205DeleteUser
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT,
    @ModifiedBy  NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Le dernier administrateur actif d'un cabinet ne peut pas être supprimé
    DECLARE @g uniqueidentifier = (SELECT UserGUID FROM dbo.T015User
                                   WHERE Id = @Id AND CompanyGUID = @CompanyGUID AND IsDeleted = 0 AND IsActive = 1);
    IF @g IS NOT NULL AND dbo.fDernierAdminCabinet(@g) = 1
        THROW 51140, N'DERNIER_ADMIN_CABINET', 1;

    UPDATE dbo.T015User
    SET IsDeleted  = 1,
        IsActive   = 0,
        ModifiedOn = GETDATE(),
        ModifiedBy = @ModifiedBy
    WHERE Id = @Id
      AND CompanyGUID = @CompanyGUID;
END
GO
