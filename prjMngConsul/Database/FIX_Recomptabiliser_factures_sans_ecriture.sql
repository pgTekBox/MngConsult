-- =============================================================================
-- FIX_Recomptabiliser_factures_sans_ecriture  (2026-11-10)
--
-- Les scripts de seed des compagnies de démo ont marqué des factures clients et
-- fournisseurs ComptabilisationStatus = 'COMPTABILISE' SANS passer par
-- sp_ComptabiliserDocument : aucune écriture T137DocumentEcriture
-- 'COMPTABILISATION', ComptabiliseeAt NULL. Tout encaissement ou paiement les
-- refuse alors (« Facture non comptabilisée. Exécuter sp_ComptabiliserDocument
-- d'abord. », sp_EncaisserFactureClient / sp_PayerFactureFournisseur).
--
-- Pour chacune : remise en NON_COMPTABILISE, puis sp_ComptabiliserDocument
-- (le numéro existant est conservé). Si la comptabilisation échoue, la facture
-- reprend son statut COMPTABILISE d'origine et l'erreur est listée à la fin.
-- =============================================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @Echecs TABLE (DocumentId INT, Compagnie NVARCHAR(200), Numero VARCHAR(200), Erreur NVARCHAR(2048));
DECLARE @Id INT, @Ok INT = 0;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT d.[Id]
    FROM dbo.T060Document d
    WHERE d.[ComptabilisationStatus] = 'COMPTABILISE'
      AND d.[DocumentTypeId] IN (1, 2, 5)
      AND NOT EXISTS (SELECT 1 FROM dbo.T137DocumentEcriture e
                      WHERE e.[DocumentId] = d.[Id] AND e.[CompanyGUID] = d.[CompanyGUID]
                        AND e.[TypeEcriture] = 'COMPTABILISATION')
    ORDER BY d.[CompanyGUID], d.[DocumentDate], d.[Id];

OPEN c;
FETCH NEXT FROM c INTO @Id;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        UPDATE dbo.T060Document SET [ComptabilisationStatus] = 'NON_COMPTABILISE' WHERE [Id] = @Id;
        EXEC dbo.sp_ComptabiliserDocument @DocumentId = @Id, @UserId = 1;
        SET @Ok = @Ok + 1;
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        UPDATE dbo.T060Document SET [ComptabilisationStatus] = 'COMPTABILISE' WHERE [Id] = @Id;
        INSERT INTO @Echecs
        SELECT d.[Id], dbo.fCompanyName(d.[CompanyGUID]), d.[DocumentNumber], @Err
        FROM dbo.T060Document d WHERE d.[Id] = @Id;
    END CATCH
    FETCH NEXT FROM c INTO @Id;
END
CLOSE c; DEALLOCATE c;

SELECT @Ok AS Recomptabilisees, (SELECT COUNT(*) FROM @Echecs) AS Echecs;
SELECT * FROM @Echecs ORDER BY Compagnie, Numero;
