SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0648SaveAdmin
-- Insert (si @Id=0) ou Update d'un administrateur (T900AdminUser).
-- @PasswordHash : NULL en édition = on conserve le mot de passe actuel.
--                 Obligatoire à la création.
-- Retourne @NewId.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0648SaveAdmin
    @Id           INT,
    @Email        NVARCHAR(200),
    @PasswordHash NVARCHAR(500) = NULL,
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @IsActive     BIT           = 1,
    @ModifiedBy   NVARCHAR(200) = NULL,
    @NewId        INT OUTPUT
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

        INSERT INTO dbo.T900AdminUser
            (Email, PasswordHash, FirstName, LastName, IsActive, CreatedBy)
        VALUES
            (@Email, @PasswordHash, @FirstName, @LastName, @IsActive, @ModifiedBy);

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T900AdminUser
        SET Email        = @Email,
            FirstName    = @FirstName,
            LastName     = @LastName,
            IsActive     = @IsActive,
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),
            ModifiedOn   = GETDATE(),
            ModifiedBy   = @ModifiedBy
        WHERE Id = @Id;

        SET @NewId = @Id;
    END
END
