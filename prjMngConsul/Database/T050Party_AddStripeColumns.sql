-- =============================================================================
-- T050Party_AddStripeColumns
-- Ajoute 2 colonnes a T050Party pour supporter les paiements aux fournisseurs
-- via Stripe Connect :
--
--   StripeAccountId    VARCHAR(50)  : acct_xxx (Connected Account du fournisseur)
--                                     NULL = fournisseur pas encore onboard
--
--   LastPaymentMethod  VARCHAR(20)  : 'card' | 'interac_present' | 'acss_debit'
--                                     Permet de pre-selectionner la methode preferee
--                                     lors d'un nouveau paiement a ce fournisseur
--
-- Idempotent : peut etre re-execute sans erreur.
-- =============================================================================

USE [MngConsul];
GO

IF COL_LENGTH('dbo.T050Party', 'StripeAccountId') IS NULL
BEGIN
    ALTER TABLE dbo.T050Party ADD StripeAccountId VARCHAR(50) NULL;
    PRINT 'Colonne StripeAccountId ajoutee a T050Party.';
END
ELSE
    PRINT 'Colonne StripeAccountId existe deja.';
GO

IF COL_LENGTH('dbo.T050Party', 'LastPaymentMethod') IS NULL
BEGIN
    ALTER TABLE dbo.T050Party ADD LastPaymentMethod VARCHAR(20) NULL;
    PRINT 'Colonne LastPaymentMethod ajoutee a T050Party.';
END
ELSE
    PRINT 'Colonne LastPaymentMethod existe deja.';
GO

-- Index pour lookup rapide par StripeAccountId (utilise par webhook handler)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T050Party_StripeAccountId' AND object_id = OBJECT_ID('dbo.T050Party'))
BEGIN
    CREATE INDEX IX_T050Party_StripeAccountId
        ON dbo.T050Party(StripeAccountId)
        WHERE StripeAccountId IS NOT NULL;
    PRINT 'Index IX_T050Party_StripeAccountId cree.';
END
GO
