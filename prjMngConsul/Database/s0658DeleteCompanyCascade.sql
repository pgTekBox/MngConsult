SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0658DeleteCompanyCascade
-- Supprime DÉFINITIVEMENT une compagnie et toutes ses données rattachées
-- (suppression "fonctionnelle" : tables du modèle vivant uniquement).
--
-- NE TOUCHE PAS aux tables legacy/backup (T121PlanComptable_BCK,
-- T121PlanComptableold, AppointmentTypesTodel) ni aux référentiels partagés.
--
-- Ordre : enfants -> parents. Tout est dans une transaction : en cas d'erreur,
-- ROLLBACK complet. Retourne un journal (table + nb de lignes supprimées).
--
-- ⚠ OPÉRATION IRRÉVERSIBLE. Faire une sauvegarde avant utilisation en prod.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0658DeleteCompanyCascade
    @CompanyGUID UNIQUEIDENTIFIER,
    @ModifiedBy  NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ------------------------------------------------------------------
    -- Garde-fous
    ------------------------------------------------------------------
    IF @CompanyGUID IS NULL OR @CompanyGUID = '00000000-0000-0000-0000-000000000000'
    BEGIN
        RAISERROR('CompanyGUID invalide.', 16, 1);
        RETURN;
    END

    IF @CompanyGUID = '00000000-0000-0000-0000-000000000001'
    BEGIN
        RAISERROR('Suppression de la compagnie modèle (Template) interdite.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID)
    BEGIN
        RAISERROR('Compagnie introuvable.', 16, 1);
        RETURN;
    END

    DECLARE @log TABLE (StepNo INT IDENTITY(1,1), TableName SYSNAME, RowsDeleted INT);

    BEGIN TRY
        BEGIN TRAN;

        -- ===================== DOCUMENTS =====================
        DELETE FROM dbo.T071_T061DocumentLine_T070RapportTaxe
        WHERE T061DocumentLine_id IN (
            SELECT Id FROM dbo.T061DocumentLine
            WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @CompanyGUID));
        INSERT @log VALUES ('T071_T061DocumentLine_T070RapportTaxe', @@ROWCOUNT);

        DELETE FROM dbo.T061DocumentLine
        WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T061DocumentLine', @@ROWCOUNT);

        DELETE FROM dbo.T062DocumentAddress
        WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T062DocumentAddress', @@ROWCOUNT);

        DELETE FROM dbo.T141ReglementDocument
        WHERE DocumentId  IN (SELECT Id FROM dbo.T060Document  WHERE CompanyGUID = @CompanyGUID)
           OR ReglementId IN (SELECT Id FROM dbo.T140Reglement WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T141ReglementDocument', @@ROWCOUNT);

        DELETE FROM dbo.T137DocumentEcriture WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T137DocumentEcriture', @@ROWCOUNT);

        DELETE FROM dbo.T060Document WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T060Document', @@ROWCOUNT);

        -- ===================== COMPTABILITÉ =====================
        DELETE FROM dbo.T136LignesEcriture
        WHERE EcrituresId IN (SELECT Id FROM dbo.T135Ecritures WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T136LignesEcriture', @@ROWCOUNT);

        DELETE FROM dbo.T139TemplateLignes
        WHERE TemplateId IN (SELECT Id FROM dbo.T138EcrituresTemplate WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T139TemplateLignes', @@ROWCOUNT);

        DELETE FROM dbo.T142ReleveBancaire WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T142ReleveBancaire', @@ROWCOUNT);

        DELETE FROM dbo.T140Reglement WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T140Reglement', @@ROWCOUNT);

        DELETE FROM dbo.T135Ecritures WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T135Ecritures', @@ROWCOUNT);

        DELETE FROM dbo.T138EcrituresTemplate WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T138EcrituresTemplate', @@ROWCOUNT);

        DELETE FROM dbo.T130Journaux WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T130Journaux', @@ROWCOUNT);

        DELETE FROM dbo.T112Periodes WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T112Periodes', @@ROWCOUNT);

        DELETE FROM dbo.T111Exercices WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T111Exercices', @@ROWCOUNT);

        DELETE FROM dbo.T121PlanComptable WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T121PlanComptable', @@ROWCOUNT);

        DELETE FROM dbo.T120PlanComptable_Classe WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T120PlanComptable_Classe', @@ROWCOUNT);

        -- (Les paramètres comptables T100/T101 sont supprimés plus bas, T101 avant T100.)

        -- ===================== PRODUITS & TAXES =====================
        DELETE FROM dbo.T075Products WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T075Products', @@ROWCOUNT);

        DELETE FROM dbo.T076ProductCategory WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T076ProductCategory', @@ROWCOUNT);

        DELETE FROM dbo.T069TaxeRate WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T069TaxeRate', @@ROWCOUNT);

        DELETE FROM dbo.T070RapportTaxe WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T070RapportTaxe', @@ROWCOUNT);

        DELETE FROM dbo.T068TaxeStatus WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T068TaxeStatus', @@ROWCOUNT);

        -- ===================== TIERS =====================
        DELETE FROM dbo.T054PartyAddress
        WHERE PartyId IN (SELECT Id FROM dbo.T050Party WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T054PartyAddress', @@ROWCOUNT);

        DELETE FROM dbo.T050Party WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T050Party', @@ROWCOUNT);

        -- ===================== AUTOPAY / PLAID =====================
        DELETE FROM dbo.T145AutoPayAttempt WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T145AutoPayAttempt', @@ROWCOUNT);

        DELETE FROM dbo.T144AuthorizationAutoPay WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T144AuthorizationAutoPay', @@ROWCOUNT);

        DELETE FROM dbo.T144PlaidSyncLog WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T144PlaidSyncLog', @@ROWCOUNT);

        DELETE FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T143PlaidAccount', @@ROWCOUNT);

        -- ===================== JOBS =====================
        DELETE FROM dbo.T203JobLog
        WHERE JobExecutionId IN (SELECT Id FROM dbo.T202JobExecution WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('T203JobLog', @@ROWCOUNT);

        DELETE FROM dbo.T204JobPlanned WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T204JobPlanned', @@ROWCOUNT);

        DELETE FROM dbo.T202JobExecution WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T202JobExecution', @@ROWCOUNT);

        DELETE FROM dbo.T201JobSchedule WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T201JobSchedule', @@ROWCOUNT);

        DELETE FROM dbo.T200JobDefinition WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T200JobDefinition', @@ROWCOUNT);

        -- ===================== IMPORTS =====================
        DELETE FROM dbo.PartyImport
        WHERE ImportFileId IN (SELECT Id FROM dbo.ImportFiles WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('PartyImport', @@ROWCOUNT);

        DELETE FROM dbo.ProductImport
        WHERE ImportFileId IN (SELECT Id FROM dbo.ImportFiles WHERE CompanyGUID = @CompanyGUID);
        INSERT @log VALUES ('ProductImport', @@ROWCOUNT);

        DELETE FROM dbo.ImportFiles WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('ImportFiles', @@ROWCOUNT);

        -- ===================== PARAMÈTRES COMPTABLES =====================
        DELETE FROM dbo.T101ParamValues WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T101ParamValues', @@ROWCOUNT);

        DELETE FROM dbo.T100ParamComptable WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T100ParamComptable', @@ROWCOUNT);

        -- ===================== DIVERS (feuilles) =====================
        DELETE FROM dbo.T0001Receipt WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T0001Receipt', @@ROWCOUNT);

        DELETE FROM dbo.Appointments WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('Appointments', @@ROWCOUNT);

        DELETE FROM dbo.T020Subscription WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T020Subscription', @@ROWCOUNT);

        DELETE FROM dbo.T300Employees WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T300Employees', @@ROWCOUNT);

        DELETE FROM dbo.T015User WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T015User', @@ROWCOUNT);

        -- ===================== LA COMPAGNIE =====================
        DELETE FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID;
        INSERT @log VALUES ('T010Company', @@ROWCOUNT);

        COMMIT TRAN;

        SELECT StepNo, TableName, RowsDeleted FROM @log ORDER BY StepNo;
        SELECT SUM(RowsDeleted) AS TotalRowsDeleted FROM @log;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
