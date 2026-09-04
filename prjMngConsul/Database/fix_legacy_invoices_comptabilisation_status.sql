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
-- VOLET FOURNISSEURS (ajoute le meme jour, a la demande)
--   19 documents DocumentTypeId = 5 (ReceiptOCR : recus numerises — Costco,
--   Esso, Rona, Postes Canada…, de 2014 a 2026) etaient dans le meme cas.
--   Ils sont marques 'COMPTABILISE' eux aussi.
--
--   Deux consequences a connaitre :
--     - la grille fournisseurs les affiche desormais « Comptabilise » ;
--     - CanPay() de wbfSuppliersInvoices n'offre le paiement QUE sur un
--       document comptabilise : ces 19 recus deviennent donc payables depuis
--       la grille, ce qui n'etait pas le cas avant.
--   Eux non plus n'ont aucune ecriture au journal.
--
-- RETOUR EN ARRIERE
--   Factures clients :
--   UPDATE dbo.T060Document SET ComptabilisationStatus = NULL
--    WHERE Id IN (111,112,113,114,115,116,117,118,119,120,
--                 121,122,123,124,125,126,127,128,129);
--   Recus fournisseurs :
--   UPDATE dbo.T060Document SET ComptabilisationStatus = NULL
--    WHERE Id IN (96,97,98,99,100,101,102,103,104,105,106,
--                 130,131,132,133,134,135,136,137);
--
-- Deja applique sur MngConsul le 2026-09-04. Rejouable sans effet.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Factures clients
UPDATE dbo.T060Document
   SET ComptabilisationStatus = 'COMPTABILISE'
 WHERE ISNULL(ComptabilisationStatus, '') = ''
   AND DocumentTypeId = 1
   AND Id IN (111,112,113,114,115,116,117,118,119,120,
              121,122,123,124,125,126,127,128,129);
GO

-- Recus fournisseurs numerises (ReceiptOCR)
UPDATE dbo.T060Document
   SET ComptabilisationStatus = 'COMPTABILISE'
 WHERE ISNULL(ComptabilisationStatus, '') = ''
   AND DocumentTypeId = 5
   AND Id IN (96,97,98,99,100,101,102,103,104,105,106,
              130,131,132,133,134,135,136,137);
GO

PRINT N'fix_legacy_invoices_comptabilisation_status.sql : termine.';
GO
