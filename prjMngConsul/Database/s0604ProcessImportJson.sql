-- =============================================================================
-- s0604ProcessImportJson
-- Lit staging.ImportFiles.JsonResult pour @ImportFileId, parse le JSON via
-- OPENJSON, et insère les lignes dans staging.PartyImport (Client/Fournisseur)
-- ou staging.ProductImport (Produit) selon TypeImport.
--
-- Les COMPTES (CompteAuxClient, CompteAuxFournisseur, RevenueAccount,
-- ExpenseAccount) ne viennent PAS du JSON — ils sont lus depuis
-- T100ParamComptable/T101ParamValues (Categorie='COMPTABILITE') pour la
-- compagnie du fichier :
--   - 'AR' → CompteAuxClient (clients)
--   - 'CF' → CompteAuxFournisseur (fournisseurs)
--   - 'VP' → RevenueAccount (produits)
--   - 'AP' → ExpenseAccount (produits)
--
-- Idempotent : supprime d'abord les lignes staging existantes pour ce
-- ImportFileId, donc peut être ré-exécutée sans dupliquer.
--
-- Retourne : SELECT @ImportFileId, @TypeImport, @InsertedCount.
-- =============================================================================

IF OBJECT_ID('dbo.s0604ProcessImportJson', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0604ProcessImportJson;
GO

CREATE PROCEDURE dbo.s0604ProcessImportJson
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
        ;WITH parsed AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNumber,
                j.[name],
                j.contact_name,
                j.address1,
                j.address2,
                j.city,
                j.province,
                j.postal_code,
                j.phone,
                j.email,
                j.tps,
                j.tvq,
                j.balance_text
            FROM OPENJSON(@JsonResult, '$.rows')
            WITH (
                [name]            NVARCHAR(500)  '$.name',
                contact_name      NVARCHAR(200)  '$.contact_name',
                address1          NVARCHAR(500)  '$.address1',
                address2          NVARCHAR(500)  '$.address2',
                city              NVARCHAR(50)   '$.city',
                province          NVARCHAR(50)   '$.province',
                postal_code       NVARCHAR(20)   '$.postal_code',
                phone             NVARCHAR(200)  '$.phone',
                email             NVARCHAR(200)  '$.email',
                tps               NVARCHAR(20)   '$.tps',
                tvq               NVARCHAR(20)   '$.tvq',
                balance_text      NVARCHAR(50)   '$.balance'
            ) AS j
        )
        INSERT INTO staging.PartyImport (
            ImportFileId, LineNumber, TypeImport,
            Name, Attention, Address1, Address2, City, Province, PostalCode,
            Phone, Email, TPS, TVQ, Balance,
            CompteAuxClient, CompteAuxFournisseur
        )
        SELECT
            @ImportFileId,
            LineNumber,
            @TypeImport,
            [name],
            contact_name,
            address1,
            address2,
            city,
            province,
            postal_code,
            phone,
            email,
            tps,
            tvq,
            TRY_CAST(REPLACE(REPLACE(balance_text, ',', '.'), ' ', '') AS DECIMAL(15,2)),
            CASE WHEN @TypeImport = 'Client'      THEN @AR END,    -- depuis T101 'AR'
            CASE WHEN @TypeImport = 'Fournisseur' THEN @CF END     -- depuis T101 'CF'
        FROM parsed;

        SET @InsertedCount = @@ROWCOUNT;
    END
    ELSE IF @TypeImport = 'Produit'
    BEGIN
        ;WITH parsed AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNumber,
                j.[name],
                j.[description],
                j.price_text,
                j.taxable_text
            FROM OPENJSON(@JsonResult, '$.rows')
            WITH (
                [name]          NVARCHAR(500)  '$.name',
                [description]   NVARCHAR(2000) '$.description',
                price_text      NVARCHAR(50)   '$.price',
                taxable_text    NVARCHAR(10)   '$.taxable'
            ) AS j
        )
        INSERT INTO staging.ProductImport (
            ImportFileId, LineNumber,
            Name, Description, Price, RevenueAccount, ExpenseAccount, Taxable
        )
        SELECT
            @ImportFileId,
            LineNumber,
            [name],
            [description],
            TRY_CAST(REPLACE(REPLACE(price_text, ',', '.'), ' ', '') AS DECIMAL(15,2)),
            @VP,    -- depuis T101 'VP'
            @AP,    -- depuis T101 'AP'
            CASE
                WHEN taxable_text IS NULL THEN NULL
                WHEN LOWER(taxable_text) IN ('true', 'oui', 'yes', 'y', '1') THEN CAST(1 AS BIT)
                WHEN LOWER(taxable_text) IN ('false', 'non', 'no', 'n', '0') THEN CAST(0 AS BIT)
                ELSE NULL
            END
        FROM parsed;

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
