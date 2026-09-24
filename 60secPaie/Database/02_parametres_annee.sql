-- =============================================================================
-- 02 — Les taux gouvernementaux d'une année vivent dans la base, pas dans le code
--
-- Jusqu'ici, ParametresAnnee.vb portait les taux de 2026 en dur : ajouter 2027
-- demandait une recompilation. Désormais chaque année est une ligne de
-- paie.ParametresAnnee, éditée dans la console Sec60Admin (Paie › Taux de
-- l'année). Le moteur lit la ligne VALIDÉE de l'année de la date de paie ;
-- à défaut, il retombe sur les valeurs du code (2026), qui restent la
-- référence de secours.
--
--   Statut  B = brouillon : en préparation, le moteur l'ignore ;
--           V = validé    : en vigueur pour les paies de cette année.
--
-- Les tranches d'imposition sont en texte « seuil|taux|constante;… » avec « * »
-- pour la dernière tranche (sans plafond) : lisible, sans dépendance JSON.
-- Ce script se rejoue sans dommage ; il ne touche pas aux lignes existantes
-- sauf pour créer 2026 (validée, valeurs du code) et 2027 (brouillon, copie
-- de 2026, à remplacer par les guides T4127 et TP-1015.F de janvier 2027).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'paie.ParametresAnnee') IS NULL
CREATE TABLE paie.ParametresAnnee (
    Annee                          int            NOT NULL CONSTRAINT PK_ParametresAnnee PRIMARY KEY,
    Statut                         char(1)        NOT NULL CONSTRAINT DF_ParametresAnnee_Statut DEFAULT ('B'),
    Source                         nvarchar(300)  NULL,      -- éditions des guides utilisées
    Note                           nvarchar(max)  NULL,

    -- Impôt fédéral (T4127)
    FedTranches                    nvarchar(400)  NOT NULL,  -- seuil|taux|constante;…;*|taux|constante
    FedMontantPersonnelBase        decimal(12,2)  NOT NULL,
    FedTauxCredits                 decimal(8,5)   NOT NULL,
    FedMontantEmploi               decimal(12,2)  NOT NULL,
    FedAbattementQuebec            decimal(8,5)   NOT NULL,
    FedCreditFondsTravailleursTaux decimal(8,5)   NOT NULL,
    FedCreditFondsTravailleursMax  decimal(12,2)  NOT NULL,
    FedSeuilForfaitaireTauxFixe    decimal(12,2)  NOT NULL,
    FedTauxFixeForfaitaireQuebec   decimal(8,5)   NOT NULL,

    -- Assurance-emploi (taux du Québec)
    AEMaxAssurable                 decimal(12,2)  NOT NULL,
    AETaux                         decimal(8,5)   NOT NULL,
    AEMaxEmploye                   decimal(12,2)  NOT NULL,

    -- Impôt du Québec (TP-1015.F)
    QcTranches                     nvarchar(400)  NOT NULL,
    QcMontantPersonnelBase         decimal(12,2)  NOT NULL,
    QcTauxCredits                  decimal(8,5)   NOT NULL,
    QcDeductionTravailleurTaux     decimal(8,5)   NOT NULL,
    QcDeductionTravailleurMax      decimal(12,2)  NOT NULL,
    QcCreditFondsTravailleursTaux  decimal(8,5)   NOT NULL,
    QcFondsTravailleursMaxAnnuel   decimal(12,2)  NOT NULL,
    QcSeuilForfaitaireTauxFixe     decimal(12,2)  NOT NULL,
    QcTauxFixeForfaitaire          decimal(8,5)   NOT NULL,

    -- RRQ
    RRQMaxGainsAdmissibles         decimal(12,2)  NOT NULL,
    RRQExemption                   decimal(12,2)  NOT NULL,
    RRQTaux                        decimal(8,5)   NOT NULL,
    RRQTauxBase                    decimal(8,5)   NOT NULL,
    RRQMaxEmploye                  decimal(12,2)  NOT NULL,
    RRQMaxBaseEmploye              decimal(12,2)  NOT NULL,
    RRQ2MaxSupplementaire          decimal(12,2)  NOT NULL,
    RRQ2Taux                       decimal(8,5)   NOT NULL,
    RRQ2MaxEmploye                 decimal(12,2)  NOT NULL,

    -- RQAP
    RQAPMaxAssurable               decimal(12,2)  NOT NULL,
    RQAPTauxEmploye                decimal(8,5)   NOT NULL,
    RQAPMaxEmploye                 decimal(12,2)  NOT NULL,
    RQAPTauxEmployeur              decimal(8,5)   NOT NULL,
    RQAPMaxEmployeur               decimal(12,2)  NOT NULL,

    -- FSS (TP-1015.F, partie 5)
    FSSTauxSecteurPublic           decimal(8,4)   NOT NULL,
    FSSMassePlancher               decimal(14,2)  NOT NULL,
    FSSMassePlafond                decimal(14,2)  NOT NULL,
    FSSGeneralConstante            decimal(8,4)   NOT NULL,
    FSSGeneralCoefficient          decimal(8,4)   NOT NULL,
    FSSPrimaireConstante           decimal(8,4)   NOT NULL,
    FSSPrimaireCoefficient         decimal(8,4)   NOT NULL,

    -- CNESST et CNT
    CNESSTMaxAssurable             decimal(12,2)  NOT NULL,
    CNTTaux                        decimal(8,5)   NOT NULL,
    CNTMaxAssujetti                decimal(12,2)  NOT NULL,

    CreeLe                         datetime2(0)   NOT NULL CONSTRAINT DF_ParametresAnnee_CreeLe DEFAULT (sysdatetime()),
    CreePar                        nvarchar(256)  NULL,
    ModifieLe                      datetime2(0)   NULL,
    ModifiePar                     nvarchar(256)  NULL,
    ValideLe                       datetime2(0)   NULL,
    ValidePar                      nvarchar(256)  NULL,
    CONSTRAINT CK_ParametresAnnee_Statut CHECK (Statut IN ('B', 'V')),
    CONSTRAINT CK_ParametresAnnee_Annee  CHECK (Annee BETWEEN 2020 AND 2100)
);
GO

-- ── 2026 : les valeurs du code, validées ─────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = 2026)
INSERT INTO paie.ParametresAnnee (Annee, Statut, Source, Note,
    FedTranches, FedMontantPersonnelBase, FedTauxCredits, FedMontantEmploi, FedAbattementQuebec,
    FedCreditFondsTravailleursTaux, FedCreditFondsTravailleursMax, FedSeuilForfaitaireTauxFixe, FedTauxFixeForfaitaireQuebec,
    AEMaxAssurable, AETaux, AEMaxEmploye,
    QcTranches, QcMontantPersonnelBase, QcTauxCredits, QcDeductionTravailleurTaux, QcDeductionTravailleurMax,
    QcCreditFondsTravailleursTaux, QcFondsTravailleursMaxAnnuel, QcSeuilForfaitaireTauxFixe, QcTauxFixeForfaitaire,
    RRQMaxGainsAdmissibles, RRQExemption, RRQTaux, RRQTauxBase, RRQMaxEmploye, RRQMaxBaseEmploye,
    RRQ2MaxSupplementaire, RRQ2Taux, RRQ2MaxEmploye,
    RQAPMaxAssurable, RQAPTauxEmploye, RQAPMaxEmploye, RQAPTauxEmployeur, RQAPMaxEmployeur,
    FSSTauxSecteurPublic, FSSMassePlancher, FSSMassePlafond, FSSGeneralConstante, FSSGeneralCoefficient,
    FSSPrimaireConstante, FSSPrimaireCoefficient,
    CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti,
    CreePar, ValideLe, ValidePar)
VALUES (2026, 'V', N'T4127 (122e et 123e éditions, ARC) ; TP-1015.F (2026-01, Revenu Québec)',
    N'Valeurs reprises du code (ParametresAnnee.vb). CNESST et CNT : à valider auprès de la CNESST.',
    N'58523|0.14|0;117045|0.205|3804;181440|0.26|10241;258482|0.29|15685;*|0.33|26024',
    16452, 0.14, 1501, 0.165, 0.15, 750, 5000, 0.10,
    68900, 0.013, 895.70,
    N'54345|0.14|0;108680|0.19|2717;132245|0.24|8151;*|0.2575|10465',
    18952, 0.14, 0.06, 1450, 0.15, 5000, 18952, 0.07,
    74600, 3500, 0.063, 0.053, 4479.30, 3768.30, 85000, 0.04, 416,
    103000, 0.0043, 442.90, 0.00602, 620.06,
    4.26, 1000000, 7800000, 1.2662, 0.3838, 0.8074, 0.4426,
    103000, 0.0006, 103000,
    N'système', sysdatetime(), N'système');
GO

-- ── Procédures ──────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE paie.spParametresAnnee_Liste
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.Annee, p.Statut, p.Source, p.CreeLe, p.CreePar, p.ModifieLe, p.ModifiePar, p.ValideLe, p.ValidePar,
           (SELECT COUNT(*) FROM paie.LotPaie l WHERE l.Statut = 'C' AND YEAR(l.DatePaie) = p.Annee) AS NbPaiesConfirmees
      FROM paie.ParametresAnnee p
     ORDER BY p.Annee DESC;
END
GO

CREATE OR ALTER PROCEDURE paie.spParametresAnnee_Get
    @Annee int,
    @SeulementValide bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM paie.ParametresAnnee
     WHERE Annee = @Annee
       AND (@SeulementValide = 0 OR Statut = 'V');
END
GO

-- Copie une année vers une autre, en brouillon : c'est le point de départ de
-- l'année suivante, à corriger ensuite avec les guides.
CREATE OR ALTER PROCEDURE paie.spParametresAnnee_Copier
    @De int, @Vers int, @Par nvarchar(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = @De)
        THROW 51001, 'L''année de départ n''existe pas.', 1;
    IF EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = @Vers)
        THROW 51002, 'Cette année existe déjà.', 1;

    INSERT INTO paie.ParametresAnnee (Annee, Statut, Source, Note,
        FedTranches, FedMontantPersonnelBase, FedTauxCredits, FedMontantEmploi, FedAbattementQuebec,
        FedCreditFondsTravailleursTaux, FedCreditFondsTravailleursMax, FedSeuilForfaitaireTauxFixe, FedTauxFixeForfaitaireQuebec,
        AEMaxAssurable, AETaux, AEMaxEmploye,
        QcTranches, QcMontantPersonnelBase, QcTauxCredits, QcDeductionTravailleurTaux, QcDeductionTravailleurMax,
        QcCreditFondsTravailleursTaux, QcFondsTravailleursMaxAnnuel, QcSeuilForfaitaireTauxFixe, QcTauxFixeForfaitaire,
        RRQMaxGainsAdmissibles, RRQExemption, RRQTaux, RRQTauxBase, RRQMaxEmploye, RRQMaxBaseEmploye,
        RRQ2MaxSupplementaire, RRQ2Taux, RRQ2MaxEmploye,
        RQAPMaxAssurable, RQAPTauxEmploye, RQAPMaxEmploye, RQAPTauxEmployeur, RQAPMaxEmployeur,
        FSSTauxSecteurPublic, FSSMassePlancher, FSSMassePlafond, FSSGeneralConstante, FSSGeneralCoefficient,
        FSSPrimaireConstante, FSSPrimaireCoefficient,
        CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti, CreePar)
    SELECT @Vers, 'B',
           N'À compléter : copie de ' + CAST(@De AS nvarchar(4)) + N' — remplacer par les guides T4127 et TP-1015.F de ' + CAST(@Vers AS nvarchar(4)),
           N'Copie de ' + CAST(@De AS nvarchar(4)) + N' en attente des guides officiels. Chaque valeur est à vérifier avant validation.',
        FedTranches, FedMontantPersonnelBase, FedTauxCredits, FedMontantEmploi, FedAbattementQuebec,
        FedCreditFondsTravailleursTaux, FedCreditFondsTravailleursMax, FedSeuilForfaitaireTauxFixe, FedTauxFixeForfaitaireQuebec,
        AEMaxAssurable, AETaux, AEMaxEmploye,
        QcTranches, QcMontantPersonnelBase, QcTauxCredits, QcDeductionTravailleurTaux, QcDeductionTravailleurMax,
        QcCreditFondsTravailleursTaux, QcFondsTravailleursMaxAnnuel, QcSeuilForfaitaireTauxFixe, QcTauxFixeForfaitaire,
        RRQMaxGainsAdmissibles, RRQExemption, RRQTaux, RRQTauxBase, RRQMaxEmploye, RRQMaxBaseEmploye,
        RRQ2MaxSupplementaire, RRQ2Taux, RRQ2MaxEmploye,
        RQAPMaxAssurable, RQAPTauxEmploye, RQAPMaxEmploye, RQAPTauxEmployeur, RQAPMaxEmployeur,
        FSSTauxSecteurPublic, FSSMassePlancher, FSSMassePlafond, FSSGeneralConstante, FSSGeneralCoefficient,
        FSSPrimaireConstante, FSSPrimaireCoefficient,
        CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti, @Par
      FROM paie.ParametresAnnee WHERE Annee = @De;
END
GO

-- Enregistre toutes les valeurs d'une année. Une année validée reste validée
-- (édition de juillet, par exemple) ; l'horodatage dit qu'elle a bougé.
CREATE OR ALTER PROCEDURE paie.spParametresAnnee_Save
    @Annee int, @Source nvarchar(300), @Note nvarchar(max),
    @FedTranches nvarchar(400), @FedMontantPersonnelBase decimal(12,2), @FedTauxCredits decimal(8,5),
    @FedMontantEmploi decimal(12,2), @FedAbattementQuebec decimal(8,5),
    @FedCreditFondsTravailleursTaux decimal(8,5), @FedCreditFondsTravailleursMax decimal(12,2),
    @FedSeuilForfaitaireTauxFixe decimal(12,2), @FedTauxFixeForfaitaireQuebec decimal(8,5),
    @AEMaxAssurable decimal(12,2), @AETaux decimal(8,5), @AEMaxEmploye decimal(12,2),
    @QcTranches nvarchar(400), @QcMontantPersonnelBase decimal(12,2), @QcTauxCredits decimal(8,5),
    @QcDeductionTravailleurTaux decimal(8,5), @QcDeductionTravailleurMax decimal(12,2),
    @QcCreditFondsTravailleursTaux decimal(8,5), @QcFondsTravailleursMaxAnnuel decimal(12,2),
    @QcSeuilForfaitaireTauxFixe decimal(12,2), @QcTauxFixeForfaitaire decimal(8,5),
    @RRQMaxGainsAdmissibles decimal(12,2), @RRQExemption decimal(12,2), @RRQTaux decimal(8,5), @RRQTauxBase decimal(8,5),
    @RRQMaxEmploye decimal(12,2), @RRQMaxBaseEmploye decimal(12,2),
    @RRQ2MaxSupplementaire decimal(12,2), @RRQ2Taux decimal(8,5), @RRQ2MaxEmploye decimal(12,2),
    @RQAPMaxAssurable decimal(12,2), @RQAPTauxEmploye decimal(8,5), @RQAPMaxEmploye decimal(12,2),
    @RQAPTauxEmployeur decimal(8,5), @RQAPMaxEmployeur decimal(12,2),
    @FSSTauxSecteurPublic decimal(8,4), @FSSMassePlancher decimal(14,2), @FSSMassePlafond decimal(14,2),
    @FSSGeneralConstante decimal(8,4), @FSSGeneralCoefficient decimal(8,4),
    @FSSPrimaireConstante decimal(8,4), @FSSPrimaireCoefficient decimal(8,4),
    @CNESSTMaxAssurable decimal(12,2), @CNTTaux decimal(8,5), @CNTMaxAssujetti decimal(12,2),
    @Par nvarchar(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = @Annee)
        INSERT INTO paie.ParametresAnnee (Annee, Statut,
            FedTranches, FedMontantPersonnelBase, FedTauxCredits, FedMontantEmploi, FedAbattementQuebec,
            FedCreditFondsTravailleursTaux, FedCreditFondsTravailleursMax, FedSeuilForfaitaireTauxFixe, FedTauxFixeForfaitaireQuebec,
            AEMaxAssurable, AETaux, AEMaxEmploye,
            QcTranches, QcMontantPersonnelBase, QcTauxCredits, QcDeductionTravailleurTaux, QcDeductionTravailleurMax,
            QcCreditFondsTravailleursTaux, QcFondsTravailleursMaxAnnuel, QcSeuilForfaitaireTauxFixe, QcTauxFixeForfaitaire,
            RRQMaxGainsAdmissibles, RRQExemption, RRQTaux, RRQTauxBase, RRQMaxEmploye, RRQMaxBaseEmploye,
            RRQ2MaxSupplementaire, RRQ2Taux, RRQ2MaxEmploye,
            RQAPMaxAssurable, RQAPTauxEmploye, RQAPMaxEmploye, RQAPTauxEmployeur, RQAPMaxEmployeur,
            FSSTauxSecteurPublic, FSSMassePlancher, FSSMassePlafond, FSSGeneralConstante, FSSGeneralCoefficient,
            FSSPrimaireConstante, FSSPrimaireCoefficient, CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti, CreePar)
        VALUES (@Annee, 'B',
            @FedTranches, @FedMontantPersonnelBase, @FedTauxCredits, @FedMontantEmploi, @FedAbattementQuebec,
            @FedCreditFondsTravailleursTaux, @FedCreditFondsTravailleursMax, @FedSeuilForfaitaireTauxFixe, @FedTauxFixeForfaitaireQuebec,
            @AEMaxAssurable, @AETaux, @AEMaxEmploye,
            @QcTranches, @QcMontantPersonnelBase, @QcTauxCredits, @QcDeductionTravailleurTaux, @QcDeductionTravailleurMax,
            @QcCreditFondsTravailleursTaux, @QcFondsTravailleursMaxAnnuel, @QcSeuilForfaitaireTauxFixe, @QcTauxFixeForfaitaire,
            @RRQMaxGainsAdmissibles, @RRQExemption, @RRQTaux, @RRQTauxBase, @RRQMaxEmploye, @RRQMaxBaseEmploye,
            @RRQ2MaxSupplementaire, @RRQ2Taux, @RRQ2MaxEmploye,
            @RQAPMaxAssurable, @RQAPTauxEmploye, @RQAPMaxEmploye, @RQAPTauxEmployeur, @RQAPMaxEmployeur,
            @FSSTauxSecteurPublic, @FSSMassePlancher, @FSSMassePlafond, @FSSGeneralConstante, @FSSGeneralCoefficient,
            @FSSPrimaireConstante, @FSSPrimaireCoefficient, @CNESSTMaxAssurable, @CNTTaux, @CNTMaxAssujetti, @Par);

    UPDATE paie.ParametresAnnee SET
        Source = @Source, Note = @Note,
        FedTranches = @FedTranches, FedMontantPersonnelBase = @FedMontantPersonnelBase, FedTauxCredits = @FedTauxCredits,
        FedMontantEmploi = @FedMontantEmploi, FedAbattementQuebec = @FedAbattementQuebec,
        FedCreditFondsTravailleursTaux = @FedCreditFondsTravailleursTaux, FedCreditFondsTravailleursMax = @FedCreditFondsTravailleursMax,
        FedSeuilForfaitaireTauxFixe = @FedSeuilForfaitaireTauxFixe, FedTauxFixeForfaitaireQuebec = @FedTauxFixeForfaitaireQuebec,
        AEMaxAssurable = @AEMaxAssurable, AETaux = @AETaux, AEMaxEmploye = @AEMaxEmploye,
        QcTranches = @QcTranches, QcMontantPersonnelBase = @QcMontantPersonnelBase, QcTauxCredits = @QcTauxCredits,
        QcDeductionTravailleurTaux = @QcDeductionTravailleurTaux, QcDeductionTravailleurMax = @QcDeductionTravailleurMax,
        QcCreditFondsTravailleursTaux = @QcCreditFondsTravailleursTaux, QcFondsTravailleursMaxAnnuel = @QcFondsTravailleursMaxAnnuel,
        QcSeuilForfaitaireTauxFixe = @QcSeuilForfaitaireTauxFixe, QcTauxFixeForfaitaire = @QcTauxFixeForfaitaire,
        RRQMaxGainsAdmissibles = @RRQMaxGainsAdmissibles, RRQExemption = @RRQExemption, RRQTaux = @RRQTaux, RRQTauxBase = @RRQTauxBase,
        RRQMaxEmploye = @RRQMaxEmploye, RRQMaxBaseEmploye = @RRQMaxBaseEmploye,
        RRQ2MaxSupplementaire = @RRQ2MaxSupplementaire, RRQ2Taux = @RRQ2Taux, RRQ2MaxEmploye = @RRQ2MaxEmploye,
        RQAPMaxAssurable = @RQAPMaxAssurable, RQAPTauxEmploye = @RQAPTauxEmploye, RQAPMaxEmploye = @RQAPMaxEmploye,
        RQAPTauxEmployeur = @RQAPTauxEmployeur, RQAPMaxEmployeur = @RQAPMaxEmployeur,
        FSSTauxSecteurPublic = @FSSTauxSecteurPublic, FSSMassePlancher = @FSSMassePlancher, FSSMassePlafond = @FSSMassePlafond,
        FSSGeneralConstante = @FSSGeneralConstante, FSSGeneralCoefficient = @FSSGeneralCoefficient,
        FSSPrimaireConstante = @FSSPrimaireConstante, FSSPrimaireCoefficient = @FSSPrimaireCoefficient,
        CNESSTMaxAssurable = @CNESSTMaxAssurable, CNTTaux = @CNTTaux, CNTMaxAssujetti = @CNTMaxAssujetti,
        ModifieLe = sysdatetime(), ModifiePar = @Par
     WHERE Annee = @Annee;
END
GO

CREATE OR ALTER PROCEDURE paie.spParametresAnnee_Valider
    @Annee int, @Par nvarchar(256) = NULL, @Valide bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = @Annee)
        THROW 51003, 'Cette année n''existe pas.', 1;
    -- Retirer la validation d'une année qui a déjà des paies confirmées la
    -- rendrait incalculable : on refuse.
    IF @Valide = 0 AND EXISTS (SELECT 1 FROM paie.LotPaie WHERE Statut = 'C' AND YEAR(DatePaie) = @Annee)
        THROW 51004, 'Des paies confirmées utilisent déjà cette année : sa validation ne peut pas être retirée.', 1;

    UPDATE paie.ParametresAnnee
       SET Statut = CASE WHEN @Valide = 1 THEN 'V' ELSE 'B' END,
           ValideLe = CASE WHEN @Valide = 1 THEN sysdatetime() ELSE NULL END,
           ValidePar = CASE WHEN @Valide = 1 THEN @Par ELSE NULL END
     WHERE Annee = @Annee;
END
GO

CREATE OR ALTER PROCEDURE paie.spParametresAnnee_Supprimer
    @Annee int
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = @Annee AND Statut = 'V')
        THROW 51005, 'Une année validée ne se supprime pas : retirez d''abord sa validation.', 1;
    DELETE FROM paie.ParametresAnnee WHERE Annee = @Annee;
END
GO

-- ── 2027 : le terrain est préparé, en brouillon ─────────────────────────────
IF NOT EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = 2027)
    EXEC paie.spParametresAnnee_Copier @De = 2026, @Vers = 2027, @Par = N'système';
GO

PRINT N'02_parametres_annee.sql : terminé.';
