-- =============================================================================
-- _DeployPhase1AutoPay
-- Script maitre pour deployer la Phase 1 (Schema BD AutoPay).
-- Execute dans l'ordre les tables, les colonnes T060 et les 13 stored procs.
--
-- Utilisation :
--   sqlcmd -S 192.168.0.203 -U MngConsul -P "..." -d MngConsul
--          -i Database\_DeployPhase1AutoPay.sql
--
-- Idempotent : on peut le relancer sans danger.
-- =============================================================================

USE [MngConsul];
GO

PRINT '=== Phase 1 AutoPay - Deploiement debut ===';
PRINT '';

PRINT '--- Tables ---';
:r T144AuthorizationAutoPay.sql
:r T145AutoPayAttempt.sql

PRINT '';
PRINT '--- Colonnes T060Document ---';
:r T060Document_AddAutoPayColumns.sql

PRINT '';
PRINT '--- Stored Procedures ---';
:r s0085CreateAuthorizationAutoPay.sql
:r s0086GetActiveAuthorization.sql
:r s0087ScheduleAutoPay.sql
:r s0088GetDuePayments.sql
:r s0089RecordAutoPayAttempt.sql
:r s0090RevokeAuthorization.sql
:r s0091GetUpcomingPreavis24h.sql
:r s0092GetUpcomingPadPreavis3Days.sql
:r s0093GetMonthlyTotalForParty.sql
:r s0094GetAutoPayHistory.sql
:r s0095CancelScheduledAutoPay.sql

PRINT '';
PRINT '=== Phase 1 AutoPay - Deploiement termine ===';
GO

-- Validation finale : compter les objets crees
SELECT
    (SELECT COUNT(*) FROM sys.tables WHERE name IN ('T144AuthorizationAutoPay','T145AutoPayAttempt')) AS TablesCreated,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'T060Document'
        AND COLUMN_NAME IN ('AutoPay','AutoPayDate','AutoPayStatus','AutoPayAttempts',
                            'AutoPayAuthorizationId','AutoPayPreavisSentDate','AutoPayPadPreavisSentDate')) AS T060ColumnsAdded,
    (SELECT COUNT(*) FROM sys.procedures WHERE name IN
        ('s0085CreateAuthorizationAutoPay','s0086GetActiveAuthorization','s0087ScheduleAutoPay',
         's0088GetDuePayments','s0089RecordAutoPayAttempt','s0090RevokeAuthorization',
         's0091GetUpcomingPreavis24h','s0091bMarkPreavisSent',
         's0092GetUpcomingPadPreavis3Days','s0092bMarkPadPreavisSent',
         's0093GetMonthlyTotalForParty','s0094GetAutoPayHistory','s0095CancelScheduledAutoPay')) AS ProceduresCreated;
GO
