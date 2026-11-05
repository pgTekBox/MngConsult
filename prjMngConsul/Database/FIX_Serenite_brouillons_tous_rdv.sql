-- =============================================================================
-- FIX — Massothérapie Sérénité : un brouillon pour CHAQUE rendez-vous
--
-- Beaucoup de RDV n'ont pas de brouillon parce qu'ils n'ont pas de service
-- (AppointmentTypeId NULL) — c'est le service qui déclenche le brouillon.
-- Pour chaque RDV sans brouillon, on attribue :
--   - un SERVICE (produit de la compagnie, parmi vwAppointmentTypes) s'il n'en
--     a pas,
--   - un CLIENT (T050Party Type=1 de la compagnie) s'il n'en a pas,
-- puis on crée le brouillon via s0970CreateDraftInvoiceFromAppointment.
-- Répartition déterministe et variée (CHECKSUM de l'Id du RDV, sels distincts
-- pour service et client). Ne touche PAS les RDV qui ont déjà un brouillon.
-- Portée : compagnie D2D2D2D2-…-002 (Massothérapie Sérénité).
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DECLARE @g UNIQUEIDENTIFIER = 'D2D2D2D2-0000-4000-8000-000000000002';
DECLARE @nSvc INT = (SELECT COUNT(*) FROM dbo.vwAppointmentTypes WHERE CompanyGUID = @g);
DECLARE @nCli INT = (SELECT COUNT(*) FROM dbo.T050Party WHERE CompanyGUID = @g AND Type = 1);

IF @nSvc = 0 OR @nCli = 0
BEGIN
    PRINT 'Aucun service ou aucun client pour cette compagnie — rien à faire.';
    RETURN;
END

-- 1) Attribuer service + client aux RDV sans brouillon (seulement si manquants)
;WITH Svc AS (
    SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) - 1 AS rn
    FROM dbo.vwAppointmentTypes WHERE CompanyGUID = @g
),
Cli AS (
    SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) - 1 AS rn
    FROM dbo.T050Party WHERE CompanyGUID = @g AND Type = 1
),
Cibles AS (
    SELECT a.Id AS ApptId,
           ((CHECKSUM(CONVERT(varchar(20), a.Id) + 'S') % @nSvc) + @nSvc) % @nSvc AS svcRn,
           ((CHECKSUM(CONVERT(varchar(20), a.Id) + 'C') % @nCli) + @nCli) % @nCli AS cliRn
    FROM dbo.Appointments a
    WHERE a.CompanyGUID = @g AND a.IsDeleted = 0
      AND NOT EXISTS (SELECT 1 FROM dbo.T060Document d
                      WHERE d.AppointmentId = a.Id AND d.DocumentTypeId = 1)
)
UPDATE a
SET a.AppointmentTypeId = ISNULL(a.AppointmentTypeId, s.Id),
    a.CustomerId        = ISNULL(a.CustomerId, c.Id)
FROM dbo.Appointments a
JOIN Cibles t ON t.ApptId = a.Id
JOIN Svc s   ON s.rn = t.svcRn
JOIN Cli c   ON c.rn = t.cliRn;

PRINT CONCAT('RDV mis à jour (service/client) : ', @@ROWCOUNT, '.');

-- 2) Créer le brouillon pour chaque RDV sans brouillon (ils ont tous un service maintenant)
DECLARE @appt INT, @doc INT, @n INT = 0;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT a.Id
    FROM dbo.Appointments a
    WHERE a.CompanyGUID = @g AND a.IsDeleted = 0
      AND NOT EXISTS (SELECT 1 FROM dbo.T060Document d
                      WHERE d.AppointmentId = a.Id AND d.DocumentTypeId = 1);
OPEN cur;
FETCH NEXT FROM cur INTO @appt;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.s0970CreateDraftInvoiceFromAppointment @appt, @g, @doc OUTPUT;
    SET @n = @n + 1;
    FETCH NEXT FROM cur INTO @appt;
END
CLOSE cur;
DEALLOCATE cur;

PRINT CONCAT('Brouillons créés : ', @n, '.');
GO

-- Contrôle : il ne doit plus rester de RDV sans brouillon
DECLARE @g2 UNIQUEIDENTIFIER = 'D2D2D2D2-0000-4000-8000-000000000002';
SELECT
    (SELECT COUNT(*) FROM dbo.Appointments a WHERE a.CompanyGUID = @g2 AND a.IsDeleted = 0) AS RdvTotal,
    (SELECT COUNT(*) FROM dbo.Appointments a WHERE a.CompanyGUID = @g2 AND a.IsDeleted = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.T060Document d WHERE d.AppointmentId = a.Id AND d.DocumentTypeId = 1)) AS RdvSansBrouillon,
    (SELECT COUNT(*) FROM dbo.T060Document d WHERE d.CompanyGUID = @g2 AND d.AppointmentId IS NOT NULL AND d.DocumentTypeId = 1) AS BrouillonsEtFactures;
GO
