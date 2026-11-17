-- =====================================================================
-- T398 — « Demande à Claude » : l'usager télécharge le fichier joint à
-- ses propres demandes depuis l'ERP (bouton « Télécharger » de l'aperçu).
--
-- s0968GetClaudePromptFichier reçoit un @UserId facultatif :
--   NULL  → console d'admin (prjSec60Admin), toutes les demandes (inchangé) ;
--   donné → seulement une demande de cet usager (ClaudePrompt.ashx?fichier=).
-- =====================================================================
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0968GetClaudePromptFichier
    @Id     int,
    @UserId int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FichierNom, FichierType, FichierData
    FROM dbo.T026ClaudePrompt
    WHERE Id = @Id AND FichierData IS NOT NULL
      AND (@UserId IS NULL OR UserId = @UserId);
END
GO
