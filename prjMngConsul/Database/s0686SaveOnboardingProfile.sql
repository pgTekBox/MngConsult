SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0686SaveOnboardingProfile
-- Sauvegarde les 12 champs de wbfNewUser : identité (T015User) +
-- infos entreprise (T010Company) + ProfileCompleted (%).
-- La ligne T010Company existe déjà (créée à l'inscription).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0686SaveOnboardingProfile
    @UserId            INT,
    @CompanyGUID       UNIQUEIDENTIFIER,
    @FirstName         NVARCHAR(100),
    @LastName          NVARCHAR(100),
    @Phone             NVARCHAR(50),
    @LegalName         VARCHAR(100),
    @NEQ               NVARCHAR(50),
    @IncorporationDate DATE,
    @BusinessNumber    NVARCHAR(50),
    @FiscalYearEnd     DATE,
    @TpsNumber         NVARCHAR(50),
    @TvqNumber         NVARCHAR(50),
    @HstNumber         NVARCHAR(50),
    @ProfileCompleted  INT,
    @ModifiedBy        NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T015User
    SET FirstName  = @FirstName,
        LastName   = @LastName,
        Phone      = @Phone,
        ModifiedOn = GETDATE(),
        ModifiedBy = @ModifiedBy
    WHERE Id = @UserId;

    UPDATE dbo.T010Company
    SET LegalName         = @LegalName,
        -- Le nom légal sert aussi de nom d'entreprise (T010Company.Name, max 50).
        Name              = CASE WHEN @LegalName IS NULL OR @LegalName = ''
                                 THEN Name ELSE LEFT(@LegalName, 50) END,
        NEQ               = @NEQ,
        IncorporationDate = @IncorporationDate,
        BusinessNumber    = @BusinessNumber,
        FiscalYearEnd     = @FiscalYearEnd,
        TpsNumber         = @TpsNumber,
        TvqNumber         = @TvqNumber,
        HstNumber         = @HstNumber,
        ProfileCompleted  = @ProfileCompleted,
        ModifiedOn        = GETDATE(),
        ModifiedBy        = @ModifiedBy
    WHERE CompanyGUID = @CompanyGUID;
END
GO
