-- =============================================================================
-- T357 — Agenda : identifiant du document (brouillon) lié au RDV
--
-- Pour ouvrir la fiche d'édition du brouillon dans un popup depuis la pastille
-- du tableau de bord, il faut l'Id du document (pas seulement son numéro).
-- On ajoute DocumentId à s0100GetAppointmentsByRange (cf. T356 pour le numéro).
-- =============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
        a.ModeFacturation,
        ISNULL(doc.DocumentNumber, '') AS DocumentNumber,
        ISNULL(doc.DocumentId, 0)     AS DocumentId
    FROM dbo.Appointments a
    LEFT JOIN dbo.vwCustomers       c ON c.Id = a.CustomerId
    LEFT JOIN dbo.T300Employees       e ON e.Id = a.EmployeeId
    LEFT JOIN dbo.vwAppointmentTypes t ON t.Id = a.AppointmentTypeId
    OUTER APPLY (
        SELECT TOP 1 d.Id AS DocumentId, d.DocumentNumber
        FROM dbo.T060Document d
        WHERE d.AppointmentId = a.Id
          AND d.DocumentTypeId = 1
          AND d.CompanyGUID = @CompanyGUID
        ORDER BY d.Id DESC
    ) doc
    WHERE a.CompanyGUID = @CompanyGUID
      AND a.IsDeleted = 0
      AND a.StartDateTime < @EndDate
      AND a.EndDateTime   > @StartDate
      AND (@EmployeeId IS NULL OR a.EmployeeId = @EmployeeId)
    ORDER BY a.StartDateTime;
END
GO
