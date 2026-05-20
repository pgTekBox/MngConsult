-- =============================================================================
-- s0608MigrateProductImportToProd
-- Pousse les lignes staging.ProductImport (Status='Pending') vers la production
-- via la procédure existante s0079InsertProduct.
--
-- Marque chaque ligne staging en sortie :
--   - 'Migrated' + MigratedToProductId + MigratedDate  si succès
--   - 'Skipped'  + ErrorMessage                          si nom manquant
--   - 'Error'    + ErrorMessage                          si exception
--
-- Retourne : ImportFileId, TotalPending, Migrated, Skipped, Errors
-- =============================================================================

IF OBJECT_ID('dbo.s0608MigrateProductImportToProd', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0608MigrateProductImportToProd;
GO

CREATE PROCEDURE dbo.s0608MigrateProductImportToProd
    @ImportFileId    INT,
    @CompanyGUID     UNIQUEIDENTIFIER = NULL,  -- NULL → lit depuis staging.ImportFiles
    @CategoryId      INT              = NULL,
    @TaxeStatusId    INT              = NULL,
    @DefaultQty      DECIMAL(15,2)    = 1,
    @AddToNewInvoice BIT              = 0,
    @NoTaxe          BIT              = 0,
    @Actif           BIT              = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Résoudre CompanyGUID ───────────────────────────────────────────────
    IF @CompanyGUID IS NULL
        SELECT @CompanyGUID = CompanyGUID FROM staging.ImportFiles WHERE Id = @ImportFileId;

    IF @CompanyGUID IS NULL
    BEGIN
        RAISERROR('CompanyGUID requis (non trouvé sur staging.ImportFiles Id=%d).', 16, 1, @ImportFileId);
        RETURN;
    END

    DECLARE @TotalPending INT, @Migrated INT = 0, @Skipped INT = 0, @Errors INT = 0;
    SELECT @TotalPending = COUNT(*) FROM staging.ProductImport
    WHERE ImportFileId = @ImportFileId AND Status = 'Pending';

    DECLARE @StageId INT, @Name NVARCHAR(500), @Description NVARCHAR(2000),
            @Price DECIMAL(15,2), @RevenueAccount NVARCHAR(20),
            @ExpenseAccount NVARCHAR(20), @Taxable BIT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id, Name, Description, Price, RevenueAccount, ExpenseAccount, Taxable
        FROM staging.ProductImport
        WHERE ImportFileId = @ImportFileId AND Status = 'Pending'
        ORDER BY ISNULL(LineNumber, 0), Id;

    OPEN cur;
    FETCH NEXT FROM cur INTO @StageId, @Name, @Description, @Price,
                              @RevenueAccount, @ExpenseAccount, @Taxable;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            IF @Name IS NULL OR LEN(LTRIM(RTRIM(@Name))) = 0
            BEGIN
                UPDATE staging.ProductImport
                SET Status = 'Skipped', ErrorMessage = 'Nom manquant'
                WHERE Id = @StageId;
                SET @Skipped += 1;
            END
            ELSE
            BEGIN
                -- Appel de la proc existante s0079InsertProduct
                -- Elle retourne un result set avec l'Id du nouveau produit
                DECLARE @InsertResult TABLE (NewId INT);
                DELETE FROM @InsertResult;

                -- NoTaxe = 1 si Taxable explicitement faux ; 0 sinon (par défaut taxable)
                DECLARE @NoTaxeForRow BIT =
                    CASE WHEN @Taxable = 0 THEN 1 ELSE @NoTaxe END;

                INSERT INTO @InsertResult (NewId)
                EXEC dbo.s0079InsertProduct
                    @CompanyGUID     = @CompanyGUID,
                    @Name            = @Name,
                    @Description     = @Description,
                    @Prix            = @Price,
                    @DefaultQty      = @DefaultQty,
                    @AddToNewInvoice = @AddToNewInvoice,
                    @NoTaxe          = @NoTaxeForRow,
                    @CategoryId      = @CategoryId,
                    @CompteVente     = @RevenueAccount,
                    @CompteAchat     = @ExpenseAccount,
                    @TaxeStatusId    = @TaxeStatusId,
                    @Actif           = @Actif;

                DECLARE @NewProductId INT;
                SELECT @NewProductId = NewId FROM @InsertResult;

                IF @NewProductId IS NULL
                BEGIN
                    UPDATE staging.ProductImport
                    SET Status = 'Error',
                        ErrorMessage = 's0079InsertProduct n''a pas retourné d''Id'
                    WHERE Id = @StageId;
                    SET @Errors += 1;
                END
                ELSE
                BEGIN
                    UPDATE staging.ProductImport
                    SET Status = 'Migrated',
                        MigratedToProductId = @NewProductId,
                        MigratedDate = GETDATE(),
                        ErrorMessage = NULL
                    WHERE Id = @StageId;
                    SET @Migrated += 1;
                END
            END
        END TRY
        BEGIN CATCH
            UPDATE staging.ProductImport
            SET Status = 'Error',
                ErrorMessage = LEFT(ERROR_MESSAGE(), 4000)
            WHERE Id = @StageId;
            SET @Errors += 1;
        END CATCH

        FETCH NEXT FROM cur INTO @StageId, @Name, @Description, @Price,
                                  @RevenueAccount, @ExpenseAccount, @Taxable;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT @ImportFileId  AS ImportFileId,
           @TotalPending  AS TotalPending,
           @Migrated      AS Migrated,
           @Skipped       AS Skipped,
           @Errors        AS Errors;
END
GO
