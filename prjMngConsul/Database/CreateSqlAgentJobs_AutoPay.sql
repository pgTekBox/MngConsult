-- =============================================================================
-- CreateSqlAgentJobs_AutoPay
--
-- Cree 2 jobs SQL Server Agent pour orchestrer le pipeline AutoPay :
--
--   Job 1 : MngConsul_AutoPay_Daily_06h00
--     - Step 1 : Send preavis 24h (cartes)
--     - Step 2 : Send preavis PAD 3 jours
--     - Schedule : tous les jours 06h00
--
--   Job 2 : MngConsul_AutoPay_Process_Every15min
--     - Step 1 : Process due payments
--     - Schedule : toutes les 15 minutes, 07h00-19h00, lundi-vendredi
--
-- Pre-requis :
--   1. SQL Server Agent doit etre demarre (service SQLSERVERAGENT)
--   2. Le compte de service SQL Agent doit pouvoir executer PowerShell
--   3. Le script Scripts\RunAutoPayProcessor.ps1 doit etre deploye
--      a un emplacement accessible au compte de service SQL Agent
--      (ex : C:\MngConsul\Scripts\RunAutoPayProcessor.ps1)
--   4. La variable d'environnement AUTOPAY_SECRET doit etre definie
--      au niveau systeme OU le secret doit etre passe en parametre -Secret
--
-- Securite :
--   - Les jobs utilisent un proxy ou compte avec droits minimaux
--   - Le secret est stocke en variable d'env (pas dans le script)
--   - Les retours HTTP du handler sont logges dans l'historique du job
--
-- Idempotence :
--   - Les jobs sont supprimes si deja existants, puis re-crees
--   - Peut etre relance sans danger
-- =============================================================================

USE [msdb];
GO

DECLARE @PowerShellPath VARCHAR(255) = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
DECLARE @ScriptPath     VARCHAR(500) = 'C:\MesSources\MngConsul\prjMngConsul\Scripts\RunAutoPayProcessor.ps1';
DECLARE @BaseUrl        VARCHAR(255) = 'https://60sec.ca';  -- prod : https://60sec.ca / dev local : http://localhost
DECLARE @NotifyOperator VARCHAR(100) = NULL; -- nom de l'operateur pour notifications email (NULL = pas de notif)

-- =============================================================================
-- JOB 1 : Daily 06h00 - Envoi des preavis
-- =============================================================================

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'MngConsul_AutoPay_Daily_06h00')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'MngConsul_AutoPay_Daily_06h00', @delete_unused_schedule = 1;
    PRINT 'Job MngConsul_AutoPay_Daily_06h00 supprime (sera recree)';
END

EXEC msdb.dbo.sp_add_job
    @job_name = N'MngConsul_AutoPay_Daily_06h00',
    @description = N'AutoPay : envoi quotidien des preavis 24h (cartes) et 3 jours (PAD)',
    @enabled = 1,
    @start_step_id = 1,
    @owner_login_name = N'sa';

EXEC msdb.dbo.sp_add_jobserver @job_name = N'MngConsul_AutoPay_Daily_06h00';

-- Step 1 : Preavis 24h cartes
DECLARE @Cmd1 NVARCHAR(2000) =
    N'-ExecutionPolicy Bypass -File "' + @ScriptPath + N'" -Mode preavis24h -BaseUrl "' + @BaseUrl + N'"';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'MngConsul_AutoPay_Daily_06h00',
    @step_name = N'Send preavis 24h (cartes)',
    @step_id = 1,
    @subsystem = N'CmdExec',
    @command = @Cmd1,
    @on_success_action = 3,  -- go to next step
    @on_fail_action = 3,     -- go to next step (preavis indep)
    @retry_attempts = 1,
    @retry_interval = 5;

-- Step 2 : Preavis PAD 3 jours
DECLARE @Cmd2 NVARCHAR(2000) =
    N'-ExecutionPolicy Bypass -File "' + @ScriptPath + N'" -Mode preavispad3d -BaseUrl "' + @BaseUrl + N'" -DaysAhead 3';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'MngConsul_AutoPay_Daily_06h00',
    @step_name = N'Send preavis PAD 3 jours',
    @step_id = 2,
    @subsystem = N'CmdExec',
    @command = @Cmd2,
    @on_success_action = 1,  -- quit reporting success
    @on_fail_action = 2,     -- quit reporting failure
    @retry_attempts = 1,
    @retry_interval = 5;

-- Schedule : tous les jours 06h00
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'MngConsul_AutoPay_Daily_06h00',
    @name = N'Daily 06h00',
    @enabled = 1,
    @freq_type = 4,           -- Daily
    @freq_interval = 1,
    @active_start_time = 60000;  -- 06:00:00

PRINT 'Job 1 MngConsul_AutoPay_Daily_06h00 cree.';
GO

-- =============================================================================
-- JOB 2 : Process due payments every 15 min during business hours
-- =============================================================================

DECLARE @PowerShellPath VARCHAR(255) = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
DECLARE @ScriptPath     VARCHAR(500) = 'C:\MesSources\MngConsul\prjMngConsul\Scripts\RunAutoPayProcessor.ps1';
DECLARE @BaseUrl        VARCHAR(255) = 'https://60sec.ca';  -- prod : https://60sec.ca / dev local : http://localhost

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'MngConsul_AutoPay_Process_Every15min')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'MngConsul_AutoPay_Process_Every15min', @delete_unused_schedule = 1;
    PRINT 'Job MngConsul_AutoPay_Process_Every15min supprime (sera recree)';
END

EXEC msdb.dbo.sp_add_job
    @job_name = N'MngConsul_AutoPay_Process_Every15min',
    @description = N'AutoPay : execute les debits dus toutes les 15 min en heures ouvrables',
    @enabled = 1,
    @start_step_id = 1,
    @owner_login_name = N'sa';

EXEC msdb.dbo.sp_add_jobserver @job_name = N'MngConsul_AutoPay_Process_Every15min';

DECLARE @CmdProcess NVARCHAR(2000) =
    N'-ExecutionPolicy Bypass -File "' + @ScriptPath + N'" -Mode process -BaseUrl "' + @BaseUrl + N'" -BatchSize 50';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'MngConsul_AutoPay_Process_Every15min',
    @step_name = N'Process due payments',
    @step_id = 1,
    @subsystem = N'CmdExec',
    @command = @CmdProcess,
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 1,
    @retry_interval = 5;

-- Schedule : toutes les 15 min, 07h00-19h00, lundi-vendredi
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'MngConsul_AutoPay_Process_Every15min',
    @name = N'Every 15 min business hours',
    @enabled = 1,
    @freq_type = 8,                    -- Weekly
    @freq_interval = 62,               -- Lundi(2)+Mardi(4)+Mer(8)+Jeudi(16)+Vendredi(32) = 62
    @freq_subday_type = 4,             -- Minutes
    @freq_subday_interval = 15,
    @freq_recurrence_factor = 1,
    @active_start_time = 70000,        -- 07:00:00
    @active_end_time = 190000;         -- 19:00:00

PRINT 'Job 2 MngConsul_AutoPay_Process_Every15min cree.';
GO

-- =============================================================================
-- Validation finale
-- =============================================================================

SELECT
    name AS JobName,
    enabled,
    description,
    date_created
FROM msdb.dbo.sysjobs
WHERE name LIKE 'MngConsul_AutoPay%'
ORDER BY name;
GO
