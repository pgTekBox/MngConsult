-- =============================================================================
-- T010Company : ajoute PlaidAutoImport (interrupteur par compagnie de l'import
-- automatique des transactions Plaid via webhook / synchro quotidienne).
-- Meme patron que les colonnes d'integration Square/Stripe sur T010Company.
-- Defaut = 1 (activé) : la fonctionnalité est active, chaque compagnie peut se
-- désactiver depuis « Processeur de paiement ». Idempotent.
-- =============================================================================
USE [MngConsul];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.T010Company') AND name = 'PlaidAutoImport')
BEGIN
    ALTER TABLE dbo.T010Company
        ADD PlaidAutoImport BIT NOT NULL
            CONSTRAINT DF_T010Company_PlaidAutoImport DEFAULT (1);
    PRINT 'Colonne T010Company.PlaidAutoImport ajoutee (defaut 1).';
END
ELSE
    PRINT 'Colonne T010Company.PlaidAutoImport existe deja.';
GO
