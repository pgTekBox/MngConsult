-- =============================================================================
-- s0009SaveDocument — création du document (T060/T061) à partir du JSON du reçu
-- -----------------------------------------------------------------------------
-- Correction : le lien vers le rapport de taxe utilisait un Id écrit en dur
-- (T070RapportTaxe_Id = 1). Ce rapport n'existe plus, la clé étrangère
-- FK_T071_T061DocumentLine_T070RapportTaxe_T070RapportTaxe rejetait donc chaque
-- insertion. Le rapport est maintenant résolu par compagnie et par période, et
-- le lien est simplement omis quand aucune période ne couvre la date.
--
-- Le reste de la procédure est inchangé.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [dbo].[s0009SaveDocument] @imageGUID uniqueidentifier as

--      s0009SaveDocument  '6E7F2478-69C1-4159-8A5B-F7FF38FDAF78'
--      s0009SaveDocument  'A091BD91-9738-4580-B5C8-FCC925CC7C9E'


--       exec A_DELETE_DOC


declare @CompanyGUID uniqueidentifier
declare @PartyGUID uniqueidentifier
declare @DocumentTypeId int 
declare @DocumentStatusId int
declare @DocumentSourceId int
declare @json varchar(max)
if (( select count(*) from [T060Document] where imageGUID = @imageGUID ) > 0 )
    return

declare @T060DocumentId int
declare @PartyId int
select  @CompanyGUID=CompanyGUID, @PartyGUID=PartyGUID,@json =[AI_JSON]  from [dbo].[T0001Receipt] where [imageGUID]=@imageGUID
 
select @PartyId=Id from  [dbo].[T050Party] where [PartyGUID]=@PartyGUID
 
select @DocumentTypeId = Id from [dbo].[T065DocumentType] where [Name] = 'ReceiptOCR'
select @DocumentStatusId = Id from [dbo].[T066DocumentStatus] where [Name] = 'Draft'
select @DocumentSourceId = Id from  [dbo].[T067DocumentSource]  where [Name] = 'OCR'

declare @Name varchar(500)
declare @DisplayName varchar(500)
declare @TPS varchar(20)
declare @TVQ varchar(20)


select @Name =Name,  @DisplayName= DisplayName,  @TPS= TPS,  @TVQ= TVQ from  [dbo].[T050Party] where id = @PartyId
declare @Total numeric(18,4) =  JSON_VALUE(@json, '$.total') 

declare @DocumentNumber varchar(200) = JSON_VALUE(@json, '$.receipt_number') 
declare @DocumentDate datetime  = dbo.fn_StringToDateTime (JSON_VALUE(@json, '$.receipt_date') )

declare @Address1 varchar(500)   
declare @Address2 varchar(500)    
declare @City varchar(50)
 
declare @State varchar(50)
declare @StateId int
declare @Country varchar(50)
declare @CountryId int
declare @PostalCode varchar(50)
declare @Phone varchar(50)
declare @Email varchar(150)
declare @Note varchar(max)
declare @AddressType int

select @AddressType = id from [dbo].[T064AddressType] where name = 'Billing'


select @Address1 = Address1 ,
      @Address2 = Address2,
      @City = City,
      @StateId = StateId,
      @CountryId = CountryId,
      @PostalCode = PostalCode,
      @Phone = Phone,
	  @Email = Email,
	  @Note = note
	  from [dbo].[T054PartyAddress] 
	  where [PartyId] =  @PartyId and [AddressTypeId] =@AddressType

select  @State = name from  [dbo].[T053State]  where [Id]=@StateId
select @Country =  Name from [dbo].[T052Country]  where [Id]=@CountryId
 


insert into [dbo].[T060Document] (  Address1,  Address2,    City , State , Country , PostalCode, Phone, Email, Note, [DocumentDate],Total,Name,DisplayName,TPS_Number,TVQ_Number, [DocumentNumber] ,[CompanyGUID],[PartyGUID],[DocumentTypeId] ,[StatusId],imageGUID,SourceId) 
                            values( @Address1, @Address2,   @City ,@State ,@Country ,@PostalCode,@Phone,@Email,@Note,@DocumentDate, @Total,@Name,@DisplayName,@TPS,@TVQ, @DocumentNumber,  @CompanyGUID,@PartyGUID,  @DocumentTypeId,@DocumentStatusId,@imageGUID,@DocumentSourceId)

set @T060DocumentId = @@IDENTITY

declare @Description varchar(2000)
declare @Qty numeric(18,4)
declare @UnitPrice numeric(18,4) 
declare @Amount numeric(18,4)
 --"items": [
 --   {
 --     "desc": "TABLETTE GRILLAGEE SUPER SLIDE 12\"X12' 471921",
 --     "qty": 1,
 --     "unit_price": 34.99,
 --     "amount": 34.99
 --   },
 --   {
 --     "desc": "SUPPORT FAST TRACK 12\" BLANC",
 --     "qty": 3,
 --     "unit_price": 5.99,
 --     "amount": 17.97
 --   }


INSERT INTO T061DocumentLine
(
    DocumentId,
    Description,
    Amount,
	UnitPrice,
	Qty,
	IncludeInRepport_TPS_TVQ,
	TaxeStatus
)
SELECT
    @T060DocumentId,
    [desc],
    amount,
	unit_price,
	qty,
	1,
	-- TaxeStatus n'etait pas renseigne : sp_RecalculerTotauxDocument, appelee
	-- au bout de s0024NormaliseTaxe, remet TPS et TVQ a 0 pour toute ligne dont
	-- TaxeStatus <> 1. Les documents issus de l'OCR sortaient donc toujours
	-- sans taxes, et leur Total valait le sous-total.
	1

FROM OPENJSON(@json, '$.items')
WITH
(
    [desc] VARCHAR(1000),
    amount numeric(18,4),
	unit_price  numeric(18,4),
	qty numeric(18,4)
)

/*
   Insert les ligne du document pour le rapport de taxe

   L'Id du rapport etait ecrit en dur (= 1). Ce rapport n'existe plus dans
   T070RapportTaxe : chaque insertion violait donc la cle etrangere
   FK_T071_T061DocumentLine_T070RapportTaxe_T070RapportTaxe et l'instruction
   etait annulee ("The INSERT statement conflicted with the FOREIGN KEY
   constraint..."), aussi bien depuis wbfReceipt.aspx que depuis le service.

   On resout maintenant le rapport de la compagnie du document dont la periode
   couvre la date du document. S'il n'y en a pas (date hors periode connue, ou
   compagnie sans rapport ouvert), on ne cree simplement pas le lien : le
   document reste valide, il sera rattache quand le rapport de la periode
   existera.
*/
declare @T070RapportTaxe_Id int
declare @DateRapport date = convert(date, coalesce(@DocumentDate, getdate()))

select top 1 @T070RapportTaxe_Id = [Id]
  from [dbo].[T070RapportTaxe]
 where [CompanyGUID]   = @CompanyGUID
   and @DateRapport   >= [DebutPeriode]
   and @DateRapport   <= [FinPeriode]
 order by [DebutPeriode] desc

if @T070RapportTaxe_Id is not null
begin
    insert into [dbo].[T071_T061DocumentLine_T070RapportTaxe]
        (T070RapportTaxe_Id  , T061DocumentLine_id )
        select  @T070RapportTaxe_Id, Id from  [dbo].[T061DocumentLine] where [DocumentId]=@T060DocumentId and [IncludeInRepport_TPS_TVQ] =1
end


--  Normalise les ligne du document, calcule TPS et TVQ
exec s0024NormaliseTaxe @T060DocumentId

/*
   Taxes reellement facturees.

   s0024NormaliseTaxe recalcule les taxes a partir des taux (5 % / 9,975 %).
   C'est le bon repli, mais ce n'est pas ce qu'on doit inscrire : pour un CTI /
   RTI, c'est le montant imprime sur le recu qui fait foi, pas une reestimation.
   Quand le JSON porte des montants de taxes, ils remplacent donc le calcul.

   Repartition au prorata du montant de chaque ligne, l'ecart d'arrondi allant
   sur la ligne la plus importante : la somme des lignes redonne exactement le
   montant du recu.
*/
declare @TPS_Json numeric(18,2)
declare @TVQ_Json numeric(18,2)

select @TPS_Json = sum(case when upper(t.name) like 'TPS%' or upper(t.name) like 'GST%' then t.amount end),
       @TVQ_Json = sum(case when upper(t.name) like 'TVQ%' or upper(t.name) like 'QST%' then t.amount end)
  from openjson(@json, '$.taxes')
  with ( name varchar(100), amount numeric(18,4) ) t

if (@TPS_Json is not null or @TVQ_Json is not null)
begin
    declare @Base numeric(18,4)
    select @Base = sum(coalesce([Amount], 0)) from [dbo].[T061DocumentLine] where [DocumentId] = @T060DocumentId

    if coalesce(@Base, 0) > 0
    begin
        update [dbo].[T061DocumentLine]
           set [TPS] = round(coalesce(@TPS_Json, 0) * coalesce([Amount], 0) / @Base, 2),
               [TVQ] = round(coalesce(@TVQ_Json, 0) * coalesce([Amount], 0) / @Base, 2)
         where [DocumentId] = @T060DocumentId

        -- Ecart d'arrondi : on le pose sur la ligne la plus grosse.
        declare @TPS_Reparti numeric(18,2)
        declare @TVQ_Reparti numeric(18,2)
        select @TPS_Reparti = sum(coalesce([TPS], 0)), @TVQ_Reparti = sum(coalesce([TVQ], 0))
          from [dbo].[T061DocumentLine] where [DocumentId] = @T060DocumentId

        declare @LigneMax int
        select top 1 @LigneMax = [Id] from [dbo].[T061DocumentLine]
         where [DocumentId] = @T060DocumentId order by coalesce([Amount], 0) desc, [Id]

        if @LigneMax is not null
            update [dbo].[T061DocumentLine]
               set [TPS] = coalesce([TPS], 0) + (coalesce(@TPS_Json, 0) - @TPS_Reparti),
                   [TVQ] = coalesce([TVQ], 0) + (coalesce(@TVQ_Json, 0) - @TVQ_Reparti)
             where [Id] = @LigneMax

        update [dbo].[T061DocumentLine]
           set [Total] = coalesce([Amount], 0) + coalesce([TPS], 0) + coalesce([TVQ], 0)
         where [DocumentId] = @T060DocumentId

        -- Les totaux de l'entete suivent les lignes.
        update d
           set [SubTotal] = x.SousTotal,
               [TPS]      = x.TPS,
               [TVQ]      = x.TVQ,
               [Total]    = x.SousTotal + x.TPS + x.TVQ
          from [dbo].[T060Document] d
         cross apply ( select sum(coalesce(l.[Amount], 0)) SousTotal,
                              sum(coalesce(l.[TPS], 0))    TPS,
                              sum(coalesce(l.[TVQ], 0))    TVQ
                         from [dbo].[T061DocumentLine] l where l.[DocumentId] = d.[Id] ) x
         where d.[Id] = @T060DocumentId
    end
end

exec sp_ResoudreComptesDocument @T060DocumentId
exec s0025BuildTaxeRepport
GO
