-- =============================================================================
-- Table staging.ImportFiles
-- Stocke les fichiers téléversés par wbfImport.aspx (clients, fournisseurs,
-- produits). Le contenu binaire est conservé pour traitement ultérieur.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

IF OBJECT_ID('staging.ImportFiles', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ImportFiles
    (
        Id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_staging_ImportFiles PRIMARY KEY,
        TypeImport      VARCHAR(20)       NOT NULL,                       -- 'Client' | 'Fournisseur' | 'Produit'
        OriginalName    NVARCHAR(255)     NOT NULL,
        FileExtension   VARCHAR(10)       NOT NULL,
        FileSize        BIGINT            NOT NULL,
        ContentType     VARCHAR(100)      NULL,
        FileContent     VARBINARY(MAX)    NOT NULL,
        UploadDate      DATETIME          NOT NULL CONSTRAINT DF_staging_ImportFiles_UploadDate DEFAULT (GETDATE()),
        UploadedBy      INT               NULL,
        CompanyGUID     UNIQUEIDENTIFIER  NULL,
        Status          VARCHAR(20)       NOT NULL CONSTRAINT DF_staging_ImportFiles_Status DEFAULT ('Pending'),
        ProcessedDate   DATETIME          NULL,
        ProcessedRows   INT               NULL,
        ErrorMessage    NVARCHAR(MAX)     NULL,
        JsonResult      NVARCHAR(MAX)     NULL,
        InputTokens     INT               NULL,
        OutputTokens    INT               NULL,
        EstimatedCostUsd DECIMAL(10,6)    NULL,
        ModelUsed       VARCHAR(50)       NULL,
        CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK (TypeImport IN ('Client', 'Fournisseur', 'Produit')),
        CONSTRAINT CK_staging_ImportFiles_Status     CHECK (Status     IN ('Pending', 'Processing', 'Done', 'Error'))
    );

    CREATE INDEX IX_staging_ImportFiles_Status_UploadDate
        ON staging.ImportFiles (Status, UploadDate DESC);

    CREATE INDEX IX_staging_ImportFiles_Type_UploadDate
        ON staging.ImportFiles (TypeImport, UploadDate DESC);
END
GO
