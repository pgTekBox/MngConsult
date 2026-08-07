SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0708ResetDemoCompany  (@CompanyGUID)
-- Reinitialise UNE compagnie de demonstration a partir du cliche DEMO_* :
--   1) supprime ses donnees vivantes (ordre enfants -> parents),
--   2) reinsere depuis DEMO_* FILTRE sur @CompanyGUID (parents -> enfants,
--      avec IDENTITY_INSERT),
--   3) restaure les champs de T010Company (UPDATE, la ligne n'est jamais supprimee).
-- GARDE : @CompanyGUID doit figurer dans dbo.fnDemoCompanies() (liste blanche),
-- sinon la proc refuse d'agir -> une vraie compagnie ne peut jamais etre touchee.
-- Transactionnel (XACT_ABORT + TRY/CATCH). Appelee depuis la console Admin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0708ResetDemoCompany
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @d UNIQUEIDENTIFIER = @CompanyGUID;

    IF NOT EXISTS (SELECT 1 FROM dbo.fnDemoCompanies() WHERE CompanyGUID = @d)
    BEGIN
        RAISERROR('Refus : cette compagnie n''est pas une demo (liste blanche fnDemoCompanies).', 16, 1);
        RETURN;
    END
    IF OBJECT_ID('dbo.DEMO_T010Company') IS NULL
    BEGIN
        RAISERROR('Cliche demo absent : executer d''abord DEMO_CreateAndSnapshot.sql.', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @d)
    BEGIN
        RAISERROR('Compagnie demo introuvable.', 16, 1);
        RETURN;
    END

    DECLARE @t SYSNAME, @scope NVARCHAR(1000), @cols NVARCHAR(MAX), @sql NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRAN;

        -- ================= 1) SUPPRESSION (enfants -> parents) =================
        DELETE FROM dbo.T071_T061DocumentLine_T070RapportTaxe
        WHERE T061DocumentLine_id IN (SELECT Id FROM dbo.T061DocumentLine
              WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d));
        DELETE FROM dbo.T061DocumentLine
        WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d);
        DELETE FROM dbo.T062DocumentAddress
        WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d);
        DELETE FROM dbo.T141ReglementDocument
        WHERE DocumentId  IN (SELECT Id FROM dbo.T060Document  WHERE CompanyGUID = @d)
           OR ReglementId IN (SELECT Id FROM dbo.T140Reglement WHERE CompanyGUID = @d);
        DELETE FROM dbo.T137DocumentEcriture      WHERE CompanyGUID = @d;
        DELETE FROM dbo.T062DocumentNumberCounter WHERE CompanyGUID = @d;
        DELETE FROM dbo.T060Document              WHERE CompanyGUID = @d;

        DELETE FROM dbo.T136LignesEcriture
        WHERE EcrituresId IN (SELECT Id FROM dbo.T135Ecritures WHERE CompanyGUID = @d);
        DELETE FROM dbo.T139TemplateLignes
        WHERE TemplateId IN (SELECT Id FROM dbo.T138EcrituresTemplate WHERE CompanyGUID = @d);
        DELETE FROM dbo.T142ReleveBancaire        WHERE CompanyGUID = @d;
        DELETE FROM dbo.T140Reglement             WHERE CompanyGUID = @d;
        DELETE FROM dbo.T135Ecritures             WHERE CompanyGUID = @d;
        DELETE FROM dbo.T138EcrituresTemplate     WHERE CompanyGUID = @d;
        DELETE FROM dbo.T130Journaux              WHERE CompanyGUID = @d;
        DELETE FROM dbo.T112Periodes              WHERE CompanyGUID = @d;
        DELETE FROM dbo.T111Exercices             WHERE CompanyGUID = @d;
        DELETE FROM dbo.T121PlanComptable         WHERE CompanyGUID = @d;
        DELETE FROM dbo.T120PlanComptable_Classe  WHERE CompanyGUID = @d;

        DELETE FROM dbo.T075Products              WHERE CompanyGUID = @d;
        DELETE FROM dbo.T076ProductCategory       WHERE CompanyGUID = @d;
        DELETE FROM dbo.T069TaxeRate              WHERE CompanyGUID = @d;
        DELETE FROM dbo.T070RapportTaxe           WHERE CompanyGUID = @d;
        DELETE FROM dbo.T068TaxeStatus            WHERE CompanyGUID = @d;

        DELETE FROM dbo.T054PartyAddress
        WHERE PartyId IN (SELECT Id FROM dbo.T050Party WHERE CompanyGUID = @d);
        DELETE FROM dbo.T050Party                 WHERE CompanyGUID = @d;

        DELETE FROM dbo.T145AutoPayAttempt        WHERE CompanyGUID = @d;
        DELETE FROM dbo.T144AuthorizationAutoPay  WHERE CompanyGUID = @d;
        DELETE FROM dbo.T144PlaidSyncLog          WHERE CompanyGUID = @d;
        DELETE FROM dbo.T143PlaidAccount          WHERE CompanyGUID = @d;

        DELETE FROM dbo.T203JobLog
        WHERE JobExecutionId IN (SELECT Id FROM dbo.T202JobExecution WHERE CompanyGUID = @d);
        DELETE FROM dbo.T204JobPlanned            WHERE CompanyGUID = @d;
        DELETE FROM dbo.T202JobExecution          WHERE CompanyGUID = @d;
        DELETE FROM dbo.T201JobSchedule           WHERE CompanyGUID = @d;
        DELETE FROM dbo.T200JobDefinition         WHERE CompanyGUID = @d;

        DELETE FROM dbo.T101ParamValues
        WHERE CompanyGUID = @d
           OR T100Id IN (SELECT Id FROM dbo.T100ParamComptable WHERE CompanyGUID = @d);
        DELETE FROM dbo.T100ParamComptable        WHERE CompanyGUID = @d;

        DELETE FROM dbo.T0001Receipt              WHERE CompanyGUID = @d;
        DELETE FROM dbo.Appointments              WHERE CompanyGUID = @d;
        DELETE FROM dbo.T020Subscription          WHERE CompanyGUID = @d;
        DELETE FROM dbo.T300Employees             WHERE CompanyGUID = @d;
        DELETE FROM dbo.T015User                  WHERE CompanyGUID = @d;

        -- ================= 2) REINSERTION (parents -> enfants, filtree @d) =====
        -- (table, predicat de portee sur DEMO_* pour ne reinserer QUE @d)
        DECLARE curIns CURSOR LOCAL FAST_FORWARD FOR
            SELECT tbl, scope FROM (VALUES
             (1 ,'T015User'                ,'CompanyGUID = @d'),
             (2 ,'T300Employees'           ,'CompanyGUID = @d'),
             (3 ,'T020Subscription'        ,'CompanyGUID = @d'),
             (4 ,'Appointments'            ,'CompanyGUID = @d'),
             (5 ,'T0001Receipt'            ,'CompanyGUID = @d'),
             (6 ,'T200JobDefinition'       ,'CompanyGUID = @d'),
             (7 ,'T201JobSchedule'         ,'CompanyGUID = @d'),
             (8 ,'T202JobExecution'        ,'CompanyGUID = @d'),
             (9 ,'T204JobPlanned'          ,'CompanyGUID = @d'),
             (10,'T203JobLog'              ,'JobExecutionId IN (SELECT Id FROM dbo.DEMO_T202JobExecution WHERE CompanyGUID = @d)'),
             (11,'T143PlaidAccount'        ,'CompanyGUID = @d'),
             (12,'T144PlaidSyncLog'        ,'CompanyGUID = @d'),
             (13,'T144AuthorizationAutoPay','CompanyGUID = @d'),
             (14,'T145AutoPayAttempt'      ,'CompanyGUID = @d'),
             (15,'T050Party'              ,'CompanyGUID = @d'),
             (16,'T054PartyAddress'        ,'PartyId IN (SELECT Id FROM dbo.DEMO_T050Party WHERE CompanyGUID = @d)'),
             (17,'T068TaxeStatus'          ,'CompanyGUID = @d'),
             (18,'T069TaxeRate'            ,'CompanyGUID = @d'),
             (19,'T070RapportTaxe'         ,'CompanyGUID = @d'),
             (20,'T076ProductCategory'     ,'CompanyGUID = @d'),
             (21,'T075Products'            ,'CompanyGUID = @d'),
             (22,'T100ParamComptable'      ,'CompanyGUID = @d'),
             (23,'T101ParamValues'         ,'CompanyGUID = @d OR T100Id IN (SELECT Id FROM dbo.DEMO_T100ParamComptable WHERE CompanyGUID = @d)'),
             (24,'T120PlanComptable_Classe','CompanyGUID = @d'),
             (25,'T121PlanComptable'       ,'CompanyGUID = @d'),
             (26,'T111Exercices'           ,'CompanyGUID = @d'),
             (27,'T112Periodes'            ,'CompanyGUID = @d'),
             (28,'T130Journaux'            ,'CompanyGUID = @d'),
             (29,'T138EcrituresTemplate'   ,'CompanyGUID = @d'),
             (30,'T139TemplateLignes'      ,'TemplateId IN (SELECT Id FROM dbo.DEMO_T138EcrituresTemplate WHERE CompanyGUID = @d)'),
             (31,'T135Ecritures'           ,'CompanyGUID = @d'),
             (32,'T136LignesEcriture'      ,'EcrituresId IN (SELECT Id FROM dbo.DEMO_T135Ecritures WHERE CompanyGUID = @d)'),
             (33,'T140Reglement'           ,'CompanyGUID = @d'),
             (34,'T142ReleveBancaire'      ,'CompanyGUID = @d'),
             (35,'T060Document'            ,'CompanyGUID = @d'),
             (36,'T062DocumentNumberCounter','CompanyGUID = @d'),
             (37,'T061DocumentLine'        ,'DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d)'),
             (38,'T062DocumentAddress'     ,'DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d)'),
             (39,'T137DocumentEcriture'    ,'CompanyGUID = @d'),
             (40,'T141ReglementDocument'   ,'DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d) OR ReglementId IN (SELECT Id FROM dbo.DEMO_T140Reglement WHERE CompanyGUID = @d)'),
             (41,'T071_T061DocumentLine_T070RapportTaxe','T061DocumentLine_id IN (SELECT Id FROM dbo.DEMO_T061DocumentLine WHERE DocumentId IN (SELECT Id FROM dbo.DEMO_T060Document WHERE CompanyGUID = @d))')
            ) v(ord, tbl, scope)
            ORDER BY ord;
        OPEN curIns;
        FETCH NEXT FROM curIns INTO @t, @scope;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF OBJECT_ID('dbo.DEMO_' + @t) IS NOT NULL
            BEGIN
                SELECT @cols = STRING_AGG(QUOTENAME(c.name), ',') WITHIN GROUP (ORDER BY c.column_id)
                FROM sys.columns c
                JOIN sys.types ty ON ty.user_type_id = c.user_type_id
                WHERE c.object_id = OBJECT_ID('dbo.' + @t)
                  AND c.is_computed = 0 AND ty.name <> 'timestamp';

                SET @sql = N'';
                IF OBJECTPROPERTY(OBJECT_ID('dbo.' + @t), 'TableHasIdentity') = 1
                    SET @sql = @sql + N'SET IDENTITY_INSERT dbo.' + @t + N' ON;';
                SET @sql = @sql + N'INSERT INTO dbo.' + @t + N' (' + @cols + N') '
                                + N'SELECT ' + @cols + N' FROM dbo.DEMO_' + @t + N' WHERE ' + @scope + N';';
                IF OBJECTPROPERTY(OBJECT_ID('dbo.' + @t), 'TableHasIdentity') = 1
                    SET @sql = @sql + N'SET IDENTITY_INSERT dbo.' + @t + N' OFF;';

                EXEC sp_executesql @sql, N'@d UNIQUEIDENTIFIER', @d = @d;
            END
            FETCH NEXT FROM curIns INTO @t, @scope;
        END
        CLOSE curIns; DEALLOCATE curIns;

        -- ================= 3) RESTAURATION de T010Company (UPDATE) =================
        DECLARE @setcols NVARCHAR(MAX);
        SELECT @setcols = STRING_AGG('t.' + QUOTENAME(c.name) + ' = s.' + QUOTENAME(c.name), ',')
        FROM sys.columns c
        JOIN sys.types ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = OBJECT_ID('dbo.T010Company')
          AND c.is_computed = 0 AND ty.name <> 'timestamp'
          AND c.name NOT IN ('Id', 'CompanyGUID');

        SET @sql = N'UPDATE t SET ' + @setcols
                 + N' FROM dbo.T010Company t JOIN dbo.DEMO_T010Company s ON s.CompanyGUID = t.CompanyGUID'
                 + N' WHERE t.CompanyGUID = @d;';
        EXEC sp_executesql @sql, N'@d UNIQUEIDENTIFIER', @d = @d;

        COMMIT TRAN;
        SELECT 'OK' AS Result, 'Demo reinitialisee.' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        DECLARE @msg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR('Echec reset demo : %s', 16, 1, @msg);
    END CATCH
END
GO
