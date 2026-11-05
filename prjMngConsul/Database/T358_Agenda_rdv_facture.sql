-- =============================================================================
-- T358 — Agenda : marquer le RDV « facturé » quand son brouillon est comptabilisé
--
-- Le RDV est « facturé » dès que la facture client qui lui est liée
-- (T060Document.AppointmentId) passe au statut COMPTABILISE. On l'expose comme
-- un indicateur EstFacture dans s0100GetAppointmentsByRange (dérivé, donc
-- toujours exact — pas de drapeau à maintenir, pas de modif de la procédure de
-- comptabilisation). Le tableau de bord masque alors le bouton « Facturer » et
-- affiche une pastille « Facturé ».
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
        CASE WHEN doc.ComptabilisationStatus = 'COMPTABILISE' THEN 1 ELSE 0 END AS EstFacture
    FROM dbo.Appointments a
    LEFT JOIN dbo.vwCustomers       c ON c.Id = a.CustomerId
    LEFT JOIN dbo.T300Employees       e ON e.Id = a.EmployeeId
    LEFT JOIN dbo.vwAppointmentTypes t ON t.Id = a.AppointmentTypeId
    OUTER APPLY (
        SELECT TOP 1 d.Id AS DocumentId, d.DocumentNumber, d.ComptabilisationStatus
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
