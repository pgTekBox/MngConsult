-- =============================================================================
-- s0603GetImportFile
-- Retourne le fichier complet (binaire + métadonnées) pour traitement.
-- Utilisé par : wbfImport.aspx.vb avant d'envoyer le fichier à OpenAI
-- =============================================================================

IF OBJECT_ID('dbo.s0603GetImportFile', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0603GetImportFile;
GO

CREATE PROCEDURE dbo.s0603GetImportFile
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id,
           TypeImport,
           OriginalName,
           FileExtension,
           FileSize,
           ContentType,
           FileContent,
           Status
    FROM staging.ImportFiles
    WHERE Id = @Id;
END
GO
