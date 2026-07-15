-- s0688LinkDocumentToSquareOrder.sql
-- Estampille une facture client (T060Document) avec le SquareOrderId d'un lien de paiement
-- Square genere depuis l'app. Ainsi, au retour du webhook payment.created, s0672ApplySquarePayment
-- retrouve NOTRE facture par SquareOrderId et la marque payee (au lieu de creer une synthetique).
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('dbo.s0688LinkDocumentToSquareOrder') IS NOT NULL
    DROP PROCEDURE dbo.s0688LinkDocumentToSquareOrder;
GO
CREATE PROCEDURE dbo.s0688LinkDocumentToSquareOrder
    @CompanyGUID   UNIQUEIDENTIFIER,
    @DocumentId    INT,
    @SquareOrderId VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T060Document
    SET SquareOrderId    = @SquareOrderId,
        SquareSyncStatus = 'LINK',
        SquareSyncDate   = GETDATE()
    WHERE Id = @DocumentId AND CompanyGUID = @CompanyGUID;

    SELECT @@ROWCOUNT AS Updated;
END
GO
