-- =============================================================================
-- T217 — L'importation de la balance de verification passe par une procedure
--
-- L'ecran ecrivait jusqu'ici par un INSERT construit dans la page, ligne par
-- ligne. Il lit desormais la balance lui-meme -- titres, comptes sans numero,
-- montants au format americain, ligne TOTAL -- et confie l'ecriture a cette
-- procedure, en un seul appel, comme les autres ecrans de la reprise.
--
-- @Lignes : [{ "Compte": "1000" | null, "Description": "Chequing",
--              "Debit": 21095.57, "Credit": 0 }]
-- @Vider  : 1 pour vider la table avant d'ecrire (la case « Vider la table
--           avant l'import » de l'ecran).
--
-- La table staging.BalanceVerification n'a pas de colonne de compagnie : elle
-- est commune a toutes. Vider efface donc aussi ce que d'autres y ont mis.
-- C'est le comportement d'origine de l'ecran, conserve tel quel ; le corriger
-- demande d'ajouter la compagnie a la table.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0768ImporterBalanceVerification]
    @Lignes NVARCHAR(MAX),
    @Vider  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF @Vider = 1
        DELETE FROM staging.BalanceVerification;

    INSERT INTO staging.BalanceVerification ([Compte], [Description], [Debit], [Credit])
    SELECT NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
           NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Description, ''))), 200), ''),
           ISNULL(j.Debit, 0),
           ISNULL(j.Credit, 0)
      FROM OPENJSON(@Lignes)
           WITH (
              Compte      NVARCHAR(50)  '$.Compte',
              Description NVARCHAR(400) '$.Description',
              Debit       DECIMAL(18,2) '$.Debit',
              Credit      DECIMAL(18,2) '$.Credit'
           ) j;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS Inserees;
END
GO

PRINT 'T217_Importer_balance_verification.sql : termine.';
GO
