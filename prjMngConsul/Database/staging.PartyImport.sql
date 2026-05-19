-- =============================================================================
-- Table staging.PartyImport
-- Stocke les lignes (clients/fournisseurs) extraites du JSON d'un fichier
-- traité par OpenAI (staging.ImportFiles.JsonResult).
-- Reflète les champs de T050Party + T054PartyAddress combinés (une ligne
-- de CSV = un tiers + une adresse). La résolution Province → StateId et
-- la séparation en T050/T054 se feront dans une étape de migration ultérieure.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

IF OBJECT_ID('staging.PartyImport', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PartyImport
    (
        Id                   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_staging_PartyImport PRIMARY KEY,
        ImportFileId         INT               NOT NULL,
        LineNumber           INT               NULL,
        TypeImport           VARCHAR(20)       NOT NULL,    -- 'Client' | 'Fournisseur'

        -- ── Champs T050Party ────────────────────────────────────────────────
        Name                 VARCHAR(500)      NULL,
        DisplayName          VARCHAR(500)      NULL,
        TPS                  VARCHAR(20)       NULL,
        TVQ                  VARCHAR(20)       NULL,
        WebSite              VARCHAR(200)      NULL,
        Note                 VARCHAR(MAX)      NULL,
        CompteAuxClient      VARCHAR(20)       NULL,
        CompteAuxFournisseur VARCHAR(20)       NULL,

        -- ── Champs T054PartyAddress ────────────────────────────────────────
        AddressName          VARCHAR(200)      NULL,        -- libellé (ex: "Siège social")
        Attention            VARCHAR(200)      NULL,        -- "à l'attention de…" (contact_name)
        Address1             VARCHAR(500)      NULL,
        Address2             VARCHAR(500)      NULL,
        City                 VARCHAR(50)       NULL,
        Province             VARCHAR(50)       NULL,        -- texte brut, à résoudre en StateId
        PostalCode           VARCHAR(20)       NULL,
        Country              VARCHAR(50)       NULL,
        Phone                VARCHAR(200)      NULL,
        Email                VARCHAR(200)      NULL,

        -- ── Champ extra du CSV ─────────────────────────────────────────────
        Balance              DECIMAL(15,2)     NULL,

        -- ── Suivi de migration vers la production ──────────────────────────
        Status               VARCHAR(20)       NOT NULL CONSTRAINT DF_staging_PartyImport_Status DEFAULT ('Pending'),
        Created              DATETIME          NOT NULL CONSTRAINT DF_staging_PartyImport_Created DEFAULT (GETDATE()),
        MigratedToPartyId    INT               NULL,        -- Id dans T050Party après migration
        MigratedDate         DATETIME          NULL,
        ErrorMessage         NVARCHAR(MAX)     NULL,

        CONSTRAINT CK_staging_PartyImport_TypeImport CHECK (TypeImport IN ('Client', 'Fournisseur')),
        CONSTRAINT CK_staging_PartyImport_Status     CHECK (Status IN ('Pending', 'Migrated', 'Error', 'Skipped')),
        CONSTRAINT FK_staging_PartyImport_ImportFile FOREIGN KEY (ImportFileId) REFERENCES staging.ImportFiles(Id)
    );

    CREATE INDEX IX_staging_PartyImport_ImportFileId
        ON staging.PartyImport (ImportFileId, LineNumber);

    CREATE INDEX IX_staging_PartyImport_Status
        ON staging.PartyImport (Status, Created DESC);
END
GO
