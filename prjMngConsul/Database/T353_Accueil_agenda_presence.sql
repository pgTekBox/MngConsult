-- =============================================================================
-- T353 — Tableau de bord client (Default.aspx) : agenda enrichi + présence
--
-- Aligne l'accueil sur la maquette « page première » du 21 octobre :
--   1) chaque RDV porte un MONTANT prévu et un DOCUMENT produit (soumission /
--      facture / tâche) → affichés sur la ligne de RDV (pastille + montant) ;
--   2) la PRÉSENCE des employés (absences, retards du jour) → pastille « Présence »
--      du bloc 1 en mode équipe.
--
-- Idempotent (colonnes/tables ajoutées si absentes, CREATE OR ALTER). Rejouable.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ---------------------------------------------------------------------------
-- 1) Appointments : montant prévu + mode de facturation (document produit)
-- ---------------------------------------------------------------------------
IF COL_LENGTH('dbo.Appointments', 'MontantPrevu') IS NULL
    ALTER TABLE dbo.Appointments ADD MontantPrevu DECIMAL(18,2) NULL;
GO
IF COL_LENGTH('dbo.Appointments', 'ModeFacturation') IS NULL
    ALTER TABLE dbo.Appointments ADD ModeFacturation NVARCHAR(20) NULL;  -- 'soumission' | 'facture' | 'tache'
GO

-- Remplissage initial (seulement les RDV sans valeur) : le document découle de
-- l'état (terminé → facture, sinon soumission) ; le montant prévu = durée × 85 $/h.
UPDATE dbo.Appointments
SET ModeFacturation = CASE WHEN Status = N'Terminé' THEN N'facture' ELSE N'soumission' END
WHERE ModeFacturation IS NULL AND IsDeleted = 0;
GO
UPDATE dbo.Appointments
SET MontantPrevu = CAST(ROUND(DATEDIFF(MINUTE, StartDateTime, EndDateTime) / 60.0 * 85.0, 2) AS DECIMAL(18,2))
WHERE MontantPrevu IS NULL AND IsDeleted = 0 AND ISNULL(IsAllDay, 0) = 0
  AND DATEDIFF(MINUTE, StartDateTime, EndDateTime) BETWEEN 1 AND 1440;
GO

-- s0100GetAppointmentsByRange : on ajoute MontantPrevu et ModeFacturation.
CREATE OR ALTER PROCEDURE [dbo].[s0100GetAppointmentsByRange]
    @CompanyGUID UNIQUEIDENTIFIER,
    @StartDate   DATETIME,
    @EndDate     DATETIME,
    @EmployeeId  INT = NULL  -- optionnel : filtre par ressource
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        a.Id,
        a.Title,
        a.Description,
        a.StartDateTime,
        a.EndDateTime,
        a.IsAllDay,
        a.CustomerId,
        ISNULL(c.Name, '') AS CustomerName,
        a.EmployeeId,
        ISNULL(e.FirstName + ' ' + e.LastName, '') AS EmployeeName,
        a.AppointmentTypeId,
        ISNULL(t.TypeName, '') AS TypeName,
        ISNULL(t.ColorHex, '#2563eb') AS ColorHex,
        a.Status,
        a.Location,
        a.RecurrenceRule,
        a.RecurrenceParentId,
        a.ReminderMinutes,
        a.MontantPrevu,
        a.ModeFacturation
    FROM dbo.Appointments a
    LEFT JOIN dbo.vwCustomers       c ON c.Id = a.CustomerId
    LEFT JOIN dbo.T300Employees       e ON e.Id = a.EmployeeId
    LEFT JOIN dbo.vwAppointmentTypes t ON t.Id = a.AppointmentTypeId
    WHERE a.CompanyGUID = @CompanyGUID
      AND a.IsDeleted = 0
      AND a.StartDateTime < @EndDate
      AND a.EndDateTime   > @StartDate
      AND (@EmployeeId IS NULL OR a.EmployeeId = @EmployeeId)
    ORDER BY a.StartDateTime;
END
GO

-- ---------------------------------------------------------------------------
-- 2) Présence des employés : absences et retards par jour
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.T301Presence', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T301Presence (
        Id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyGUID UNIQUEIDENTIFIER  NOT NULL,
        EmployeeId  INT               NOT NULL,
        Jour        DATE              NOT NULL,
        Type        NVARCHAR(10)      NOT NULL,   -- 'absence' | 'retard'
        Note        NVARCHAR(200)     NULL,
        CreatedOn   DATETIME2(0)      NOT NULL CONSTRAINT DF_T301_Created DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_T301_Type CHECK (Type IN ('absence', 'retard'))
    );
    CREATE INDEX IX_T301_CompanyJour ON dbo.T301Presence (CompanyGUID, Jour);
END
GO

-- s0969GetPresenceDuJour : les absences / retards d'un jour pour une compagnie.
CREATE OR ALTER PROCEDURE dbo.s0969GetPresenceDuJour
    @CompanyGUID uniqueidentifier,
    @Jour        date = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Jour IS NULL SET @Jour = CAST(SYSDATETIME() AS date);
    SELECT
        p.Id, p.EmployeeId,
        ISNULL(e.FirstName + ' ' + e.LastName, '') AS EmployeeName,
        p.Type, p.Note
    FROM dbo.T301Presence p
    LEFT JOIN dbo.T300Employees e ON e.Id = p.EmployeeId
    WHERE p.CompanyGUID = @CompanyGUID AND p.Jour = @Jour
    ORDER BY CASE p.Type WHEN 'absence' THEN 0 ELSE 1 END, EmployeeName;
END
GO
