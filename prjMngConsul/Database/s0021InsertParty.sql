SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0021InsertParty — insertion d'un tiers (client / fournisseur) dans T050Party.
-- Correctif 2026-07-24 : @DisplayName varchar(200) -> varchar(500) pour matcher
-- la colonne T050Party.DisplayName varchar(500). Corps inchangé.
-- =============================================================================
CREATE OR ALTER procedure [dbo].[s0021InsertParty]
    @CompanyGUID uniqueidentifier, @Origin int, @Note varchar(max), @DisplayName varchar(500),
    @Type int, @Name varchar(500), @PartyCodeiD int, @TPS varchar(20), @TVQ varchar(20), @WebSite varchar(200)

as

declare @AccountClient varchar(20)
declare @AccountFournisseur varchar(20)
if  @PartyCodeiD = 1
       set @AccountClient = [dbo].[fGetAccount](@CompanyGUID,'AR')

if  @PartyCodeiD = 2
       set @AccountFournisseur = [dbo].[fGetAccount](@CompanyGUID,'AP')


insert into [dbo].[T050Party]
     (CompanyGUID,[CompteAuxClient] ,[CompteAuxFournisseur],Name ,DisplayName,TPS,TVQ,WebSite,Note,Type,Origin )
	 values (@CompanyGUID, @AccountClient ,@AccountFournisseur , @Name ,@DisplayName  , @TPS,  @TVQ ,@WebSite,@Note,@Type,@Origin)

declare @NewId int
set @NewId = @@IDENTITY
select @NewId  PartyId
GO
