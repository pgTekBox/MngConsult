-- =============================================================================
-- T021Plan
-- Catalogue des forfaits (plans d'abonnement) disponibles dans MngConsul.
-- Chaque ligne = un forfait * un cycle de facturation (monthly / annual).
--
-- Liens :
-- - T020Subscription.PlanCode → T021Plan.Code (le user choisit un forfait,
--   et T020Subscription enregistre quel abonnement il a souscrit)
-- - StripeProductId / StripePriceId : IDs Stripe associés (à remplir après
--   création des produits dans le Dashboard Stripe)
--
-- ATTENTION : ce script crée la table si elle n'existe pas, puis insère
-- les 3 forfaits initiaux (solo, comsolo, com119) si pas déjà présents.
-- Ré-exécution safe (idempotent).
-- =============================================================================

USE [MngConsul];
GO

-- =============================================================================
-- 1. Création de la table
-- =============================================================================

IF OBJECT_ID('dbo.T021Plan', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T021Plan (
        Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

        -- Identification du forfait
        Code                VARCHAR(50)     NOT NULL,           -- 'solo', 'comsolo', 'com119'
        Name                NVARCHAR(100)   NOT NULL,           -- 'Solo', 'ComSolo', 'COM119'
        Description         NVARCHAR(500)   NULL,               -- Description marketing courte
        DescriptionLong     NVARCHAR(MAX)   NULL,               -- Détail complet (pour page forfait)

        -- Tarification
        Amount              DECIMAL(10,2)   NOT NULL,           -- 19.00, 39.00, 119.00
        Currency            VARCHAR(10)     NOT NULL DEFAULT 'CAD',
        BillingCycle        VARCHAR(20)     NOT NULL DEFAULT 'monthly',  -- monthly, annual, quarterly

        -- Intégration processeur de paiement
        ProcessorName       VARCHAR(50)     NULL,               -- 'Stripe', 'Moneris', etc.
        StripeProductId     VARCHAR(50)     NULL,               -- prod_xxx (à remplir après création Stripe)
        StripePriceId       VARCHAR(50)     NULL,               -- price_xxx (à remplir après création Stripe)

        -- Période d'essai
        TrialDays           INT             NOT NULL DEFAULT 0, -- 0 = pas d'essai

        -- Limites du forfait (NULL = illimité)
        MaxUsers            INT             NULL,
        MaxClients          INT             NULL,
        MaxDocuments        INT             NULL,
        MaxStorageMB        INT             NULL,

        -- Liste des fonctionnalités (texte libre ou JSON)
        Features            NVARCHAR(MAX)   NULL,

        -- Affichage UI
        DisplayOrder        INT             NOT NULL DEFAULT 0, -- Tri ascendant
        IsRecommended       BIT             NOT NULL DEFAULT 0, -- Badge "Populaire"
        IsActive            BIT             NOT NULL DEFAULT 1, -- 0 = ne plus offrir (clients existants gardent leur abo)

        -- Audit (suit le pattern T015User / T020Subscription)
        CreatedOn           DATETIME        NOT NULL DEFAULT GETDATE(),
        CreatedBy           NVARCHAR(200)   NULL,
        ModifiedOn          DATETIME        NULL,
        ModifiedBy          NVARCHAR(200)   NULL,
        IsDeleted           BIT             NOT NULL DEFAULT 0,

        -- Contraintes
        CONSTRAINT UQ_T021Plan_Code_Cycle UNIQUE (Code, BillingCycle, IsDeleted)
    );

    PRINT 'Table dbo.T021Plan créée.';
END
ELSE
BEGIN
    PRINT 'Table dbo.T021Plan existe déjà - skip CREATE.';
END
GO

-- Index pour la requête principale (liste des forfaits actifs pour UI)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T021Plan_Active_Display' AND object_id = OBJECT_ID('dbo.T021Plan'))
BEGIN
    CREATE INDEX IX_T021Plan_Active_Display
        ON dbo.T021Plan(IsActive, DisplayOrder)
        WHERE IsDeleted = 0;
    PRINT 'Index IX_T021Plan_Active_Display créé.';
END
GO

-- =============================================================================
-- 2. Seed data : insertion des 3 forfaits initiaux
--    (cycle mensuel seulement pour démarrer - on pourra ajouter l'annuel après)
-- =============================================================================

-- Solo (forfait individuel)
IF NOT EXISTS (SELECT 1 FROM dbo.T021Plan WHERE Code = 'solo' AND BillingCycle = 'monthly')
BEGIN
    INSERT INTO dbo.T021Plan
        (Code, Name, Description, Amount, Currency, BillingCycle,
         ProcessorName, TrialDays, DisplayOrder, IsRecommended, IsActive,
         CreatedBy)
    VALUES
        ('solo', 'Solo',
         'Forfait individuel pour consultants autonomes',
         19.00, 'CAD', 'monthly',
         'Stripe', 14, 10, 0, 1,
         'system');
    PRINT 'Forfait solo (mensuel) inséré.';
END
GO

-- ComSolo (forfait individuel + commandes)
IF NOT EXISTS (SELECT 1 FROM dbo.T021Plan WHERE Code = 'comsolo' AND BillingCycle = 'monthly')
BEGIN
    INSERT INTO dbo.T021Plan
        (Code, Name, Description, Amount, Currency, BillingCycle,
         ProcessorName, TrialDays, DisplayOrder, IsRecommended, IsActive,
         CreatedBy)
    VALUES
        ('comsolo', 'ComSolo',
         'Solo avec gestion des commandes',
         39.00, 'CAD', 'monthly',
         'Stripe', 14, 20, 1, 1,
         'system');  -- IsRecommended = 1 (plan populaire)
    PRINT 'Forfait comsolo (mensuel) inséré.';
END
GO

-- COM119 (forfait entreprise)
IF NOT EXISTS (SELECT 1 FROM dbo.T021Plan WHERE Code = 'com119' AND BillingCycle = 'monthly')
BEGIN
    INSERT INTO dbo.T021Plan
        (Code, Name, Description, Amount, Currency, BillingCycle,
         ProcessorName, TrialDays, DisplayOrder, IsRecommended, IsActive,
         CreatedBy)
    VALUES
        ('com119', 'COM119',
         'Forfait entreprise avec toutes les fonctionnalités',
         119.00, 'CAD', 'monthly',
         'Stripe', 14, 30, 0, 1,
         'system');
    PRINT 'Forfait com119 (mensuel) inséré.';
END
GO

-- =============================================================================
-- 2b. Versions ANNUELLES (rabais 2 mois gratuits = 10× le mensuel)
-- =============================================================================

-- Solo annuel
IF NOT EXISTS (SELECT 1 FROM dbo.T021Plan WHERE Code = 'solo' AND BillingCycle = 'annual')
BEGIN
    INSERT INTO dbo.T021Plan
        (Code, Name, Description, Amount, Currency, BillingCycle,
         ProcessorName, TrialDays, DisplayOrder, IsRecommended, IsActive,
         CreatedBy)
    VALUES
        ('solo', 'Solo',
         'Forfait individuel pour consultants autonomes (paiement annuel - 2 mois gratuits)',
         190.00, 'CAD', 'annual',     -- 19 × 10 = 190 (au lieu de 19 × 12 = 228, économie 38$)
         'Stripe', 14, 10, 0, 1,
         'system');
    PRINT 'Forfait solo (annuel) inséré.';
END
GO

-- ComSolo annuel
IF NOT EXISTS (SELECT 1 FROM dbo.T021Plan WHERE Code = 'comsolo' AND BillingCycle = 'annual')
BEGIN
    INSERT INTO dbo.T021Plan
        (Code, Name, Description, Amount, Currency, BillingCycle,
         ProcessorName, TrialDays, DisplayOrder, IsRecommended, IsActive,
         CreatedBy)
    VALUES
        ('comsolo', 'ComSolo',
         'Solo avec gestion des commandes (paiement annuel - 2 mois gratuits)',
         390.00, 'CAD', 'annual',     -- 39 × 10 = 390 (au lieu de 39 × 12 = 468, économie 78$)
         'Stripe', 14, 20, 1, 1,
         'system');
    PRINT 'Forfait comsolo (annuel) inséré.';
END
GO

-- COM119 annuel
IF NOT EXISTS (SELECT 1 FROM dbo.T021Plan WHERE Code = 'com119' AND BillingCycle = 'annual')
BEGIN
    INSERT INTO dbo.T021Plan
        (Code, Name, Description, Amount, Currency, BillingCycle,
         ProcessorName, TrialDays, DisplayOrder, IsRecommended, IsActive,
         CreatedBy)
    VALUES
        ('com119', 'COM119',
         'Forfait entreprise avec toutes les fonctionnalités (paiement annuel - 2 mois gratuits)',
         1190.00, 'CAD', 'annual',    -- 119 × 10 = 1190 (au lieu de 119 × 12 = 1428, économie 238$)
         'Stripe', 14, 30, 0, 1,
         'system');
    PRINT 'Forfait com119 (annuel) inséré.';
END
GO

-- =============================================================================
-- 3. Vérification : afficher le contenu actuel
-- =============================================================================
SELECT
    Id,
    Code,
    Name,
    Amount,
    Currency,
    BillingCycle,
    ProcessorName,
    StripePriceId,
    TrialDays,
    DisplayOrder,
    IsRecommended,
    IsActive
FROM dbo.T021Plan
WHERE IsDeleted = 0
ORDER BY DisplayOrder, Code;
GO
