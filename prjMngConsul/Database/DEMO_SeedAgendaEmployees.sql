SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- DEMO_SeedAgendaEmployees.sql
-- Peaufinage de la démo « Logiciels Cronus Ltée » : ajoute des EMPLOYÉS et des
-- RENDEZ-VOUS (agenda) pour que ces écrans ne soient pas vides.
-- Idempotent : réinitialise d'abord ces données démo puis les recrée.
-- À suivre d'un re-snapshot (DEMO_CreateAndSnapshot.sql) pour figer.
-- =============================================================================
USE [MngConsul];
GO
SET NOCOUNT ON;

DECLARE @d UNIQUEIDENTIFIER = 'D89EB638-6B05-443D-B1C9-01A6316443BF';

-- Nettoyage (enfants d'abord : Appointments référence Employees)
DELETE FROM dbo.Appointments   WHERE CompanyGUID = @d;
DELETE FROM dbo.T300Employees  WHERE CompanyGUID = @d;

-- Deux clients de la démo pour rattacher des rendez-vous
DECLARE @c1 INT = (SELECT MIN(Id) FROM dbo.T050Party WHERE CompanyGUID = @d AND Type IN (1,3));
DECLARE @c2 INT = (SELECT MIN(Id) FROM dbo.T050Party WHERE CompanyGUID = @d AND Type IN (1,3) AND Id > @c1);

-- ---- Employés ----
DECLARE @emp TABLE (Id INT, Prenom VARCHAR(50));
INSERT INTO dbo.T300Employees
    (CompanyGUID, EmployeeNumber, FirstName, LastName, DisplayName, JobTitle, Department,
     Email, Phone, City, HireDate, EmploymentStatus, EmploymentType, Active)
OUTPUT inserted.Id, inserted.FirstName INTO @emp(Id, Prenom)
VALUES
 (@d, N'EMP-001', N'Marie',  N'Tremblay', N'Marie Tremblay', N'Directrice des ventes', N'Ventes',
      N'marie.tremblay@cronus.ca', N'514-222-3401', N'Montréal', '2022-03-15', N'Actif', N'Temps plein', 1),
 (@d, N'EMP-002', N'Luc',    N'Gagnon',   N'Luc Gagnon',     N'Technicien',            N'Support',
      N'luc.gagnon@cronus.ca',     N'514-222-3402', N'Montréal', '2023-06-01', N'Actif', N'Temps plein', 1),
 (@d, N'EMP-003', N'Sophie', N'Roy',      N'Sophie Roy',     N'Comptable',             N'Administration',
      N'sophie.roy@cronus.ca',     N'514-222-3403', N'Montréal', '2021-09-20', N'Actif', N'Temps plein', 1);

DECLARE @eMarie  INT = (SELECT Id FROM @emp WHERE Prenom = N'Marie');
DECLARE @eLuc    INT = (SELECT Id FROM @emp WHERE Prenom = N'Luc');
DECLARE @eSophie INT = (SELECT Id FROM @emp WHERE Prenom = N'Sophie');

-- ---- Rendez-vous (agenda), autour de la date courante ----
DECLARE @t0 DATE = CAST(GETDATE() AS DATE);

INSERT INTO dbo.Appointments
    (CompanyGUID, Title, Description, StartDateTime, EndDateTime, IsAllDay,
     CustomerId, EmployeeId, Status, Location, ReminderMinutes)
VALUES
 (@d, N'Rencontre client — présentation', N'Présentation de l''offre logicielle',
      DATEADD(HOUR,10,CAST(DATEADD(DAY,1,@t0) AS DATETIME)),
      DATEADD(HOUR,11,CAST(DATEADD(DAY,1,@t0) AS DATETIME)), 0, @c1, @eMarie, N'Planifié', N'Bureau Montréal', 30),
 (@d, N'Installation logiciel', N'Déploiement et configuration chez le client',
      DATEADD(HOUR,14,CAST(DATEADD(DAY,2,@t0) AS DATETIME)),
      DATEADD(HOUR,16,CAST(DATEADD(DAY,2,@t0) AS DATETIME)), 0, @c2, @eLuc, N'Planifié', N'Sur site', 60),
 (@d, N'Suivi comptable', N'Révision comptable mensuelle',
      DATEADD(HOUR,9,CAST(DATEADD(DAY,3,@t0) AS DATETIME)),
      DATEADD(MINUTE,30,DATEADD(HOUR,9,CAST(DATEADD(DAY,3,@t0) AS DATETIME))), 0, NULL, @eSophie, N'Planifié', N'Bureau Montréal', 15),
 (@d, N'Appel de vente', N'Relance d''un prospect',
      DATEADD(HOUR,15,CAST(@t0 AS DATETIME)),
      DATEADD(HOUR,16,CAST(@t0 AS DATETIME)), 0, @c1, @eMarie, N'Planifié', NULL, 10),
 (@d, N'Formation équipe', N'Nouveautés du produit',
      CAST(DATEADD(DAY,5,@t0) AS DATETIME),
      CAST(DATEADD(DAY,5,@t0) AS DATETIME), 1, NULL, NULL, N'Planifié', N'Salle de conférence', NULL);

PRINT 'Demo enrichie : 3 employes + 5 rendez-vous.';
GO
