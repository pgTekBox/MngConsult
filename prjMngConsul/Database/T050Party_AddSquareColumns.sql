-- =============================================================================
-- T050Party_AddSquareColumns
-- Ajoute les colonnes de synchronisation Square (Customers API) sur T050Party.
-- Ne concernent que les CLIENTS (Type IN (1,3)) ; les fournisseurs gardent
-- leurs colonnes Stripe. Meme approche que T075Products pour le catalogue.
--
--   SquareCustomerId      VARCHAR(100) : id du client cote Square (customer_xxx)
--   SquareCustomerVersion BIGINT       : version (concurrence optimiste pour PUT)
--   SquareSyncStatus      VARCHAR(20)  : 'OK' | 'ERROR' | ...
--   SquareSyncDate        DATETIME     : date de la derniere synchro
--
-- Idempotent : peut etre re-execute sans erreur.
-- =============================================================================

USE [MngConsul];
GO

IF COL_LENGTH('dbo.T050Party', 'SquareCustomerId') IS NULL
BEGIN
    ALTER TABLE dbo.T050Party ADD SquareCustomerId VARCHAR(100) NULL;
    PRINT 'Colonne SquareCustomerId ajoutee a T050Party.';
END
ELSE
    PRINT 'Colonne SquareCustomerId existe deja.';
GO

IF COL_LENGTH('dbo.T050Party', 'SquareCustomerVersion') IS NULL
BEGIN
    ALTER TABLE dbo.T050Party ADD SquareCustomerVersion BIGINT NULL;
    PRINT 'Colonne SquareCustomerVersion ajoutee a T050Party.';
END
ELSE
    PRINT 'Colonne SquareCustomerVersion existe deja.';
GO

IF COL_LENGTH('dbo.T050Party', 'SquareSyncStatus') IS NULL
BEGIN
    ALTER TABLE dbo.T050Party ADD SquareSyncStatus VARCHAR(20) NULL;
    PRINT 'Colonne SquareSyncStatus ajoutee a T050Party.';
END
ELSE
    PRINT 'Colonne SquareSyncStatus existe deja.';
GO

IF COL_LENGTH('dbo.T050Party', 'SquareSyncDate') IS NULL
BEGIN
    ALTER TABLE dbo.T050Party ADD SquareSyncDate DATETIME NULL;
    PRINT 'Colonne SquareSyncDate ajoutee a T050Party.';
END
ELSE
    PRINT 'Colonne SquareSyncDate existe deja.';
GO
