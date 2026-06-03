-- =============================================================================
-- s0609DeleteImportFile
-- Supprime un fichier d'import + toutes les lignes staging associées
-- (staging.PartyImport et staging.ProductImport) en une transaction atomique.
--
-- Ne touche PAS aux lignes de production (T050Party, T054PartyAddress, etc.)
-- déjà migrées — celles-ci restent en base, juste sans lien retour vers le
-- fichier source (qui disparaît).
--
-- Utilisé par : wbfImport.aspx.vb (bouton 🗑 Supprimer du GridView)
-- =============================================================================

IF OBJECT_ID('dbo.s0609DeleteImportFile', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0609DeleteImportFile;
GO

CREATE PROCEDURE dbo.s0609DeleteImportFile
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM staging.PartyImport   WHERE ImportFileId = @Id;
        DECLARE @PartyDeleted INT = @@ROWCOUNT;

        DELETE FROM staging.ProductImport WHERE ImportFileId = @Id;
        DECLARE @ProductDeleted INT = @@ROWCOUNT;

        DELETE FROM staging.ImportFiles   WHERE Id = @Id;
        DECLARE @FileDeleted INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @Id              AS Id,
               @FileDeleted     AS FileDeleted,
               @PartyDeleted    AS PartyImportDeleted,
               @ProductDeleted  AS ProductImportDeleted;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
