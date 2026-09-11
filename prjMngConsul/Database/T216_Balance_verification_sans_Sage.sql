-- =============================================================================
-- T216 — La balance de verification n'appartient plus a Sage
--
-- La table de preparation portait le nom du premier logiciel pris en charge :
-- staging.SageBalanceVerification, avec des colonnes SageCompte, SageDebit...
-- Or la reprise s'applique desormais a QuickBooks, Sage 50 ou Acomba : un nom
-- lie a un seul logiciel ment des qu'on en importe un autre.
--
--   staging.SageBalanceVerification  ->  staging.BalanceVerification
--   SageCompte       ->  Compte
--   SageDescription  ->  Description
--   SageDebit        ->  Debit
--   SageCredit       ->  Credit
--
-- Aucune procedure, vue ni fonction ne la reference (verifie dans
-- sys.sql_modules) ; seul l'ecran ImportBalanceVerification l'utilise.
--
-- Rejouable : chaque renommage n'a lieu que si l'ancien nom existe encore.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.SageBalanceVerification', 'U') IS NOT NULL
   AND OBJECT_ID('staging.BalanceVerification', 'U') IS NULL
    EXEC sp_rename 'staging.SageBalanceVerification', 'BalanceVerification';
GO

IF COL_LENGTH('staging.BalanceVerification', 'SageCompte') IS NOT NULL
    EXEC sp_rename 'staging.BalanceVerification.SageCompte', 'Compte', 'COLUMN';
GO
IF COL_LENGTH('staging.BalanceVerification', 'SageDescription') IS NOT NULL
    EXEC sp_rename 'staging.BalanceVerification.SageDescription', 'Description', 'COLUMN';
GO
IF COL_LENGTH('staging.BalanceVerification', 'SageDebit') IS NOT NULL
    EXEC sp_rename 'staging.BalanceVerification.SageDebit', 'Debit', 'COLUMN';
GO
IF COL_LENGTH('staging.BalanceVerification', 'SageCredit') IS NOT NULL
    EXEC sp_rename 'staging.BalanceVerification.SageCredit', 'Credit', 'COLUMN';
GO

PRINT 'T216_Balance_verification_sans_Sage.sql : termine.';
GO
