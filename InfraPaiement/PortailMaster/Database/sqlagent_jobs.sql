/* =====================================================================
   60secPaiement - Jobs SQL Server Agent (a executer par un ADMIN sysadmin)
   ---------------------------------------------------------------------
   Cree 3 taches planifiees :
     1. 60secPaiement_ReglementQuotidien  (T-SQL, quotidien 22:00)
        -> EXEC dbo.s0056RunDailySettlement  [reglement SIMULE des echeances]
     2. 60secPaiement_GenerationLotEFT     (T-SQL, quotidien 06:00)
        -> EXEC dbo.s0057AutoGenerateBatch  [genere le lot du jour]
     3. 60secPaiement_Webhooks             (PowerShell, toutes les 2 min)
        -> POST WebhookDispatcher.ashx      [vide la file de webhooks]

   AVANT D'EXECUTER : remplacer <HOST_PORTAIL> et <DISPATCH_SECRET> ci-dessous.
   Prerequis : SQL Server Agent demarre ; sous-systeme PowerShell disponible.
   ===================================================================== */

DECLARE @DbName     SYSNAME       = N'60secPaiement';
DECLARE @PortailUrl NVARCHAR(300) = N'https://<HOST_PORTAIL>/WebhookDispatcher.ashx?max=200';
DECLARE @Secret     NVARCHAR(100) = N'<DISPATCH_SECRET>';   -- = Web.config Webhook.DispatchSecret

/* --------- 1) Reglement quotidien --------- */
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'60secPaiement_ReglementQuotidien')
BEGIN
    EXEC msdb.dbo.sp_add_job @job_name = N'60secPaiement_ReglementQuotidien', @enabled = 1,
        @description = N'Reglement simule des echeances EFT (entrant + sortant).';
    EXEC msdb.dbo.sp_add_jobstep @job_name = N'60secPaiement_ReglementQuotidien',
        @step_name = N'Regler', @subsystem = N'TSQL', @database_name = @DbName,
        @command = N'EXEC dbo.s0056RunDailySettlement;';
    EXEC msdb.dbo.sp_add_schedule @schedule_name = N'60sec_Quotidien_22h',
        @freq_type = 4, @freq_interval = 1, @active_start_time = 220000;   -- tous les jours 22:00
    EXEC msdb.dbo.sp_attach_schedule @job_name = N'60secPaiement_ReglementQuotidien', @schedule_name = N'60sec_Quotidien_22h';
    EXEC msdb.dbo.sp_add_jobserver @job_name = N'60secPaiement_ReglementQuotidien';
END

/* --------- 2) Generation du lot EFT --------- */
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'60secPaiement_GenerationLotEFT')
BEGIN
    EXEC msdb.dbo.sp_add_job @job_name = N'60secPaiement_GenerationLotEFT', @enabled = 1,
        @description = N'Generation du lot EFT (CPA-005) a partir des transactions initiees.';
    EXEC msdb.dbo.sp_add_jobstep @job_name = N'60secPaiement_GenerationLotEFT',
        @step_name = N'Generer', @subsystem = N'TSQL', @database_name = @DbName,
        @command = N'EXEC dbo.s0057AutoGenerateBatch;';
    EXEC msdb.dbo.sp_add_schedule @schedule_name = N'60sec_Quotidien_06h',
        @freq_type = 4, @freq_interval = 1, @active_start_time = 060000;
    EXEC msdb.dbo.sp_attach_schedule @job_name = N'60secPaiement_GenerationLotEFT', @schedule_name = N'60sec_Quotidien_06h';
    EXEC msdb.dbo.sp_add_jobserver @job_name = N'60secPaiement_GenerationLotEFT';
END

/* --------- 3) Dispatch des webhooks (toutes les 2 min) --------- */
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'60secPaiement_Webhooks')
BEGIN
    DECLARE @psCmd NVARCHAR(1000) = N'$ProgressPreference=''SilentlyContinue''; try { Invoke-WebRequest -Uri ''' + @PortailUrl + N''' -Method POST -Headers @{''X-Dispatch-Secret''=''' + @Secret + N'''} -UseBasicParsing -TimeoutSec 60 | Out-Null } catch { exit 1 }';
    EXEC msdb.dbo.sp_add_job @job_name = N'60secPaiement_Webhooks', @enabled = 1,
        @description = N'Vide la file de webhooks (POST signe vers les abonnes).';
    EXEC msdb.dbo.sp_add_jobstep @job_name = N'60secPaiement_Webhooks',
        @step_name = N'Dispatch', @subsystem = N'PowerShell', @command = @psCmd;
    EXEC msdb.dbo.sp_add_schedule @schedule_name = N'60sec_2min',
        @freq_type = 4, @freq_interval = 1,
        @freq_subday_type = 4, @freq_subday_interval = 2;   -- toutes les 2 minutes
    EXEC msdb.dbo.sp_attach_schedule @job_name = N'60secPaiement_Webhooks', @schedule_name = N'60sec_2min';
    EXEC msdb.dbo.sp_add_jobserver @job_name = N'60secPaiement_Webhooks';
END
GO

PRINT N'Jobs SQL Agent crees (verifier <HOST_PORTAIL> / <DISPATCH_SECRET>).';
GO
