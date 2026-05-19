-- =============================================================================
-- s0600InsertImportFile
-- Insère un fichier téléversé dans staging.ImportFiles.
-- Retourne l'Id généré pour permettre au caller de référencer l'enregistrement.
-- Utilisé par : wbfImport.aspx.vb
-- =============================================================================

IF OBJECT_ID('dbo.s0600InsertImportFile', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0600InsertImportFile;
GO

CREATE PROCEDURE dbo.s0600InsertImportFile
    @TypeImport     VARCHAR(20),
    @OriginalName   NVARCHAR(255),
    @FileExtension  VARCHAR(10),
    @FileSize       BIGINT,
    @ContentType    VARCHAR(100)    = NULL,
    @FileContent    VARBINARY(MAX),
    @UploadedBy     INT             = NULL,
    @CompanyGUID    UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO staging.ImportFiles
        (TypeImport, OriginalName, FileExtension, FileSize, ContentType,
         FileContent, UploadDate, UploadedBy, CompanyGUID, Status)
    OUTPUT INSERTED.Id
    VALUES
        (@TypeImport, @OriginalName, @FileExtension, @FileSize, @ContentType,
         @FileContent, GETDATE(), @UploadedBy, @CompanyGUID, 'Pending');
END
GO
