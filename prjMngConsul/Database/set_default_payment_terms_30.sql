-- =============================================================================
-- Délai de paiement par défaut : 30 jours sur les CLIENTS (2026-09-04)
--
-- Le champ T050Party.PaymentTermDays, ajouté la veille, valait 0 partout :
-- une facture comptabilisée était donc échue le jour même et basculait
-- aussitôt « EN_RETARD ». On pose 30 jours sur les clients.
--
-- PÉRIMÈTRE
--   Type 1 (Client) et 3 (Client et Fournisseur) — le même filtre que la
--   grille « Gestion des clients ». Les FOURNISSEURS ne sont pas touchés :
--   leur délai est celui qu'EUX accordent, pas une politique maison.
--
--   Seuls les tiers encore à 0 sont modifiés : un délai déjà saisi (un client
--   était à 30) est une décision, on ne l'écrase pas.
--
-- EFFET
--   Les factures DÉJÀ comptabilisées gardent l'échéance qu'elles ont reçue :
--   ce délai sert au calcul lors des prochaines comptabilisations
--   (sp_ComptabiliserDocument : DueDate = DocumentDate + délai du tiers).
--
-- RETOUR EN ARRIÈRE
--   UPDATE dbo.T050Party SET PaymentTermDays = 0
--    WHERE [Type] IN (1, 3) AND PaymentTermDays = 30;
--   (attention : remettrait aussi à 0 le client qui était déjà à 30)
--
-- Déjà appliqué sur MngConsul le 2026-09-04. Rejouable sans effet.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

UPDATE dbo.T050Party
   SET PaymentTermDays = 30
 WHERE [Type] IN (1, 3)
   AND ISNULL(PaymentTermDays, 0) = 0;
GO

PRINT N'set_default_payment_terms_30.sql : termine.';
GO
