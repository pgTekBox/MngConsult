SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- s0011GetSuppliers : liste des fournisseurs (Type 2 ou 3) d'une compagnie.
-- Ajout de StripeAccountId pour afficher le badge « inscription Stripe » dans la liste.
-- =============================================================
CREATE OR ALTER PROCEDURE [dbo].[s0011Getsuppliers]
    @CompanyGUID uniqueidentifier,
    @Search varchar(100)
AS
SELECT T050.[Id]
      ,T050.[PartyGUID]
      ,T050.[CompanyGUID]
      ,T050.[Name]
      ,'<b>' + T050.[Name] + '</b>' + ISNULL(Addr.Addresses, '') AS NameAllAdddress
      ,T050.[DisplayName]
      ,T050.[TPS]
      ,T050.[TVQ]
      ,T050.[WebSite]
      ,T050.[Created]
      ,T050.[StripeAccountId]
  FROM [dbo].[T050Party] T050

  OUTER APPLY (
    SELECT '<div><span style="color: darkgrey;">' + A.[Name] + ':</span>  ' + coalesce(A.Address1,'') + coalesce(A.Address2,'') + ' ' + coalesce([City],'') + '</div> ' AS Addresses,
           coalesce(A.Address1,'') + ' ' + coalesce(A.Address2,'') Address12
    FROM dbo.vwPartyAddress AS A
    WHERE A.PartyId = T050.Id
) AS Addr
  WHERE T050.Type in (2,3)
    AND T050.CompanyGUID = @CompanyGUID
    AND T050.[Name] + ' ' + ISNULL(Addr.Address12, '') like '%' + @Search + '%'
GO
