-- =============================================================================
-- T360 — Agenda : montant du RDV = total du brouillon / de la facture
--
-- Le montant affiché sur la rangée du RDV (boîte « Aujourd'hui ») doit être le
-- TOTAL inscrit dans le document lié (brouillon ou facture, taxes incluses),
-- pas le montant prévu. On ajoute DocumentTotal à s0100GetAppointmentsByRange
-- (via le même OUTER APPLY que DocumentNumber/DocumentId/EstFacture).
-- Le code-behind affiche DocumentTotal s'il existe, sinon MontantPrevu.
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
        ISNULL(doc.DocumentId, 0)     AS DocumentId,
        CASE WHEN doc.ComptabilisationStatus = 'COMPTABILISE' THEN 1 ELSE 0 END AS EstFacture,
        doc.DocumentTotal
    FROM dbo.Appointments a
    LEFT JOIN dbo.vwCustomers       c ON c.Id = a.CustomerId
    LEFT JOIN dbo.T300Employees       e ON e.Id = a.EmployeeId
    LEFT JOIN dbo.vwAppointmentTypes t ON t.Id = a.AppointmentTypeId
    OUTER APPLY (
        SELECT TOP 1 d.Id AS DocumentId, d.DocumentNumber, d.ComptabilisationStatus,
                     d.Total AS DocumentTotal
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
