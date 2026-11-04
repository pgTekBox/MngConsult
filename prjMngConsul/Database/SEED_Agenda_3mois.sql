-- =============================================================================
-- SEED — Agenda : 2 à 4 rendez-vous par jour ouvrable, 3 mois, par entreprise
--
-- Pour chaque compagnie ayant au moins un employé actif, on crée, du jour même
-- jusqu'à ~3 mois, de 2 à 4 rendez-vous par jour ouvrable (lundi-vendredi),
-- répartis entre les employés de la compagnie. Chaque RDV a un service, un client
-- au hasard (si la compagnie en a), un lieu, un montant prévu et un mode
-- (soumission/facture). Les créneaux sont décalés dans la journée (pas de
-- chevauchement).
--
-- La variété vient de tranches de 2 octets d'un SHA2_256 de (compagnie|jour|
-- créneau) : bonne répartition sur toutes les positions. (CHECKSUM % petitN a de
-- mauvais bits de poids faible → tout le monde tombait sur le même employé.)
-- =============================================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- On repart propre : on retire les RDV de démonstration déjà générés par ce seed.
DELETE FROM dbo.Appointments WHERE Description = N'Rendez-vous de démonstration.';
GO

DECLARE @today date = CAST(GETDATE() AS date);

;WITH Nums AS (
    SELECT TOP (92) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects
),
Days AS (
    SELECT DATEADD(DAY, n, @today) AS d FROM Nums
    WHERE (DATEDIFF(DAY, '19000101', DATEADD(DAY, n, @today)) % 7) <= 4   -- lundi..vendredi
),
Comp AS (
    SELECT DISTINCT CompanyGUID FROM dbo.T300Employees WHERE Active = 1 AND CompanyGUID IS NOT NULL
),
Slots AS (SELECT s FROM (VALUES (1),(2),(3),(4)) x(s)),
Keep AS (
    -- 2 à 4 RDV par (compagnie, jour) : hash sur (compagnie|jour) → 2..4.
    SELECT c.CompanyGUID, dd.d, sl.s
    FROM Comp c CROSS JOIN Days dd CROSS JOIN Slots sl
    WHERE sl.s <= 2 + (CONVERT(int, SUBSTRING(
            HASHBYTES('SHA2_256', CONVERT(char(36), c.CompanyGUID) + '|' + CONVERT(char(8), dd.d, 112)), 1, 2)) % 3)
),
Base AS (
    SELECT k.CompanyGUID, k.d, k.s,
           HASHBYTES('SHA2_256', CONVERT(char(36), k.CompanyGUID) + '|' + CONVERT(char(8), k.d, 112) + '|' + CONVERT(varchar(2), k.s)) AS h
    FROM Keep k
),
Calc AS (
    SELECT b.CompanyGUID, b.d, b.s,
           CONVERT(int, SUBSTRING(b.h, 1, 2))  AS hEmp,
           CONVERT(int, SUBSTRING(b.h, 3, 2))  AS hSvc,
           CONVERT(int, SUBSTRING(b.h, 5, 2))  AS hLoc,
           CONVERT(int, SUBSTRING(b.h, 7, 2))  AS hStart,
           CONVERT(int, SUBSTRING(b.h, 9, 2))  AS hDur,
           CONVERT(int, SUBSTRING(b.h, 11, 2)) AS hRate,
           CONVERT(int, SUBSTRING(b.h, 13, 2)) AS hStat,
           CONVERT(int, SUBSTRING(b.h, 15, 2)) AS hMode,
           CONVERT(int, SUBSTRING(b.h, 17, 2)) AS hCust
    FROM Base b
),
Vals AS (
    SELECT c.*,
           (CASE c.s WHEN 1 THEN 480 WHEN 2 THEN 600 WHEN 3 THEN 780 ELSE 900 END)
               + (CASE WHEN c.hStart % 2 = 0 THEN 0 ELSE 30 END) AS startMin,
           (CASE c.hDur % 3 WHEN 0 THEN 30 WHEN 1 THEN 60 ELSE 90 END) AS dur,
           (60 + c.hRate % 61) AS rate
    FROM Calc c
),
EmpN AS (
    SELECT CompanyGUID, Id,
           ROW_NUMBER() OVER (PARTITION BY CompanyGUID ORDER BY Id) AS rn,
           COUNT(*)    OVER (PARTITION BY CompanyGUID) AS cnt
    FROM dbo.T300Employees WHERE Active = 1 AND CompanyGUID IS NOT NULL
),
CustN AS (
    SELECT CompanyGUID, Id,
           ROW_NUMBER() OVER (PARTITION BY CompanyGUID ORDER BY Id) AS rn,
           COUNT(*)    OVER (PARTITION BY CompanyGUID) AS cnt
    FROM dbo.vwCustomers
),
Svc AS (
    SELECT v, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
    FROM (VALUES (N'Consultation'),(N'Rendez-vous'),(N'Suivi'),(N'Installation'),
                 (N'Entretien'),(N'Évaluation'),(N'Service'),(N'Réparation')) t(v)
),
Loc AS (
    SELECT v, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
    FROM (VALUES (N'À votre place'),(N'Chez le client'),(N'Téléphone'),(N'Visio')) t(v)
)
INSERT INTO dbo.Appointments
    (CompanyGUID, Title, Description, StartDateTime, EndDateTime, IsAllDay,
     CustomerId, EmployeeId, Status, Location, MontantPrevu, ModeFacturation,
     IsDeleted, CreatedOn)
SELECT
    v.CompanyGUID,
    svc.v,
    N'Rendez-vous de démonstration.',
    DATEADD(MINUTE, v.startMin, CAST(v.d AS datetime)),
    DATEADD(MINUTE, v.startMin + v.dur, CAST(v.d AS datetime)),
    0,
    cu.Id,
    en.Id,
    CASE WHEN v.hStat % 4 = 0 THEN N'Confirmé' ELSE N'Planifié' END,
    loc.v,
    CAST(ROUND(v.dur / 60.0 * v.rate, 2) AS decimal(18,2)),
    CASE WHEN v.hMode % 2 = 0 THEN N'soumission' ELSE N'facture' END,
    0, GETDATE()
FROM Vals v
JOIN EmpN en ON en.CompanyGUID = v.CompanyGUID AND en.rn = (v.hEmp % en.cnt) + 1
JOIN Svc svc ON svc.i = v.hSvc % 8
JOIN Loc loc ON loc.i = v.hLoc % 4
LEFT JOIN CustN cu ON cu.CompanyGUID = v.CompanyGUID AND cu.rn = (v.hCust % cu.cnt) + 1;

PRINT CONCAT('Rendez-vous créés : ', @@ROWCOUNT, '.');
GO
