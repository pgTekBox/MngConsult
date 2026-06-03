-- =============================================================================
-- T021Plan_FixAccents
-- Corrige les accents francais corrompus suite a un deploiement sans BOM
-- UTF-8 (sqlcmd a lu les bytes UTF-8 comme Windows-1252).
--
-- IMPORTANT : ce fichier DOIT etre sauvegarde avec BOM UTF-8 (EF BB BF).
-- IMPORTANT : deployer avec sqlcmd -f 65001 -I -i <file>
--
-- Symptomes corriges :
--   "1 Ã  9 employÃ©s"  -> "1 à 9 employés"
--   "1â€"19 employÃ©s"  -> "1–19 employés"
--   "0 employÃ©"        -> "0 employé"
--   etc.
-- =============================================================================

USE [MngConsul];
GO

SET QUOTED_IDENTIFIER ON;
GO

-- =============================================================================
-- Solo (Travailleur Autonome) - monthly + annual
-- =============================================================================

UPDATE dbo.T021Plan SET
    Name = N'Travailleur Autonome',
    Description = N'Idéal pour le Travailleur Autonome non incorporé qui veut gérer ses finances simplement.',
    Tagline = N'Sans incorporation',
    EmployeeRange = N'0 employé',
    Features = N'Gestion des clients avec calendrier
Facturation client
Gestion des fournisseurs
Plan comptable complet
États financiers en temps réel
Remises gouvernementales
Assistant IA en français
Point de vente (POS)',
    ModifiedOn = GETDATE(),
    ModifiedBy = 'fix_accents'
WHERE Code = 'solo' AND BillingCycle = 'monthly' AND IsDeleted = 0;

UPDATE dbo.T021Plan SET
    Name = N'Travailleur Autonome',
    Description = N'Idéal pour le Travailleur Autonome non incorporé qui veut gérer ses finances simplement (paiement annuel - 2 mois gratuits).',
    Tagline = N'Sans incorporation',
    EmployeeRange = N'0 employé',
    Features = N'Gestion des clients avec calendrier
Facturation client
Gestion des fournisseurs
Plan comptable complet
États financiers en temps réel
Remises gouvernementales
Assistant IA en français
Point de vente (POS)',
    ModifiedOn = GETDATE(),
    ModifiedBy = 'fix_accents'
WHERE Code = 'solo' AND BillingCycle = 'annual' AND IsDeleted = 0;
GO

-- =============================================================================
-- ComSolo (Compagnie Solo) - monthly + annual
-- =============================================================================

UPDATE dbo.T021Plan SET
    Name = N'Compagnie Solo',
    Description = N'Pour l''entrepreneur incorporé qui décide de ne pas se verser de salaire.',
    Tagline = N'Avec incorporation',
    EmployeeRange = N'0 employé',
    BadgeText = N'Le plus populaire',
    Features = N'Tout du plan Travailleur Autonome
Comptabilité d''entreprise incorporée
Dividendes & rémunération mixte
Fermeture & ouverture d''année
Connexion compte bancaire
Conciliation financière automatisée',
    ModifiedOn = GETDATE(),
    ModifiedBy = 'fix_accents'
WHERE Code = 'comsolo' AND BillingCycle = 'monthly' AND IsDeleted = 0;

UPDATE dbo.T021Plan SET
    Name = N'Compagnie Solo',
    Description = N'Pour l''entrepreneur incorporé qui décide de ne pas se verser de salaire (paiement annuel - 2 mois gratuits).',
    Tagline = N'Avec incorporation',
    EmployeeRange = N'0 employé',
    BadgeText = N'Le plus populaire',
    Features = N'Tout du plan Travailleur Autonome
Comptabilité d''entreprise incorporée
Dividendes & rémunération mixte
Fermeture & ouverture d''année
Connexion compte bancaire
Conciliation financière automatisée',
    ModifiedOn = GETDATE(),
    ModifiedBy = 'fix_accents'
WHERE Code = 'comsolo' AND BillingCycle = 'annual' AND IsDeleted = 0;
GO

-- =============================================================================
-- COM119 (Compagnie 1-19) - monthly + annual
-- =============================================================================

UPDATE dbo.T021Plan SET
    Name = N'Compagnie 1–19',
    Description = N'Conçu pour les PME en croissance avec une équipe d''employés à temps plein.',
    Tagline = N'1 à 9 employés',
    EmployeeRange = N'1–19 employés',
    Features = N'Tout du plan Compagnie Solo
Paie jusqu''à 19 employés
Portail employé & talons de paie
Gestion des congés & maladies
Contrats & T4A
Alertes de conformité RH',
    ModifiedOn = GETDATE(),
    ModifiedBy = 'fix_accents'
WHERE Code = 'com119' AND BillingCycle = 'monthly' AND IsDeleted = 0;

UPDATE dbo.T021Plan SET
    Name = N'Compagnie 1–19',
    Description = N'Conçu pour les PME en croissance avec une équipe d''employés à temps plein (paiement annuel - 2 mois gratuits).',
    Tagline = N'1 à 9 employés',
    EmployeeRange = N'1–19 employés',
    Features = N'Tout du plan Compagnie Solo
Paie jusqu''à 19 employés
Portail employé & talons de paie
Gestion des congés & maladies
Contrats & T4A
Alertes de conformité RH',
    ModifiedOn = GETDATE(),
    ModifiedBy = 'fix_accents'
WHERE Code = 'com119' AND BillingCycle = 'annual' AND IsDeleted = 0;
GO

PRINT 'Accents corriges dans T021Plan.';
GO
