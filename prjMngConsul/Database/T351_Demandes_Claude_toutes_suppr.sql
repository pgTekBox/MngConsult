-- =============================================================================
-- T351 — « Demande à Claude » : liste de TOUTES les demandes de l'usager + suppr.
--
--  - s0966GetClaudePromptsByPage : @Page devient optionnel (NULL = toutes les
--    pages) et la page est retournée, pour le menu déroulant qui montre
--    désormais toutes les demandes avec le nom de la page.
--  - s0967DeleteClaudePrompt : supprime une demande de l'usager, seulement si
--    elle n'est pas « fait ».
--
-- Idempotent (CREATE OR ALTER). Rejouable.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0966GetClaudePromptsByPage
    @UserId int = NULL,
    @Page   nvarchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (200)
        Id, Page, Created, Statut, Prompt
    FROM dbo.T026ClaudePrompt
    WHERE (@Page IS NULL OR Page = @Page)
      AND (@UserId IS NULL OR UserId = @UserId)
    ORDER BY Created DESC, Id DESC;
END
GO

-- ---------------------------------------------------------------------------
-- s0967DeleteClaudePrompt : supprime une demande (de l'usager) non encore faite.
-- Retourne Supprime (nombre de lignes retirées : 1 si OK, 0 sinon).
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0967DeleteClaudePrompt
    @UserId int = NULL,
    @Id     int
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.T026ClaudePrompt
    WHERE Id = @Id
      AND Statut <> 'fait'
      AND (@UserId IS NULL OR UserId = @UserId);
    SELECT @@ROWCOUNT AS Supprime;
END
GO
