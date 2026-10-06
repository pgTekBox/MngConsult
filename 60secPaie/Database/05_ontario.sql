-- =============================================================================
-- 05 — Paie de l'Ontario
--
-- Jusqu'ici 60secPaie ne calculait que la paie du Québec. La province d'emploi est
-- désormais celle de la compagnie (paie.Compagnie.Province, « QC » ou « ON ») et
-- elle est figée sur chaque paie (paie.Paie.Province) : une compagnie qui change
-- de province garde un historique juste.
--
-- AUCUNE COLONNE DE MONTANT N'EST AJOUTÉE. Les colonnes gardent leur nom québécois
-- et leur contenu suit la province de la paie :
--
--     colonne de paie.Paie          Québec (QC)              Ontario (ON)
--     ---------------------------   ----------------------   ---------------------------------------
--     ImpotQuebec                   impôt du Québec          impôt de l'Ontario (surtaxe et
--                                                            contribution-santé comprises)
--     RRQ, RRQ2, GainsRRQ           RRQ                      RPC (Régime de pensions du Canada)
--     EmployeurRRQ, EmployeurRRQ2   RRQ, part employeur      RPC, part employeur
--     EmployeurFSS, GainsFSS        FSS                      impôt-santé des employeurs (ISE)
--     EmployeurCNESST, GainsCNESST  CNESST                   WSIB (CSPAAT)
--     RQAP, EmployeurRQAP           RQAP                     toujours 0
--     EmployeurCNT                  normes du travail        toujours 0
--
-- Il en va de même de paie.CumulatifDepart (soldes de départ, qui reçoivent eux aussi une
-- colonne Province) et des exemptions de
-- paie.EmployePaie (ExemptImpotQuebec = impôt provincial, ExemptRRQ = RRQ ou RPC,
-- ExemptFSS = FSS ou ISE, ExemptCNESST = CNESST ou WSIB).
--
-- Remises : en Ontario tout va au Receveur général (impôt fédéral, impôt de
-- l'Ontario, RPC, AE) ; il n'y a pas de remise à Revenu Québec. L'ISE et la WSIB
-- se paient à part : 60secPaie les calcule et les affiche, sans en faire une remise.
--
-- Les taux de l'Ontario (T4127) s'ajoutent à paie.ParametresAnnee, en colonnes
-- NULLables : une année saisie avant ce script reste valide pour le Québec, et
-- le moteur refuse de calculer l'Ontario tant que ses taux ne sont pas là.
--
-- Ce script se rejoue sans dommage. Il s'exécute après 01 à 04 (il redéfinit la
-- vue paie.Employe de 03 et les procédures Copier et Save de 02).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── La province de chaque paie ──────────────────────────────────────────────
-- Les paies existantes sont toutes du Québec : c'est la valeur par défaut.
IF COL_LENGTH('paie.Paie', 'Province') IS NULL
    ALTER TABLE paie.Paie ADD Province nchar(2) NOT NULL CONSTRAINT DF_Paie_Province DEFAULT (N'QC');
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Paie_Province' AND parent_object_id = OBJECT_ID(N'paie.Paie'))
    ALTER TABLE paie.Paie ADD CONSTRAINT CK_Paie_Province CHECK (Province IN (N'QC', N'ON'));
GO

-- Les cumulatifs de départ appartiennent eux aussi à une province : celle de la compagnie
-- au moment de leur saisie. Elle dit dans quelles cases du T4 ils vont (RRQ ou RPC) et à quel
-- plafond d'accidents du travail ils comptent (CNESST ou WSIB).
IF COL_LENGTH('paie.CumulatifDepart', 'Province') IS NULL
    ALTER TABLE paie.CumulatifDepart ADD Province nchar(2) NOT NULL CONSTRAINT DF_CumulatifDepart_Province DEFAULT (N'QC');
GO

-- ── La compagnie ────────────────────────────────────────────────────────────
-- paie.Compagnie.Province existe depuis le début (« QC » par défaut) : elle devient
-- la province d'emploi. Une valeur qui n'est pas le code d'une province ou d'un territoire y est ramenée
-- à QC. (Les treize codes, et non seulement QC et ON : ce script se rejoue après 06_provinces.sql, et une
-- compagnie de l'Alberta ne doit pas redevenir québécoise.)
UPDATE paie.Compagnie SET Province = N'QC'
 WHERE Province IS NULL OR Province NOT IN (N'QC', N'ON', N'AB', N'BC', N'MB', N'NB', N'NL', N'NS', N'NT', N'NU', N'PE', N'SK', N'YT');
GO

-- Ontario : l'employeur admissible retranche l'exemption de l'impôt-santé des
-- employeurs (secteur privé, masse salariale ontarienne sous le seuil).
IF COL_LENGTH('paie.Compagnie', 'ISEExemptionAdmissible') IS NULL
    ALTER TABLE paie.Compagnie ADD ISEExemptionAdmissible bit NOT NULL CONSTRAINT DF_Compagnie_ISEExemption DEFAULT (1);
GO

-- ── L'employé : formulaire TD1ON ────────────────────────────────────────────
IF COL_LENGTH('paie.EmployePaie', 'TD1ONMontantDemande') IS NULL
    ALTER TABLE paie.EmployePaie ADD
        TD1ONMontantDemande   decimal(12,2) NULL,      -- NULL = montant personnel de base de l'Ontario
        TD1ONAutresCredits    decimal(12,2) NOT NULL CONSTRAINT DF_EmployePaie_TD1ONK3P DEFAULT (0),
        TD1ONPersonnesACharge tinyint       NOT NULL CONSTRAINT DF_EmployePaie_TD1ONY DEFAULT (0);  -- réduction d'impôt de l'Ontario (facteur Y)
GO

-- La vue des employés porte le TD1ON. C'est la définition de 03_unites_cnesst.sql
-- plus ces trois colonnes : toute retouche de la vue se fait désormais ICI.
CREATE OR ALTER VIEW paie.Employe AS
SELECT
    t.Id,
    c.Id                                   AS CompagnieId,
    CAST(ISNULL(t.Active, 1) AS bit)       AS Actif,
    CAST(CASE WHEN ep.EmployeId IS NULL THEN 0 ELSE 1 END AS bit) AS PaieConfiguree,
    t.EmployeeNumber                       AS Code,
    ISNULL(t.FirstName, N'')               AS Prenom,
    ISNULL(t.LastName, N'')                AS Nom,
    t.Address1                             AS Adresse1,
    t.Address2                             AS Adresse2,
    t.City                                 AS Ville,
    CAST(CASE s.Name WHEN 'Quebec' THEN N'QC' WHEN 'Ontario' THEN N'ON' WHEN 'Alberta' THEN N'AB' WHEN 'British Columbia' THEN N'BC'
              WHEN 'Manitoba' THEN N'MB' WHEN 'New Brunswick' THEN N'NB' WHEN 'Nova Scotia' THEN N'NS' WHEN 'Saskatchewan' THEN N'SK'
              WHEN 'Prince Edward Island' THEN N'PE' WHEN 'Newfoundland and Labrador' THEN N'NL'
              WHEN 'Northwest Territories' THEN N'NT' WHEN 'Nunavut' THEN N'NU' WHEN 'Yukon' THEN N'YT' ELSE N'QC' END AS nchar(2)) AS Province,
    t.PostalCode                           AS CodePostal,
    t.Email                                AS Courriel,
    COALESCE(NULLIF(t.Phone, ''), t.Mobile) AS Telephone,
    COALESCE(ep.DateNaissance, t.DateOfBirth) AS DateNaissance,
    ISNULL(ep.Langue, N'FR')               AS Langue,
    ep.NASChiffre,
    t.SIN                                  AS NASMngConsul,
    t.JobTitle                             AS Poste,
    t.HireDate                             AS DateEmbauche,
    t.TerminationDate                      AS DateFinEmploi,
    COALESCE(ep.PeriodesParAnnee, CASE t.PayFrequency WHEN 'Weekly' THEN 52 WHEN 'BiWeekly' THEN 26 WHEN 'SemiMonthly' THEN 24 WHEN 'Monthly' THEN 12 WHEN 'Annually' THEN 1 WHEN 'Yearly' THEN 1 END) AS PeriodesParAnnee,
    ep.HeuresSemaine,
    COALESCE(ep.TauxHoraire, NULLIF(t.HourlyRate, 0))     AS TauxHoraire,
    COALESCE(ep.SalaireAnnuel, NULLIF(t.AnnualSalary, 0)) AS SalaireAnnuel,
    ep.TauxVacances,
    ISNULL(ep.ExemptImpotFederal, 0) AS ExemptImpotFederal, ISNULL(ep.ExemptImpotQuebec, 0) AS ExemptImpotQuebec,
    ISNULL(ep.ExemptRRQ, 0) AS ExemptRRQ, ISNULL(ep.ExemptRQAP, 0) AS ExemptRQAP, ISNULL(ep.ExemptAE, 0) AS ExemptAE,
    ISNULL(ep.ExemptFSS, 0) AS ExemptFSS, ISNULL(ep.ExemptCNESST, 0) AS ExemptCNESST,
    ep.TD1MontantDemande, ISNULL(ep.TD1ImpotAdditionnel, 0) AS TD1ImpotAdditionnel, ISNULL(ep.TD1DeductionZone, 0) AS TD1DeductionZone,
    ISNULL(ep.TD1DeductionsAnnuelles, 0) AS TD1DeductionsAnnuelles, ISNULL(ep.TD1AutresCredits, 0) AS TD1AutresCredits,
    ISNULL(ep.CodeDentaireT4, 1) AS CodeDentaireT4,
    ep.TP1015Montant, ISNULL(ep.TP1015ImpotAdditionnel, 0) AS TP1015ImpotAdditionnel, ISNULL(ep.TP1015DeductionsLigne19, 0) AS TP1015DeductionsLigne19,
    ISNULL(ep.TP1016Deductions, 0) AS TP1016Deductions, ISNULL(ep.TP1016Credits, 0) AS TP1016Credits,
    ep.TD1ONMontantDemande, ISNULL(ep.TD1ONAutresCredits, 0) AS TD1ONAutresCredits, ISNULL(ep.TD1ONPersonnesACharge, 0) AS TD1ONPersonnesACharge,
    ISNULL(ep.DepotDirect, 0)              AS DepotDirect,
    COALESCE(ep.Transit, LEFT(t.BankTransit, 5))         AS Transit,
    COALESCE(ep.Institution, LEFT(t.BankInstitution, 3)) AS Institution,
    ep.CompteChiffre,
    t.BankAccount                          AS CompteMngConsul,
    ISNULL(ep.TalonParCourriel, 0)         AS TalonParCourriel,
    ep.Note,
    ep.UniteCNESSTId,
    u.Code                                 AS UniteCNESSTCode,
    u.Description                          AS UniteCNESSTDescription,
    CASE WHEN u.Actif = 1 THEN u.Taux END  AS UniteCNESSTTaux   -- unité désactivée : on revient au taux de la compagnie
FROM dbo.T300Employees t
JOIN paie.Compagnie c ON c.CompanyGUID = t.CompanyGUID
LEFT JOIN paie.EmployePaie ep ON ep.EmployeId = t.Id
LEFT JOIN paie.UniteCNESST u ON u.Id = ep.UniteCNESSTId
LEFT JOIN dbo.T053State s ON s.Id = t.StateId;
GO

-- ── Les taux : hors Québec (RPC, AE) et Ontario ─────────────────────────────
-- Tranches : « seuil|taux|constante;… » comme les autres. Contribution-santé :
-- « seuil|base|taux|plafond;… ». ISE : tranches de masse salariale, taux en %.
IF COL_LENGTH('paie.ParametresAnnee', 'OnTranches') IS NULL
    ALTER TABLE paie.ParametresAnnee ADD
        FedTauxFixeForfaitaireHorsQuebec  decimal(8,5)   NULL,
        AETauxHorsQuebec                  decimal(8,5)   NULL,
        AEMaxEmployeHorsQuebec            decimal(12,2)  NULL,
        RPCMaxGainsAdmissibles            decimal(12,2)  NULL,
        RPCExemption                      decimal(12,2)  NULL,
        RPCTaux                           decimal(8,5)   NULL,
        RPCTauxBase                       decimal(8,5)   NULL,
        RPCMaxEmploye                     decimal(12,2)  NULL,
        RPCMaxBaseEmploye                 decimal(12,2)  NULL,
        RPC2MaxSupplementaire             decimal(12,2)  NULL,
        RPC2Taux                          decimal(8,5)   NULL,
        RPC2MaxEmploye                    decimal(12,2)  NULL,
        OnTranches                        nvarchar(400)  NULL,
        OnMontantPersonnelBase            decimal(12,2)  NULL,
        OnTauxCredits                     decimal(8,5)   NULL,
        OnSurtaxeSeuil1                   decimal(12,2)  NULL,
        OnSurtaxeTaux1                    decimal(8,5)   NULL,
        OnSurtaxeSeuil2                   decimal(12,2)  NULL,
        OnSurtaxeTaux2                    decimal(8,5)   NULL,
        OnReductionBase                   decimal(12,2)  NULL,
        OnReductionParPersonne            decimal(12,2)  NULL,
        OnContributionSante               nvarchar(400)  NULL,
        ISETranches                       nvarchar(400)  NULL,
        ISEExemption                      decimal(14,2)  NULL,
        ISESeuilSansExemption             decimal(14,2)  NULL,
        WSIBMaxAssurable                  decimal(12,2)  NULL;
GO

-- 2026 : T4127, 122e édition (1er janvier 2026). La 123e (1er juillet) ne change rien
-- pour l'Ontario. ISE (exemption, seuil) et plafond de la WSIB : à valider auprès du
-- ministère des Finances de l'Ontario et de la WSIB.
UPDATE paie.ParametresAnnee
   SET
           FedTauxFixeForfaitaireHorsQuebec = 0.15,
           AETauxHorsQuebec = 0.0163,
           AEMaxEmployeHorsQuebec = 1123.07,
           RPCMaxGainsAdmissibles = 74600,
           RPCExemption = 3500,
           RPCTaux = 0.0595,
           RPCTauxBase = 0.0495,
           RPCMaxEmploye = 4230.45,
           RPCMaxBaseEmploye = 3519.45,
           RPC2MaxSupplementaire = 85000,
           RPC2Taux = 0.04,
           RPC2MaxEmploye = 416,
           OnTranches = N'53891|0.0505|0;107785|0.0915|2210;150000|0.1116|4376;220000|0.1216|5876;*|0.1316|8076',
           OnMontantPersonnelBase = 12989,
           OnTauxCredits = 0.0505,
           OnSurtaxeSeuil1 = 5818,
           OnSurtaxeTaux1 = 0.20,
           OnSurtaxeSeuil2 = 7446,
           OnSurtaxeTaux2 = 0.36,
           OnReductionBase = 300,
           OnReductionParPersonne = 554,
           OnContributionSante = N'20000|0|0.06|300;36000|300|0.06|450;48000|450|0.25|600;72000|600|0.25|750;200000|750|0.25|900',
           ISETranches = N'200000|0.98|0;230000|1.101|0;260000|1.223|0;290000|1.344|0;320000|1.465|0;350000|1.586|0;380000|1.708|0;400000|1.829|0;*|1.95|0',
           ISEExemption = 1000000,
           ISESeuilSansExemption = 5000000,
           WSIBMaxAssurable = 121700,
       Source = CASE WHEN Source LIKE N'%Ontario%' THEN Source ELSE ISNULL(Source + N' ; ', N'') + N'Ontario : T4127 (122e édition)' END,
       ModifieLe = sysdatetime(), ModifiePar = N'système'
 WHERE Annee = 2026 AND OnTranches IS NULL;
GO

-- Les années en brouillon copiées de 2026 avant ce script (2027) reçoivent la même
-- copie, à remplacer comme le reste par les guides de l'année. Une année VALIDÉE
-- n'est jamais complétée d'office : ses taux de l'Ontario se saisissent.
UPDATE d
   SET
           FedTauxFixeForfaitaireHorsQuebec = s.FedTauxFixeForfaitaireHorsQuebec,
           AETauxHorsQuebec = s.AETauxHorsQuebec,
           AEMaxEmployeHorsQuebec = s.AEMaxEmployeHorsQuebec,
           RPCMaxGainsAdmissibles = s.RPCMaxGainsAdmissibles,
           RPCExemption = s.RPCExemption,
           RPCTaux = s.RPCTaux,
           RPCTauxBase = s.RPCTauxBase,
           RPCMaxEmploye = s.RPCMaxEmploye,
           RPCMaxBaseEmploye = s.RPCMaxBaseEmploye,
           RPC2MaxSupplementaire = s.RPC2MaxSupplementaire,
           RPC2Taux = s.RPC2Taux,
           RPC2MaxEmploye = s.RPC2MaxEmploye,
           OnTranches = s.OnTranches,
           OnMontantPersonnelBase = s.OnMontantPersonnelBase,
           OnTauxCredits = s.OnTauxCredits,
           OnSurtaxeSeuil1 = s.OnSurtaxeSeuil1,
           OnSurtaxeTaux1 = s.OnSurtaxeTaux1,
           OnSurtaxeSeuil2 = s.OnSurtaxeSeuil2,
           OnSurtaxeTaux2 = s.OnSurtaxeTaux2,
           OnReductionBase = s.OnReductionBase,
           OnReductionParPersonne = s.OnReductionParPersonne,
           OnContributionSante = s.OnContributionSante,
           ISETranches = s.ISETranches,
           ISEExemption = s.ISEExemption,
           ISESeuilSansExemption = s.ISESeuilSansExemption,
           WSIBMaxAssurable = s.WSIBMaxAssurable
  FROM paie.ParametresAnnee d
  JOIN paie.ParametresAnnee s ON s.Annee = 2026
 WHERE d.Statut = 'B' AND d.Annee > 2026 AND d.OnTranches IS NULL AND s.OnTranches IS NOT NULL;
GO

-- ── Procédures : Copier et Save connaissent les nouvelles colonnes ──────────
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
        CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti,
        FedTauxFixeForfaitaireHorsQuebec, AETauxHorsQuebec, AEMaxEmployeHorsQuebec, RPCMaxGainsAdmissibles,
        RPCExemption, RPCTaux, RPCTauxBase, RPCMaxEmploye,
        RPCMaxBaseEmploye, RPC2MaxSupplementaire, RPC2Taux, RPC2MaxEmploye,
        OnTranches, OnMontantPersonnelBase, OnTauxCredits, OnSurtaxeSeuil1,
        OnSurtaxeTaux1, OnSurtaxeSeuil2, OnSurtaxeTaux2, OnReductionBase,
        OnReductionParPersonne, OnContributionSante, ISETranches, ISEExemption,
        ISESeuilSansExemption, WSIBMaxAssurable,
        CreePar)
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
        CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti,
        FedTauxFixeForfaitaireHorsQuebec, AETauxHorsQuebec, AEMaxEmployeHorsQuebec, RPCMaxGainsAdmissibles,
        RPCExemption, RPCTaux, RPCTauxBase, RPCMaxEmploye,
        RPCMaxBaseEmploye, RPC2MaxSupplementaire, RPC2Taux, RPC2MaxEmploye,
        OnTranches, OnMontantPersonnelBase, OnTauxCredits, OnSurtaxeSeuil1,
        OnSurtaxeTaux1, OnSurtaxeSeuil2, OnSurtaxeTaux2, OnReductionBase,
        OnReductionParPersonne, OnContributionSante, ISETranches, ISEExemption,
        ISESeuilSansExemption, WSIBMaxAssurable,
        @Par
      FROM paie.ParametresAnnee WHERE Annee = @De;
END
GO

-- Enregistre toutes les valeurs d'une année. Une année validée reste validée.
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
    @Par nvarchar(256) = NULL,
    -- Hors Québec et Ontario : facultatifs. NULL = ne pas toucher à la valeur en place, pour que
    -- la console Sec60Admin continue de fonctionner telle quelle tant qu'elle ne les saisit pas.
    @FedTauxFixeForfaitaireHorsQuebec decimal(8,5) = NULL,
    @AETauxHorsQuebec decimal(8,5) = NULL,
    @AEMaxEmployeHorsQuebec decimal(12,2) = NULL,
    @RPCMaxGainsAdmissibles decimal(12,2) = NULL,
    @RPCExemption decimal(12,2) = NULL,
    @RPCTaux decimal(8,5) = NULL,
    @RPCTauxBase decimal(8,5) = NULL,
    @RPCMaxEmploye decimal(12,2) = NULL,
    @RPCMaxBaseEmploye decimal(12,2) = NULL,
    @RPC2MaxSupplementaire decimal(12,2) = NULL,
    @RPC2Taux decimal(8,5) = NULL,
    @RPC2MaxEmploye decimal(12,2) = NULL,
    @OnTranches nvarchar(400) = NULL,
    @OnMontantPersonnelBase decimal(12,2) = NULL,
    @OnTauxCredits decimal(8,5) = NULL,
    @OnSurtaxeSeuil1 decimal(12,2) = NULL,
    @OnSurtaxeTaux1 decimal(8,5) = NULL,
    @OnSurtaxeSeuil2 decimal(12,2) = NULL,
    @OnSurtaxeTaux2 decimal(8,5) = NULL,
    @OnReductionBase decimal(12,2) = NULL,
    @OnReductionParPersonne decimal(12,2) = NULL,
    @OnContributionSante nvarchar(400) = NULL,
    @ISETranches nvarchar(400) = NULL,
    @ISEExemption decimal(14,2) = NULL,
    @ISESeuilSansExemption decimal(14,2) = NULL,
    @WSIBMaxAssurable decimal(12,2) = NULL
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
            FSSPrimaireConstante, FSSPrimaireCoefficient, CNESSTMaxAssurable, CNTTaux, CNTMaxAssujetti, CreePar,
            FedTauxFixeForfaitaireHorsQuebec, AETauxHorsQuebec, AEMaxEmployeHorsQuebec, RPCMaxGainsAdmissibles,
            RPCExemption, RPCTaux, RPCTauxBase, RPCMaxEmploye,
            RPCMaxBaseEmploye, RPC2MaxSupplementaire, RPC2Taux, RPC2MaxEmploye,
            OnTranches, OnMontantPersonnelBase, OnTauxCredits, OnSurtaxeSeuil1,
            OnSurtaxeTaux1, OnSurtaxeSeuil2, OnSurtaxeTaux2, OnReductionBase,
            OnReductionParPersonne, OnContributionSante, ISETranches, ISEExemption,
            ISESeuilSansExemption, WSIBMaxAssurable)
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
            @FSSPrimaireConstante, @FSSPrimaireCoefficient, @CNESSTMaxAssurable, @CNTTaux, @CNTMaxAssujetti, @Par,
            @FedTauxFixeForfaitaireHorsQuebec, @AETauxHorsQuebec, @AEMaxEmployeHorsQuebec, @RPCMaxGainsAdmissibles,
            @RPCExemption, @RPCTaux, @RPCTauxBase, @RPCMaxEmploye,
            @RPCMaxBaseEmploye, @RPC2MaxSupplementaire, @RPC2Taux, @RPC2MaxEmploye,
            @OnTranches, @OnMontantPersonnelBase, @OnTauxCredits, @OnSurtaxeSeuil1,
            @OnSurtaxeTaux1, @OnSurtaxeSeuil2, @OnSurtaxeTaux2, @OnReductionBase,
            @OnReductionParPersonne, @OnContributionSante, @ISETranches, @ISEExemption,
            @ISESeuilSansExemption, @WSIBMaxAssurable);

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
        FedTauxFixeForfaitaireHorsQuebec = COALESCE(@FedTauxFixeForfaitaireHorsQuebec, FedTauxFixeForfaitaireHorsQuebec),
        AETauxHorsQuebec = COALESCE(@AETauxHorsQuebec, AETauxHorsQuebec),
        AEMaxEmployeHorsQuebec = COALESCE(@AEMaxEmployeHorsQuebec, AEMaxEmployeHorsQuebec),
        RPCMaxGainsAdmissibles = COALESCE(@RPCMaxGainsAdmissibles, RPCMaxGainsAdmissibles),
        RPCExemption = COALESCE(@RPCExemption, RPCExemption),
        RPCTaux = COALESCE(@RPCTaux, RPCTaux),
        RPCTauxBase = COALESCE(@RPCTauxBase, RPCTauxBase),
        RPCMaxEmploye = COALESCE(@RPCMaxEmploye, RPCMaxEmploye),
        RPCMaxBaseEmploye = COALESCE(@RPCMaxBaseEmploye, RPCMaxBaseEmploye),
        RPC2MaxSupplementaire = COALESCE(@RPC2MaxSupplementaire, RPC2MaxSupplementaire),
        RPC2Taux = COALESCE(@RPC2Taux, RPC2Taux),
        RPC2MaxEmploye = COALESCE(@RPC2MaxEmploye, RPC2MaxEmploye),
        OnTranches = COALESCE(@OnTranches, OnTranches),
        OnMontantPersonnelBase = COALESCE(@OnMontantPersonnelBase, OnMontantPersonnelBase),
        OnTauxCredits = COALESCE(@OnTauxCredits, OnTauxCredits),
        OnSurtaxeSeuil1 = COALESCE(@OnSurtaxeSeuil1, OnSurtaxeSeuil1),
        OnSurtaxeTaux1 = COALESCE(@OnSurtaxeTaux1, OnSurtaxeTaux1),
        OnSurtaxeSeuil2 = COALESCE(@OnSurtaxeSeuil2, OnSurtaxeSeuil2),
        OnSurtaxeTaux2 = COALESCE(@OnSurtaxeTaux2, OnSurtaxeTaux2),
        OnReductionBase = COALESCE(@OnReductionBase, OnReductionBase),
        OnReductionParPersonne = COALESCE(@OnReductionParPersonne, OnReductionParPersonne),
        OnContributionSante = COALESCE(@OnContributionSante, OnContributionSante),
        ISETranches = COALESCE(@ISETranches, ISETranches),
        ISEExemption = COALESCE(@ISEExemption, ISEExemption),
        ISESeuilSansExemption = COALESCE(@ISESeuilSansExemption, ISESeuilSansExemption),
        WSIBMaxAssurable = COALESCE(@WSIBMaxAssurable, WSIBMaxAssurable),
        ModifieLe = sysdatetime(), ModifiePar = @Par
     WHERE Annee = @Annee;
END
GO

PRINT N'05_ontario.sql : terminé.';
