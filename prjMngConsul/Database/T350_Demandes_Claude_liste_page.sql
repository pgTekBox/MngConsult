-- =============================================================================
-- T350 — « Demande à Claude » : liste des demandes de la page courante
--
-- Pour alimenter le menu déroulant « Demandes précédentes » de la fenêtre
-- flottante de l'ERP (heure/date + statut). Scopé à l'usager et à la page.
-- Idempotent (CREATE OR ALTER). Rejouable.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0966GetClaudePromptsByPage
    @UserId int = NULL,
    @Page   nvarchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (100)
        Id, Created, Statut, Prompt
    FROM dbo.T026ClaudePrompt
    WHERE Page = @Page
      AND (@UserId IS NULL OR UserId = @UserId)
    ORDER BY Created DESC, Id DESC;
END
GO
