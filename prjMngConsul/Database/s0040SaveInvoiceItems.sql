SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[s0040SaveInvoiceItems]
(
    @InvoiceId   INT,
    @toPost      INT,
    @PartyGUID   UNIQUEIDENTIFIER,
    @DueDate     DATETIME,
    @IssueDate   DATETIME,
	@DocumentType varchar(20),
    @CompanyGUID UNIQUEIDENTIFIER = NULL,   -- optionnel : pour la création
    @Items       dbo.TVP_InvoiceItem_v6 READONLY
)
AS
/*
DECLARE @items dbo.TVP_InvoiceItem_v6;
-- (laisser vide pour test rapide ou ajouter des lignes)

EXEC dbo.s0040SaveInvoiceItems
    @InvoiceId   = 0,
    @toPost      = 0,
    @PartyGUID   = '465231CA-1F89-4813-B855-2242AA25EAD5',
    @DueDate     = '2026-06-13',
    @IssueDate   = '2026-05-13',
    @CompanyGUID = '5B674F82-8914-4A87-8C05-8F92E105338E',
    @Items       = @items;


*/


BEGIN
    SET NOCOUNT ON;



    DECLARE @PartyId INT;
	declare @DocumentTypeId int = 0
	if @DocumentType = 'CLIENT'
			set @DocumentTypeId = 1
	if @DocumentType = 'FOURNISSEUR'
		set @DocumentTypeId = 2


    /* =================================================================
       0) Si la facture n'existe pas (Id = 0), on la CRÉE d'abord
       ================================================================= */
    IF ISNULL(@InvoiceId, 0) = 0
    BEGIN
        -- Récupérer le CompanyGUID depuis le client si non fourni
        IF @CompanyGUID IS NULL
        BEGIN
            SELECT TOP 1 @CompanyGUID = CompanyGUID
            FROM dbo.T050Party
            WHERE PartyGUID = @PartyGUID;
        END

        INSERT INTO dbo.T060Document
        (
            CompanyGUID,
            PartyGUID,
            DocumentTypeId,    -- 1 (Facture)
            StatusId,          -- 1
            SourceId,          -- 2
            DocumentDate,
            DueDate,
            ComptabilisationStatus
        )
        VALUES
        (
            @CompanyGUID,
            @PartyGUID,
            @DocumentTypeId,
            1,
            2,
            @IssueDate,
            @DueDate,
            'NON_COMPTABILISE'
        );

        SET @InvoiceId = SCOPE_IDENTITY();

        -- Numéro de document = Id du document
        UPDATE dbo.T060Document
        SET DocumentNumber = CASE WHEN @DocumentTypeId = 1 THEN 'BROUILLON-' + CAST(@InvoiceId AS VARCHAR(20)) ELSE CAST(@InvoiceId AS VARCHAR(20)) END
        WHERE Id = @InvoiceId;
    END

    /* =================================================================
       1) Mise à jour du client (Name / DisplayName / TPS / TVQ / PartyGUID)
          + récupération de @PartyId
       ================================================================= */
    UPDATE T060
    SET
        T060.[Name]        = T050.[Name],
        T060.[DisplayName] = T050.[DisplayName],
        T060.[PartyGUID]   = T050.PartyGUID,
        T060.[TPS_Number]  = T050.[TPS],
        T060.[TVQ_Number]  = T050.[TVQ],
        @PartyId           = T050.Id
    FROM dbo.T060Document T060
    INNER JOIN dbo.T050Party T050 ON T050.PartyGUID = @PartyGUID
    WHERE T060.Id = @InvoiceId;

    /* =================================================================
       2) Récupérer l'adresse principale du client
       ================================================================= */
    DECLARE @Address1   VARCHAR(1000);
    DECLARE @Address2   VARCHAR(1000);
    DECLARE @City       VARCHAR(1000);
    DECLARE @State      VARCHAR(1000);
    DECLARE @Country    VARCHAR(1000);
    DECLARE @PostalCode VARCHAR(1000);
    DECLARE @Phone      VARCHAR(1000);
    DECLARE @Email      VARCHAR(1000);

    SELECT
        @Address1   = T054.[Address1],
        @Address2   = T054.[Address2],
        @City       = T054.[City],
        @State      = T053.Name,
        @Country    = T052.Name,
        @PostalCode = T054.[PostalCode],
        @Phone      = T054.Phone,
        @Email      = T054.Email
    FROM dbo.T054PartyAddress T054
    LEFT JOIN dbo.T053State   T053 ON T053.id = T054.StateId
    LEFT JOIN dbo.T052Country T052 ON T052.id = T054.CountryId
    WHERE AddressTypeId = 1
      AND PartyId = @PartyId;

    /* =================================================================
       3) Mise à jour des dates et infos d'adresse sur la facture
       ================================================================= */
    UPDATE dbo.T060Document
    SET DueDate       = @DueDate,
        DocumentDate  = @IssueDate,
        Address1      = @Address1,
        Address2      = @Address2,
        City          = @City,
        State         = @State,
        Country       = @Country,
        PostalCode    = @PostalCode,
        Phone         = @Phone,
        Email         = @Email
    WHERE Id = @InvoiceId;

    /* =================================================================
       4) DELETE des lignes (Deleted = 1 et Id existant)
       ================================================================= */
    DELETE L
    FROM dbo.T061DocumentLine L
    JOIN @Items I ON I.Id = L.Id
    WHERE L.DocumentId = @InvoiceId
      AND I.Deleted = 1
      AND ISNULL(I.Id, 0) > 0;

    /* =================================================================
       5) UPDATE des lignes (Dirty = 1, Deleted = 0, Id existant)
       ================================================================= */
    UPDATE L
       SET L.ProductId       = CASE WHEN I.ProductId = 0 THEN NULL ELSE I.ProductId END,
           L.[Description]   = I.[Description],
           L.Qty             = I.Qty,
           L.CompteComptable = CONVERT(VARCHAR(20), I.AccountId),
           L.UnitPrice       = I.UnitPrice,
           L.Amount          = I.Amount,
           L.Ordre           = I.Ordre,
           L.TaxeStatus      = I.TaxeStatus
    FROM dbo.T061DocumentLine L
    JOIN @Items I ON I.Id = L.Id
    WHERE L.DocumentId = @InvoiceId
      AND I.Deleted = 0
      AND I.Dirty = 1
      AND ISNULL(I.Id, 0) > 0;

    /* =================================================================
       6) INSERT des nouvelles lignes (Id null/0, Deleted = 0)
       ================================================================= */
    DECLARE @Inserted TABLE (NewId INT NOT NULL);

    INSERT INTO dbo.T061DocumentLine
    (
        DocumentId,
        ProductId,
        CompteComptable,
        [Description],
        Qty,
        UnitPrice,
        Amount,
        Ordre,
        TaxeStatus
    )
    OUTPUT inserted.Id INTO @Inserted (NewId)
    SELECT
        @InvoiceId,
        CASE WHEN I.ProductId = 0 THEN NULL ELSE I.ProductId END,
        CONVERT(VARCHAR(20), I.AccountId),
        I.[Description],
        I.Qty,
        I.UnitPrice,
        I.Amount,
        I.Ordre,
        I.TaxeStatus
    FROM @Items I
    WHERE ISNULL(I.Id, 0) < 0
      AND I.Deleted = 0;

    /* =================================================================
       7) Réordonner les lignes + recalculer les totaux
       ================================================================= */
    EXEC s0091ReorderItem @InvoiceId;
    EXEC sp_RecalculerTotauxDocument @InvoiceId;

    /* =================================================================
       8) Comptabilisation si demandée
       ================================================================= */
    IF @toPost = 1
    BEGIN
        EXEC sp_ComptabiliserDocument @DocumentId = @InvoiceId;
    END

    /* =================================================================
       9) Retour : l'Id de la facture (utile si elle vient d'être créée)
       ================================================================= */
    SELECT @InvoiceId AS InvoiceId; 
END
