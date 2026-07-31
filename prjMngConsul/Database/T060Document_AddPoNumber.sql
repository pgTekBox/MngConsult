-- =============================================================================
-- T060Document : ajoute la colonne PoNumber (numero de bon de commande) pour les
-- factures FOURNISSEUR. Avant, l'ecran renvoyait la constante 123 (champ factice).
-- Idempotent.
-- =============================================================================
USE [MngConsul];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.T060Document') AND name = 'PoNumber')
BEGIN
    ALTER TABLE dbo.T060Document ADD PoNumber VARCHAR(50) NULL;
    PRINT 'Colonne T060Document.PoNumber ajoutee.';
END
ELSE
    PRINT 'Colonne T060Document.PoNumber existe deja.';
GO
