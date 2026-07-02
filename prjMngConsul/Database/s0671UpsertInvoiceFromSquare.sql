-- =============================================================================
-- s0671UpsertInvoiceFromSquare
-- Insere ou met a jour une Facture Client (T060Document, DocumentTypeId=1,
-- SourceId=4 API) + ses lignes (T061DocumentLine) a partir d'une facture OU
-- d'un paiement Square. Sens ENTRANT (Square -> app). Utilise par le webhook
-- (invoice.* / payment.*) ET par le bouton import.
--
-- Cle de rapprochement : SquareOrderId (unifie facture + paiement du meme
-- order), repli SquareInvoiceId. Sinon -> creation.
--
-- Totaux : on stocke les montants AUTORITATIFS de Square (@*Cents / 100), on ne
-- recalcule PAS via sp_RecalculerTotauxDocument (les taux de taxe sont
-- per-compagnie et peuvent differer du calcul Square). Le TaxeStatus par ligne
-- (TAXABLE/EXEMPT de la compagnie) ne sert qu'a l'affichage.
--
-- PartyGUID resolu via T050Party.SquareCustomerId (le webhook garantit d'abord
-- le client via s0666). Le snapshot destinataire (nom/adresse) est copie sur
-- T060Document meme si le client local est introuvable (le PDF lit ces colonnes).
--
-- @Action OUTPUT : 'created' | 'updated'.
-- =============================================================================

USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0671UpsertInvoiceFromSquare', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0671UpsertInvoiceFromSquare;
GO

CREATE PROCEDURE dbo.s0671UpsertInvoiceFromSquare
    @CompanyGUID          UNIQUEIDENTIFIER,
    @SquareInvoiceId      VARCHAR(100)  = NULL,
    @SquareInvoiceVersion BIGINT        = NULL,
    @SquareOrderId        VARCHAR(100)  = NULL,
    @SquarePaymentId      VARCHAR(100)  = NULL,
    @SquareCustomerId     VARCHAR(100)  = NULL,
    @InvoiceNumber        VARCHAR(200)  = NULL,
    @SquareStatus         VARCHAR(40)   = NULL,   -- statut Square (invoice ou payment)
    @IssueDate            DATETIME      = NULL,
    @DueDate              DATETIME      = NULL,
    @SubTotalCents        BIGINT        = NULL,
    @TpsCents             BIGINT        = NULL,
    @TvqCents             BIGINT        = NULL,
    @TotalCents           BIGINT        = NULL,
    @RecipientName        NVARCHAR(500) = NULL,
    @RecipientEmail       NVARCHAR(150) = NULL,
    @RecipientPhone       NVARCHAR(50)  = NULL,
    @RecipientAddress1    NVARCHAR(500) = NULL,
    @RecipientAddress2    NVARCHAR(500) = NULL,
    @RecipientCity        NVARCHAR(50)  = NULL,
    @RecipientState       NVARCHAR(50)  = NULL,
    @RecipientPostalCode  NVARCHAR(50)  = NULL,
    @Lines                dbo.TVP_SquareInvoiceLine READONLY,
    @DocumentId           INT          = NULL OUTPUT,
    @Action               VARCHAR(20)  = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DefaultCo UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1. Mapping du statut Square -> StatusId (T066DocumentStatus)
    DECLARE @StatusId INT = 2;  -- Posted par defaut
    IF    @SquareStatus = 'DRAFT'                                                            SET @StatusId = 1;
    ELSE IF @SquareStatus IN ('UNPAID','SCHEDULED','PARTIALLY_PAID','PAYMENT_PENDING')        SET @StatusId = 2;
    ELSE IF @SquareStatus IN ('PAID','REFUNDED','PARTIALLY_REFUNDED','COMPLETED','APPROVED')  SET @StatusId = 3;
    ELSE IF @SquareStatus IN ('CANCELED','FAILED')                                            SET @StatusId = 4;

    -- 2. Resolution du client local
    DECLARE @PartyGUID UNIQUEIDENTIFIER = NULL;
    IF @SquareCustomerId IS NOT NULL
        SELECT TOP 1 @PartyGUID = PartyGUID
        FROM dbo.T050Party
        WHERE SquareCustomerId = @SquareCustomerId AND CompanyGUID = @CompanyGUID
        ORDER BY Id;

    -- 3. TaxeStatus de la compagnie (repli sur la compagnie par defaut)
    DECLARE @TaxableId INT, @ExemptId INT;
    SELECT TOP 1 @TaxableId = Id FROM dbo.T068TaxeStatus WHERE CompanyGUID = @CompanyGUID AND TaxStatus = 'TAXABLE' ORDER BY Id;
    IF @TaxableId IS NULL SELECT TOP 1 @TaxableId = Id FROM dbo.T068TaxeStatus WHERE CompanyGUID = @DefaultCo AND TaxStatus = 'TAXABLE' ORDER BY Id;
    SELECT TOP 1 @ExemptId  = Id FROM dbo.T068TaxeStatus WHERE CompanyGUID = @CompanyGUID AND TaxStatus = 'EXEMPT'  ORDER BY Id;
    IF @ExemptId  IS NULL SELECT TOP 1 @ExemptId  = Id FROM dbo.T068TaxeStatus WHERE CompanyGUID = @DefaultCo AND TaxStatus = 'EXEMPT'  ORDER BY Id;

    -- 4. Montants autoritatifs Square
    DECLARE @SubTotal NUMERIC(18,2) = CASE WHEN @SubTotalCents IS NULL THEN NULL ELSE @SubTotalCents / 100.0 END;
    DECLARE @TPS      NUMERIC(18,2) = CASE WHEN @TpsCents      IS NULL THEN NULL ELSE @TpsCents      / 100.0 END;
    DECLARE @TVQ      NUMERIC(18,2) = CASE WHEN @TvqCents      IS NULL THEN NULL ELSE @TvqCents      / 100.0 END;
    DECLARE @Total    NUMERIC(18,2) = CASE WHEN @TotalCents    IS NULL THEN NULL ELSE @TotalCents    / 100.0 END;

    -- 5. Rapprochement du document existant (order d'abord, puis invoice)
    SET @DocumentId = NULL;
    IF @SquareOrderId IS NOT NULL
        SELECT TOP 1 @DocumentId = Id FROM dbo.T060Document
        WHERE SquareOrderId = @SquareOrderId AND CompanyGUID = @CompanyGUID ORDER BY Id;
    IF @DocumentId IS NULL AND @SquareInvoiceId IS NOT NULL
        SELECT TOP 1 @DocumentId = Id FROM dbo.T060Document
        WHERE SquareInvoiceId = @SquareInvoiceId AND CompanyGUID = @CompanyGUID ORDER BY Id;
    -- repli paiement : vente comptoir sans order ni facture (idempotence par paiement)
    IF @DocumentId IS NULL AND @SquarePaymentId IS NOT NULL
        SELECT TOP 1 @DocumentId = Id FROM dbo.T060Document
        WHERE SquarePaymentId = @SquarePaymentId AND CompanyGUID = @CompanyGUID ORDER BY Id;

    IF @DocumentId IS NULL
    BEGIN
        INSERT INTO dbo.T060Document
            (CompanyGUID, PartyGUID, DocumentTypeId, StatusId, SourceId,
             DocumentDate, DueDate, DocumentNumber, ComptabilisationStatus,
             Name, DisplayName, Address1, Address2, City, State, PostalCode, Phone, Email,
             SubTotal, TPS, TVQ, Total,
             SquareInvoiceId, SquareInvoiceVersion, SquareOrderId, SquarePaymentId,
             SquareSyncStatus, SquareSyncDate)
        VALUES
            (@CompanyGUID, @PartyGUID, 1, @StatusId, 4,
             ISNULL(@IssueDate, GETDATE()), @DueDate, NULL, 'NON_COMPTABILISE',
             @RecipientName, @RecipientName, @RecipientAddress1, @RecipientAddress2,
             @RecipientCity, @RecipientState, @RecipientPostalCode, @RecipientPhone, @RecipientEmail,
             @SubTotal, @TPS, @TVQ, @Total,
             @SquareInvoiceId, @SquareInvoiceVersion, @SquareOrderId, @SquarePaymentId,
             'IMPORT', GETDATE());

        SET @DocumentId = SCOPE_IDENTITY();

        UPDATE dbo.T060Document
        SET DocumentNumber = COALESCE(NULLIF(LTRIM(RTRIM(@InvoiceNumber)), ''), 'SQ-' + CAST(@DocumentId AS VARCHAR(20)))
        WHERE Id = @DocumentId;

        SET @Action = 'created';
    END
    ELSE
    BEGIN
        UPDATE dbo.T060Document
        SET PartyGUID             = COALESCE(@PartyGUID, PartyGUID),
            StatusId              = @StatusId,
            DocumentDate          = COALESCE(@IssueDate, DocumentDate),
            DueDate               = COALESCE(@DueDate, DueDate),
            DocumentNumber        = COALESCE(NULLIF(LTRIM(RTRIM(@InvoiceNumber)), ''), DocumentNumber),
            Name                  = COALESCE(@RecipientName, Name),
            DisplayName           = COALESCE(@RecipientName, DisplayName),
            Address1              = COALESCE(@RecipientAddress1, Address1),
            Address2              = COALESCE(@RecipientAddress2, Address2),
            City                  = COALESCE(@RecipientCity, City),
            State                 = COALESCE(@RecipientState, State),
            PostalCode            = COALESCE(@RecipientPostalCode, PostalCode),
            Phone                 = COALESCE(@RecipientPhone, Phone),
            Email                 = COALESCE(@RecipientEmail, Email),
            SubTotal              = COALESCE(@SubTotal, SubTotal),
            TPS                   = COALESCE(@TPS, TPS),
            TVQ                   = COALESCE(@TVQ, TVQ),
            Total                 = COALESCE(@Total, Total),
            SquareInvoiceId       = COALESCE(@SquareInvoiceId, SquareInvoiceId),
            SquareInvoiceVersion  = COALESCE(@SquareInvoiceVersion, SquareInvoiceVersion),
            SquareOrderId         = COALESCE(@SquareOrderId, SquareOrderId),
            SquarePaymentId       = COALESCE(@SquarePaymentId, SquarePaymentId),
            SquareSyncStatus      = 'IMPORT',
            SquareSyncDate        = GETDATE()
        WHERE Id = @DocumentId AND CompanyGUID = @CompanyGUID;

        SET @Action = 'updated';
    END

    -- 6. Remplacement des lignes (uniquement si des lignes sont fournies)
    IF EXISTS (SELECT 1 FROM @Lines)
    BEGIN
        DELETE FROM dbo.T061DocumentLine WHERE DocumentId = @DocumentId;

        INSERT INTO dbo.T061DocumentLine
            (DocumentId, ProductId, Description, Qty, UnitPrice, Amount, TaxeStatus, Ordre)
        SELECT
            @DocumentId,
            p.Id,                                   -- produit local relie via SquareItemId (NULL si introuvable)
            L.Description,
            ISNULL(L.Qty, 1),
            ISNULL(L.UnitPrice, 0),
            ISNULL(L.Amount, 0),
            CASE WHEN ISNULL(L.HasTax, 0) = 1 THEN @TaxableId ELSE @ExemptId END,
            ISNULL(L.Ordre, 0)
        FROM @Lines L
        LEFT JOIN dbo.T075Products p
               ON p.CompanyGUID = @CompanyGUID
              AND L.SquareItemId IS NOT NULL
              AND (p.SquareVariationId = L.SquareItemId OR p.SquareItemId = L.SquareItemId);
    END

    SELECT @DocumentId AS DocumentId, @Action AS Action;
END
GO
