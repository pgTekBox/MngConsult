-- =============================================================================
-- T401 — Soldes d'ouverture de la reprise (Importation 2, carte 3)
--
-- La balance de vérification en préparation (staging.BalanceVerification)
-- devient UNE écriture d'ouverture, au journal OD, datée de la date de
-- bascule (la veille du premier jour tenu dans 60secondes).
--
-- Chaque ligne de la balance retrouve son compte du plan exactement comme le
-- contrôle s0771 : par numéro, sinon par nom, dans staging.ImportPlanComptable.
-- Le compte de 60secondes est celui de la décision de correspondance
-- (staging.CorrespondanceCompte.PlanComptableId : LIER, ou CREER une fois le
-- compte créé par s0767). Plusieurs lignes qui aboutissent au même compte sont
-- additionnées ; un solde net nul ne fait pas de ligne.
--
-- L'écriture est passée EN BROUILLON par sp_SaveEcriture (même chemin que le
-- Journal général) : rien n'entre au grand livre avant qu'on la valide.
-- Pièce OUV-REPRISE : une seule par compagnie. Tant qu'elle existe, rien
-- n'est recréé ; pour recommencer, supprimer le brouillon au journal.
--
--   s1025SoldesOuverture @CompanyGUID, @DateBascule, @UserId, @Creer
--     @Creer = 0 : vérifie seulement (état de la carte)
--     @Creer = 1 : crée l'écriture si rien ne bloque
--
--   Jeux rendus (à la création, sp_SaveEcriture en rend un premier) :
--   avant-dernier : les lignes qui bloquent — Compte, Nom, Montant, Motif
--   dernier       : Statut, Message, EcritureId, NumeroPiece, EcritureStatut,
--                   NbLignes, NbBloquees, TotalDebit, TotalCredit
--     Statut : VIDE | BLOQUE | PRET | CREE | EXISTE
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1025SoldesOuverture]
    @CompanyGUID UNIQUEIDENTIFIER,
    @DateBascule DATE = NULL,
    @UserId      INT  = NULL,
    @Creer       BIT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Piece VARCHAR(50) = 'OUV-REPRISE';
    DECLARE @Resultat TABLE (
        Statut VARCHAR(10), Message NVARCHAR(600), EcritureId INT, NumeroPiece VARCHAR(50),
        EcritureStatut VARCHAR(15), NbLignes INT, NbBloquees INT, TotalDebit DECIMAL(18,2), TotalCredit DECIMAL(18,2));
    DECLARE @Bloque TABLE (Compte VARCHAR(20), Nom NVARCHAR(400), Montant DECIMAL(18,2), Motif NVARCHAR(300));

    -- ── Déjà passée ? ───────────────────────────────────────────────────────
    DECLARE @ExId INT, @ExStatut VARCHAR(15);
    SELECT TOP 1 @ExId = e.[Id], @ExStatut = e.[Statut]
      FROM dbo.T135Ecritures e
     WHERE e.[CompanyGUID] = @CompanyGUID AND e.[NumeroPiece] = @Piece AND e.[Statut] <> 'EXTOURNEE'
     ORDER BY e.[Id] DESC;

    -- ── Le plan en préparation et la balance ───────────────────────────────
    DECLARE @Systeme VARCHAR(20);
    SELECT TOP 1 @Systeme = p.[SystemeSource]
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID
     ORDER BY p.[Id] DESC;

    DECLARE @plan TABLE (CleSource NVARCHAR(400), Compte VARCHAR(20), NomCle NVARCHAR(400));
    INSERT INTO @plan
    SELECT p.[CleSource], p.[Compte], UPPER(LTRIM(RTRIM(ISNULL(p.[Nom], ''))))
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID AND p.[Statut] IN ('OK', 'EXISTE');

    DECLARE @bal TABLE (Id INT, Compte VARCHAR(20), Nom NVARCHAR(400), NomCle NVARCHAR(400), Net DECIMAL(18,2),
                        CleSource NVARCHAR(400), PlanComptableId INT, Action VARCHAR(10));
    INSERT INTO @bal (Id, Compte, Nom, NomCle, Net)
    SELECT b.[Id], b.[Compte], b.[Description], UPPER(LTRIM(RTRIM(ISNULL(b.[Description], '')))),
           ISNULL(b.[Debit], 0) - ISNULL(b.[Credit], 0)
      FROM staging.BalanceVerification b
     WHERE b.[CompanyGUID] = @CompanyGUID;

    IF NOT EXISTS (SELECT 1 FROM @bal)
    BEGIN
        INSERT INTO @Resultat VALUES ('VIDE', N'Aucune balance de vérification en préparation.', @ExId, CASE WHEN @ExId IS NULL THEN NULL ELSE @Piece END, @ExStatut, 0, 0, 0, 0);
        GOTO Fin;
    END

    -- Même rapprochement que s0771 : numéro d'abord, sinon nom.
    UPDATE b SET b.CleSource = m.CleSource
      FROM @bal b
     OUTER APPLY (SELECT TOP 1 pl.CleSource FROM @plan pl
                   WHERE (b.Compte IS NOT NULL AND pl.Compte IS NOT NULL AND pl.Compte = b.Compte)
                      OR (b.NomCle <> '' AND pl.NomCle = b.NomCle)
                   ORDER BY CASE WHEN b.Compte IS NOT NULL AND pl.Compte = b.Compte THEN 0 ELSE 1 END) m;

    UPDATE b SET b.PlanComptableId = c.[PlanComptableId], b.Action = c.[Action]
      FROM @bal b
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID AND c.[SystemeSource] = @Systeme AND c.[CleSource] = b.CleSource;

    -- ── Ce qui empêche l'écriture (seulement les lignes qui portent un solde) ─
    INSERT INTO @Bloque (Compte, Nom, Montant, Motif)
    SELECT b.Compte, b.Nom, b.Net,
           CASE WHEN b.CleSource IS NULL       THEN N'Absent du plan comptable importé.'
                WHEN b.Action IS NULL          THEN N'Compte à décider : associez-le à un compte de 60secondes.'
                WHEN b.Action = 'IGNORER'      THEN N'Marqué « Ignorer », mais porte un solde.'
                WHEN b.Action = 'CREER'        THEN N'Marqué « Créer », mais pas encore créé au plan.'
                ELSE N'Compte de 60secondes introuvable.' END
      FROM @bal b
     WHERE b.Net <> 0
       AND (b.PlanComptableId IS NULL
            OR NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable pc
                            WHERE pc.[Id] = b.PlanComptableId AND pc.[CompanyGUID] = @CompanyGUID));

    -- ── Les lignes de l'écriture : un solde net par compte de 60secondes ────
    DECLARE @Lignes dbo.TVP_LigneEcriture;
    INSERT INTO @Lignes (Id, PlanComptableId, PartyId, Libelle, MontantDebit, MontantCredit, Ordre, Dirty, Deleted)
    SELECT 0, x.PlanComptableId, NULL, 'Solde d''ouverture - reprise',
           CASE WHEN x.Net > 0 THEN x.Net ELSE 0 END,
           CASE WHEN x.Net < 0 THEN -x.Net ELSE 0 END,
           ROW_NUMBER() OVER (ORDER BY pc.[Compte]), 1, 0
      FROM (SELECT b.PlanComptableId, SUM(b.Net) AS Net
              FROM @bal b
             WHERE b.PlanComptableId IS NOT NULL
             GROUP BY b.PlanComptableId) x
      JOIN dbo.T121PlanComptable pc ON pc.[Id] = x.PlanComptableId AND pc.[CompanyGUID] = @CompanyGUID
     WHERE x.Net <> 0;

    DECLARE @NbLignes INT = (SELECT COUNT(*) FROM @Lignes);
    DECLARE @NbBloquees INT = (SELECT COUNT(*) FROM @Bloque);
    DECLARE @TD DECIMAL(18,2) = (SELECT ISNULL(SUM(MontantDebit), 0) FROM @Lignes);
    DECLARE @TC DECIMAL(18,2) = (SELECT ISNULL(SUM(MontantCredit), 0) FROM @Lignes);

    IF @ExId IS NOT NULL
    BEGIN
        INSERT INTO @Resultat VALUES ('EXISTE',
            N'L''écriture d''ouverture ' + @Piece + N' existe déjà (' + LOWER(@ExStatut) + N'). Pour la refaire, supprimez le brouillon au Journal général.',
            @ExId, @Piece, @ExStatut, @NbLignes, @NbBloquees, @TD, @TC);
        GOTO Fin;
    END

    IF @NbBloquees > 0
    BEGIN
        INSERT INTO @Resultat VALUES ('BLOQUE',
            CAST(@NbBloquees AS NVARCHAR(10)) + N' ligne(s) de la balance n''ont pas encore de compte dans 60secondes.',
            NULL, NULL, NULL, @NbLignes, @NbBloquees, @TD, @TC);
        GOTO Fin;
    END

    IF ABS(@TD - @TC) > 0.005 OR @TD = 0
    BEGIN
        INSERT INTO @Resultat VALUES ('BLOQUE',
            N'La balance ne s''équilibre pas : débit ' + FORMAT(@TD, 'N2', 'fr-CA') + N' $, crédit ' + FORMAT(@TC, 'N2', 'fr-CA') + N' $.',
            NULL, NULL, NULL, @NbLignes, 0, @TD, @TC);
        GOTO Fin;
    END

    IF @DateBascule IS NULL
    BEGIN
        INSERT INTO @Resultat VALUES ('BLOQUE', N'Indiquez la date de bascule (étape 2) : l''écriture d''ouverture est datée de ce jour-là.',
            NULL, NULL, NULL, @NbLignes, 0, @TD, @TC);
        GOTO Fin;
    END

    -- ── Journal OD et période ouverte de la date de bascule ────────────────
    DECLARE @Journal INT = (SELECT TOP 1 [Id] FROM dbo.T130Journaux
                             WHERE [CompanyGUID] = @CompanyGUID AND [Type] = 'OD' AND [Actif] = 1 ORDER BY [Id]);
    DECLARE @Periode INT = (SELECT TOP 1 p.[id] FROM dbo.T112Periodes p
                              JOIN dbo.T111Exercices ex ON ex.[id] = p.[exercice_id]
                             WHERE p.[CompanyGUID] = @CompanyGUID
                               AND @DateBascule BETWEEN ex.[date_debut] AND ex.[date_fin]
                               AND p.[mois] = MONTH(@DateBascule)
                               AND p.[statut] = 'OUVERTE' AND ex.[statut] = 'OUVERT');

    IF @Journal IS NULL
    BEGIN
        INSERT INTO @Resultat VALUES ('BLOQUE', N'Aucun journal des opérations diverses (OD) actif.', NULL, NULL, NULL, @NbLignes, 0, @TD, @TC);
        GOTO Fin;
    END
    IF @Periode IS NULL
    BEGIN
        INSERT INTO @Resultat VALUES ('BLOQUE',
            N'Aucune période ouverte au ' + CONVERT(NVARCHAR(10), @DateBascule, 23) + N' : ouvrez l''exercice qui contient la date de bascule.',
            NULL, NULL, NULL, @NbLignes, 0, @TD, @TC);
        GOTO Fin;
    END

    IF @Creer = 0
    BEGIN
        INSERT INTO @Resultat VALUES ('PRET',
            CAST(@NbLignes AS NVARCHAR(10)) + N' comptes, ' + FORMAT(@TD, 'N2', 'fr-CA') + N' $ au débit et au crédit, au ' + CONVERT(NVARCHAR(10), @DateBascule, 23) + N'.',
            NULL, NULL, NULL, @NbLignes, 0, @TD, @TC);
        GOTO Fin;
    END

    -- ── Création, en brouillon ─────────────────────────────────────────────
    EXEC dbo.sp_SaveEcriture
         @EcritureId = 0, @CompanyGUID = @CompanyGUID, @JournauxId = @Journal, @PeriodeId = @Periode,
         @DateEcriture = @DateBascule, @NumeroPiece = @Piece,
         @Libelle = 'Soldes d''ouverture - reprise de la balance de vérification',
         @ToValider = 0, @UserId = @UserId, @Lignes = @Lignes;

    SELECT TOP 1 @ExId = [Id], @ExStatut = [Statut]
      FROM dbo.T135Ecritures
     WHERE [CompanyGUID] = @CompanyGUID AND [NumeroPiece] = @Piece
     ORDER BY [Id] DESC;

    IF @ExId IS NULL
        THROW 51060, N'L''écriture d''ouverture n''a pas été enregistrée.', 1;

    INSERT INTO @Resultat VALUES ('CREE',
        N'Écriture d''ouverture ' + @Piece + N' créée en brouillon au journal OD : ' + CAST(@NbLignes AS NVARCHAR(10)) +
        N' comptes, ' + FORMAT(@TD, 'N2', 'fr-CA') + N' $. Validez-la au Journal général pour la passer au grand livre.',
        @ExId, @Piece, @ExStatut, @NbLignes, 0, @TD, @TC);

Fin:
    SELECT Compte, Nom, Montant, Motif FROM @Bloque ORDER BY ABS(Montant) DESC;
    SELECT Statut, Message, EcritureId, NumeroPiece, EcritureStatut, NbLignes, NbBloquees, TotalDebit, TotalCredit FROM @Resultat;
END
GO
