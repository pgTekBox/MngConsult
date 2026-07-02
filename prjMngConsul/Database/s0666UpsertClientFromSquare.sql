-- =============================================================================
-- s0666UpsertClientFromSquare
-- Insere ou met a jour un CLIENT MngConsul (T050Party + T054PartyAddress) a
-- partir d'un client Square. Sens ENTRANT (Square -> app). Utilise par le
-- webhook (customer.created/updated) ET par l'import a la demande.
--
-- Cle de rapprochement, dans l'ordre :
--   1. @ReferenceId (= T050Party.Id pousse par nous lors de l'export)
--   2. @SquareCustomerId deja stocke sur un client
--   3. @Email (1er client de type CLIENT avec ce courriel)
--   4. aucun -> creation d'un nouveau client (Type=1)
--
-- @Action OUTPUT : 'created' | 'updated'
-- COALESCE sur les colonnes : ne pas ecraser une valeur locale avec NULL.
--
-- QUOTED_IDENTIFIER ON obligatoire (T050Party a un index filtre).
-- =============================================================================

USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0666UpsertClientFromSquare', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0666UpsertClientFromSquare;
GO

CREATE PROCEDURE dbo.s0666UpsertClientFromSquare
    @CompanyGUID           UNIQUEIDENTIFIER,
    @SquareCustomerId      VARCHAR(100),
    @SquareCustomerVersion BIGINT        = NULL,
    @ReferenceId           VARCHAR(50)   = NULL,
    @Name                  NVARCHAR(200) = NULL,
    @Email                 VARCHAR(200)  = NULL,
    @Phone                 VARCHAR(200)  = NULL,
    @Address1              VARCHAR(500)  = NULL,
    @Address2              VARCHAR(500)  = NULL,
    @City                  VARCHAR(50)   = NULL,
    @PostalCode            VARCHAR(20)   = NULL,
    @Action                VARCHAR(20)   = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PartyId INT = NULL;
    DECLARE @refId INT = NULL;
    IF @ReferenceId IS NOT NULL AND @ReferenceId LIKE '%[0-9]%' AND @ReferenceId NOT LIKE '%[^0-9]%'
        SET @refId = TRY_CONVERT(INT, @ReferenceId);

    -- 1. par reference_id (=PartyId)
    IF @refId IS NOT NULL
        SELECT @PartyId = Id FROM dbo.T050Party
        WHERE Id = @refId AND CompanyGUID = @CompanyGUID AND ISNULL(isDeleted, 0) = 0;

    -- 2. par SquareCustomerId deja stocke
    IF @PartyId IS NULL AND @SquareCustomerId IS NOT NULL
        SELECT TOP 1 @PartyId = Id FROM dbo.T050Party
        WHERE SquareCustomerId = @SquareCustomerId AND CompanyGUID = @CompanyGUID AND ISNULL(isDeleted, 0) = 0
        ORDER BY Id;

    -- 3. par courriel (client existant)
    IF @PartyId IS NULL AND @Email IS NOT NULL AND LEN(LTRIM(RTRIM(@Email))) > 0
        SELECT TOP 1 @PartyId = p.Id
        FROM dbo.T050Party p
        JOIN dbo.T054PartyAddress a ON a.PartyId = p.Id
        WHERE p.CompanyGUID = @CompanyGUID AND ISNULL(p.isDeleted, 0) = 0
          AND p.Type IN (1, 3)
          AND LOWER(LTRIM(RTRIM(a.Email))) = LOWER(LTRIM(RTRIM(@Email)))
        ORDER BY p.Id;

    -- ── Creation ────────────────────────────────────────────────────────────
    IF @PartyId IS NULL
    BEGIN
        INSERT INTO dbo.T050Party
            (CompanyGUID, Name, DisplayName, Type, Origin, Note, isDeleted,
             SquareCustomerId, SquareCustomerVersion, SquareSyncStatus, SquareSyncDate)
        VALUES
            (@CompanyGUID, ISNULL(@Name, N'(Sans nom)'), ISNULL(@Name, N'(Sans nom)'), 1, 1,
             N'Importe de Square', 0,
             @SquareCustomerId, @SquareCustomerVersion, 'IMPORT', GETDATE());
        SET @PartyId = SCOPE_IDENTITY();

        IF @Email IS NOT NULL OR @Phone IS NOT NULL OR @Address1 IS NOT NULL OR @City IS NOT NULL OR @PostalCode IS NOT NULL
        BEGIN
            DECLARE @CountryId INT, @StateId INT;
            SELECT @CountryId = Id FROM dbo.T052Country WHERE LOWER(Name) = 'canada';
            IF @CountryId IS NULL SELECT TOP 1 @CountryId = Id FROM dbo.T052Country ORDER BY Id;
            SELECT TOP 1 @StateId = Id FROM dbo.T053State WHERE LOWER(Name) IN ('quebec', N'québec');
            IF @StateId IS NULL SELECT TOP 1 @StateId = Id FROM dbo.T053State ORDER BY Id;

            INSERT INTO dbo.T054PartyAddress
                (PartyId, AddressTypeId, Name, Address1, Address2, City, StateId, CountryId, PostalCode, Phone, Email, CreatedUTC)
            VALUES
                (@PartyId, 1, N'Principale', @Address1, @Address2, @City, @StateId, @CountryId, @PostalCode, @Phone, @Email, SYSUTCDATETIME());
        END

        SET @Action = 'created';
    END
    ELSE
    -- ── Mise a jour ───────────────────────────────────────────────────────────
    BEGIN
        UPDATE dbo.T050Party
        SET SquareCustomerId      = @SquareCustomerId,
            SquareCustomerVersion = COALESCE(@SquareCustomerVersion, SquareCustomerVersion),
            Name                  = COALESCE(@Name, Name),
            DisplayName           = COALESCE(@Name, DisplayName),
            SquareSyncStatus      = 'IMPORT',
            SquareSyncDate        = GETDATE()
        WHERE Id = @PartyId AND CompanyGUID = @CompanyGUID;

        -- Adresse principale : mise a jour si elle existe, sinon creation
        DECLARE @AddrId INT;
        SELECT TOP 1 @AddrId = Id FROM dbo.T054PartyAddress
        WHERE PartyId = @PartyId
        ORDER BY CASE WHEN AddressTypeId = 1 THEN 0 ELSE 1 END, Id;

        IF @AddrId IS NOT NULL
        BEGIN
            UPDATE dbo.T054PartyAddress
            SET Email      = COALESCE(@Email, Email),
                Phone      = COALESCE(@Phone, Phone),
                Address1   = COALESCE(@Address1, Address1),
                Address2   = COALESCE(@Address2, Address2),
                City       = COALESCE(@City, City),
                PostalCode = COALESCE(@PostalCode, PostalCode)
            WHERE Id = @AddrId;
        END
        ELSE IF @Email IS NOT NULL OR @Phone IS NOT NULL OR @Address1 IS NOT NULL OR @City IS NOT NULL OR @PostalCode IS NOT NULL
        BEGIN
            DECLARE @CId INT, @SId INT;
            SELECT @CId = Id FROM dbo.T052Country WHERE LOWER(Name) = 'canada';
            IF @CId IS NULL SELECT TOP 1 @CId = Id FROM dbo.T052Country ORDER BY Id;
            SELECT TOP 1 @SId = Id FROM dbo.T053State WHERE LOWER(Name) IN ('quebec', N'québec');
            IF @SId IS NULL SELECT TOP 1 @SId = Id FROM dbo.T053State ORDER BY Id;

            INSERT INTO dbo.T054PartyAddress
                (PartyId, AddressTypeId, Name, Address1, Address2, City, StateId, CountryId, PostalCode, Phone, Email, CreatedUTC)
            VALUES
                (@PartyId, 1, N'Principale', @Address1, @Address2, @City, @SId, @CId, @PostalCode, @Phone, @Email, SYSUTCDATETIME());
        END

        SET @Action = 'updated';
    END

    SELECT @PartyId AS PartyId, @Action AS Action;
END
GO
