SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0017UpdateParty — mise à jour d'un tiers (client / fournisseur) dans T050Party.
-- Correctif 2026-07-24 : @DisplayName varchar(200) -> varchar(500) pour matcher
-- la colonne T050Party.DisplayName varchar(500). Corps inchangé.
-- =============================================================================
CREATE OR ALTER procedure [dbo].[s0017UpdateParty]
    @CompanyGUID uniqueidentifier, @DisplayName varchar(500), @Note varchar(max), @Type int,
    @Id int, @Name varchar(500), @TPS varchar(20), @TVQ varchar(20), @WebSite varchar(200)

as

UPDATE [dbo].[T050Party]
   SET CompanyGUID = @CompanyGUID
      ,Name = @Name
      ,DisplayName  =  @DisplayName
      ,TPS = @TPS
      ,TVQ = @TVQ
      ,WebSite = @WebSite
	  ,Note = @Note
	  ,Type= @Type

 WHERE Id = @Id
GO
