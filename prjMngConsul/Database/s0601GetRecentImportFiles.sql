-- =============================================================================
-- s0601GetRecentImportFiles
-- Retourne les N derniers fichiers téléversés (par défaut 10), triés par
-- date d'upload décroissante. Le binaire FileContent n'est PAS retourné.
-- Utilisé par : wbfImport.aspx.vb
-- =============================================================================

IF OBJECT_ID('dbo.s0601GetRecentImportFiles', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0601GetRecentImportFiles;
GO

CREATE PROCEDURE dbo.s0601GetRecentImportFiles
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
           Id,
           TypeImport,
           OriginalName,
           FileExtension,
           FileSize,
           UploadDate,
           Status,
           InputTokens,
           OutputTokens,
           EstimatedCostUsd
    FROM staging.ImportFiles
    ORDER BY Id DESC;
END
GO
