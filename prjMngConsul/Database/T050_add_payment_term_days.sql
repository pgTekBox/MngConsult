-- =============================================================================
-- Délai de paiement par tiers — T050Party.PaymentTermDays
--
--   Nombre de jours d'échéance propre au client (ou au fournisseur), défaut 0.
--   Utilisé à la COMPTABILISATION d'une facture pour calculer la date
--   d'échéance : DueDate = DocumentDate + PaymentTermDays.
--   Un brouillon n'a ni date de facture ni date d'échéance : les deux sont
--   attribuées au moment de la transformation en facture
--   (voir sp_ComptabiliserDocument).
--
-- Procédures mises à jour pour transporter la colonne :
--   s0012GetOneSuppliersCustomer (lecture de la fiche)
--   s0017UpdateParty / s0021InsertParty (écriture ; paramètre optionnel,
--   defaut 0, pour ne casser aucun appelant existant).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.T050Party', 'PaymentTermDays') IS NULL
    ALTER TABLE dbo.T050Party
        ADD PaymentTermDays INT NOT NULL CONSTRAINT DF_T050Party_PaymentTermDays DEFAULT (0);
GO

-- ---------------------------------------------------------------- lecture ---
CREATE OR ALTER PROCEDURE [dbo].[s0012GetOneSuppliersCustomer]
    @CompanyGUID uniqueidentifier,
    @PartyId     int
AS
SELECT  [Id]
      ,[PartyGUID]
      ,[CompanyGUID]
      ,[Name]
      ,[DisplayName]
      ,[TPS]
      ,[TVQ]
      ,[WebSite]
      ,[Created]
      ,[Note]
      ,CASE [Origin] WHEN 1 THEN 'Syteme'
                     WHEN 2 THEN 'AI OCR' END Origin
      ,[Type]
      ,[PaymentTermDays]
  FROM [T050Party]
 WHERE CompanyGUID = @CompanyGUID AND Id = @PartyId
GO

-- ------------------------------------------------------------ mise a jour ---
CREATE OR ALTER PROCEDURE [dbo].[s0017UpdateParty]
    @CompanyGUID uniqueidentifier, @DisplayName varchar(500), @Note varchar(max), @Type int,
    @Id int, @Name varchar(500), @TPS varchar(20), @TVQ varchar(20), @WebSite varchar(200),
    @PaymentTermDays int = 0
AS
UPDATE [dbo].[T050Party]
   SET CompanyGUID     = @CompanyGUID
      ,Name            = @Name
      ,DisplayName     = @DisplayName
      ,TPS             = @TPS
      ,TVQ             = @TVQ
      ,WebSite         = @WebSite
      ,Note            = @Note
      ,Type            = @Type
      ,PaymentTermDays = CASE WHEN @PaymentTermDays < 0 THEN 0 ELSE @PaymentTermDays END
 WHERE Id = @Id
GO

-- --------------------------------------------------------------- insertion --
CREATE OR ALTER PROCEDURE [dbo].[s0021InsertParty]
    @CompanyGUID uniqueidentifier, @Origin int, @Note varchar(max), @DisplayName varchar(500),
    @Type int, @Name varchar(500), @PartyCodeiD int, @TPS varchar(20), @TVQ varchar(20),
    @WebSite varchar(200), @PaymentTermDays int = 0
AS

DECLARE @AccountClient varchar(20)
DECLARE @AccountFournisseur varchar(20)
IF @PartyCodeiD = 1
       SET @AccountClient = [dbo].[fGetAccount](@CompanyGUID,'AR')

IF @PartyCodeiD = 2
       SET @AccountFournisseur = [dbo].[fGetAccount](@CompanyGUID,'AP')

INSERT INTO [dbo].[T050Party]
     (CompanyGUID, [CompteAuxClient], [CompteAuxFournisseur], Name, DisplayName, TPS, TVQ,
      WebSite, Note, Type, Origin, PaymentTermDays)
VALUES (@CompanyGUID, @AccountClient, @AccountFournisseur, @Name, @DisplayName, @TPS, @TVQ,
      @WebSite, @Note, @Type, @Origin, CASE WHEN @PaymentTermDays < 0 THEN 0 ELSE @PaymentTermDays END)

DECLARE @NewId int
SET @NewId = @@IDENTITY
SELECT @NewId PartyId
GO

PRINT N'T050_add_payment_term_days.sql : termine.';
GO
