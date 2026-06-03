-- =============================================================================
-- T021Plan_AddLandingPageColumns
-- Migration : ajoute les colonnes de présentation à T021Plan pour permettre
-- au LandingPage.aspx de générer dynamiquement les plan-cards.
--
-- Puis met à jour les 3 forfaits mensuels et les 3 annuels avec les
-- vraies valeurs (prix, noms, descriptions, icônes SVG, classes CSS).
--
-- Idempotent : peut être ré-exécuté sans erreur.
-- =============================================================================

USE [MngConsul];
GO

SET QUOTED_IDENTIFIER ON;
GO

-- =============================================================================
-- 1. Ajout des colonnes de présentation (si pas déjà présentes)
-- =============================================================================

IF COL_LENGTH('dbo.T021Plan', 'Tagline') IS NULL
    ALTER TABLE dbo.T021Plan ADD Tagline NVARCHAR(200) NULL;
GO

IF COL_LENGTH('dbo.T021Plan', 'EmployeeRange') IS NULL
    ALTER TABLE dbo.T021Plan ADD EmployeeRange NVARCHAR(100) NULL;
GO

IF COL_LENGTH('dbo.T021Plan', 'PlanIconCssClass') IS NULL
    ALTER TABLE dbo.T021Plan ADD PlanIconCssClass VARCHAR(50) NULL;
GO

IF COL_LENGTH('dbo.T021Plan', 'PlanCardCssClass') IS NULL
    ALTER TABLE dbo.T021Plan ADD PlanCardCssClass VARCHAR(50) NULL;
GO

IF COL_LENGTH('dbo.T021Plan', 'BadgeText') IS NULL
    ALTER TABLE dbo.T021Plan ADD BadgeText NVARCHAR(100) NULL;
GO

IF COL_LENGTH('dbo.T021Plan', 'IconSvg') IS NULL
    ALTER TABLE dbo.T021Plan ADD IconSvg NVARCHAR(MAX) NULL;
GO

PRINT 'Colonnes de présentation ajoutées (ou déjà présentes).';
GO

-- =============================================================================
-- 2. UPDATE des 3 forfaits MENSUELS avec valeurs réelles de LandingPage
-- =============================================================================

-- Solo / Travailleur Autonome
UPDATE dbo.T021Plan SET
    Name = N'Travailleur Autonome',
    Amount = 69.99,
    Description = N'Idéal pour le Travailleur Autonome non incorporé qui veut gérer ses finances simplement.',
    Tagline = N'Sans incorporation',
    EmployeeRange = N'0 employé',
    PlanIconCssClass = 'plan-icon-slate',
    PlanCardCssClass = '',
    BadgeText = NULL,
    IconSvg = N'<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle>',
    Features = N'Gestion des clients avec calendrier
Facturation client
Gestion des fournisseurs
Plan comptable complet
États financiers en temps réel
Remises gouvernementales
Assistant IA en français
Point de vente (POS)',
    IsRecommended = 0,
    ModifiedOn = GETDATE(),
    ModifiedBy = 'migration_landingpage'
WHERE Code = 'solo' AND BillingCycle = 'monthly' AND IsDeleted = 0;
GO

-- ComSolo / Compagnie Solo (le plus populaire)
UPDATE dbo.T021Plan SET
    Name = N'Compagnie Solo',
    Amount = 99.99,
    Description = N'Pour l''entrepreneur incorporé qui décide de ne pas se verser de salaire.',
    Tagline = N'Avec incorporation',
    EmployeeRange = N'0 employé',
    PlanIconCssClass = 'plan-icon-sky',
    PlanCardCssClass = 'featured',
    BadgeText = N'Le plus populaire',
    IconSvg = N'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><polyline points="16 11 18 13 22 9"></polyline>',
    Features = N'Tout du plan Travailleur Autonome
Comptabilité d''entreprise incorporée
Dividendes & rémunération mixte
Fermeture & ouverture d''année
Connexion compte bancaire
Conciliation financière automatisée',
    IsRecommended = 1,
    ModifiedOn = GETDATE(),
    ModifiedBy = 'migration_landingpage'
WHERE Code = 'comsolo' AND BillingCycle = 'monthly' AND IsDeleted = 0;
GO

-- COM119 / Compagnie 1-19
UPDATE dbo.T021Plan SET
    Name = N'Compagnie 1–19',
    Amount = 149.99,
    Description = N'Conçu pour les PME en croissance avec une équipe d''employés à temps plein.',
    Tagline = N'1 à 9 employés',
    EmployeeRange = N'1–19 employés',
    PlanIconCssClass = 'plan-icon-emerald',
    PlanCardCssClass = 'emerald-bordered',
    BadgeText = NULL,
    IconSvg = N'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>',
    Features = N'Tout du plan Compagnie Solo
Paie jusqu''à 19 employés
Portail employé & talons de paie
Gestion des congés & maladies
Contrats & T4A
Alertes de conformité RH',
    IsRecommended = 0,
    ModifiedOn = GETDATE(),
    ModifiedBy = 'migration_landingpage'
WHERE Code = 'com119' AND BillingCycle = 'monthly' AND IsDeleted = 0;
GO

PRINT 'Forfaits mensuels mis à jour avec données LandingPage.';
GO

-- =============================================================================
-- 3. UPDATE des 3 forfaits ANNUELS (= 10× mensuel, 2 mois gratuits)
--    Mêmes noms/descriptions/icônes que mensuels, prix annuel
-- =============================================================================

-- Solo annuel
UPDATE dbo.T021Plan SET
    Name = N'Travailleur Autonome',
    Amount = 699.90,  -- 10 × 69.99
    Description = N'Idéal pour le Travailleur Autonome non incorporé qui veut gérer ses finances simplement (paiement annuel - 2 mois gratuits).',
    Tagline = N'Sans incorporation',
    EmployeeRange = N'0 employé',
    PlanIconCssClass = 'plan-icon-slate',
    PlanCardCssClass = '',
    BadgeText = NULL,
    IconSvg = N'<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle>',
    Features = N'Gestion des clients avec calendrier
Facturation client
Gestion des fournisseurs
Plan comptable complet
États financiers en temps réel
Remises gouvernementales
Assistant IA en français
Point de vente (POS)',
    IsRecommended = 0,
    ModifiedOn = GETDATE(),
    ModifiedBy = 'migration_landingpage'
WHERE Code = 'solo' AND BillingCycle = 'annual' AND IsDeleted = 0;
GO

-- ComSolo annuel
UPDATE dbo.T021Plan SET
    Name = N'Compagnie Solo',
    Amount = 999.90,  -- 10 × 99.99
    Description = N'Pour l''entrepreneur incorporé qui décide de ne pas se verser de salaire (paiement annuel - 2 mois gratuits).',
    Tagline = N'Avec incorporation',
    EmployeeRange = N'0 employé',
    PlanIconCssClass = 'plan-icon-sky',
    PlanCardCssClass = 'featured',
    BadgeText = N'Le plus populaire',
    IconSvg = N'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><polyline points="16 11 18 13 22 9"></polyline>',
    Features = N'Tout du plan Travailleur Autonome
Comptabilité d''entreprise incorporée
Dividendes & rémunération mixte
Fermeture & ouverture d''année
Connexion compte bancaire
Conciliation financière automatisée',
    IsRecommended = 1,
    ModifiedOn = GETDATE(),
    ModifiedBy = 'migration_landingpage'
WHERE Code = 'comsolo' AND BillingCycle = 'annual' AND IsDeleted = 0;
GO

-- COM119 annuel
UPDATE dbo.T021Plan SET
    Name = N'Compagnie 1–19',
    Amount = 1499.90,  -- 10 × 149.99
    Description = N'Conçu pour les PME en croissance avec une équipe d''employés à temps plein (paiement annuel - 2 mois gratuits).',
    Tagline = N'1 à 9 employés',
    EmployeeRange = N'1–19 employés',
    PlanIconCssClass = 'plan-icon-emerald',
    PlanCardCssClass = 'emerald-bordered',
    BadgeText = NULL,
    IconSvg = N'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>',
    Features = N'Tout du plan Compagnie Solo
Paie jusqu''à 19 employés
Portail employé & talons de paie
Gestion des congés & maladies
Contrats & T4A
Alertes de conformité RH',
    IsRecommended = 0,
    ModifiedOn = GETDATE(),
    ModifiedBy = 'migration_landingpage'
WHERE Code = 'com119' AND BillingCycle = 'annual' AND IsDeleted = 0;
GO

PRINT 'Forfaits annuels mis à jour avec données LandingPage.';
GO

-- =============================================================================
-- 4. Vérification : afficher le contenu après migration
-- =============================================================================
SELECT
    Code,
    Name,
    Tagline,
    EmployeeRange,
    Amount,
    BillingCycle,
    PlanIconCssClass,
    PlanCardCssClass,
    BadgeText,
    IsRecommended
FROM dbo.T021Plan
WHERE IsDeleted = 0
ORDER BY BillingCycle DESC, DisplayOrder, Code;
GO
