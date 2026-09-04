-- =============================================================================
-- s0010GetCustomers — liste des clients pour la grille « Gestion des clients ».
--
-- Modifications 2026-09-04 :
--   1. Le COURRIEL de l'adresse (T054PartyAddress.Email) est affiché à la
--      suite de l'adresse, dans le bloc HTML NameAllAdddress.
--   2. Nouvelle colonne ARecevoir : total encore dû par le client, soit la
--      somme des ResteAPayer de ses factures COMPTABILISÉES non soldées.
--      Les brouillons sont exclus : tant qu'une facture n'est pas
--      comptabilisée, ce n'est pas une créance.
--   3. Colonnes brutes [Name] (déjà présente) et ARecevoir : elles servent au
--      tri de la grille, qui ne peut pas trier sur le HTML.
--   4. L'agrégation des adresses passe par STRING_AGG : l'OUTER APPLY
--      d'origine renvoyait une ligne PAR adresse, ce qui aurait duplique le
--      client dès qu'il en aurait eu deux (aucun cas en base aujourd'hui).
--      La recherche couvre maintenant aussi le courriel.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0010GetCustomers]
    @CompanyGUID uniqueidentifier,
    @Search      varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT T050.[Id]
          ,T050.[PartyGUID]
          ,T050.[CompanyGUID]
          ,T050.[Name]
          ,'<b>' + T050.[Name] + '</b>' + ' ' + ISNULL(Addr.Addresses, '') AS NameAllAdddress
          ,T050.[DisplayName]
          ,T050.[TPS]
          ,T050.[TVQ]
          ,T050.[WebSite]
          ,T050.[Created]
          ,ISNULL(Addr.Email, '')        AS Email
          ,ISNULL(Solde.ARecevoir, 0)    AS ARecevoir
      FROM [dbo].[T050Party] T050

      OUTER APPLY (
        SELECT STRING_AGG(
                   '<div><span style="color: darkgrey;">' + ISNULL(TY.[Name], '') + ':</span> '
                 + COALESCE(PA.Address1, '') + COALESCE(PA.Address2, '') + ' ' + COALESCE(PA.City, '')
                 + CASE WHEN NULLIF(LTRIM(RTRIM(PA.Email)), '') IS NOT NULL
                        THEN '<div class="cust-email">' + PA.Email + '</div>'
                        ELSE '' END
                 + '</div>', '') WITHIN GROUP (ORDER BY PA.Id)              AS Addresses,
               STRING_AGG(COALESCE(PA.Address1, '') + ' ' + COALESCE(PA.Address2, '')
                          + ' ' + COALESCE(PA.Email, ''), ' ')              AS Address12,
               MAX(PA.Email)                                                AS Email
        FROM dbo.T054PartyAddress PA
        LEFT JOIN dbo.T064AddressType TY ON TY.Id = PA.AddressTypeId
        WHERE PA.PartyId = T050.Id
      ) AS Addr

      -- Créances : factures comptabilisées, non entièrement payées.
      OUTER APPLY (
        SELECT SUM(vi.[ResteAPayer]) AS ARecevoir
        FROM dbo.vwCustomersInvoices vi
        WHERE vi.[PartyId] = T050.[Id]
          AND vi.[CompanyGUID] = T050.[CompanyGUID]
          AND vi.[ComptabilisationStatus] = 'COMPTABILISE'
          AND vi.[StatutPaiement] <> 'PAYEE'
      ) AS Solde

     WHERE T050.[Type] IN (1, 3)
       AND T050.[CompanyGUID] = @CompanyGUID
       AND T050.[Name] + ' ' + ISNULL(Addr.Address12, '') LIKE '%' + @Search + '%';
END
GO

PRINT N's0010GetCustomers.sql : termine.';
GO
