-- =============================================================================
-- DEMO_CreateAndSnapshot.sql
-- Definit dbo.s0709SnapshotDemoCompany(@CompanyGUID) PUIS capture le cliche des
-- 3 compagnies de demonstration (dbo.fnDemoCompanies()).
--
-- Les tables DEMO_* contiennent le cliche fige des 3 demos A LA FOIS (chaque
-- ligne garde son CompanyGUID). La proc capture UNE demo a la fois :
--   DEMO_T := (lignes DEMO_T des AUTRES demos)  +  (lignes vivantes de @CompanyGUID)
-- => on peut peaufiner UNE demo dans l'application puis recapturer SEULEMENT
--    celle-la, sans figer l'etat courant des autres.
--
-- GARDE : @CompanyGUID doit figurer dans dbo.fnDemoCompanies() (liste blanche).
-- La proc s0708ResetDemoCompany restaure une demo a partir de ces tables.
-- Prerequis : dbo.fnDemoCompanies() doit exister (fnDemoCompanies.sql).
-- =============================================================================
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0709SnapshotDemoCompany
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @d UNIQUEIDENTIFIER = @CompanyGUID;

    IF NOT EXISTS (SELECT 1 FROM dbo.fnDemoCompanies() WHERE CompanyGUID = @d)
    BEGIN
        RAISERROR('Refus : cette compagnie n''est pas une demo (liste blanche fnDemoCompanies).', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @d)
    BEGIN
        RAISERROR('Compagnie demo introuvable.', 16, 1);
        RETURN;
    END

    -- (table, portee sur les tables VIVANTes, portee sur les tables DEMO_)
    DECLARE @list TABLE (ord INT, tbl SYSNAME, live NVARCHAR(1000), demo NVARCHAR(1000));
    INSERT INTO @list (ord, tbl, live, demo) VALUES
     (0 ,'T010Company'             ,'CompanyGUID = @d','CompanyGUID = @d'),
     (1 ,'T015User'                ,'CompanyGUID = @d','CompanyGUID = @d'),
     (2 ,'T300Employees'           ,'CompanyGUID = @d','CompanyGUID = @d'),
     (3 ,'T020Subscription'        ,'CompanyGUID = @d','CompanyGUID = @d'),
     (4 ,'Appointments'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (5 ,'T0001Receipt'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (6 ,'T200JobDefinition'       ,'CompanyGUID = @d','CompanyGUID = @d'),
     (7 ,'T201JobSchedule'         ,'CompanyGUID = @d','CompanyGUID = @d'),
     (8 ,'T202JobExecution'        ,'CompanyGUID = @d','CompanyGUID = @d'),
     (9 ,'T204JobPlanned'          ,'CompanyGUID = @d','CompanyGUID = @d'),
     (10,'T203JobLog'              ,'JobExecutionId IN (SELECT Id FROM dbo.T202JobExecution WHERE CompanyGUID = @d)','JobExecutionId IN (SELECT Id FROM dbo.DEMO_T202JobExecution WHERE CompanyGUID = @d)'),
     (11,'T143PlaidAccount'        ,'CompanyGUID = @d','CompanyGUID = @d'),
     (12,'T144PlaidSyncLog'        ,'CompanyGUID = @d','CompanyGUID = @d'),
     (13,'T144AuthorizationAutoPay','CompanyGUID = @d','CompanyGUID = @d'),
     (14,'T145AutoPayAttempt'      ,'CompanyGUID = @d','CompanyGUID = @d'),
     (15,'T050Party'              ,'CompanyGUID = @d','CompanyGUID = @d'),
     (16,'T054PartyAddress'        ,'PartyId IN (SELECT Id FROM dbo.T050Party WHERE CompanyGUID = @d)','PartyId IN (SELECT Id FROM dbo.DEMO_T050Party WHERE CompanyGUID = @d)'),
     (17,'T068TaxeStatus'          ,'CompanyGUID = @d','CompanyGUID = @d'),
     (18,'T069TaxeRate'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (19,'T070RapportTaxe'         ,'CompanyGUID = @d','CompanyGUID = @d'),
     (20,'T076ProductCategory'     ,'CompanyGUID = @d','CompanyGUID = @d'),
     (21,'T075Products'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (22,'T100ParamComptable'      ,'CompanyGUID = @d','CompanyGUID = @d'),
     (23,'T101ParamValues'         ,'CompanyGUID = @d OR T100Id IN (SELECT Id FROM dbo.T100ParamComptable WHERE CompanyGUID = @d)','CompanyGUID = @d OR T100Id IN (SELECT Id FROM dbo.DEMO_T100ParamComptable WHERE CompanyGUID = @d)'),
     (24,'T120PlanComptable_Classe','CompanyGUID = @d','CompanyGUID = @d'),
     (25,'T121PlanComptable'       ,'CompanyGUID = @d','CompanyGUID = @d'),
     (26,'T111Exercices'           ,'CompanyGUID = @d','CompanyGUID = @d'),
     (27,'T112Periodes'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (28,'T130Journaux'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (29,'T138EcrituresTemplate'   ,'CompanyGUID = @d','CompanyGUID = @d'),
     (30,'T139TemplateLignes'      ,'TemplateId IN (SELECT Id FROM dbo.T138EcrituresTemplate WHERE CompanyGUID = @d)','TemplateId IN (SELECT Id FROM dbo.DEMO_T138EcrituresTemplate WHERE CompanyGUID = @d)'),
     (31,'T135Ecritures'           ,'CompanyGUID = @d','CompanyGUID = @d'),
     (32,'T136LignesEcriture'      ,'EcrituresId IN (SELECT Id FROM dbo.T135Ecritures WHERE CompanyGUID = @d)','EcrituresId IN (SELECT Id FROM dbo.DEMO_T135Ecritures WHERE CompanyGUID = @d)'),
     (33,'T140Reglement'           ,'CompanyGUID = @d','CompanyGUID = @d'),
     (34,'T142ReleveBancaire'      ,'CompanyGUID = @d','CompanyGUID = @d'),
     (35,'T060Document'            ,'CompanyGUID = @d','CompanyGUID = @d'),
     (36,'T062DocumentNumberCounter','CompanyGUID = @d','CompanyGUID = @d'),
     (37,'T061DocumentLine'        ,'DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d)','DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d)'),
     (38,'T062DocumentAddress'     ,'DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d)','DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d)'),
     (39,'T137DocumentEcriture'    ,'CompanyGUID = @d','CompanyGUID = @d'),
     (40,'T141ReglementDocument'   ,'DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d) OR ReglementId IN (SELECT Id FROM dbo.T140Reglement WHERE CompanyGUID = @d)','DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d) OR ReglementId IN (SELECT Id FROM dbo.DEMO_T140Reglement WHERE CompanyGUID = @d)'),
     (41,'T071_T061DocumentLine_T070RapportTaxe','T061DocumentLine_id IN (SELECT Id FROM dbo.T061DocumentLine WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d))','T061DocumentLine_id IN (SELECT Id FROM dbo.DEMO_T061DocumentLine WHERE DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d))');

    DECLARE @t SYSNAME, @live NVARCHAR(1000), @demo NVARCHAR(1000), @sql NVARCHAR(MAX);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT tbl, live, demo FROM @list ORDER BY ord;
    OPEN cur; FETCH NEXT FROM cur INTO @t, @live, @demo;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- DEMO_ := (autres demos, conservees) + (lignes vivantes de @d, rafraichies)
        SET @sql =
            N'IF OBJECT_ID(''dbo.DEMO_' + @t + ''') IS NULL SELECT * INTO dbo.DEMO_' + @t + N' FROM dbo.' + @t + N' WHERE 1=0;'
          + N'SELECT * INTO #z FROM (SELECT * FROM dbo.DEMO_' + @t + N' WHERE NOT(' + @demo + N')'
          + N' UNION ALL SELECT * FROM dbo.' + @t + N' WHERE ' + @live + N') q;'
          + N'DROP TABLE dbo.DEMO_' + @t + N'; SELECT * INTO dbo.DEMO_' + @t + N' FROM #z; DROP TABLE #z;';
        EXEC sp_executesql @sql, N'@d UNIQUEIDENTIFIER', @d = @d;
        FETCH NEXT FROM cur INTO @t, @live, @demo;
    END
    CLOSE cur; DEALLOCATE cur;

    SELECT 'OK' AS Result, 'Cliche demo recapture.' AS Message;
END
GO

-- Bootstrap : capturer le cliche des 3 demos (Cronus + les 2 clones)
DECLARE @g UNIQUEIDENTIFIER;
DECLARE cg CURSOR LOCAL FAST_FORWARD FOR SELECT CompanyGUID FROM dbo.fnDemoCompanies();
OPEN cg; FETCH NEXT FROM cg INTO @g;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.s0709SnapshotDemoCompany @g;
    FETCH NEXT FROM cg INTO @g;
END
CLOSE cg; DEALLOCATE cg;
GO
