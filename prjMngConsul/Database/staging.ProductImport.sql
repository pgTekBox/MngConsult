-- =============================================================================
-- Table staging.ProductImport
-- Stocke les lignes (produits/services) extraites du JSON d'un fichier
-- traité par OpenAI (staging.ImportFiles.JsonResult).
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

IF OBJECT_ID('staging.ProductImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ProductImport
    (
        Id                   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_staging_ProductImport PRIMARY KEY,
        ImportFileId         INT               NOT NULL,
        LineNumber           INT               NULL,

        Name                 VARCHAR(500)      NULL,
        Description          VARCHAR(2000)     NULL,
        Price                DECIMAL(15,2)     NULL,
        RevenueAccount       VARCHAR(20)       NULL,
        ExpenseAccount       VARCHAR(20)       NULL,
        Taxable              BIT               NULL,

        Status               VARCHAR(20)       NOT NULL CONSTRAINT DF_staging_ProductImport_Status DEFAULT ('Pending'),
        Created              DATETIME          NOT NULL CONSTRAINT DF_staging_ProductImport_Created DEFAULT (GETDATE()),
        MigratedToProductId  INT               NULL,
        MigratedDate         DATETIME          NULL,
        ErrorMessage         NVARCHAR(MAX)     NULL,

        CONSTRAINT CK_staging_ProductImport_Status CHECK (Status IN ('Pending', 'Migrated', 'Error', 'Skipped')),
        CONSTRAINT FK_staging_ProductImport_ImportFile FOREIGN KEY (ImportFileId) REFERENCES staging.ImportFiles(Id)
    );

    CREATE INDEX IX_staging_ProductImport_ImportFileId
        ON staging.ProductImport (ImportFileId, LineNumber);

    CREATE INDEX IX_staging_ProductImport_Status
        ON staging.ProductImport (Status, Created DESC);
END
GO
