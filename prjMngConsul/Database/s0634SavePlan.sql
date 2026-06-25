SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0634SavePlan
-- Insert (si @Id=0) ou Update d'un forfait (T021Plan).
-- Retourne @NewId (Id inséré ou @Id en édition).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0634SavePlan
    @Id              INT,
    @Code            VARCHAR(50),
    @Name            NVARCHAR(100),
    @Description     NVARCHAR(500)  = NULL,
    @DescriptionLong NVARCHAR(MAX)  = NULL,
    @Amount          DECIMAL(18,2),
    @Currency        VARCHAR(10),
    @BillingCycle    VARCHAR(20),
    @ProcessorName   VARCHAR(50)    = NULL,
    @StripeProductId VARCHAR(50)    = NULL,
    @StripePriceId   VARCHAR(50)    = NULL,
    @TrialDays       INT            = 0,
    @MaxUsers        INT            = NULL,
    @MaxClients      INT            = NULL,
    @MaxDocuments    INT            = NULL,
    @MaxStorageMB    INT            = NULL,
    @Features        NVARCHAR(MAX)  = NULL,
    @DisplayOrder    INT            = 0,
    @IsRecommended   BIT            = 0,
    @IsActive        BIT            = 1,
    @Tagline         NVARCHAR(200)  = NULL,
    @EmployeeRange   NVARCHAR(100)  = NULL,
    @BadgeText       NVARCHAR(100)  = NULL,
    @ModifiedBy      NVARCHAR(200)  = NULL,
    @NewId           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Id, 0) = 0
    BEGIN
        INSERT INTO dbo.T021Plan
            (Code, Name, Description, DescriptionLong, Amount, Currency, BillingCycle,
             ProcessorName, StripeProductId, StripePriceId, TrialDays,
             MaxUsers, MaxClients, MaxDocuments, MaxStorageMB, Features,
             DisplayOrder, IsRecommended, IsActive, Tagline, EmployeeRange, BadgeText,
             CreatedOn, CreatedBy, IsDeleted)
        VALUES
            (@Code, @Name, @Description, @DescriptionLong, @Amount, @Currency, @BillingCycle,
             @ProcessorName, @StripeProductId, @StripePriceId, @TrialDays,
             @MaxUsers, @MaxClients, @MaxDocuments, @MaxStorageMB, @Features,
             @DisplayOrder, @IsRecommended, @IsActive, @Tagline, @EmployeeRange, @BadgeText,
             GETDATE(), @ModifiedBy, 0);

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T021Plan
        SET Code            = @Code,
            Name            = @Name,
            Description     = @Description,
            DescriptionLong = @DescriptionLong,
            Amount          = @Amount,
            Currency        = @Currency,
            BillingCycle    = @BillingCycle,
            ProcessorName   = @ProcessorName,
            StripeProductId = @StripeProductId,
            StripePriceId   = @StripePriceId,
            TrialDays       = @TrialDays,
            MaxUsers        = @MaxUsers,
            MaxClients      = @MaxClients,
            MaxDocuments    = @MaxDocuments,
            MaxStorageMB    = @MaxStorageMB,
            Features        = @Features,
            DisplayOrder    = @DisplayOrder,
            IsRecommended   = @IsRecommended,
            IsActive        = @IsActive,
            Tagline         = @Tagline,
            EmployeeRange   = @EmployeeRange,
            BadgeText       = @BadgeText,
            ModifiedOn      = GETDATE(),
            ModifiedBy      = @ModifiedBy
        WHERE Id = @Id;

        SET @NewId = @Id;
    END
END
