SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0038GetInvoiceById — lecture d'une facture (entete) pour l'ecran d'edition.
-- Correctif 2026-07-24 : PoNumber renvoyait la constante 123 (factice) -> renvoie
-- desormais la vraie colonne T060Document.PoNumber. RefNo reste l'alias de
-- DocumentNumber. Reste inchange par ailleurs.
-- =============================================================================
CREATE OR ALTER procedure [dbo].[s0038GetInvoiceById] @InvoiceId int as


SELECT [Id]
      ,[Created]
      ,[DocumentGUID]
      ,[CompanyGUID]
      ,coalesce([PartyGUID],CONVERT(UNIQUEIDENTIFIER, '00000000-0000-0000-0000-000000000000')) [PartyGUID]
      ,[DocumentTypeId]
      ,[StatusId]
      ,coalesce([DocumentDate],getdate()) IssueDate
	  ,coalesce(DueDate,getdate()) DueDate
      ,[DocumentNumber]
      ,[SubTotal]
      ,[TPS]
      ,[TVQ]
      ,[SourceId]
      ,[imageGUID]
      ,[Name]
      ,[DisplayName]
      ,[TPS_Number]
      ,[TVQ_Number]
      ,[Total]
      ,[Address1]
      ,[Address2]
	  ,[Address1] + ', ' + [City]   FullName
      ,[City]
      ,[State]
      ,[Country]
      ,[PostalCode]
      ,[Phone]
      ,[Email]
      ,[Note]
	  ,ReceivedDate
	  ,[PoNumber] PoNumber
	  ,[DocumentNumber]  RefNo,
	  case when [ComptabilisationStatus] ='COMPTABILISE' then 1 else 0 end Comptabilise
  FROM [dbo].[T060Document]

  where id = @InvoiceId
GO
