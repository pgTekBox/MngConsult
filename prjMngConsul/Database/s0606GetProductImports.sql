-- =============================================================================
-- s0606GetProductImports
-- Retourne les lignes staging.ProductImport pour un ImportFileId donné,
-- avec le résumé du fichier source.
-- Utilisé par : wbfImportView.aspx (visualisation des données staging)
-- =============================================================================

IF OBJECT_ID('dbo.s0606GetProductImports', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0606GetProductImports;
GO

CREATE PROCEDURE dbo.s0606GetProductImports
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Table 0 : résumé du fichier
    SELECT Id,
           TypeImport,
           OriginalName,
           FileExtension,
           UploadDate,
           Status,
           ProcessedDate,
           ProcessedRows,
           InputTokens,
           OutputTokens,
           EstimatedCostUsd,
           ModelUsed,
           ErrorMessage
    FROM staging.ImportFiles
    WHERE Id = @ImportFileId;

    -- Table 1 : lignes staging
    SELECT Id,
           LineNumber,
           Name,
           Description,
           Price,
           RevenueAccount,
           ExpenseAccount,
           Taxable,
           Status,
           MigratedToProductId,
           MigratedDate,
           ErrorMessage
    FROM staging.ProductImport
    WHERE ImportFileId = @ImportFileId
    ORDER BY ISNULL(LineNumber, 0), Id;
END
GO
