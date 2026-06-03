-- =============================================================================
-- T015User_AddStripeCustomerId
-- Ajoute la colonne StripeCustomerId a T015User pour mapper le user MngConsul
-- avec son Customer Stripe (cus_xxx). Permet de re-creer des Checkout Sessions
-- sans re-creer le Customer Stripe a chaque fois.
--
-- Idempotent : peut etre re-execute sans erreur.
-- =============================================================================

USE [MngConsul];
GO

IF COL_LENGTH('dbo.T015User', 'StripeCustomerId') IS NULL
BEGIN
    ALTER TABLE dbo.T015User ADD StripeCustomerId VARCHAR(50) NULL;
    PRINT 'Colonne StripeCustomerId ajoutee a T015User.';
END
ELSE
BEGIN
    PRINT 'Colonne StripeCustomerId existe deja - skip ALTER.';
END
GO

-- Index pour lookup rapide par StripeCustomerId (utilise par webhook handler)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T015User_StripeCustomerId' AND object_id = OBJECT_ID('dbo.T015User'))
BEGIN
    CREATE INDEX IX_T015User_StripeCustomerId
        ON dbo.T015User(StripeCustomerId)
        WHERE StripeCustomerId IS NOT NULL AND IsDeleted = 0;
    PRINT 'Index IX_T015User_StripeCustomerId cree.';
END
GO
