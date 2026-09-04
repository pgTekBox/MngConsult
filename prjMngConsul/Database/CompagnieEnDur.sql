-- =============================================================================
-- La compagnie n'est plus écrite en dur
-- -----------------------------------------------------------------------------
-- Trois procédures écrivaient ou lisaient CompanyGUID = '87893D29-…' (Baignoire
-- Excel) quelle que soit la compagnie du reçu :
--   s0008SaveMerchant             le marchand était créé dans cette compagnie
--   s0033SaveCustomer             idem pour le client d'une facture scannée
--   sp_ResoudreCompteDocumentLine les comptes par défaut étaient cherchés dans
--                                 le plan comptable de cette compagnie
--
-- Chacune prend maintenant la compagnie de son contexte : celle du reçu pour les
-- deux premières, celle du document pour la troisième.
--
-- Les occurrences du GUID restées dans des lignes commentées (exemples d'appel)
-- ne sont pas touchées.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
--      s0008SaveMerchant '60B445FF-0C63-4942-88EE-1A3E752933C9'
CREATE OR ALTER PROCEDURE [dbo].[s0008SaveMerchant] @imageGUID uniqueidentifier  as


declare @PartyGUID uniqueidentifier
-- La compagnie du marchand est celle du recu : elle etait ecrite en dur.
declare @CompanyGUID uniqueidentifier
 
declare @json varchar(max)
declare @merchant_name varchar(200)
declare @merchant_street varchar(500)



select @json = [AI_JSON], @CompanyGUID = [CompanyGUID]  from [dbo].[T0001Receipt] where  [imageGUID]=@imageGUID

set @merchant_name = JSON_VALUE(@json, '$.merchant_name')
set @merchant_street = coalesce( JSON_VALUE(@json, '$.merchant_street'),'')



Declare @PartyId int
-- fait une recherche par le nom , Address1
if ((select count(*) from [dbo].[T050Party] t050
          inner join [dbo].[T054PartyAddress] T054 on t050.[Id]=T054.[PartyId]
             where t050.name  COLLATE Latin1_General_CI_AI  = @merchant_name and coalesce([Address1],'')  COLLATE Latin1_General_CI_AI =  @merchant_street  and  [CompanyGUID]=@CompanyGUID) =0)
    begin
      declare @StateId as int 
      declare @CountryId as int 
	  declare @PartyTypeId int 

	   select @PartyTypeId = id  from  [dbo].[T055PartyType]  where [TypeCode]  COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.receipt_type') 
	  if @PartyTypeId is null
	       begin
		      insert into [T055PartyType] (TypeCode,Name) values (JSON_VALUE(@json, '$.receipt_type') ,JSON_VALUE(@json, '$.receipt_type') )
			   select @PartyTypeId = id  from  [dbo].[T055PartyType]  where [TypeCode]  COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.receipt_type') 

		   end


	    select @StateId = id, @CountryId = CountryId from  [dbo].[T053State] where name COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.merchant_state') 
	    if @StateId is null 
		begin 
		    if  JSON_VALUE(@json, '$.merchant_state')  in ('QC','QUE')
			    select @StateId = id ,@CountryId = CountryId  from  [dbo].[T053State] where name = 'Quebec'
				else
			    select @StateId = id ,@CountryId = CountryId  from  [dbo].[T053State] where name = 'Unknown'
        end

			INSERT INTO  [dbo].[T050Party]
			(
				  [CompanyGUID]
				   
                   ,[CompteAuxClient]
				   ,[CompteAuxFournisseur] 
				  ,[Name]
				  ,DisplayName
				  
				  ,[Type]
				 
			 
				  ,[TPS]
				  ,[TVQ]
				  ,[WebSite]
                  ,[Origin]
	  
			)
			SELECT
				 @CompanyGUID,
				dbo.fGetAccount (@CompanyGUID,'AR'),
				dbo.fGetAccount (@CompanyGUID,'AP'),
				JSON_VALUE(@json, '$.merchant_name'),
				JSON_VALUE(@json, '$.merchant_name'),
				 
				 @PartyTypeId,
			 
			  
				JSON_VALUE(@json, '$.number_tps'),
				JSON_VALUE(@json, '$.number_tvq'),
				JSON_VALUE(@json, '$.merchant_website') ,
				2
	
	set @PartyId = @@IDENTITY 
	select @PartyGUID = PartyGUID from [dbo].[T050Party] where id = @PartyId

	insert into [dbo].[T054PartyAddress]
	            ([PartyId],
                 [AddressTypeId],
	             [Address1],
                 [City],
                  [StateId],
                 [CountryId],
                [PostalCode],
                [Phone],
                 [Email])
				 values (
				 @PartyId,
				 1,
				 JSON_VALUE(@json, '$.merchant_street'),
				  JSON_VALUE(@json, '$.merchant_city'),
				   @StateId  ,
				   @CountryId ,
                 JSON_VALUE(@json, '$.merchand_postalcode'),
				  JSON_VALUE(@json, '$.merchant_phonenumber'),
				    JSON_VALUE(@json, '$.merchant_email'))


	update  [dbo].[T0001Receipt] set PartyGUID = @PartyGUID  where  [imageGUID]=@imageGUID
END
    else
	begin
	select   @PartyGUID = PartyGUID from [dbo].[T050Party] t050
          inner join [dbo].[T054PartyAddress] T054 on t050.[Id]=T054.[PartyId]
             where t050.name  COLLATE Latin1_General_CI_AI  = @merchant_name and coalesce([Address1],'')  COLLATE Latin1_General_CI_AI =  @merchant_street  and  [CompanyGUID]=@CompanyGUID
	update  [dbo].[T0001Receipt] set  PartyGUID = @PartyGUID  where  [imageGUID]=@imageGUID
	end
GO

CREATE OR ALTER PROCEDURE [dbo].[s0033SaveCustomer] @imageGUID uniqueidentifier  as


--             [s0033SaveCustomer] '804E48CA-CBCE-4715-B233-44A7BF152028'

declare @PartyGUID uniqueidentifier
-- La compagnie du client est celle du document scanne : elle etait ecrite en dur.
declare @CompanyGUID uniqueidentifier
 
declare @json varchar(max)
declare @buyer_name varchar(200)
declare @StateId int
declare @CountryId int
declare @PartyId int
declare @Buyer_address1  varchar(500)


select @json = [AI_JSON], @CompanyGUID = [CompanyGUID]  from [dbo].[T0001Receipt] where  [imageGUID]=@imageGUID
 
set @buyer_name = JSON_VALUE(@json, '$.buyer.name')
set @Buyer_address1 = JSON_VALUE(@json, '$.buyer.address.line1')

if ((select count(*) from [dbo].[T050Party] t050
          inner join [dbo].[T054PartyAddress] T054 on t050.[Id]=T054.[PartyId]
             where t050.name  COLLATE Latin1_General_CI_AI  = @buyer_name and coalesce([Address1],'')  COLLATE Latin1_General_CI_AI =  @Buyer_address1  and  [CompanyGUID]=@CompanyGUID) =0)
			  
   begin
         select @StateId = id, @CountryId = CountryId from  [dbo].[T053State] where name COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.buyer.address.province') 
				if @StateId is null 
				begin 
					if  JSON_VALUE(@json, '$.buyer.address.province')  in ('QC','QUE','Québec')
						select @StateId = id ,@CountryId = CountryId  from  [dbo].[T053State] where name = 'Quebec'
						else
						select @StateId = id ,@CountryId = CountryId  from  [dbo].[T053State] where name = 'Unknown'
				end
 
 			INSERT INTO  [dbo].[T050Party]
					(
						  [CompanyGUID]
						  ,[CompteAuxClient]
						  ,[Name]
						  ,DisplayName
						  ,[Origin]
					)
					SELECT
    					@CompanyGUID,
						dbo.fGetAccount (@CompanyGUID,'AR'),
						JSON_VALUE(@json,   '$.buyer.name'),
						JSON_VALUE(@json,   '$.buyer.name'),
						3
					set @PartyId = @@IDENTITY 
	                select @PartyGUID = PartyGUID from [dbo].[T050Party] where id = @PartyId
					update  [dbo].[T0001Receipt] set PartyGUID = @PartyGUID  where  [imageGUID]=@imageGUID
					--select @imageGUID
					-- A_DELETE_CLIENT
					-- select id , partyguid from [dbo].[T0001Receipt]
					insert into [dbo].[T054PartyAddress]
								([PartyId],
								 [AddressTypeId],
								 [Address1],
								 [Address2],
								 [City],
								 [StateId],
								 [CountryId],
								 [PostalCode],
								 [Phone],
								 [Email]
								 )
								  values (
									@PartyId,
									1,
									JSON_VALUE(@json, '$.buyer.address.line1'),
									JSON_VALUE(@json, '$.buyer.address.line2'),
									JSON_VALUE(@json, '$.buyer.address.city'),
									@StateId  ,
									@CountryId ,
									JSON_VALUE(@json, '$.buyer.address.postal_code'),
									JSON_VALUE(@json, '$.buyer.phone'),
									JSON_VALUE(@json, '$.buyer.email'))

   end
   else
   begin 

   	select   @PartyGUID = PartyGUID from [dbo].[T050Party] t050
          inner join [dbo].[T054PartyAddress] T054 on t050.[Id]=T054.[PartyId]
          where t050.name  COLLATE Latin1_General_CI_AI  = @buyer_name and 
		        coalesce([Address1],'')  COLLATE Latin1_General_CI_AI = @Buyer_address1  and  
				[CompanyGUID]=@CompanyGUID
--	update  [dbo].[T0001Receipt] set  PartyGUID = @PartyGUID  where  [imageGUID]=@imageGUID


   end

--set @merchant_street = coalesce( JSON_VALUE(@json, '$.merchant_street'),'')



--Declare @PartyId int
---- fait une recherche par le nom , Address1
--if ((select count(*) from [dbo].[T050Party] t050
--          inner join [dbo].[T054PartyAddress] T054 on t050.[Id]=T054.[PartyId]
--             where t050.name  COLLATE Latin1_General_CI_AI  = @merchant_name and coalesce([Address1],'')  COLLATE Latin1_General_CI_AI =  @merchant_street  and  [CompanyGUID]='87893D29-6D64-40C8-8E45-A3492B4FBB91') =0)
--    begin
--      declare @StateId as int 
--      declare @CountryId as int 
--	  declare @PartyTypeId int 

--	   select @PartyTypeId = id  from  [dbo].[T055PartyType]  where [TypeCode]  COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.receipt_type') 
--	  if @PartyTypeId is null
--	       begin
--		      insert into [T055PartyType] (TypeCode,Name) values (JSON_VALUE(@json, '$.receipt_type') ,JSON_VALUE(@json, '$.receipt_type') )
--			   select @PartyTypeId = id  from  [dbo].[T055PartyType]  where [TypeCode]  COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.receipt_type') 

--		   end


--	    select @StateId = id, @CountryId = CountryId from  [dbo].[T053State] where name COLLATE Latin1_General_CI_AI=   JSON_VALUE(@json, '$.merchant_state') 
--	    if @StateId is null 
--		begin 
--		    if  JSON_VALUE(@json, '$.merchant_state')  in ('QC','QUE')
--			    select @StateId = id ,@CountryId = CountryId  from  [dbo].[T053State] where name = 'Quebec'
--				else
--			    select @StateId = id ,@CountryId = CountryId  from  [dbo].[T053State] where name = 'Unknown'
--        end

--			INSERT INTO  [dbo].[T050Party]
--			(
--				  [CompanyGUID]
--				  ,[PartyCodeId]
--				  ,[Name]
--				  ,DisplayName
				  
--				  ,[Type]
				 
			 
--				  ,[TPS]
--				  ,[TVQ]
--				  ,[WebSite]
--                  ,[Origin]
	  
--			)
--			SELECT
--				 '87893D29-6D64-40C8-8E45-A3492B4FBB91',
--				@PartyCodeId,
--				JSON_VALUE(@json, '$.merchant_name'),
--				JSON_VALUE(@json, '$.merchant_name'),
				 
--				 @PartyTypeId,
			 
			  
--				JSON_VALUE(@json, '$.number_tps'),
--				JSON_VALUE(@json, '$.number_tvq'),
--				JSON_VALUE(@json, '$.merchant_website') ,
--				2
	
--	set @PartyId = @@IDENTITY 
--	select @PartyGUID = PartyGUID from [dbo].[T050Party] where id = @PartyId

--	insert into [dbo].[T054PartyAddress]
--	            ([PartyId],
--                 [AddressTypeId],
--	             [Address1],
--                 [City],
--                  [StateId],
--                 [CountryId],
--                [PostalCode],
--                [Phone],
--                 [Email])
--				 values (
--				 @PartyId,
--				 1,
--				 JSON_VALUE(@json, '$.merchant_street'),
--				  JSON_VALUE(@json, '$.merchant_city'),
--				   @StateId  ,
--				   @CountryId ,
--                 JSON_VALUE(@json, '$.merchand_postalcode'),
--				  JSON_VALUE(@json, '$.merchant_phonenumber'),
--				    JSON_VALUE(@json, '$.merchant_email'))


--	update  [dbo].[T0001Receipt] set PartyGUID = @PartyGUID  where  [imageGUID]=@imageGUID
--END
--    else
--	begin
--	select   @PartyGUID = PartyGUID from [dbo].[T050Party] t050
--          inner join [dbo].[T054PartyAddress] T054 on t050.[Id]=T054.[PartyId]
--             where t050.name  COLLATE Latin1_General_CI_AI  = @merchant_name and coalesce([Address1],'')  COLLATE Latin1_General_CI_AI =  @merchant_street  and  [CompanyGUID]='87893D29-6D64-40C8-8E45-A3492B4FBB91'
--	update  [dbo].[T0001Receipt] set  PartyGUID = @PartyGUID  where  [imageGUID]=@imageGUID
--	end
GO

-- ============================================================
-- 4. sp_ResoudreCompteDocumentLine — inchangée
--    Utilise v_Products qui gère déjà les 2 niveaux
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[sp_ResoudreCompteDocumentLine]
    @DocumentLineId INT,
    @DocumentTypeId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Les comptes par defaut se cherchent dans le plan comptable de la
    -- compagnie DU DOCUMENT : le GUID etait ecrit en dur, une ligne d'une
    -- autre compagnie tombait donc sur un plan comptable qui n'est pas le sien.
    DECLARE @CompanyGUID  UNIQUEIDENTIFIER;

    SELECT @CompanyGUID = d.[CompanyGUID]
      FROM [dbo].[T061DocumentLine] l
      JOIN [dbo].[T060Document] d ON d.[Id] = l.[DocumentId]
     WHERE l.[Id] = @DocumentLineId;

    DECLARE
        @ProductId      INT,
        @CompteVente    VARCHAR(20),
        @CompteAchat    VARCHAR(20),
        @CompteResolu   VARCHAR(20),
        @TaxeStatusId   INT;

    SELECT @ProductId=[ProductId]
    FROM [dbo].[T061DocumentLine]
    WHERE [Id]=@DocumentLineId;

    IF @ProductId IS NOT NULL
    BEGIN
        SELECT
            @CompteVente  =[CompteVente],
            @CompteAchat  =[CompteAchat],
            @TaxeStatusId =[TaxeStatusId]
        FROM [dbo].[v_Products]       -- COALESCE déjà fait dans la vue
        WHERE [ProductId]=@ProductId;
    END
--	Id	Name	Description
--1	FactureClient	Facture Client  (AR)
--2	FactureFournisseur	Facture Fournisseur  (AP)
--3	CreditClient	Avoir Client (AR Credit)
--4	CreditFournisseur	Avoir Fournisseur (AP Credit)
--5	ReceiptOCR	Reçu (Receipt OCR)
--6	Expense	Expense (Dépense)
--9	Autre	Autre

--ShortName	Name
--AR	CompteAuxClient
--AP	CompteAuxFournisseur
--VP	Vente de produit
--AP	Achat produits
--CC	Credit client


-- select [dbo].[fGetAccount]('87893d29-6d64-40c8-8e45-a3492b4fbb91','AR') 

    SET @CompteResolu=CASE @DocumentTypeId
        WHEN 1 THEN ISNULL(@CompteVente,  [dbo].[fGetAccount](@CompanyGUID,'AR'))
        WHEN 3 THEN ISNULL(@CompteVente, [dbo].[fGetAccount](@CompanyGUID,'CC'))
        WHEN 2 THEN ISNULL(@CompteAchat, [dbo].[fGetAccount](@CompanyGUID,'AP'))
        WHEN 4 THEN ISNULL(@CompteAchat,[dbo].[fGetAccount](@CompanyGUID,'CF'))
        WHEN 5 THEN ISNULL(@CompteAchat, [dbo].[fGetAccount](@CompanyGUID,'AP'))
        WHEN 6 THEN ISNULL(@CompteAchat, [dbo].[fGetAccount](@CompanyGUID,'DP'))
        ELSE '0'
    END;
	 
	if @CompteResolu <> '0'
	begin
	 
		UPDATE [dbo].[T061DocumentLine]
		SET [CompteComptable] = @CompteResolu,
			[TaxeStatus]  = ISNULL(@TaxeStatusId,[TaxeStatus])
		WHERE [Id]=@DocumentLineId and  coalesce(CompteComptable,'') = '' ;
     end 
	 

    --SELECT @CompteResolu AS CompteResolu;
END;
GO

PRINT N'CompagnieEnDur.sql : termine.';
GO
