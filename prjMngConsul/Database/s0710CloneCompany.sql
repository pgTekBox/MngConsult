-- =============================================================================
-- s0710CloneCompany  (@src, @dst, @newCompanyCode)
-- Clone PROFOND d'une compagnie (@src) vers une NOUVELLE compagnie (@dst).
-- Sert a fabriquer les compagnies de demonstration a partir de « Cronus ».
--
-- Technique : NouvelId = AncienId + decalage (decalage = MAX(Id) de la table,
-- donc bloc d'Id garanti sans collision). IDENTITY_INSERT pour reinserer l'Id
-- exact. Chaque FK est remappee en ajoutant le decalage de sa table parente.
-- Seul lien par GUID (T060Document.PartyGUID -> T050Party.PartyGUID) via #pg.
-- Les GUID « propres » (DocumentGUID, EcrituresGUID, ...) sont regeneres.
-- Les champs d'integration (Square*, AutoPay*, Stripe*, PDF*, jetons) sont
-- neutralises. Tables NON clonees : T015User, T020Subscription, T143PlaidAccount,
-- jobs (T200-204), T144/T145 (etat d'integration, pas du contenu de demo).
--
-- @dst doit NE PAS exister. Aucune compagnie existante n'est modifiee.
-- =============================================================================
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0710CloneCompany
    @src            UNIQUEIDENTIFIER,
    @dst            UNIQUEIDENTIFIER,
    @newCompanyCode VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @src)
    BEGIN RAISERROR('Compagnie source introuvable.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @dst)
    BEGIN RAISERROR('Compagnie destination existe deja.', 16, 1); RETURN; END

    ---------------------------------------------------------------------------
    -- Metadonnees : tables a cloner (ordre parents -> enfants)
    ---------------------------------------------------------------------------
    CREATE TABLE #tbl (ord INT, tbl SYSNAME, idcol SYSNAME NULL, isident BIT, pred NVARCHAR(1000));
    INSERT INTO #tbl (ord, tbl, idcol, isident, pred) VALUES
     (1 ,'T068TaxeStatus'          ,'Id',1,'CompanyGUID = @src'),
     (2 ,'T069TaxeRate'            ,'Id',1,'CompanyGUID = @src'),
     (3 ,'T070RapportTaxe'         ,'Id',1,'CompanyGUID = @src'),
     (4 ,'T111Exercices'           ,'id',1,'CompanyGUID = @src'),
     (5 ,'T112Periodes'            ,'id',1,'exercice_id IN (SELECT id FROM dbo.T111Exercices WHERE CompanyGUID = @src)'),
     (6 ,'T120PlanComptable_Classe','Id',0,'CompanyGUID = @src'),
     (7 ,'T121PlanComptable'       ,'Id',0,'CompanyGUID = @src'),
     (8 ,'T130Journaux'            ,'Id',1,'CompanyGUID = @src'),
     (9 ,'T100ParamComptable'      ,'Id',1,'CompanyGUID = @src'),
     (10,'T101ParamValues'         ,'Id',1,'CompanyGUID = @src OR T100Id IN (SELECT Id FROM dbo.T100ParamComptable WHERE CompanyGUID = @src)'),
     (11,'T076ProductCategory'     ,'Id',1,'CompanyGUID = @src'),
     (12,'T075Products'            ,'Id',1,'CompanyGUID = @src'),
     (13,'T050Party'              ,'Id',1,'CompanyGUID = @src'),
     (14,'T054PartyAddress'        ,'Id',1,'PartyId IN (SELECT Id FROM dbo.T050Party WHERE CompanyGUID = @src)'),
     (15,'T060Document'            ,'Id',1,'CompanyGUID = @src'),
     (16,'T061DocumentLine'        ,'Id',1,'DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @src)'),
     (17,'T135Ecritures'           ,'Id',1,'CompanyGUID = @src'),
     (18,'T136LignesEcriture'      ,'Id',1,'EcrituresId IN (SELECT Id FROM dbo.T135Ecritures WHERE CompanyGUID = @src)'),
     (19,'T137DocumentEcriture'    ,'Id',1,'CompanyGUID = @src'),
     (20,'T142ReleveBancaire'      ,'Id',1,'CompanyGUID = @src'),
     (21,'T300Employees'           ,'Id',1,'CompanyGUID = @src'),
     (22,'Appointments'            ,'Id',1,'CompanyGUID = @src'),
     (23,'T062DocumentNumberCounter',NULL,0,'CompanyGUID = @src');

    ---------------------------------------------------------------------------
    -- FK a remapper : (table, colonne) -> table parente (on ajoute son decalage)
    ---------------------------------------------------------------------------
    CREATE TABLE #fk (tbl SYSNAME, col SYSNAME, parentTbl SYSNAME);
    INSERT INTO #fk (tbl, col, parentTbl) VALUES
     ('T076ProductCategory','TaxeStatusDefault','T068TaxeStatus'),
     ('T075Products','CategoryId','T076ProductCategory'),
     ('T075Products','TaxeStatusId','T068TaxeStatus'),
     ('T112Periodes','exercice_id','T111Exercices'),
     ('T120PlanComptable_Classe','ParentId','T120PlanComptable_Classe'),
     ('T121PlanComptable','ClasseId','T120PlanComptable_Classe'),
     ('T121PlanComptable','ClasseParentId','T120PlanComptable_Classe'),
     ('T101ParamValues','T100Id','T100ParamComptable'),
     ('T054PartyAddress','PartyId','T050Party'),
     ('T061DocumentLine','DocumentId','T060Document'),
     ('T061DocumentLine','ProductId','T075Products'),
     ('T061DocumentLine','TaxeStatus','T068TaxeStatus'),
     ('T135Ecritures','JournauxId','T130Journaux'),
     ('T135Ecritures','PeriodeId','T112Periodes'),
     ('T135Ecritures','EcritureOrigId','T135Ecritures'),
     ('T136LignesEcriture','EcrituresId','T135Ecritures'),
     ('T136LignesEcriture','PlanComptableId','T121PlanComptable'),
     ('T137DocumentEcriture','DocumentId','T060Document'),
     ('T137DocumentEcriture','EcrituresId','T135Ecritures'),
     ('T300Employees','ManagerId','T300Employees'),
     ('Appointments','CustomerId','T050Party'),
     ('Appointments','EmployeeId','T300Employees'),
     ('Appointments','RecurrenceParentId','Appointments');

    ---------------------------------------------------------------------------
    -- Overrides : colonne -> expression litterale (GUID propre, neutralisation)
    ---------------------------------------------------------------------------
    CREATE TABLE #ov (tbl SYSNAME, col SYSNAME, expr NVARCHAR(400));
    INSERT INTO #ov (tbl, col, expr) VALUES
     -- GUID propres regeneres
     ('T060Document','DocumentGUID','NEWID()'),
     ('T070RapportTaxe','RapportGUID','NEWID()'),
     ('T076ProductCategory','CategoryGUID','NEWID()'),
     ('T130Journaux','JournauxGUID','NEWID()'),
     ('T135Ecritures','EcrituresGUID','NEWID()'),
     ('T136LignesEcriture','LignesEcritureGUID','NEWID()'),
     ('T137DocumentEcriture','DocumentEcritureGUID','NEWID()'),
     ('T142ReleveBancaire','ReleveBancaireGUID','NEWID()'),
     ('T300Employees','EmployeeGUID','NEWID()'),
     -- lien document->client par GUID (via #pg)
     ('T050Party','PartyGUID','(SELECT NewGuid FROM #pg WHERE OldId = s.Id)'),
     ('T060Document','PartyGUID','ISNULL((SELECT NewGuid FROM #pg WHERE OldGuid = s.PartyGUID), s.PartyGUID)'),
     -- neutralisation integration (T050Party)
     ('T050Party','StripeAccountId','NULL'),
     ('T050Party','SquareCustomerId','NULL'),
     ('T050Party','SquareCustomerVersion','NULL'),
     ('T050Party','SquareSyncStatus','NULL'),
     ('T050Party','SquareSyncDate','NULL'),
     -- neutralisation integration (T060Document)
     ('T060Document','SquareInvoiceId','NULL'),
     ('T060Document','SquareInvoiceVersion','NULL'),
     ('T060Document','SquareOrderId','NULL'),
     ('T060Document','SquarePaymentId','NULL'),
     ('T060Document','SquareSyncStatus','NULL'),
     ('T060Document','SquareSyncDate','NULL'),
     ('T060Document','AutoPay','0'),
     ('T060Document','AutoPayDate','NULL'),
     ('T060Document','AutoPayStatus','NULL'),
     ('T060Document','AutoPayAttempts','0'),
     ('T060Document','AutoPayAuthorizationId','NULL'),
     ('T060Document','AutoPayPreavisSentDate','NULL'),
     ('T060Document','AutoPayPadPreavisSentDate','NULL'),
     ('T060Document','PdfData','NULL'),
     ('T060Document','PdfFileName','NULL'),
     ('T060Document','PdfGeneratedOn','NULL'),
     ('T060Document','PDFContentType','NULL'),
     -- releve bancaire : reglement non clone
     ('T142ReleveBancaire','ReglementId','NULL');

    ---------------------------------------------------------------------------
    -- Decalages : #off(tbl, offv) ou off = MAX(idcol) courant (0 si vide)
    ---------------------------------------------------------------------------
    CREATE TABLE #off (tbl SYSNAME PRIMARY KEY, offv BIGINT);
    DECLARE @ct SYSNAME, @cidcol SYSNAME, @o BIGINT, @sqlo NVARCHAR(500);
    DECLARE curo CURSOR LOCAL FAST_FORWARD FOR SELECT tbl, idcol FROM #tbl WHERE idcol IS NOT NULL;
    OPEN curo; FETCH NEXT FROM curo INTO @ct, @cidcol;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sqlo = N'SELECT @o = ISNULL(MAX(' + QUOTENAME(@cidcol) + N'),0) FROM dbo.' + QUOTENAME(@ct) + N';';
        EXEC sp_executesql @sqlo, N'@o BIGINT OUTPUT', @o = @o OUTPUT;
        INSERT INTO #off (tbl, offv) VALUES (@ct, @o);
        FETCH NEXT FROM curo INTO @ct, @cidcol;
    END
    CLOSE curo; DEALLOCATE curo;

    ---------------------------------------------------------------------------
    -- Map GUID des parties (ancien GUID -> nouveau GUID)
    ---------------------------------------------------------------------------
    SELECT Id AS OldId, PartyGUID AS OldGuid, NEWID() AS NewGuid
    INTO #pg
    FROM dbo.T050Party WHERE CompanyGUID = @src;

    ---------------------------------------------------------------------------
    -- 1) La compagnie elle-meme (jetons/verif mail non copies)
    ---------------------------------------------------------------------------
    INSERT INTO dbo.T010Company (CompanyGUID, CompanyCode, ComptableGUID, ModifiedOn, ModifiedBy, Created,
                                 Logo, LogoContentType, LogoUpdatedOn, PlaidAutoImport)
    SELECT @dst, @newCompanyCode, ComptableGUID, ModifiedOn, ModifiedBy, GETDATE(),
           Logo, LogoContentType, LogoUpdatedOn, 0
    FROM dbo.T010Company WHERE CompanyGUID = @src;

    ---------------------------------------------------------------------------
    -- 2) Boucle de clonage table par table
    ---------------------------------------------------------------------------
    DECLARE @t SYSNAME, @idcol SYSNAME, @isident BIT, @pred NVARCHAR(1000), @off BIGINT;
    DECLARE @cols NVARCHAR(MAX), @sel NVARCHAR(MAX), @sql NVARCHAR(MAX);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT t.tbl, t.idcol, t.isident, t.pred, ISNULL(o.offv,0)
        FROM #tbl t LEFT JOIN #off o ON o.tbl = t.tbl ORDER BY t.ord;
    OPEN cur; FETCH NEXT FROM cur INTO @t, @idcol, @isident, @pred, @off;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @cols = NULL; SET @sel = NULL;
        SELECT
            @cols = STRING_AGG(QUOTENAME(c.name), ',') WITHIN GROUP (ORDER BY c.column_id),
            @sel  = STRING_AGG(
                CASE
                    WHEN @idcol IS NOT NULL AND c.name = @idcol
                        THEN N's.' + QUOTENAME(c.name) + N'+' + CONVERT(VARCHAR(20), @off)
                    WHEN c.name = 'CompanyGUID' THEN N'@dst'
                    WHEN ov.expr IS NOT NULL THEN ov.expr
                    WHEN fk.parentTbl IS NOT NULL
                        THEN N'CASE WHEN s.' + QUOTENAME(c.name)
                           + N' IN (SELECT ' + QUOTENAME(fk.parentIdcol) + N' FROM dbo.' + QUOTENAME(fk.parentTbl)
                           + N' WHERE ' + fk.parentPred + N') THEN s.' + QUOTENAME(c.name) + N'+' + CONVERT(VARCHAR(20), fk.parentoff)
                           + N' ELSE s.' + QUOTENAME(c.name) + N' END'
                    ELSE N's.' + QUOTENAME(c.name)
                END, ',') WITHIN GROUP (ORDER BY c.column_id)
        FROM sys.columns c
        JOIN sys.types ty ON ty.user_type_id = c.user_type_id
        LEFT JOIN #ov ov ON ov.tbl = @t AND ov.col = c.name
        LEFT JOIN (SELECT f.col, f.parentTbl, pt.idcol AS parentIdcol, pt.pred AS parentPred, po.offv AS parentoff
                   FROM #fk f JOIN #tbl pt ON pt.tbl = f.parentTbl JOIN #off po ON po.tbl = f.parentTbl
                   WHERE f.tbl = @t) fk ON fk.col = c.name
        WHERE c.object_id = OBJECT_ID('dbo.' + @t)
          AND c.is_computed = 0 AND ty.name <> 'timestamp';

        SET @sql =
              CASE WHEN @isident = 1 THEN N'SET IDENTITY_INSERT dbo.' + QUOTENAME(@t) + N' ON;' ELSE N'' END
            + N'INSERT INTO dbo.' + QUOTENAME(@t) + N' (' + @cols + N') SELECT ' + @sel
            + N' FROM dbo.' + QUOTENAME(@t) + N' s WHERE ' + @pred + N';'
            + CASE WHEN @isident = 1 THEN N'SET IDENTITY_INSERT dbo.' + QUOTENAME(@t) + N' OFF;' ELSE N'' END;

        EXEC sp_executesql @sql, N'@src UNIQUEIDENTIFIER, @dst UNIQUEIDENTIFIER', @src = @src, @dst = @dst;

        FETCH NEXT FROM cur INTO @t, @idcol, @isident, @pred, @off;
    END
    CLOSE cur; DEALLOCATE cur;

    SELECT 'OK' AS Result, @dst AS NewCompanyGUID, 'Compagnie clonee.' AS Message;
END
GO
