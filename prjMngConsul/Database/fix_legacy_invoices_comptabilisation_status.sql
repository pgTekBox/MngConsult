-- =============================================================================
-- Correctif ponctuel (2026-09-04) — anciennes factures clients sans statut
-- de comptabilisation.
--
-- CONTEXTE
--   19 factures clients (Id 111 a 129, datees d'octobre 2024 a mars 2025)
--   avaient T060Document.ComptabilisationStatus a NULL. La vue
--   vwCustomersInvoices les affichait donc « Brouillon » (tout ce qui n'est
--   pas 'COMPTABILISE'), et leur StatutPaiement restait fige a 'IN_PROGRESS',
--   alors qu'elles portent de vrais numeros de facture (59350, 59365, …) et
--   ne sont pas des brouillons.
--
--   Elles sont desormais marquees 'COMPTABILISE' : l'ecran est coherent avec
--   les boutons de la grille (Encaisser / Envoyer, pas de « Comptabiliser »)
--   et leur statut de paiement se recalcule normalement — les 19 sont
--   ressorties 'EN_RETARD', ce qui reflete la realite (solde impaye, echeance
--   depassee).
--
-- A SAVOIR
--   AUCUNE de ces 19 factures n'a d'ecriture au journal (T137DocumentEcriture
--   vide pour elles). Ce correctif change l'ETIQUETTE, pas la comptabilite :
--   le grand livre reste inchange. Si ces factures doivent aussi etre passees
--   au journal, il faut les comptabiliser une par une (sp_ComptabiliserDocument),
--   ce qui creerait des ecritures datees de 2024-2025 — a ne faire qu'en
--   connaissance de cause, exercice par exercice.
--
--   Les 19 documents fournisseurs (DocumentTypeId = 5) sont dans la meme
--   situation et n'ont PAS ete touches.
--
-- RETOUR EN ARRIERE
--   UPDATE dbo.T060Document SET ComptabilisationStatus = NULL
--    WHERE Id IN (111,112,113,114,115,116,117,118,119,120,
--                 121,122,123,124,125,126,127,128,129);
--
-- Deja applique sur MngConsul le 2026-09-04. Rejouable sans effet.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

UPDATE dbo.T060Document
   SET ComptabilisationStatus = 'COMPTABILISE'
 WHERE ISNULL(ComptabilisationStatus, '') = ''
   AND DocumentTypeId = 1
   AND Id IN (111,112,113,114,115,116,117,118,119,120,
              121,122,123,124,125,126,127,128,129);
GO

PRINT N'fix_legacy_invoices_comptabilisation_status.sql : termine.';
GO
