-- =============================================================================
-- T256 — Tout ce qu'Apideck rend sur un client, un fournisseur, un produit
--
-- Jusqu'ici la préparation ne retenait qu'une douzaine de champs par tiers et
-- quatre par produit : ce que l'import par fichier CSV savait lire. Apideck en
-- rend bien plus — prénom et nom séparés, mobile, site web, adresse de
-- livraison, devise, conditions, taux de taxe, comptes de la source, prix
-- d'achat, quantité en stock… — et tout cela se perdait entre le dépôt brut
-- (staging.ConnecteurDonnee, où il reste) et l'écran, qui ne le montrait pas.
--
-- Ce script ouvre la préparation à l'ensemble :
--
--   1) staging.PartyImport   +34 colonnes, toutes NULL — l'import par fichier
--                            continue de ne remplir que les siennes ;
--   2) staging.ProductImport +30 colonnes, même principe ;
--   3) dbo.fImportBit        lit un booléen sous toutes ses formes ;
--   4) s0604ProcessImportJson lit les nouvelles clés JSON quand elles y sont ;
--   5) s0773GetImportLignes  rend toutes les colonnes à l'écran.
--
-- Ce qui n'a pas de colonne — comptes bancaires, champs personnalisés, taxes
-- multiples, 2e et 3e téléphones — va dans [ExtraJson], tel quel : rien n'est
-- perdu, et on ne fige pas vingt colonnes pour des données qu'aucune source
-- ne rend encore.
--
-- Rien ne change en dbo : la promotion (s0607/s0608) reprend les mêmes
-- colonnes qu'avant. Ce script donne à voir ; appliquer davantage à T050Party
-- ou T075Products est une décision à part.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) staging.PartyImport — le tiers en entier
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.PartyImport', 'SourceId')       IS NULL ALTER TABLE staging.PartyImport ADD [SourceId]       VARCHAR(100)  NULL;   -- l'Id chez la source (QuickBooks)
IF COL_LENGTH('staging.PartyImport', 'CompanyName')    IS NULL ALTER TABLE staging.PartyImport ADD [CompanyName]    VARCHAR(500)  NULL;   -- company_name, brut ([Name] reste le nom retenu)
IF COL_LENGTH('staging.PartyImport', 'Title')          IS NULL ALTER TABLE staging.PartyImport ADD [Title]          VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'FirstName')      IS NULL ALTER TABLE staging.PartyImport ADD [FirstName]      VARCHAR(200)  NULL;
IF COL_LENGTH('staging.PartyImport', 'MiddleName')     IS NULL ALTER TABLE staging.PartyImport ADD [MiddleName]     VARCHAR(200)  NULL;
IF COL_LENGTH('staging.PartyImport', 'LastName')       IS NULL ALTER TABLE staging.PartyImport ADD [LastName]       VARCHAR(200)  NULL;
IF COL_LENGTH('staging.PartyImport', 'Suffix')         IS NULL ALTER TABLE staging.PartyImport ADD [Suffix]         VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'Individual')     IS NULL ALTER TABLE staging.PartyImport ADD [Individual]     BIT           NULL;   -- personne plutôt qu'entreprise
IF COL_LENGTH('staging.PartyImport', 'IsProject')      IS NULL ALTER TABLE staging.PartyImport ADD [IsProject]      BIT           NULL;   -- client « projet » de QuickBooks
IF COL_LENGTH('staging.PartyImport', 'Category')       IS NULL ALTER TABLE staging.PartyImport ADD [Category]       VARCHAR(100)  NULL;   -- customer_category / supplier_category
IF COL_LENGTH('staging.PartyImport', 'Mobile')         IS NULL ALTER TABLE staging.PartyImport ADD [Mobile]         VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'Fax')            IS NULL ALTER TABLE staging.PartyImport ADD [Fax]            VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'AltPhone')       IS NULL ALTER TABLE staging.PartyImport ADD [AltPhone]       VARCHAR(50)   NULL;   -- tout numéro qui n'est ni principal, ni mobile, ni fax
IF COL_LENGTH('staging.PartyImport', 'Address3')       IS NULL ALTER TABLE staging.PartyImport ADD [Address3]       VARCHAR(500)  NULL;   -- lignes 3 à 5 de l'adresse, réunies
IF COL_LENGTH('staging.PartyImport', 'ShipAttention')  IS NULL ALTER TABLE staging.PartyImport ADD [ShipAttention]  VARCHAR(200)  NULL;
IF COL_LENGTH('staging.PartyImport', 'ShipAddress1')   IS NULL ALTER TABLE staging.PartyImport ADD [ShipAddress1]   VARCHAR(500)  NULL;
IF COL_LENGTH('staging.PartyImport', 'ShipAddress2')   IS NULL ALTER TABLE staging.PartyImport ADD [ShipAddress2]   VARCHAR(500)  NULL;
IF COL_LENGTH('staging.PartyImport', 'ShipCity')       IS NULL ALTER TABLE staging.PartyImport ADD [ShipCity]       VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'ShipProvince')   IS NULL ALTER TABLE staging.PartyImport ADD [ShipProvince]   VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'ShipPostalCode') IS NULL ALTER TABLE staging.PartyImport ADD [ShipPostalCode] VARCHAR(20)   NULL;
IF COL_LENGTH('staging.PartyImport', 'ShipCountry')    IS NULL ALTER TABLE staging.PartyImport ADD [ShipCountry]    VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'Taxable')        IS NULL ALTER TABLE staging.PartyImport ADD [Taxable]        BIT           NULL;
IF COL_LENGTH('staging.PartyImport', 'TaxRateName')    IS NULL ALTER TABLE staging.PartyImport ADD [TaxRateName]    VARCHAR(100)  NULL;   -- le code de taxe par défaut du tiers
IF COL_LENGTH('staging.PartyImport', 'TaxRateCode')    IS NULL ALTER TABLE staging.PartyImport ADD [TaxRateCode]    VARCHAR(50)   NULL;
IF COL_LENGTH('staging.PartyImport', 'TaxRate')        IS NULL ALTER TABLE staging.PartyImport ADD [TaxRate]        DECIMAL(9,4)  NULL;
IF COL_LENGTH('staging.PartyImport', 'Currency')       IS NULL ALTER TABLE staging.PartyImport ADD [Currency]       VARCHAR(3)    NULL;
IF COL_LENGTH('staging.PartyImport', 'Terms')          IS NULL ALTER TABLE staging.PartyImport ADD [Terms]          VARCHAR(100)  NULL;   -- conditions de paiement, en clair
IF COL_LENGTH('staging.PartyImport', 'PaymentMethod')  IS NULL ALTER TABLE staging.PartyImport ADD [PaymentMethod]  VARCHAR(100)  NULL;
IF COL_LENGTH('staging.PartyImport', 'ParentName')     IS NULL ALTER TABLE staging.PartyImport ADD [ParentName]     VARCHAR(500)  NULL;   -- sous-client / sous-fournisseur
IF COL_LENGTH('staging.PartyImport', 'AccountName')    IS NULL ALTER TABLE staging.PartyImport ADD [AccountName]    VARCHAR(200)  NULL;   -- compte comptable rattaché chez la source
IF COL_LENGTH('staging.PartyImport', 'SourceStatus')   IS NULL ALTER TABLE staging.PartyImport ADD [SourceStatus]   VARCHAR(30)   NULL;   -- active / inactive / archived…
IF COL_LENGTH('staging.PartyImport', 'SourceCreated')  IS NULL ALTER TABLE staging.PartyImport ADD [SourceCreated]  DATETIME      NULL;
IF COL_LENGTH('staging.PartyImport', 'SourceUpdated')  IS NULL ALTER TABLE staging.PartyImport ADD [SourceUpdated]  DATETIME      NULL;
IF COL_LENGTH('staging.PartyImport', 'ExtraJson')      IS NULL ALTER TABLE staging.PartyImport ADD [ExtraJson]      NVARCHAR(MAX) NULL;   -- le reste, tel quel : banques, champs perso, taxes multiples, autres contacts
GO

-- -----------------------------------------------------------------------------
-- 2) staging.ProductImport — le produit en entier
--
--    [Price] reste le prix de vente et [RevenueAccount]/[ExpenseAccount] les
--    comptes PAR DÉFAUT de la compagnie (T101), comme avant. Les comptes que
--    la SOURCE attache à l'article arrivent dans leurs propres colonnes : ce
--    sont deux informations, et les confondre ferait croire à une
--    correspondance qui n'existe pas encore.
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.ProductImport', 'SourceId')             IS NULL ALTER TABLE staging.ProductImport ADD [SourceId]             VARCHAR(100)  NULL;
IF COL_LENGTH('staging.ProductImport', 'Code')                 IS NULL ALTER TABLE staging.ProductImport ADD [Code]                 VARCHAR(100)  NULL;   -- SKU / code article
IF COL_LENGTH('staging.ProductImport', 'ItemType')             IS NULL ALTER TABLE staging.ProductImport ADD [ItemType]             VARCHAR(30)   NULL;   -- inventory, non_inventory, service, other…
IF COL_LENGTH('staging.ProductImport', 'Active')               IS NULL ALTER TABLE staging.ProductImport ADD [Active]               BIT           NULL;
IF COL_LENGTH('staging.ProductImport', 'Sold')                 IS NULL ALTER TABLE staging.ProductImport ADD [Sold]                 BIT           NULL;   -- vendable
IF COL_LENGTH('staging.ProductImport', 'Purchased')            IS NULL ALTER TABLE staging.ProductImport ADD [Purchased]            BIT           NULL;   -- achetable
IF COL_LENGTH('staging.ProductImport', 'Tracked')              IS NULL ALTER TABLE staging.ProductImport ADD [Tracked]              BIT           NULL;   -- suivi en inventaire
IF COL_LENGTH('staging.ProductImport', 'PurchasePrice')        IS NULL ALTER TABLE staging.ProductImport ADD [PurchasePrice]        DECIMAL(15,2) NULL;   -- coût d'achat
IF COL_LENGTH('staging.ProductImport', 'Unit')                 IS NULL ALTER TABLE staging.ProductImport ADD [Unit]                 VARCHAR(50)   NULL;   -- unité de vente
IF COL_LENGTH('staging.ProductImport', 'PurchaseUnit')         IS NULL ALTER TABLE staging.ProductImport ADD [PurchaseUnit]         VARCHAR(50)   NULL;
IF COL_LENGTH('staging.ProductImport', 'SalesTaxInclusive')    IS NULL ALTER TABLE staging.ProductImport ADD [SalesTaxInclusive]    BIT           NULL;
IF COL_LENGTH('staging.ProductImport', 'PurchaseTaxInclusive') IS NULL ALTER TABLE staging.ProductImport ADD [PurchaseTaxInclusive] BIT           NULL;
IF COL_LENGTH('staging.ProductImport', 'SalesTaxRateName')     IS NULL ALTER TABLE staging.ProductImport ADD [SalesTaxRateName]     VARCHAR(100)  NULL;
IF COL_LENGTH('staging.ProductImport', 'SalesTaxRate')         IS NULL ALTER TABLE staging.ProductImport ADD [SalesTaxRate]         DECIMAL(9,4)  NULL;
IF COL_LENGTH('staging.ProductImport', 'PurchaseTaxRateName')  IS NULL ALTER TABLE staging.ProductImport ADD [PurchaseTaxRateName]  VARCHAR(100)  NULL;
IF COL_LENGTH('staging.ProductImport', 'PurchaseTaxRate')      IS NULL ALTER TABLE staging.ProductImport ADD [PurchaseTaxRate]      DECIMAL(9,4)  NULL;
IF COL_LENGTH('staging.ProductImport', 'IncomeAccountName')    IS NULL ALTER TABLE staging.ProductImport ADD [IncomeAccountName]    VARCHAR(200)  NULL;   -- compte de revenu chez la source
IF COL_LENGTH('staging.ProductImport', 'IncomeAccountCode')    IS NULL ALTER TABLE staging.ProductImport ADD [IncomeAccountCode]    VARCHAR(50)   NULL;
IF COL_LENGTH('staging.ProductImport', 'ExpenseAccountName')   IS NULL ALTER TABLE staging.ProductImport ADD [ExpenseAccountName]   VARCHAR(200)  NULL;   -- compte de dépense chez la source
IF COL_LENGTH('staging.ProductImport', 'ExpenseAccountCode')   IS NULL ALTER TABLE staging.ProductImport ADD [ExpenseAccountCode]   VARCHAR(50)   NULL;
IF COL_LENGTH('staging.ProductImport', 'AssetAccountName')     IS NULL ALTER TABLE staging.ProductImport ADD [AssetAccountName]     VARCHAR(200)  NULL;   -- compte de stock chez la source
IF COL_LENGTH('staging.ProductImport', 'AssetAccountCode')     IS NULL ALTER TABLE staging.ProductImport ADD [AssetAccountCode]     VARCHAR(50)   NULL;
IF COL_LENGTH('staging.ProductImport', 'Quantity')             IS NULL ALTER TABLE staging.ProductImport ADD [Quantity]             DECIMAL(15,4) NULL;   -- quantité en main
IF COL_LENGTH('staging.ProductImport', 'InventoryDate')        IS NULL ALTER TABLE staging.ProductImport ADD [InventoryDate]        DATE          NULL;   -- date du solde d'ouverture
IF COL_LENGTH('staging.ProductImport', 'Currency')             IS NULL ALTER TABLE staging.ProductImport ADD [Currency]             VARCHAR(3)    NULL;
IF COL_LENGTH('staging.ProductImport', 'Category')             IS NULL ALTER TABLE staging.ProductImport ADD [Category]             VARCHAR(200)  NULL;   -- catégorie / catégorie de suivi
IF COL_LENGTH('staging.ProductImport', 'ParentName')           IS NULL ALTER TABLE staging.ProductImport ADD [ParentName]           VARCHAR(500)  NULL;   -- sous-article
IF COL_LENGTH('staging.ProductImport', 'SourceCreated')        IS NULL ALTER TABLE staging.ProductImport ADD [SourceCreated]        DATETIME      NULL;
IF COL_LENGTH('staging.ProductImport', 'SourceUpdated')        IS NULL ALTER TABLE staging.ProductImport ADD [SourceUpdated]        DATETIME      NULL;
IF COL_LENGTH('staging.ProductImport', 'ExtraJson')            IS NULL ALTER TABLE staging.ProductImport ADD [ExtraJson]            NVARCHAR(MAX) NULL;   -- département, emplacement, catégories de suivi, champs perso…
GO

-- -----------------------------------------------------------------------------
-- 3) dbo.fImportBit — un booléen tel qu'un JSON ou un CSV le dit
--
--    true/false d'Apideck, oui/non d'un fichier, 1/0 d'un export. NULL quand
--    la valeur manque ou ne se lit pas : ne rien affirmer vaut mieux qu'un
--    « non » inventé.
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fImportBit(@v NVARCHAR(10))
RETURNS BIT
AS
BEGIN
    RETURN CASE
        WHEN @v IS NULL THEN NULL
        WHEN LOWER(LTRIM(RTRIM(@v))) IN ('true', 'oui', 'yes', 'y', '1', 'vrai') THEN CAST(1 AS BIT)
        WHEN LOWER(LTRIM(RTRIM(@v))) IN ('false', 'non', 'no', 'n', '0', 'faux') THEN CAST(0 AS BIT)
        ELSE NULL
    END;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0604ProcessImportJson — lit tout ce que le JSON porte
--
--    Chaque clé est facultative : un fichier CSV lu directement n'en donne
--    qu'une douzaine, et ses lignes entrent comme avant. Une extraction Apideck
--    les donne toutes. Les comptes par défaut (T101) restent ce qu'ils étaient.
--
--    Remplace la version de Database/s0604ProcessImportJson.sql.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0604ProcessImportJson
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TypeImport    VARCHAR(20),
            @JsonResult    NVARCHAR(MAX),
            @Status        VARCHAR(20),
            @CompanyGUID   UNIQUEIDENTIFIER,
            @InsertedCount INT = 0;

    -- ── 1. Récupérer le fichier et son JSON ─────────────────────────────────
    SELECT @TypeImport  = TypeImport,
           @JsonResult  = JsonResult,
           @Status      = Status,
           @CompanyGUID = CompanyGUID
    FROM staging.ImportFiles
    WHERE Id = @ImportFileId;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('ImportFileId %d introuvable dans staging.ImportFiles.', 16, 1, @ImportFileId);
        RETURN;
    END

    IF @JsonResult IS NULL OR LEN(@JsonResult) = 0
    BEGIN
        RAISERROR('JsonResult vide pour ImportFileId %d (le fichier n''a peut-être pas encore été traité par l''IA).', 16, 1, @ImportFileId);
        RETURN;
    END

    IF ISJSON(@JsonResult) = 0
    BEGIN
        RAISERROR('JsonResult invalide (pas du JSON) pour ImportFileId %d.', 16, 1, @ImportFileId);
        RETURN;
    END

    -- ── 2. Lookup des comptes par défaut de la compagnie (T100/T101) ───────
    DECLARE @AR NVARCHAR(20),    -- CompteAuxClient
            @CF NVARCHAR(20),    -- CompteAuxFournisseur
            @VP NVARCHAR(20),    -- Compte vente (revenue)
            @AP NVARCHAR(20);    -- Compte achat (expense)

    IF @CompanyGUID IS NOT NULL
    BEGIN
        SELECT @AR = MAX(CASE WHEN pc.ShortName = 'AR' THEN pv.sVal END),
               @CF = MAX(CASE WHEN pc.ShortName = 'CF' THEN pv.sVal END),
               @VP = MAX(CASE WHEN pc.ShortName = 'VP' THEN pv.sVal END),
               @AP = MAX(CASE WHEN pc.ShortName = 'AP' THEN pv.sVal END)
        FROM dbo.T100ParamComptable pc
        INNER JOIN dbo.T101ParamValues pv
                ON pv.T100Id = pc.Id
               AND pv.CompanyGUID = pc.CompanyGUID
        WHERE pc.CompanyGUID = @CompanyGUID
          AND pc.Categorie   = 'COMPTABILITE'
          AND pc.ShortName IN ('AR', 'CF', 'VP', 'AP');
    END

    -- ── 3. Nettoyer les lignes staging existantes pour ce fichier ──────────
    DELETE FROM staging.PartyImport   WHERE ImportFileId = @ImportFileId;
    DELETE FROM staging.ProductImport WHERE ImportFileId = @ImportFileId;

    -- ── 4. Aiguillage selon TypeImport ─────────────────────────────────────
    IF @TypeImport IN ('Client', 'Fournisseur')
    BEGIN
        INSERT INTO staging.PartyImport (
            ImportFileId, LineNumber, TypeImport,
            Name, DisplayName, CompanyName, Attention,
            Title, FirstName, MiddleName, LastName, Suffix, Individual, IsProject, Category,
            Address1, Address2, Address3, City, Province, PostalCode, Country,
            ShipAttention, ShipAddress1, ShipAddress2, ShipCity, ShipProvince, ShipPostalCode, ShipCountry,
            Phone, Mobile, Fax, AltPhone, Email, WebSite,
            TPS, TVQ, Taxable, TaxRateName, TaxRateCode, TaxRate,
            Currency, Terms, PaymentMethod, ParentName, AccountName, Balance, Note,
            SourceId, SourceStatus, SourceCreated, SourceUpdated, ExtraJson,
            CompteAuxClient, CompteAuxFournisseur
        )
        SELECT
            @ImportFileId,
            ROW_NUMBER() OVER (ORDER BY (SELECT 0)),
            @TypeImport,
            j.[name], j.display_name, j.company_name, j.contact_name,
            j.title, j.first_name, j.middle_name, j.last_name, j.suffix,
            dbo.fImportBit(j.individual), dbo.fImportBit(j.is_project), j.category,
            j.address1, j.address2, j.address3, j.city, j.province, j.postal_code, j.country,
            j.ship_attention, j.ship_address1, j.ship_address2, j.ship_city, j.ship_province, j.ship_postal_code, j.ship_country,
            j.phone, j.mobile, j.fax, j.alt_phone, j.email, j.website,
            j.tps, j.tvq, dbo.fImportBit(j.taxable), j.tax_rate_name, j.tax_rate_code,
            TRY_CAST(REPLACE(j.tax_rate, ',', '.') AS DECIMAL(9,4)),
            j.currency, j.terms, j.payment_method, j.parent_name, j.account_name,
            TRY_CAST(REPLACE(REPLACE(j.balance_text, ',', '.'), ' ', '') AS DECIMAL(15,2)),
            j.note,
            j.source_id, j.source_status,
            TRY_CAST(TRY_CAST(j.source_created AS DATETIMEOFFSET) AS DATETIME),
            TRY_CAST(TRY_CAST(j.source_updated AS DATETIMEOFFSET) AS DATETIME),
            j.extra,
            CASE WHEN @TypeImport = 'Client'      THEN @AR END,    -- depuis T101 'AR'
            CASE WHEN @TypeImport = 'Fournisseur' THEN @CF END     -- depuis T101 'CF'
        FROM OPENJSON(@JsonResult, '$.rows')
        WITH (
            [name]            NVARCHAR(500)  '$.name',
            display_name      NVARCHAR(500)  '$.display_name',
            company_name      NVARCHAR(500)  '$.company_name',
            contact_name      NVARCHAR(200)  '$.contact_name',
            title             NVARCHAR(50)   '$.title',
            first_name        NVARCHAR(200)  '$.first_name',
            middle_name       NVARCHAR(200)  '$.middle_name',
            last_name         NVARCHAR(200)  '$.last_name',
            suffix            NVARCHAR(50)   '$.suffix',
            individual        NVARCHAR(10)   '$.individual',
            is_project        NVARCHAR(10)   '$.is_project',
            category          NVARCHAR(100)  '$.category',
            address1          NVARCHAR(500)  '$.address1',
            address2          NVARCHAR(500)  '$.address2',
            address3          NVARCHAR(500)  '$.address3',
            city              NVARCHAR(50)   '$.city',
            province          NVARCHAR(50)   '$.province',
            postal_code       NVARCHAR(20)   '$.postal_code',
            country           NVARCHAR(50)   '$.country',
            ship_attention    NVARCHAR(200)  '$.ship_attention',
            ship_address1     NVARCHAR(500)  '$.ship_address1',
            ship_address2     NVARCHAR(500)  '$.ship_address2',
            ship_city         NVARCHAR(50)   '$.ship_city',
            ship_province     NVARCHAR(50)   '$.ship_province',
            ship_postal_code  NVARCHAR(20)   '$.ship_postal_code',
            ship_country      NVARCHAR(50)   '$.ship_country',
            phone             NVARCHAR(200)  '$.phone',
            mobile            NVARCHAR(50)   '$.mobile',
            fax               NVARCHAR(50)   '$.fax',
            alt_phone         NVARCHAR(50)   '$.alt_phone',
            email             NVARCHAR(200)  '$.email',
            website           NVARCHAR(200)  '$.website',
            tps               NVARCHAR(20)   '$.tps',
            tvq               NVARCHAR(20)   '$.tvq',
            taxable           NVARCHAR(10)   '$.taxable',
            tax_rate_name     NVARCHAR(100)  '$.tax_rate_name',
            tax_rate_code     NVARCHAR(50)   '$.tax_rate_code',
            tax_rate          NVARCHAR(30)   '$.tax_rate',
            currency          NVARCHAR(3)    '$.currency',
            terms             NVARCHAR(100)  '$.terms',
            payment_method    NVARCHAR(100)  '$.payment_method',
            parent_name       NVARCHAR(500)  '$.parent_name',
            account_name      NVARCHAR(200)  '$.account_name',
            balance_text      NVARCHAR(50)   '$.balance',
            note              NVARCHAR(MAX)  '$.note',
            source_id         NVARCHAR(100)  '$.source_id',
            source_status     NVARCHAR(30)   '$.source_status',
            source_created    NVARCHAR(40)   '$.source_created',
            source_updated    NVARCHAR(40)   '$.source_updated',
            extra             NVARCHAR(MAX)  '$.extra' AS JSON
        ) AS j;

        SET @InsertedCount = @@ROWCOUNT;
    END
    ELSE IF @TypeImport = 'Produit'
    BEGIN
        INSERT INTO staging.ProductImport (
            ImportFileId, LineNumber,
            Name, Code, Description, ItemType, Active, Sold, Purchased, Tracked, Taxable,
            Price, PurchasePrice, Unit, PurchaseUnit,
            SalesTaxInclusive, PurchaseTaxInclusive,
            SalesTaxRateName, SalesTaxRate, PurchaseTaxRateName, PurchaseTaxRate,
            RevenueAccount, ExpenseAccount,
            IncomeAccountName, IncomeAccountCode, ExpenseAccountName, ExpenseAccountCode,
            AssetAccountName, AssetAccountCode,
            Quantity, InventoryDate, Currency, Category, ParentName,
            SourceId, SourceCreated, SourceUpdated, ExtraJson
        )
        SELECT
            @ImportFileId,
            ROW_NUMBER() OVER (ORDER BY (SELECT 0)),
            j.[name], j.code, j.[description], j.item_type,
            dbo.fImportBit(j.active), dbo.fImportBit(j.sold), dbo.fImportBit(j.purchased),
            dbo.fImportBit(j.tracked), dbo.fImportBit(j.taxable),
            TRY_CAST(REPLACE(REPLACE(j.price_text, ',', '.'), ' ', '') AS DECIMAL(15,2)),
            TRY_CAST(REPLACE(REPLACE(j.purchase_price, ',', '.'), ' ', '') AS DECIMAL(15,2)),
            j.unit, j.purchase_unit,
            dbo.fImportBit(j.sales_tax_inclusive), dbo.fImportBit(j.purchase_tax_inclusive),
            j.sales_tax_rate_name, TRY_CAST(REPLACE(j.sales_tax_rate, ',', '.') AS DECIMAL(9,4)),
            j.purchase_tax_rate_name, TRY_CAST(REPLACE(j.purchase_tax_rate, ',', '.') AS DECIMAL(9,4)),
            @VP,    -- depuis T101 'VP'
            @AP,    -- depuis T101 'AP'
            j.income_account_name, j.income_account_code,
            j.expense_account_name, j.expense_account_code,
            j.asset_account_name, j.asset_account_code,
            TRY_CAST(REPLACE(j.quantity, ',', '.') AS DECIMAL(15,4)),
            TRY_CAST(j.inventory_date AS DATE),
            j.currency, j.category, j.parent_name,
            j.source_id,
            TRY_CAST(TRY_CAST(j.source_created AS DATETIMEOFFSET) AS DATETIME),
            TRY_CAST(TRY_CAST(j.source_updated AS DATETIMEOFFSET) AS DATETIME),
            j.extra
        FROM OPENJSON(@JsonResult, '$.rows')
        WITH (
            [name]                 NVARCHAR(500)  '$.name',
            code                   NVARCHAR(100)  '$.code',
            [description]          NVARCHAR(2000) '$.description',
            item_type              NVARCHAR(30)   '$.item_type',
            active                 NVARCHAR(10)   '$.active',
            sold                   NVARCHAR(10)   '$.sold',
            purchased              NVARCHAR(10)   '$.purchased',
            tracked                NVARCHAR(10)   '$.tracked',
            taxable                NVARCHAR(10)   '$.taxable',
            price_text             NVARCHAR(50)   '$.price',
            purchase_price         NVARCHAR(50)   '$.purchase_price',
            unit                   NVARCHAR(50)   '$.unit',
            purchase_unit          NVARCHAR(50)   '$.purchase_unit',
            sales_tax_inclusive    NVARCHAR(10)   '$.sales_tax_inclusive',
            purchase_tax_inclusive NVARCHAR(10)   '$.purchase_tax_inclusive',
            sales_tax_rate_name    NVARCHAR(100)  '$.sales_tax_rate_name',
            sales_tax_rate         NVARCHAR(30)   '$.sales_tax_rate',
            purchase_tax_rate_name NVARCHAR(100)  '$.purchase_tax_rate_name',
            purchase_tax_rate      NVARCHAR(30)   '$.purchase_tax_rate',
            income_account_name    NVARCHAR(200)  '$.income_account_name',
            income_account_code    NVARCHAR(50)   '$.income_account_code',
            expense_account_name   NVARCHAR(200)  '$.expense_account_name',
            expense_account_code   NVARCHAR(50)   '$.expense_account_code',
            asset_account_name     NVARCHAR(200)  '$.asset_account_name',
            asset_account_code     NVARCHAR(50)   '$.asset_account_code',
            quantity               NVARCHAR(30)   '$.quantity',
            inventory_date         NVARCHAR(20)   '$.inventory_date',
            currency               NVARCHAR(3)    '$.currency',
            category               NVARCHAR(200)  '$.category',
            parent_name            NVARCHAR(500)  '$.parent_name',
            source_id              NVARCHAR(100)  '$.source_id',
            source_created         NVARCHAR(40)   '$.source_created',
            source_updated         NVARCHAR(40)   '$.source_updated',
            extra                  NVARCHAR(MAX)  '$.extra' AS JSON
        ) AS j;

        SET @InsertedCount = @@ROWCOUNT;
    END
    ELSE
    BEGIN
        RAISERROR('TypeImport inconnu "%s" pour ImportFileId %d.', 16, 1, @TypeImport, @ImportFileId);
        RETURN;
    END

    -- ── 5. Mettre à jour le compteur dans staging.ImportFiles ──────────────
    UPDATE staging.ImportFiles
    SET ProcessedRows = @InsertedCount
    WHERE Id = @ImportFileId;

    -- ── 6. Résumé ───────────────────────────────────────────────────────────
    SELECT @ImportFileId  AS ImportFileId,
           @TypeImport    AS TypeImport,
           @InsertedCount AS InsertedCount;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0773GetImportLignes — rend toutes les colonnes de la préparation
--
--    Seule différence avec T219 : p.* au lieu d'une liste fermée. Les colonnes
--    ajoutées ci-dessus — et celles qui viendront — arrivent ainsi à l'écran
--    sans qu'on ait à retoucher cette procédure. Les verdicts ne changent pas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0773GetImportLignes]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Type VARCHAR(20);
    SELECT @Type = [TypeImport]
      FROM staging.ImportFiles
     WHERE [Id] = @ImportFileId
       AND [CompanyGUID] = @CompanyGUID;

    IF @Type IS NULL
        THROW 50360, 'Ce fichier n''existe pas pour cette compagnie.', 1;

    DECLARE @r TABLE (Statut VARCHAR(20), Existant BIT, Doublon BIT);

    IF @Type = 'Produit'
    BEGIN
        SELECT p.*,
               ex.[Id] AS ExistantId,
               CAST(NULL AS VARCHAR(100)) AS ExistantType,
               CASE WHEN ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM(ISNULL(p.[Name], ''))))
                                           ORDER BY ISNULL(p.[LineNumber], 0), p.[Id]) > 1
                    THEN 1 ELSE 0 END AS Doublon
          INTO #lp
          FROM staging.ProductImport p
         OUTER APPLY (SELECT TOP 1 t.[Id]
                        FROM dbo.T075Products t
                       WHERE t.[CompanyGUID] = @CompanyGUID
                         AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name])))
                       ORDER BY t.[Id]) ex
         WHERE p.[ImportFileId] = @ImportFileId;

        INSERT INTO @r
        SELECT [Status], CASE WHEN ExistantId IS NULL THEN 0 ELSE 1 END, Doublon FROM #lp;
    END
    ELSE
    BEGIN
        SELECT p.*,
               ex.[Id] AS ExistantId,
               ex.TypeNom AS ExistantType,
               CASE WHEN ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM(ISNULL(p.[Name], ''))))
                                           ORDER BY ISNULL(p.[LineNumber], 0), p.[Id]) > 1
                    THEN 1 ELSE 0 END AS Doublon
          INTO #lt
          FROM staging.PartyImport p
         OUTER APPLY (SELECT TOP 1 t.[Id], ty.[Name] AS TypeNom
                        FROM dbo.T050Party t
                        LEFT JOIN dbo.T055PartyType ty ON ty.[Id] = t.[Type]
                       WHERE t.[CompanyGUID] = @CompanyGUID
                         AND ISNULL(t.[isDeleted], 0) = 0
                         AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name])))
                       ORDER BY t.[Id]) ex
         WHERE p.[ImportFileId] = @ImportFileId;

        INSERT INTO @r
        SELECT [Status], CASE WHEN ExistantId IS NULL THEN 0 ELSE 1 END, Doublon FROM #lt;
    END

    SELECT f.[Id], f.[TypeImport], f.[OriginalName], f.[UploadDate], f.[ModelUsed], f.[EstimatedCostUsd],
           (SELECT COUNT(*) FROM @r)                                                          AS Lignes,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Pending' AND Existant = 0 AND Doublon = 0) AS Nouveaux,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Pending' AND Existant = 1)                AS Existants,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Pending' AND Existant = 0 AND Doublon = 1) AS Doublons,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Migrated')                                AS Crees,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Skipped')                                 AS Ecartes,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Error')                                   AS Erreurs
      FROM staging.ImportFiles f
     WHERE f.[Id] = @ImportFileId;

    IF @Type = 'Produit'
        SELECT * FROM #lp ORDER BY ISNULL([LineNumber], 0), [Id];
    ELSE
        SELECT * FROM #lt ORDER BY ISNULL([LineNumber], 0), [Id];
END
GO
