-- =============================================================================
-- s0034SaveCustomerDocument — facture client créée à partir du JSON du scan
-- -----------------------------------------------------------------------------
-- Mêmes deux corrections que s0009SaveDocument :
--   - TaxeStatus = 1 sur les lignes insérées, sans quoi
--     sp_RecalculerTotauxDocument remet TPS et TVQ à 0 et ramène le Total au
--     sous-total ;
--   - les montants de taxes lus dans $.totals.taxes sont reportés sur les
--     lignes (au prorata, écart d'arrondi sur la plus grosse), parce que c'est
--     le montant réellement facturé qui fait foi.
--
-- Le bloc de rattachement au rapport de taxe reste commenté, comme il l'était.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [dbo].[s0034SaveCustomerDocument] @imageGUID uniqueidentifier as

--     s0034SaveCustomerDocument   '804E48CA-CBCE-4715-B233-44A7BF152028'
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
 
select @DocumentTypeId = Id from [dbo].[T065DocumentType] where [Name] = 'FactureClient'
select @DocumentStatusId = Id from [dbo].[T066DocumentStatus] where [Name] = 'Draft'
select @DocumentSourceId = Id from  [dbo].[T067DocumentSource]  where [Name] = 'OCR'

declare @Name varchar(500)
declare @DisplayName varchar(500)
 


  select @Name =Name,  
         @DisplayName= DisplayName   
  from  [dbo].[T050Party] where id = @PartyId

declare @Total numeric(18,4) =  JSON_VALUE(@json, '$.totals.total') 
declare @SubTotal numeric(18,4) =  JSON_VALUE(@json, '$.totals.subtotal') 

-- (un « select @SubTotal » de mise au point trainait ici : il renvoyait un jeu
--  de resultats parasite a l'appelant, il est retire.)
declare @TPS_amount numeric(18,2)
declare @TVQ_amount numeric(18,2)
set @TPS_amount = ( 
                    select top 1 amount 
					  from openjson(@json,'$.totals.taxes')
					  with (
					  code nvarchar(20)  '$.code' ,
					  amount numeric(18,2) '$.amount'
					  ) 
					  where code in ('TPS')
				     )
set @TVQ_amount = ( 
                    select top 1 amount 
					  from openjson(@json,'$.totals.taxes')
					  with (
					  code nvarchar(20)  '$.code' ,
					  amount numeric(18,2) '$.amount'
					  ) 
					  where code in ('TVQ')
				     )

declare @InvoiceNumber varchar(20) =JSON_VALUE(@json, '$.invoice.number') 
declare @DateFacturaion date       = dbo.fn_StringToDateTime (JSON_VALUE(@json, '$.invoice.issue_date') )  
declare @DueDate date       = dbo.fn_StringToDateTime (JSON_VALUE(@json, '$.invoice.due_date') )




--select @TPS_amount,@TVQ_amount,@DateFacturaion,@InvoiceNumber
--     s0034SaveCustomerDocument   '804E48CA-CBCE-4715-B233-44A7BF152028'
 
  
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
 


insert into [dbo].[T060Document] (  Address1,  Address2,    City , State , Country , PostalCode, Phone, Email, Note, [DocumentDate],DueDate, Total,Name,DisplayName,  [DocumentNumber] ,[CompanyGUID],[PartyGUID],[DocumentTypeId] ,[StatusId],imageGUID,SourceId) 
                            values( @Address1, @Address2,   @City ,@State ,@Country ,@PostalCode,@Phone,@Email,@Note,@DateFacturaion,@DueDate, @Total,@Name,@DisplayName,  @InvoiceNumber,  @CompanyGUID,@PartyGUID,  @DocumentTypeId,@DocumentStatusId,@imageGUID,@DocumentSourceId)

 set @T060DocumentId = @@IDENTITY
  


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
    [description],
    line_total,
	unit_price,
	quantity,
	1,
	-- TaxeStatus n'etait pas renseigne : sp_RecalculerTotauxDocument remet TPS
	-- et TVQ a 0 pour toute ligne dont TaxeStatus <> 1, et recalcule ensuite le
	-- Total de l'entete a partir des lignes. La facture client issue de l'OCR
	-- perdait donc ses taxes, et son Total tombait au sous-total alors que le
	-- JSON portait le bon montant.
	1

FROM OPENJSON(@json, '$.line_items')
WITH
(
    description VARCHAR(1000),
    line_total numeric(18,4),
	unit_price  numeric(18,4),
	quantity numeric(18,4)
)

/*
   Insert les ligne du document pour le rapport de taxe

declare @T070RapportTaxe_Id int = 1
insert into [dbo].[T071_T061DocumentLine_T070RapportTaxe]
    (T070RapportTaxe_Id  , T061DocumentLine_id )
	select  @T070RapportTaxe_Id, Id from  [dbo].[T061DocumentLine] where [DocumentId]=@T060DocumentId and [IncludeInRepport_TPS_TVQ] =1


--  Normalise les ligne du document, calcule TPS et TVQ
exec s0024NormaliseTaxe @T060DocumentId
exec s0025BuildTaxeRepport
*/
-- Calule les totaux a partir des ligne vers la T060Document
exec sp_RecalculerTotauxDocument  @T060DocumentId

/*
   Taxes reellement facturees.

   sp_RecalculerTotauxDocument recalcule les taxes aux taux courants. Sur une
   facture client, c'est le montant reellement facture qui fait foi : @TPS_amount
   et @TVQ_amount, deja lus plus haut dans $.totals.taxes, le remplacent.

   Repartition au prorata du montant de chaque ligne, l'ecart d'arrondi allant
   sur la ligne la plus importante : la somme des lignes redonne exactement le
   total de la facture.
*/
if (@TPS_amount is not null or @TVQ_amount is not null)
begin
    declare @Base numeric(18,4)
    select @Base = sum(coalesce([Amount], 0)) from [dbo].[T061DocumentLine] where [DocumentId] = @T060DocumentId

    if coalesce(@Base, 0) > 0
    begin
        update [dbo].[T061DocumentLine]
           set [TPS] = round(coalesce(@TPS_amount, 0) * coalesce([Amount], 0) / @Base, 2),
               [TVQ] = round(coalesce(@TVQ_amount, 0) * coalesce([Amount], 0) / @Base, 2)
         where [DocumentId] = @T060DocumentId

        declare @TPS_Reparti numeric(18,2)
        declare @TVQ_Reparti numeric(18,2)
        select @TPS_Reparti = sum(coalesce([TPS], 0)), @TVQ_Reparti = sum(coalesce([TVQ], 0))
          from [dbo].[T061DocumentLine] where [DocumentId] = @T060DocumentId

        declare @LigneMax int
        select top 1 @LigneMax = [Id] from [dbo].[T061DocumentLine]
         where [DocumentId] = @T060DocumentId order by coalesce([Amount], 0) desc, [Id]

        if @LigneMax is not null
            update [dbo].[T061DocumentLine]
               set [TPS] = coalesce([TPS], 0) + (coalesce(@TPS_amount, 0) - @TPS_Reparti),
                   [TVQ] = coalesce([TVQ], 0) + (coalesce(@TVQ_amount, 0) - @TVQ_Reparti)
             where [Id] = @LigneMax

        update [dbo].[T061DocumentLine]
           set [Total] = coalesce([Amount], 0) + coalesce([TPS], 0) + coalesce([TVQ], 0)
         where [DocumentId] = @T060DocumentId

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
GO
