-- =============================================================================
-- T419 : forfait CIE 1-50 — la limite est de 50 employés (pas 19)
-- Reliquats de l'ancien forfait com119 : tranche d'employés « 1–19 » et fonction
-- « Paie jusqu'à 19 employés » dans les trois langues, et la carte mise en forme
-- (DescriptionLong, non affichée aujourd'hui) « 1–19 » / « 1 à 9 employés ».
-- Décision du 2026-11-26 : le forfait couvre jusqu'à 50 employés.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

UPDATE dbo.T021Plan
   SET EmployeeRange    = N'1–50 employés',
       EmployeeRange_en = N'1–50 employees',
       EmployeeRange_es = N'1–50 empleados',
       Features    = REPLACE(Features,    N'Paie jusqu''à 19 employés',      N'Paie jusqu''à 50 employés'),
       Features_en = REPLACE(Features_en, N'Payroll for up to 19 employees', N'Payroll for up to 50 employees'),
       Features_es = REPLACE(Features_es, N'Nómina para hasta 19 empleados', N'Nómina para hasta 50 empleados'),
       DescriptionLong = REPLACE(REPLACE(REPLACE(REPLACE(CAST(DescriptionLong AS NVARCHAR(MAX)),
                             N'Compagnie 1&ndash;19',            N'Société 1&ndash;50 employ&eacute;s'),
                             N'1 &agrave; 9 employ&eacute;s',    N'1 &agrave; 50 employ&eacute;s'),
                             N'1&ndash;19 employ&eacute;s',      N'1&ndash;50 employ&eacute;s'),
                             N'jusqu''&agrave; 19 employ&eacute;s', N'jusqu''&agrave; 50 employ&eacute;s'),
       ModifiedOn = GETDATE(),
       ModifiedBy = N'T419'
 WHERE Code = 'CIE 1-50'
   AND IsDeleted = 0;
GO
