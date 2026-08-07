-- =============================================================================
-- s0106GetEmployeesForAgenda (révisé)
--   Les « ressources » de l'agenda = les employés (T300Employees).
--   CORRECTION : filtrer par @CompanyGUID (la version précédente l'ignorait et
--   renvoyait les employés actifs de TOUTES les compagnies). Aligne l'agenda sur
--   la page de gestion des employés (même ensemble, même libellé FullName).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0106GetEmployeesForAgenda
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        Id,
        LTRIM(RTRIM(COALESCE(NULLIF(DisplayName, ''),
              LTRIM(RTRIM(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')))))) AS FullName,
        ISNULL(ColorHex, '#64748B') AS ColorHex
    FROM dbo.T300Employees
    WHERE Active = 1
      AND CompanyGUID = @CompanyGUID
    ORDER BY FullName;
END
GO
