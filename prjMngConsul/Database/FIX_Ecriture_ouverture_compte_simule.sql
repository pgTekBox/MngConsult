-- =============================================================================
-- FIX — Écriture d'ouverture du compte bancaire simulé (Massothérapie Sérénité)
--
-- Le relevé simulé (s0977, T366) part d'un solde d'ouverture de 18 500,00 $ la
-- veille de son premier mouvement (2026-08-12). Sans écriture d'ouverture aux
-- livres, la conciliation bancaire (T368) garde un écart de 18 500,00 $.
--
-- Écriture validée au journal OD, datée du 2026-08-11 :
--     1010 Banque - Compte chèques        D 18 500,00
--     3100 Apports du propriétaire        C 18 500,00
-- Passée par sp_SaveEcriture (même chemin que le Journal général).
-- Idempotente : ne fait rien si la pièce OUV-RELEVE-SIM existe déjà.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @c UNIQUEIDENTIFIER = 'd2d2d2d2-0000-4000-8000-000000000002';
DECLARE @Date DATE = '2026-08-11';
DECLARE @Montant DECIMAL(15, 2) = 18500.00;

IF EXISTS (SELECT 1 FROM dbo.T135Ecritures WHERE CompanyGUID = @c AND NumeroPiece = 'OUV-RELEVE-SIM')
BEGIN
    PRINT 'Écriture d''ouverture déjà passée.';
    RETURN;
END

DECLARE @Journal INT = (SELECT TOP 1 Id FROM dbo.T130Journaux WHERE CompanyGUID = @c AND Type = 'OD' AND Actif = 1);
DECLARE @Periode INT = (SELECT p.id FROM dbo.T112Periodes p JOIN dbo.T111Exercices ex ON ex.id = p.exercice_id
                        WHERE p.CompanyGUID = @c AND ex.annee = YEAR(@Date) AND p.mois = MONTH(@Date)
                          AND p.statut = 'OUVERTE' AND ex.statut = 'OUVERT');
DECLARE @Banque INT = (SELECT TOP 1 Id FROM dbo.T121PlanComptable WHERE CompanyGUID = @c AND compte = '1010' AND Actif = 1);
DECLARE @Apports INT = (SELECT TOP 1 Id FROM dbo.T121PlanComptable WHERE CompanyGUID = @c AND compte = '3100' AND Actif = 1);

IF @Journal IS NULL OR @Periode IS NULL OR @Banque IS NULL OR @Apports IS NULL
    THROW 51050, 'Journal OD, période d''août 2026 ou comptes 1010/3100 introuvables.', 1;

DECLARE @Lignes dbo.TVP_LigneEcriture;
INSERT INTO @Lignes (Id, PlanComptableId, PartyId, Libelle, MontantDebit, MontantCredit, Ordre, Dirty, Deleted)
VALUES (0, @Banque, NULL, 'Solde d''ouverture du compte bancaire', @Montant, 0, 1, 1, 0),
       (0, @Apports, NULL, 'Solde d''ouverture du compte bancaire', 0, @Montant, 2, 1, 0);

EXEC dbo.sp_SaveEcriture
     @EcritureId = 0, @CompanyGUID = @c, @JournauxId = @Journal, @PeriodeId = @Periode,
     @DateEcriture = @Date, @NumeroPiece = 'OUV-RELEVE-SIM',
     @Libelle = 'Solde d''ouverture - Banque simulée 4821',
     @ToValider = 1, @UserId = NULL, @Lignes = @Lignes;
GO
