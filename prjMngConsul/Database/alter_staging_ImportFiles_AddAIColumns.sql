-- =============================================================================
-- ALTER staging.ImportFiles : ajoute les colonnes pour stocker le résultat
-- de l'extraction par l'API OpenAI (ChatGPT).
-- À exécuter UNE FOIS sur les bases qui ont déjà la table.
-- Pour une nouvelle installation, le script staging.ImportFiles.sql contient
-- déjà ces colonnes.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('staging.ImportFiles') AND name = 'JsonResult')
    ALTER TABLE staging.ImportFiles ADD JsonResult NVARCHAR(MAX) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('staging.ImportFiles') AND name = 'InputTokens')
    ALTER TABLE staging.ImportFiles ADD InputTokens INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('staging.ImportFiles') AND name = 'OutputTokens')
    ALTER TABLE staging.ImportFiles ADD OutputTokens INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('staging.ImportFiles') AND name = 'EstimatedCostUsd')
    ALTER TABLE staging.ImportFiles ADD EstimatedCostUsd DECIMAL(10,6) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('staging.ImportFiles') AND name = 'ModelUsed')
    ALTER TABLE staging.ImportFiles ADD ModelUsed VARCHAR(50) NULL;
GO
