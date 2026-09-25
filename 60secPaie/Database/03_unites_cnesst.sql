-- =============================================================================
-- 03 — Unités de classification de la CNESST
--
-- La CNESST classe l'employeur dans une ou plusieurs unités selon son activité,
-- chacune avec son taux ($ par 100 $ de salaire assurable). Jusqu'ici la
-- compagnie n'avait qu'un taux (paie.Compagnie.TauxCNESST, le taux de versement
-- périodique). Désormais :
--   · paie.UniteCNESST : les unités de la compagnie, avec leur taux ;
--   · paie.EmployePaie.UniteCNESSTId : l'unité de l'employé (NULL = taux de la
--     compagnie, comme avant) ;
--   · paie.Paie.UniteCNESSTId / TauxCNESST : figés à chaque calcul, pour que
--     la Déclaration des salaires se regroupe par unité même si l'employé
--     change d'unité en cours d'année.
-- Ce script se rejoue sans dommage.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'paie.UniteCNESST') IS NULL
CREATE TABLE paie.UniteCNESST (
    Id          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_UniteCNESST PRIMARY KEY,
    CompagnieId int NOT NULL CONSTRAINT FK_UniteCNESST_Compagnie REFERENCES paie.Compagnie(Id),
    Code        nvarchar(10)  NOT NULL,     -- ex. 80030
    Description nvarchar(200) NOT NULL,     -- ex. Bureau de comptables
    Taux        decimal(7,4)  NOT NULL,     -- $ par 100 $ de salaire assurable
    Actif       bit NOT NULL CONSTRAINT DF_UniteCNESST_Actif DEFAULT (1),
    CONSTRAINT UQ_UniteCNESST_Code UNIQUE (CompagnieId, Code)
);
GO

IF COL_LENGTH('paie.EmployePaie', 'UniteCNESSTId') IS NULL
BEGIN
    ALTER TABLE paie.EmployePaie ADD UniteCNESSTId int NULL
        CONSTRAINT FK_EmployePaie_UniteCNESST REFERENCES paie.UniteCNESST(Id);
END
GO

IF COL_LENGTH('paie.Paie', 'UniteCNESSTId') IS NULL ALTER TABLE paie.Paie ADD UniteCNESSTId int NULL;
IF COL_LENGTH('paie.Paie', 'TauxCNESST')    IS NULL ALTER TABLE paie.Paie ADD TauxCNESST decimal(7,4) NULL;
GO

-- La vue des employés porte l'unité et son taux, pour la fiche et le calcul.
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
              WHEN 'Prince Edward Island' THEN N'PE' WHEN 'Newfoundland and Labrador' THEN N'NL' ELSE N'QC' END AS nchar(2)) AS Province,
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

PRINT N'03_unites_cnesst.sql : terminé.';
