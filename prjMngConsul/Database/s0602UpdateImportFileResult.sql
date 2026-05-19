-- =============================================================================
-- s0602UpdateImportFileResult
-- Met à jour staging.ImportFiles avec le résultat de l'extraction OpenAI :
-- JSON retourné, tokens utilisés, coût estimé, statut final.
-- Utilisé par : wbfImport.aspx.vb (handler du bouton "Traiter")
-- =============================================================================

IF OBJECT_ID('dbo.s0602UpdateImportFileResult', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0602UpdateImportFileResult;
GO

CREATE PROCEDURE dbo.s0602UpdateImportFileResult
    @Id              INT,
    @JsonResult      NVARCHAR(MAX)    = NULL,
    @InputTokens     INT              = NULL,
    @OutputTokens    INT              = NULL,
    @EstimatedCostUsd DECIMAL(10,6)   = NULL,
    @ModelUsed       VARCHAR(50)      = NULL,
    @Status          VARCHAR(20),                    -- 'Done' ou 'Error'
    @ErrorMessage    NVARCHAR(MAX)    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE staging.ImportFiles
    SET JsonResult       = @JsonResult,
        InputTokens      = @InputTokens,
        OutputTokens     = @OutputTokens,
        EstimatedCostUsd = @EstimatedCostUsd,
        ModelUsed        = @ModelUsed,
        Status           = @Status,
        ErrorMessage     = @ErrorMessage,
        ProcessedDate    = GETDATE()
    WHERE Id = @Id;
END
GO
