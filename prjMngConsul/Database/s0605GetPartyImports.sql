-- =============================================================================
-- s0605GetPartyImports
-- Retourne les lignes staging.PartyImport pour un ImportFileId donné,
-- avec le résumé du fichier source (jointure sur staging.ImportFiles).
-- Utilisé par : wbfImportView.aspx (visualisation des données staging)
-- =============================================================================

IF OBJECT_ID('dbo.s0605GetPartyImports', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0605GetPartyImports;
GO

CREATE PROCEDURE dbo.s0605GetPartyImports
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
           TypeImport,
           Name,
           Attention,
           Address1,
           Address2,
           City,
           Province,
           PostalCode,
           Country,
           Phone,
           Email,
           TPS,
           TVQ,
           Balance,
           CompteAuxClient,
           CompteAuxFournisseur,
           Status,
           MigratedToPartyId,
           MigratedDate,
           ErrorMessage
    FROM staging.PartyImport
    WHERE ImportFileId = @ImportFileId
    ORDER BY ISNULL(LineNumber, 0), Id;
END
GO
