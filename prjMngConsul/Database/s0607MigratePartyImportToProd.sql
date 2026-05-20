-- =============================================================================
-- s0607MigratePartyImportToProd
-- Pousse les lignes staging.PartyImport (Status='Pending') vers la production
-- T050Party + T054PartyAddress. Saute les doublons par Name dans la même Company.
--
-- Marque chaque ligne staging en sortie :
--   - 'Migrated' + MigratedToPartyId + MigratedDate  si succès
--   - 'Skipped'  + ErrorMessage                       si nom manquant ou doublon
--   - 'Error'    + ErrorMessage                       si exception
--
-- Retourne : ImportFileId, Migrated, Skipped, Errors, TotalPending
-- =============================================================================

IF OBJECT_ID('dbo.s0607MigratePartyImportToProd', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0607MigratePartyImportToProd;
GO

CREATE PROCEDURE dbo.s0607MigratePartyImportToProd
    @ImportFileId          INT,
    @CompanyGUID           UNIQUEIDENTIFIER = NULL,  -- NULL → lit depuis staging.ImportFiles
    @AddressTypeId         INT              = 1,     -- adresse principale par défaut
    @PartyTypeClient       INT              = NULL,  -- T055PartyType.Id pour clients      ; NULL = auto via s0022
    @PartyTypeFournisseur  INT              = NULL,  -- T055PartyType.Id pour fournisseurs ; NULL = auto via s0022
    @PartyCodeiD           INT              = 1,
    @Origin                INT              = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Résoudre CompanyGUID ───────────────────────────────────────────────
    IF @CompanyGUID IS NULL
        SELECT @CompanyGUID = CompanyGUID FROM staging.ImportFiles WHERE Id = @ImportFileId;

    IF @CompanyGUID IS NULL
    BEGIN
        RAISERROR('CompanyGUID requis (non trouvé sur staging.ImportFiles Id=%d).', 16, 1, @ImportFileId);
        RETURN;
    END

    -- ── Résoudre @PartyTypeClient / @PartyTypeFournisseur depuis T055PartyType ─
    -- Mapping par TypeCode (stable et sémantique) :
    --   TypeCode='CLIENT'       → utilisé pour TypeImport='Client'
    --   TypeCode='FOURNISSEUR'  → utilisé pour TypeImport='Fournisseur'
    -- Si T050Party.Type est nullable et qu'aucun type n'est trouvé, on laisse NULL.
    IF @PartyTypeClient IS NULL
        SELECT @PartyTypeClient = Id FROM dbo.T055PartyType WHERE TypeCode = 'CLIENT';

    IF @PartyTypeFournisseur IS NULL
        SELECT @PartyTypeFournisseur = Id FROM dbo.T055PartyType WHERE TypeCode = 'FOURNISSEUR';

    -- ── Compteurs ──────────────────────────────────────────────────────────
    DECLARE @TotalPending INT, @Migrated INT = 0, @Skipped INT = 0, @Errors INT = 0;
    SELECT @TotalPending = COUNT(*) FROM staging.PartyImport
    WHERE ImportFileId = @ImportFileId AND Status = 'Pending';

    -- ── Variables curseur ──────────────────────────────────────────────────
    DECLARE @StageId INT, @Name NVARCHAR(500), @Attention NVARCHAR(200),
            @Address1 NVARCHAR(500), @Address2 NVARCHAR(500), @City NVARCHAR(50),
            @Province NVARCHAR(50), @PostalCode NVARCHAR(20), @Country NVARCHAR(50),
            @Phone NVARCHAR(200), @Email NVARCHAR(200),
            @TPS NVARCHAR(20), @TVQ NVARCHAR(20),
            @CompteAuxClient NVARCHAR(20), @CompteAuxFournisseur NVARCHAR(20),
            @TypeImport NVARCHAR(20);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id, Name, Attention, Address1, Address2, City, Province,
               PostalCode, Country, Phone, Email, TPS, TVQ,
               CompteAuxClient, CompteAuxFournisseur, TypeImport
        FROM staging.PartyImport
        WHERE ImportFileId = @ImportFileId AND Status = 'Pending'
        ORDER BY ISNULL(LineNumber, 0), Id;

    -- ── Pré-calculer les défauts T052Country / T053State ───────────────────
    -- StateId et CountryId sont NOT NULL dans T054PartyAddress, donc on a
    -- toujours besoin d'une valeur. On utilise 'Canada' / 'unknown' en repli.
    DECLARE @DefaultCountryId INT, @DefaultStateId INT;
    SELECT @DefaultCountryId = Id FROM dbo.T052Country WHERE LOWER(Name) = 'canada';
    SELECT @DefaultStateId   = Id FROM dbo.T053State   WHERE LOWER(Name) = 'unknown';
    -- ultime fallback : prendre le 1er Id si rien ne matche
    IF @DefaultCountryId IS NULL SELECT TOP 1 @DefaultCountryId = Id FROM dbo.T052Country ORDER BY Id;
    IF @DefaultStateId   IS NULL SELECT TOP 1 @DefaultStateId   = Id FROM dbo.T053State   ORDER BY Id;

    -- Variables réutilisées dans le curseur (déclarées 1 fois, RESET à chaque itération)
    DECLARE @StateId INT, @CountryId INT, @NewPartyId INT,
            @PartyTypeForRow INT,
            @Cn NVARCHAR(50), @Pn NVARCHAR(50);

    OPEN cur;
    FETCH NEXT FROM cur INTO @StageId, @Name, @Attention, @Address1, @Address2, @City,
                              @Province, @PostalCode, @Country, @Phone, @Email,
                              @TPS, @TVQ, @CompteAuxClient, @CompteAuxFournisseur, @TypeImport;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Nom requis
            IF @Name IS NULL OR LEN(LTRIM(RTRIM(@Name))) = 0
            BEGIN
                UPDATE staging.PartyImport
                SET Status = 'Skipped', ErrorMessage = 'Nom manquant'
                WHERE Id = @StageId;
                SET @Skipped += 1;
            END
            ELSE
            BEGIN
                -- Doublon par Name dans la même Company ?
                DECLARE @ExistingId INT = NULL;
                SELECT TOP 1 @ExistingId = Id
                FROM T050Party
                WHERE CompanyGUID = @CompanyGUID
                  AND ISNULL(isDeleted, 0) = 0
                  AND LOWER(LTRIM(RTRIM(Name))) = LOWER(LTRIM(RTRIM(@Name)));

                IF @ExistingId IS NOT NULL
                BEGIN
                    UPDATE staging.PartyImport
                    SET Status = 'Skipped',
                        MigratedToPartyId = @ExistingId,
                        ErrorMessage = 'Doublon : un tiers avec ce nom existe déjà (Id=' + CAST(@ExistingId AS VARCHAR(10)) + ')'
                    WHERE Id = @StageId;
                    SET @Skipped += 1;
                END
                ELSE
                BEGIN
                    BEGIN TRANSACTION;

                    -- Choisir le bon T055PartyType.Id selon TypeImport de la ligne
                    SET @PartyTypeForRow =
                        CASE WHEN @TypeImport = 'Client'      THEN @PartyTypeClient
                             WHEN @TypeImport = 'Fournisseur' THEN @PartyTypeFournisseur
                        END;

                    -- INSERT dans T050Party
                    INSERT INTO T050Party (CompanyGUID, Name, DisplayName, TPS, TVQ, WebSite,
                                           Type, Origin, Note, CompteAuxClient, CompteAuxFournisseur,
                                           isDeleted)
                    VALUES (@CompanyGUID, @Name, @Name, @TPS, @TVQ, NULL,
                            @PartyTypeForRow, @Origin, NULL, @CompteAuxClient, @CompteAuxFournisseur,
                            0);
                    SET @NewPartyId = SCOPE_IDENTITY();

                    -- ── Résoudre Country → CountryId ────────────────────────
                    -- 1) exact Name, 2) abréviation, 3) défaut 'Canada'
                    SET @CountryId = NULL;
                    IF @Country IS NOT NULL AND LEN(LTRIM(RTRIM(@Country))) > 0
                    BEGIN
                        SET @Cn = LOWER(LTRIM(RTRIM(@Country)));
                        SELECT TOP 1 @CountryId = Id
                        FROM dbo.T052Country
                        WHERE LOWER(Name) = @Cn
                           OR (@Cn IN ('ca', 'can', 'cad') AND LOWER(Name) = 'canada')
                           OR (@Cn IN ('us', 'usa', 'u.s.', 'u.s.a.', 'united states', 'états-unis', 'etats-unis')
                               AND LOWER(Name) = 'usa');
                    END
                    IF @CountryId IS NULL SET @CountryId = @DefaultCountryId;

                    -- ── Résoudre Province → StateId ─────────────────────────
                    -- 1) exact Name, 2) abréviation, 3) défaut 'unknown'
                    SET @StateId = NULL;
                    IF @Province IS NOT NULL AND LEN(LTRIM(RTRIM(@Province))) > 0
                    BEGIN
                        SET @Pn = LOWER(LTRIM(RTRIM(@Province)));
                        SELECT TOP 1 @StateId = Id
                        FROM dbo.T053State
                        WHERE LOWER(Name) = @Pn
                           OR (@Pn IN ('qc', 'qué', 'que', 'québec') AND LOWER(Name) = 'quebec')
                           OR (@Pn IN ('on', 'ont')                  AND LOWER(Name) = 'ontario');
                    END
                    IF @StateId IS NULL SET @StateId = @DefaultStateId;

                    -- INSERT adresse si données présentes
                    IF @Address1 IS NOT NULL OR @City IS NOT NULL OR @PostalCode IS NOT NULL
                       OR @Phone IS NOT NULL OR @Email IS NOT NULL
                    BEGIN
                        INSERT INTO T054PartyAddress (PartyId, AddressTypeId, Name, Attention,
                                                       Address1, Address2, City, StateId, CountryId,
                                                       PostalCode, Phone, Email, CreatedUTC)
                        VALUES (@NewPartyId, @AddressTypeId, NULL, @Attention,
                                @Address1, @Address2, @City, @StateId, @CountryId,
                                @PostalCode, @Phone, @Email, SYSUTCDATETIME());
                    END

                    -- Marquer staging
                    UPDATE staging.PartyImport
                    SET Status = 'Migrated',
                        MigratedToPartyId = @NewPartyId,
                        MigratedDate = GETDATE(),
                        ErrorMessage = NULL
                    WHERE Id = @StageId;

                    COMMIT TRANSACTION;
                    SET @Migrated += 1;
                END
            END
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

            UPDATE staging.PartyImport
            SET Status = 'Error',
                ErrorMessage = LEFT(ERROR_MESSAGE(), 4000)
            WHERE Id = @StageId;
            SET @Errors += 1;
        END CATCH

        FETCH NEXT FROM cur INTO @StageId, @Name, @Attention, @Address1, @Address2, @City,
                                  @Province, @PostalCode, @Country, @Phone, @Email,
                                  @TPS, @TVQ, @CompteAuxClient, @CompteAuxFournisseur, @TypeImport;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT @ImportFileId  AS ImportFileId,
           @TotalPending  AS TotalPending,
           @Migrated      AS Migrated,
           @Skipped       AS Skipped,
           @Errors        AS Errors;
END
GO
