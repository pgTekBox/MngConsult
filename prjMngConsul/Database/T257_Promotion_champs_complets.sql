-- =============================================================================
-- T257 — La promotion porte tout : de la préparation à T050Party / T075Products
--
-- T256 a ouvert la préparation à l'ensemble des champs d'Apideck. Mais la
-- promotion (s0607, s0608) continuait de n'en créer qu'une douzaine : le site
-- web, le mobile, la devise, les conditions, le prix d'achat, la quantité en
-- main s'arrêtaient à la porte de l'application.
--
-- Ce script fait le dernier pas :
--
--   1) T050Party   +25 colonnes (identité de la personne, autres téléphones,
--                  devise, conditions, taxe, tiers parent, source, ExtraJson) ;
--                  DisplayName, WebSite, Note enfin remplis ; PaymentTermDays
--                  déduit des conditions (« Net 30 » → 30).
--   2) T054PartyAddress : l'adresse de livraison devient un SECOND
--                  enregistrement (type 2 Shipping), la facturation reste le
--                  premier (type 1 Billing) ; les lignes 3 à 5 rejoignent Address2.
--   3) T075Products +24 colonnes (code, type, coût d'achat, unités, taxes de
--                  vente et d'achat, comptes de la source, stock, devise…) ;
--                  Actif suit la source, TaxeStatusId est résolu par compagnie,
--                  CategoryId retrouvé quand une catégorie porte le même nom.
--   4) s0607 / s0608 réécrites pour tout porter.
--
-- Ce qui reste des NOMS et non des liens : les comptes de la source sur un
-- article (CompteVenteSource…), le tiers parent quand il n'est pas encore créé
-- (ParentName), la catégorie inconnue (CategorieSource). On ne devine pas une
-- correspondance ; on garde le nom pour qu'elle puisse être faite.
--
-- Rien n'est modifié sur les tiers et produits déjà en place : seules les
-- lignes de préparation « Pending » sont créées, comme avant.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) T050Party — ce qu'un tiers porte désormais
-- -----------------------------------------------------------------------------
IF COL_LENGTH('dbo.T050Party', 'SourceId')            IS NULL ALTER TABLE dbo.T050Party ADD [SourceId]            VARCHAR(100)  NULL;   -- l'Id chez la source (QuickBooks)
IF COL_LENGTH('dbo.T050Party', 'Title')               IS NULL ALTER TABLE dbo.T050Party ADD [Title]               VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T050Party', 'FirstName')           IS NULL ALTER TABLE dbo.T050Party ADD [FirstName]           VARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T050Party', 'MiddleName')          IS NULL ALTER TABLE dbo.T050Party ADD [MiddleName]          VARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T050Party', 'LastName')            IS NULL ALTER TABLE dbo.T050Party ADD [LastName]            VARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T050Party', 'Suffix')              IS NULL ALTER TABLE dbo.T050Party ADD [Suffix]              VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T050Party', 'Individual')          IS NULL ALTER TABLE dbo.T050Party ADD [Individual]          BIT           NULL;   -- personne plutôt qu'entreprise
IF COL_LENGTH('dbo.T050Party', 'IsProject')           IS NULL ALTER TABLE dbo.T050Party ADD [IsProject]           BIT           NULL;
IF COL_LENGTH('dbo.T050Party', 'Category')            IS NULL ALTER TABLE dbo.T050Party ADD [Category]            VARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T050Party', 'Mobile')              IS NULL ALTER TABLE dbo.T050Party ADD [Mobile]              VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T050Party', 'Fax')                 IS NULL ALTER TABLE dbo.T050Party ADD [Fax]                 VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T050Party', 'AltPhone')            IS NULL ALTER TABLE dbo.T050Party ADD [AltPhone]            VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T050Party', 'Currency')            IS NULL ALTER TABLE dbo.T050Party ADD [Currency]            VARCHAR(3)    NULL;
IF COL_LENGTH('dbo.T050Party', 'Terms')               IS NULL ALTER TABLE dbo.T050Party ADD [Terms]               VARCHAR(100)  NULL;   -- en clair ; PaymentTermDays en est déduit
IF COL_LENGTH('dbo.T050Party', 'SourcePaymentMethod') IS NULL ALTER TABLE dbo.T050Party ADD [SourcePaymentMethod] VARCHAR(100)  NULL;   -- distinct de LastPaymentMethod, qui vient des paiements d'ici
IF COL_LENGTH('dbo.T050Party', 'Taxable')             IS NULL ALTER TABLE dbo.T050Party ADD [Taxable]             BIT           NULL;
IF COL_LENGTH('dbo.T050Party', 'TaxRateName')         IS NULL ALTER TABLE dbo.T050Party ADD [TaxRateName]         VARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T050Party', 'ParentPartyId')       IS NULL ALTER TABLE dbo.T050Party ADD [ParentPartyId]       INT           NULL;   -- le parent, quand il est déjà ici
IF COL_LENGTH('dbo.T050Party', 'ParentName')          IS NULL ALTER TABLE dbo.T050Party ADD [ParentName]          VARCHAR(500)  NULL;   -- sinon, son nom
IF COL_LENGTH('dbo.T050Party', 'AccountName')         IS NULL ALTER TABLE dbo.T050Party ADD [AccountName]         VARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T050Party', 'SourceStatus')        IS NULL ALTER TABLE dbo.T050Party ADD [SourceStatus]        VARCHAR(30)   NULL;
IF COL_LENGTH('dbo.T050Party', 'SourceCreated')       IS NULL ALTER TABLE dbo.T050Party ADD [SourceCreated]       DATETIME      NULL;
IF COL_LENGTH('dbo.T050Party', 'SourceUpdated')       IS NULL ALTER TABLE dbo.T050Party ADD [SourceUpdated]       DATETIME      NULL;
IF COL_LENGTH('dbo.T050Party', 'SourceBalance')       IS NULL ALTER TABLE dbo.T050Party ADD [SourceBalance]       DECIMAL(15,2) NULL;   -- le solde annoncé par la source à l'import : un repère, pas un solde d'ici
IF COL_LENGTH('dbo.T050Party', 'SourceExtraJson')     IS NULL ALTER TABLE dbo.T050Party ADD [SourceExtraJson]     NVARCHAR(MAX) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_T050Party_Parent')
    ALTER TABLE dbo.T050Party
        ADD CONSTRAINT FK_T050Party_Parent FOREIGN KEY ([ParentPartyId]) REFERENCES dbo.T050Party ([Id]);
GO

-- -----------------------------------------------------------------------------
-- 2) T075Products — ce qu'un article porte désormais
--    Les noms suivent la table (Prix, CompteVente, Actif) : en français.
-- -----------------------------------------------------------------------------
IF COL_LENGTH('dbo.T075Products', 'SourceId')          IS NULL ALTER TABLE dbo.T075Products ADD [SourceId]          VARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T075Products', 'Code')              IS NULL ALTER TABLE dbo.T075Products ADD [Code]              VARCHAR(100)  NULL;   -- SKU
IF COL_LENGTH('dbo.T075Products', 'TypeArticle')       IS NULL ALTER TABLE dbo.T075Products ADD [TypeArticle]       VARCHAR(30)   NULL;   -- inventory, non_inventory, service, other
IF COL_LENGTH('dbo.T075Products', 'Vendable')          IS NULL ALTER TABLE dbo.T075Products ADD [Vendable]          BIT           NULL;
IF COL_LENGTH('dbo.T075Products', 'Achetable')         IS NULL ALTER TABLE dbo.T075Products ADD [Achetable]         BIT           NULL;
IF COL_LENGTH('dbo.T075Products', 'SuiviStock')        IS NULL ALTER TABLE dbo.T075Products ADD [SuiviStock]        BIT           NULL;
IF COL_LENGTH('dbo.T075Products', 'PrixAchat')         IS NULL ALTER TABLE dbo.T075Products ADD [PrixAchat]         DECIMAL(18,2) NULL;
IF COL_LENGTH('dbo.T075Products', 'Unite')             IS NULL ALTER TABLE dbo.T075Products ADD [Unite]             VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T075Products', 'UniteAchat')        IS NULL ALTER TABLE dbo.T075Products ADD [UniteAchat]        VARCHAR(50)   NULL;
IF COL_LENGTH('dbo.T075Products', 'TaxeVenteIncluse')  IS NULL ALTER TABLE dbo.T075Products ADD [TaxeVenteIncluse]  BIT           NULL;
IF COL_LENGTH('dbo.T075Products', 'TaxeAchatIncluse')  IS NULL ALTER TABLE dbo.T075Products ADD [TaxeAchatIncluse]  BIT           NULL;
IF COL_LENGTH('dbo.T075Products', 'TaxeVenteSource')   IS NULL ALTER TABLE dbo.T075Products ADD [TaxeVenteSource]   VARCHAR(100)  NULL;   -- le nom du taux chez la source
IF COL_LENGTH('dbo.T075Products', 'TaxeAchatSource')   IS NULL ALTER TABLE dbo.T075Products ADD [TaxeAchatSource]   VARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T075Products', 'CompteVenteSource') IS NULL ALTER TABLE dbo.T075Products ADD [CompteVenteSource] VARCHAR(200)  NULL;   -- le compte chez la source, en nom : CompteVente reste celui d'ici
IF COL_LENGTH('dbo.T075Products', 'CompteAchatSource') IS NULL ALTER TABLE dbo.T075Products ADD [CompteAchatSource] VARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T075Products', 'CompteStockSource') IS NULL ALTER TABLE dbo.T075Products ADD [CompteStockSource] VARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T075Products', 'QteEnMain')         IS NULL ALTER TABLE dbo.T075Products ADD [QteEnMain]         DECIMAL(15,4) NULL;
IF COL_LENGTH('dbo.T075Products', 'DateInventaire')    IS NULL ALTER TABLE dbo.T075Products ADD [DateInventaire]    DATE          NULL;
IF COL_LENGTH('dbo.T075Products', 'Devise')            IS NULL ALTER TABLE dbo.T075Products ADD [Devise]            VARCHAR(3)    NULL;
IF COL_LENGTH('dbo.T075Products', 'CategorieSource')   IS NULL ALTER TABLE dbo.T075Products ADD [CategorieSource]   VARCHAR(200)  NULL;   -- quand aucune catégorie d'ici ne porte ce nom
IF COL_LENGTH('dbo.T075Products', 'ParentName')        IS NULL ALTER TABLE dbo.T075Products ADD [ParentName]        VARCHAR(500)  NULL;
IF COL_LENGTH('dbo.T075Products', 'SourceCreated')     IS NULL ALTER TABLE dbo.T075Products ADD [SourceCreated]     DATETIME      NULL;
IF COL_LENGTH('dbo.T075Products', 'SourceUpdated')     IS NULL ALTER TABLE dbo.T075Products ADD [SourceUpdated]     DATETIME      NULL;
IF COL_LENGTH('dbo.T075Products', 'SourceExtraJson')   IS NULL ALTER TABLE dbo.T075Products ADD [SourceExtraJson]   NVARCHAR(MAX) NULL;
GO

-- -----------------------------------------------------------------------------
-- 3) dbo.fTermesEnJours — « Net 30 », « 30 jours », « Due on receipt » → 30, 30, 0
--
--    Le premier nombre de la chaîne, quand il y en a un. NULL sinon : on ne
--    remplace pas le défaut de la compagnie par une supposition.
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fTermesEnJours(@termes VARCHAR(100))
RETURNS INT
AS
BEGIN
    IF @termes IS NULL RETURN NULL;
    DECLARE @t VARCHAR(100) = LOWER(LTRIM(RTRIM(@termes)));
    IF @t IN ('due on receipt', 'à réception', 'a reception', 'sur réception', 'sur reception', 'comptant', 'cash') RETURN 0;
    DECLARE @i INT = PATINDEX('%[0-9]%', @t);
    IF @i = 0 RETURN NULL;
    DECLARE @j INT = @i;
    WHILE @j <= LEN(@t) AND SUBSTRING(@t, @j, 1) LIKE '[0-9]' SET @j += 1;
    RETURN TRY_CAST(SUBSTRING(@t, @i, @j - @i) AS INT);
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0607MigratePartyImportToProd — le tiers en entier
--
--    Même contrat qu'avant (mêmes paramètres, même résumé, mêmes verdicts
--    Skipped / Error), et en plus :
--      · DisplayName, WebSite, Note, et les 25 colonnes ajoutées ;
--      · PaymentTermDays déduit des conditions, sinon le défaut de la table ;
--      · ParentPartyId quand un tiers du nom du parent existe déjà ici ;
--      · l'adresse de livraison en second T054PartyAddress (type 2).
--
--    Remplace la version de Database/s0607MigratePartyImportToProd.sql.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0607MigratePartyImportToProd
    @ImportFileId          INT,
    @CompanyGUID           UNIQUEIDENTIFIER = NULL,  -- NULL → lit depuis staging.ImportFiles
    @AddressTypeId         INT              = 1,     -- adresse principale (facturation)
    @PartyTypeClient       INT              = NULL,  -- T055PartyType.Id pour clients      ; NULL = auto
    @PartyTypeFournisseur  INT              = NULL,  -- T055PartyType.Id pour fournisseurs ; NULL = auto
    @PartyCodeiD           INT              = 1,
    @Origin                INT              = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
        SELECT @CompanyGUID = CompanyGUID FROM staging.ImportFiles WHERE Id = @ImportFileId;

    IF @CompanyGUID IS NULL
    BEGIN
        RAISERROR('CompanyGUID requis (non trouvé sur staging.ImportFiles Id=%d).', 16, 1, @ImportFileId);
        RETURN;
    END

    IF @PartyTypeClient IS NULL
        SELECT @PartyTypeClient = Id FROM dbo.T055PartyType WHERE TypeCode = 'CLIENT';
    IF @PartyTypeFournisseur IS NULL
        SELECT @PartyTypeFournisseur = Id FROM dbo.T055PartyType WHERE TypeCode = 'FOURNISSEUR';

    -- La livraison a son type d'adresse ; s'il manque, elle rejoint le type principal.
    DECLARE @ShippingTypeId INT = (SELECT TOP 1 Id FROM dbo.T064AddressType WHERE LOWER(Name) IN ('shipping', 'livraison') ORDER BY Id);
    IF @ShippingTypeId IS NULL SET @ShippingTypeId = @AddressTypeId;

    DECLARE @TotalPending INT, @Migrated INT = 0, @Skipped INT = 0, @Errors INT = 0;
    SELECT @TotalPending = COUNT(*) FROM staging.PartyImport
    WHERE ImportFileId = @ImportFileId AND Status = 'Pending';

    DECLARE @DefaultCountryId INT, @DefaultStateId INT;
    SELECT @DefaultCountryId = Id FROM dbo.T052Country WHERE LOWER(Name) = 'canada';
    SELECT @DefaultStateId   = Id FROM dbo.T053State   WHERE LOWER(Name) = 'unknown';
    IF @DefaultCountryId IS NULL SELECT TOP 1 @DefaultCountryId = Id FROM dbo.T052Country ORDER BY Id;
    IF @DefaultStateId   IS NULL SELECT TOP 1 @DefaultStateId   = Id FROM dbo.T053State   ORDER BY Id;

    DECLARE @StageId INT, @TypeImport NVARCHAR(20),
            @Name NVARCHAR(500), @DisplayName NVARCHAR(500), @Attention NVARCHAR(200),
            @Title NVARCHAR(50), @FirstName NVARCHAR(200), @MiddleName NVARCHAR(200), @LastName NVARCHAR(200), @Suffix NVARCHAR(50),
            @Individual BIT, @IsProject BIT, @Category NVARCHAR(100),
            @Address1 NVARCHAR(500), @Address2 NVARCHAR(500), @Address3 NVARCHAR(500), @City NVARCHAR(50),
            @Province NVARCHAR(50), @PostalCode NVARCHAR(20), @Country NVARCHAR(50),
            @ShipAttention NVARCHAR(200), @ShipAddress1 NVARCHAR(500), @ShipAddress2 NVARCHAR(500), @ShipCity NVARCHAR(50),
            @ShipProvince NVARCHAR(50), @ShipPostalCode NVARCHAR(20), @ShipCountry NVARCHAR(50),
            @Phone NVARCHAR(200), @Mobile NVARCHAR(50), @Fax NVARCHAR(50), @AltPhone NVARCHAR(50),
            @Email NVARCHAR(200), @WebSite NVARCHAR(200),
            @TPS NVARCHAR(20), @TVQ NVARCHAR(20), @Taxable BIT, @TaxRateName NVARCHAR(100),
            @Currency NVARCHAR(3), @Terms NVARCHAR(100), @PaymentMethod NVARCHAR(100),
            @ParentName NVARCHAR(500), @AccountName NVARCHAR(200), @Balance DECIMAL(15,2), @Note NVARCHAR(MAX),
            @SourceId NVARCHAR(100), @SourceStatus NVARCHAR(30), @SourceCreated DATETIME, @SourceUpdated DATETIME,
            @ExtraJson NVARCHAR(MAX),
            @CompteAuxClient NVARCHAR(20), @CompteAuxFournisseur NVARCHAR(20);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id, TypeImport,
               Name, DisplayName, Attention,
               Title, FirstName, MiddleName, LastName, Suffix, Individual, IsProject, Category,
               Address1, Address2, Address3, City, Province, PostalCode, Country,
               ShipAttention, ShipAddress1, ShipAddress2, ShipCity, ShipProvince, ShipPostalCode, ShipCountry,
               Phone, Mobile, Fax, AltPhone, Email, WebSite,
               TPS, TVQ, Taxable, TaxRateName,
               Currency, Terms, PaymentMethod, ParentName, AccountName, Balance, Note,
               SourceId, SourceStatus, SourceCreated, SourceUpdated, ExtraJson,
               CompteAuxClient, CompteAuxFournisseur
        FROM staging.PartyImport
        WHERE ImportFileId = @ImportFileId AND Status = 'Pending'
        ORDER BY ISNULL(LineNumber, 0), Id;

    DECLARE @StateId INT, @CountryId INT, @NewPartyId INT, @ParentPartyId INT, @TermDays INT,
            @PartyTypeForRow INT, @ExistingId INT,
            @Cn NVARCHAR(50), @Pn NVARCHAR(50);

    OPEN cur;
    FETCH NEXT FROM cur INTO @StageId, @TypeImport,
                              @Name, @DisplayName, @Attention,
                              @Title, @FirstName, @MiddleName, @LastName, @Suffix, @Individual, @IsProject, @Category,
                              @Address1, @Address2, @Address3, @City, @Province, @PostalCode, @Country,
                              @ShipAttention, @ShipAddress1, @ShipAddress2, @ShipCity, @ShipProvince, @ShipPostalCode, @ShipCountry,
                              @Phone, @Mobile, @Fax, @AltPhone, @Email, @WebSite,
                              @TPS, @TVQ, @Taxable, @TaxRateName,
                              @Currency, @Terms, @PaymentMethod, @ParentName, @AccountName, @Balance, @Note,
                              @SourceId, @SourceStatus, @SourceCreated, @SourceUpdated, @ExtraJson,
                              @CompteAuxClient, @CompteAuxFournisseur;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            IF @Name IS NULL OR LEN(LTRIM(RTRIM(@Name))) = 0
            BEGIN
                UPDATE staging.PartyImport
                SET Status = 'Skipped', ErrorMessage = 'Nom manquant'
                WHERE Id = @StageId;
                SET @Skipped += 1;
            END
            ELSE
            BEGIN
                SET @ExistingId = NULL;
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

                    SET @PartyTypeForRow =
                        CASE WHEN @TypeImport = 'Client'      THEN @PartyTypeClient
                             WHEN @TypeImport = 'Fournisseur' THEN @PartyTypeFournisseur
                        END;

                    -- Le parent, s'il est déjà ici — créé plus haut dans ce même
                    -- fichier, ou de longue date. Sinon son nom attend.
                    SET @ParentPartyId = NULL;
                    IF @ParentName IS NOT NULL AND LEN(LTRIM(RTRIM(@ParentName))) > 0
                        SELECT TOP 1 @ParentPartyId = Id
                        FROM T050Party
                        WHERE CompanyGUID = @CompanyGUID
                          AND ISNULL(isDeleted, 0) = 0
                          AND LOWER(LTRIM(RTRIM(Name))) = LOWER(LTRIM(RTRIM(@ParentName)))
                        ORDER BY Id;

                    SET @TermDays = dbo.fTermesEnJours(@Terms);

                    INSERT INTO T050Party (CompanyGUID, Name, DisplayName, TPS, TVQ, WebSite,
                                           Type, Origin, Note, CompteAuxClient, CompteAuxFournisseur,
                                           isDeleted, PaymentTermDays,
                                           SourceId, Title, FirstName, MiddleName, LastName, Suffix,
                                           Individual, IsProject, Category, Mobile, Fax, AltPhone,
                                           Currency, Terms, SourcePaymentMethod, Taxable, TaxRateName,
                                           ParentPartyId, ParentName, AccountName,
                                           SourceStatus, SourceCreated, SourceUpdated, SourceBalance, SourceExtraJson)
                    VALUES (@CompanyGUID, @Name, ISNULL(NULLIF(LTRIM(RTRIM(@DisplayName)), ''), @Name), @TPS, @TVQ, @WebSite,
                            @PartyTypeForRow, @Origin, @Note, @CompteAuxClient, @CompteAuxFournisseur,
                            0, ISNULL(@TermDays, 0),
                            @SourceId, @Title, @FirstName, @MiddleName, @LastName, @Suffix,
                            @Individual, @IsProject, @Category, @Mobile, @Fax, @AltPhone,
                            @Currency, @Terms, @PaymentMethod, @Taxable, @TaxRateName,
                            @ParentPartyId, @ParentName, @AccountName,
                            @SourceStatus, @SourceCreated, @SourceUpdated, @Balance, @ExtraJson);
                    SET @NewPartyId = SCOPE_IDENTITY();

                    -- ── L'adresse de facturation ─────────────────────────────
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

                    IF @Address1 IS NOT NULL OR @City IS NOT NULL OR @PostalCode IS NOT NULL
                       OR @Phone IS NOT NULL OR @Email IS NOT NULL
                    BEGIN
                        INSERT INTO T054PartyAddress (PartyId, AddressTypeId, Name, Attention,
                                                       Address1, Address2, City, StateId, CountryId,
                                                       PostalCode, Phone, Email, CreatedUTC)
                        VALUES (@NewPartyId, @AddressTypeId, NULL, @Attention,
                                @Address1,
                                NULLIF(STUFF(CONCAT(', ' + NULLIF(@Address2, ''), ', ' + NULLIF(@Address3, '')), 1, 2, ''), ''),
                                @City, @StateId, @CountryId,
                                @PostalCode, @Phone, @Email, SYSUTCDATETIME());
                    END

                    -- ── L'adresse de livraison, quand la source en a une ─────
                    IF NULLIF(@ShipAddress1, '') IS NOT NULL OR NULLIF(@ShipCity, '') IS NOT NULL
                       OR NULLIF(@ShipPostalCode, '') IS NOT NULL
                    BEGIN
                        SET @CountryId = NULL;
                        IF @ShipCountry IS NOT NULL AND LEN(LTRIM(RTRIM(@ShipCountry))) > 0
                        BEGIN
                            SET @Cn = LOWER(LTRIM(RTRIM(@ShipCountry)));
                            SELECT TOP 1 @CountryId = Id
                            FROM dbo.T052Country
                            WHERE LOWER(Name) = @Cn
                               OR (@Cn IN ('ca', 'can', 'cad') AND LOWER(Name) = 'canada')
                               OR (@Cn IN ('us', 'usa', 'u.s.', 'u.s.a.', 'united states', 'états-unis', 'etats-unis')
                                   AND LOWER(Name) = 'usa');
                        END
                        IF @CountryId IS NULL SET @CountryId = @DefaultCountryId;

                        SET @StateId = NULL;
                        IF @ShipProvince IS NOT NULL AND LEN(LTRIM(RTRIM(@ShipProvince))) > 0
                        BEGIN
                            SET @Pn = LOWER(LTRIM(RTRIM(@ShipProvince)));
                            SELECT TOP 1 @StateId = Id
                            FROM dbo.T053State
                            WHERE LOWER(Name) = @Pn
                               OR (@Pn IN ('qc', 'qué', 'que', 'québec') AND LOWER(Name) = 'quebec')
                               OR (@Pn IN ('on', 'ont')                  AND LOWER(Name) = 'ontario');
                        END
                        IF @StateId IS NULL SET @StateId = @DefaultStateId;

                        INSERT INTO T054PartyAddress (PartyId, AddressTypeId, Name, Attention,
                                                       Address1, Address2, City, StateId, CountryId,
                                                       PostalCode, Phone, Email, CreatedUTC)
                        VALUES (@NewPartyId, @ShippingTypeId, 'Livraison', @ShipAttention,
                                @ShipAddress1, @ShipAddress2, @ShipCity, @StateId, @CountryId,
                                @ShipPostalCode, NULL, NULL, SYSUTCDATETIME());
                    END

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

        FETCH NEXT FROM cur INTO @StageId, @TypeImport,
                                  @Name, @DisplayName, @Attention,
                                  @Title, @FirstName, @MiddleName, @LastName, @Suffix, @Individual, @IsProject, @Category,
                                  @Address1, @Address2, @Address3, @City, @Province, @PostalCode, @Country,
                                  @ShipAttention, @ShipAddress1, @ShipAddress2, @ShipCity, @ShipProvince, @ShipPostalCode, @ShipCountry,
                                  @Phone, @Mobile, @Fax, @AltPhone, @Email, @WebSite,
                                  @TPS, @TVQ, @Taxable, @TaxRateName,
                                  @Currency, @Terms, @PaymentMethod, @ParentName, @AccountName, @Balance, @Note,
                                  @SourceId, @SourceStatus, @SourceCreated, @SourceUpdated, @ExtraJson,
                                  @CompteAuxClient, @CompteAuxFournisseur;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- Les parents créés APRÈS leurs enfants dans ce même fichier : un second
    -- passage les relie. Seules les lignes de ce fichier sont touchées.
    UPDATE p
       SET p.ParentPartyId = pa.Id
      FROM dbo.T050Party p
      JOIN staging.PartyImport s ON s.MigratedToPartyId = p.Id AND s.ImportFileId = @ImportFileId
     CROSS APPLY (SELECT TOP 1 x.Id FROM dbo.T050Party x
                   WHERE x.CompanyGUID = @CompanyGUID AND ISNULL(x.isDeleted, 0) = 0 AND x.Id <> p.Id
                     AND LOWER(LTRIM(RTRIM(x.Name))) = LOWER(LTRIM(RTRIM(p.ParentName)))
                   ORDER BY x.Id) pa
     WHERE p.ParentPartyId IS NULL
       AND NULLIF(LTRIM(RTRIM(p.ParentName)), '') IS NOT NULL;

    SELECT @ImportFileId  AS ImportFileId,
           @TotalPending  AS TotalPending,
           @Migrated      AS Migrated,
           @Skipped       AS Skipped,
           @Errors        AS Errors;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0608MigrateProductImportToProd — l'article en entier
--
--    La création passe toujours par s0079InsertProduct (mêmes défauts, même
--    numérotation) ; ce qu'il ne connaît pas est posé juste après, sur la
--    ligne créée. Et en plus :
--      · Actif suit la source quand elle le dit (@Actif reste le défaut) ;
--      · TaxeStatusId résolu par compagnie (TAXABLE / EXEMPT) d'après Taxable,
--        sauf si l'appelant l'impose ;
--      · CategoryId retrouvé quand une catégorie d'ici porte le nom de celle
--        de la source ; sinon le nom reste dans CategorieSource.
--
--    Remplace la version de Database/s0608MigrateProductImportToProd.sql.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0608MigrateProductImportToProd
    @ImportFileId    INT,
    @CompanyGUID     UNIQUEIDENTIFIER = NULL,  -- NULL → lit depuis staging.ImportFiles
    @CategoryId      INT              = NULL,
    @TaxeStatusId    INT              = NULL,
    @DefaultQty      DECIMAL(15,2)    = 1,
    @AddToNewInvoice BIT              = 0,
    @NoTaxe          BIT              = 0,
    @Actif           BIT              = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
        SELECT @CompanyGUID = CompanyGUID FROM staging.ImportFiles WHERE Id = @ImportFileId;

    IF @CompanyGUID IS NULL
    BEGIN
        RAISERROR('CompanyGUID requis (non trouvé sur staging.ImportFiles Id=%d).', 16, 1, @ImportFileId);
        RETURN;
    END

    -- Les statuts de taxe de la compagnie : chaque compagnie a les siens.
    DECLARE @TaxableId INT = (SELECT TOP 1 Id FROM dbo.T068TaxeStatus WHERE CompanyGUID = @CompanyGUID AND TaxStatus = 'TAXABLE' ORDER BY Id);
    DECLARE @ExemptId  INT = (SELECT TOP 1 Id FROM dbo.T068TaxeStatus WHERE CompanyGUID = @CompanyGUID AND TaxStatus = 'EXEMPT'  ORDER BY Id);

    DECLARE @TotalPending INT, @Migrated INT = 0, @Skipped INT = 0, @Errors INT = 0;
    SELECT @TotalPending = COUNT(*) FROM staging.ProductImport
    WHERE ImportFileId = @ImportFileId AND Status = 'Pending';

    DECLARE @StageId INT, @Name NVARCHAR(500), @Description NVARCHAR(2000),
            @Price DECIMAL(15,2), @RevenueAccount NVARCHAR(20), @ExpenseAccount NVARCHAR(20), @Taxable BIT,
            @SourceId NVARCHAR(100), @Code NVARCHAR(100), @ItemType NVARCHAR(30),
            @Active BIT, @Sold BIT, @Purchased BIT, @Tracked BIT,
            @PurchasePrice DECIMAL(15,2), @Unit NVARCHAR(50), @PurchaseUnit NVARCHAR(50),
            @SalesTaxInclusive BIT, @PurchaseTaxInclusive BIT,
            @SalesTaxRateName NVARCHAR(100), @PurchaseTaxRateName NVARCHAR(100),
            @IncomeAccountName NVARCHAR(200), @ExpenseAccountName NVARCHAR(200), @AssetAccountName NVARCHAR(200),
            @Quantity DECIMAL(15,4), @InventoryDate DATE, @Currency NVARCHAR(3),
            @Category NVARCHAR(200), @ParentName NVARCHAR(500),
            @SourceCreated DATETIME, @SourceUpdated DATETIME, @ExtraJson NVARCHAR(MAX);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id, Name, Description, Price, RevenueAccount, ExpenseAccount, Taxable,
               SourceId, Code, ItemType, Active, Sold, Purchased, Tracked,
               PurchasePrice, Unit, PurchaseUnit, SalesTaxInclusive, PurchaseTaxInclusive,
               SalesTaxRateName, PurchaseTaxRateName,
               IncomeAccountName, ExpenseAccountName, AssetAccountName,
               Quantity, InventoryDate, Currency, Category, ParentName,
               SourceCreated, SourceUpdated, ExtraJson
        FROM staging.ProductImport
        WHERE ImportFileId = @ImportFileId AND Status = 'Pending'
        ORDER BY ISNULL(LineNumber, 0), Id;

    DECLARE @InsertResult TABLE (NewId INT);
    DECLARE @NewProductId INT, @NoTaxeForRow BIT, @ActifForRow BIT, @TaxeStatusForRow INT, @CategoryForRow INT;

    OPEN cur;
    FETCH NEXT FROM cur INTO @StageId, @Name, @Description, @Price, @RevenueAccount, @ExpenseAccount, @Taxable,
                              @SourceId, @Code, @ItemType, @Active, @Sold, @Purchased, @Tracked,
                              @PurchasePrice, @Unit, @PurchaseUnit, @SalesTaxInclusive, @PurchaseTaxInclusive,
                              @SalesTaxRateName, @PurchaseTaxRateName,
                              @IncomeAccountName, @ExpenseAccountName, @AssetAccountName,
                              @Quantity, @InventoryDate, @Currency, @Category, @ParentName,
                              @SourceCreated, @SourceUpdated, @ExtraJson;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            IF @Name IS NULL OR LEN(LTRIM(RTRIM(@Name))) = 0
            BEGIN
                UPDATE staging.ProductImport
                SET Status = 'Skipped', ErrorMessage = 'Nom manquant'
                WHERE Id = @StageId;
                SET @Skipped += 1;
            END
            ELSE
            BEGIN
                DELETE FROM @InsertResult;

                SET @NoTaxeForRow  = CASE WHEN @Taxable = 0 THEN 1 ELSE @NoTaxe END;
                SET @ActifForRow   = ISNULL(@Active, @Actif);
                SET @TaxeStatusForRow = COALESCE(@TaxeStatusId,
                                                 CASE WHEN @Taxable = 1 THEN @TaxableId
                                                      WHEN @Taxable = 0 THEN @ExemptId END);

                -- La catégorie : celle qu'on impose, sinon celle d'ici qui porte
                -- le nom de la source, sinon aucune — et le nom reste visible.
                SET @CategoryForRow = @CategoryId;
                IF @CategoryForRow IS NULL AND NULLIF(LTRIM(RTRIM(@Category)), '') IS NOT NULL
                    SELECT TOP 1 @CategoryForRow = Id
                    FROM dbo.T076ProductCategory
                    WHERE CompanyGUID = @CompanyGUID
                      AND LOWER(LTRIM(RTRIM(Name))) = LOWER(LTRIM(RTRIM(@Category)))
                    ORDER BY Id;

                INSERT INTO @InsertResult (NewId)
                EXEC dbo.s0079InsertProduct
                    @CompanyGUID     = @CompanyGUID,
                    @Name            = @Name,
                    @Description     = @Description,
                    @Prix            = @Price,
                    @DefaultQty      = @DefaultQty,
                    @AddToNewInvoice = @AddToNewInvoice,
                    @NoTaxe          = @NoTaxeForRow,
                    @CategoryId      = @CategoryForRow,
                    @CompteVente     = @RevenueAccount,
                    @CompteAchat     = @ExpenseAccount,
                    @TaxeStatusId    = @TaxeStatusForRow,
                    @Actif           = @ActifForRow;

                SET @NewProductId = NULL;
                SELECT @NewProductId = NewId FROM @InsertResult;

                IF @NewProductId IS NULL
                BEGIN
                    UPDATE staging.ProductImport
                    SET Status = 'Error',
                        ErrorMessage = 's0079InsertProduct n''a pas retourné d''Id'
                    WHERE Id = @StageId;
                    SET @Errors += 1;
                END
                ELSE
                BEGIN
                    -- Ce que s0079 ne connaît pas : posé sur la ligne qu'il vient de créer.
                    UPDATE dbo.T075Products
                       SET SourceId          = @SourceId,
                           Code              = @Code,
                           TypeArticle       = @ItemType,
                           Vendable          = @Sold,
                           Achetable         = @Purchased,
                           SuiviStock        = @Tracked,
                           PrixAchat         = @PurchasePrice,
                           Unite             = @Unit,
                           UniteAchat        = @PurchaseUnit,
                           TaxeVenteIncluse  = @SalesTaxInclusive,
                           TaxeAchatIncluse  = @PurchaseTaxInclusive,
                           TaxeVenteSource   = @SalesTaxRateName,
                           TaxeAchatSource   = @PurchaseTaxRateName,
                           CompteVenteSource = @IncomeAccountName,
                           CompteAchatSource = @ExpenseAccountName,
                           CompteStockSource = @AssetAccountName,
                           QteEnMain         = @Quantity,
                           DateInventaire    = @InventoryDate,
                           Devise            = @Currency,
                           CategorieSource   = CASE WHEN @CategoryForRow IS NULL THEN NULLIF(LTRIM(RTRIM(@Category)), '') END,
                           ParentName        = @ParentName,
                           SourceCreated     = @SourceCreated,
                           SourceUpdated     = @SourceUpdated,
                           SourceExtraJson   = @ExtraJson
                     WHERE Id = @NewProductId;

                    UPDATE staging.ProductImport
                    SET Status = 'Migrated',
                        MigratedToProductId = @NewProductId,
                        MigratedDate = GETDATE(),
                        ErrorMessage = NULL
                    WHERE Id = @StageId;
                    SET @Migrated += 1;
                END
            END
        END TRY
        BEGIN CATCH
            UPDATE staging.ProductImport
            SET Status = 'Error',
                ErrorMessage = LEFT(ERROR_MESSAGE(), 4000)
            WHERE Id = @StageId;
            SET @Errors += 1;
        END CATCH

        FETCH NEXT FROM cur INTO @StageId, @Name, @Description, @Price, @RevenueAccount, @ExpenseAccount, @Taxable,
                                  @SourceId, @Code, @ItemType, @Active, @Sold, @Purchased, @Tracked,
                                  @PurchasePrice, @Unit, @PurchaseUnit, @SalesTaxInclusive, @PurchaseTaxInclusive,
                                  @SalesTaxRateName, @PurchaseTaxRateName,
                                  @IncomeAccountName, @ExpenseAccountName, @AssetAccountName,
                                  @Quantity, @InventoryDate, @Currency, @Category, @ParentName,
                                  @SourceCreated, @SourceUpdated, @ExtraJson;
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
