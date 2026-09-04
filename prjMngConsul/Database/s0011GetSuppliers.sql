-- =============================================================================
-- s0011GetSuppliers — liste des fournisseurs pour la grille « Fournisseurs ».
--
-- Modifications 2026-09-04 (symétriques de s0010GetCustomers) :
--   1. Le COURRIEL de l'adresse (T054PartyAddress.Email) s'affiche à la suite
--      de l'adresse, dans le bloc HTML NameAllAdddress.
--   2. Nouvelle colonne APayer : ce que l'on doit encore au fournisseur —
--      total des documents d'achat COMPTABILISÉS (facture fournisseur ou reçu),
--      moins les règlements de sens DÉCAISSEMENT non annulés. Jamais négatif.
--   3. Colonnes brutes [Name] et APayer : elles servent au tri de la grille,
--      qui ne peut pas trier sur le HTML.
--   4. Agrégation des adresses par STRING_AGG : l'OUTER APPLY d'origine
--      renvoyait une ligne PAR adresse et aurait dupliqué le fournisseur dès
--      qu'il en aurait eu deux. La recherche couvre maintenant le courriel.
--
--   StripeAccountId est conservé (badge « inscription Stripe » de la liste).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0011GetSuppliers]
    @CompanyGUID uniqueidentifier,
    @Search      varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

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
          ,ISNULL(Addr.Email, '')      AS Email
          ,ISNULL(Solde.APayer, 0)     AS APayer
      FROM [dbo].[T050Party] T050

      OUTER APPLY (
        SELECT STRING_AGG(
                   '<div><span style="color: darkgrey;">' + ISNULL(TY.[Name], '') + ':</span>  '
                 + COALESCE(PA.Address1, '') + COALESCE(PA.Address2, '') + ' ' + COALESCE(PA.City, '')
                 + CASE WHEN NULLIF(LTRIM(RTRIM(PA.Email)), '') IS NOT NULL
                        THEN '<div class="cust-email">' + PA.Email + '</div>'
                        ELSE '' END
                 + '</div> ', '') WITHIN GROUP (ORDER BY PA.Id)            AS Addresses,
               STRING_AGG(COALESCE(PA.Address1, '') + ' ' + COALESCE(PA.Address2, '')
                          + ' ' + COALESCE(PA.Email, ''), ' ')             AS Address12,
               MAX(PA.Email)                                               AS Email
        FROM dbo.T054PartyAddress PA
        LEFT JOIN dbo.T064AddressType TY ON TY.Id = PA.AddressTypeId
        WHERE PA.PartyId = T050.Id
      ) AS Addr

      -- Dettes : documents d'achat comptabilisés, moins ce qui a déjà été payé.
      OUTER APPLY (
        SELECT SUM(CASE WHEN d.[Total] - ISNULL(pc.DejaPaye, 0) > 0
                        THEN d.[Total] - ISNULL(pc.DejaPaye, 0) ELSE 0 END) AS APayer
        FROM dbo.T060Document d
        OUTER APPLY (
            SELECT SUM(rd.[MontantImpute]) AS DejaPaye
            FROM dbo.T141ReglementDocument rd
            INNER JOIN dbo.T140Reglement r ON r.[Id] = rd.[ReglementId]
            WHERE rd.[DocumentId] = d.[Id]
              AND r.[Statut] <> 'ANNULE'
              AND r.[Sens] = 'DECAISSEMENT'
        ) pc
        WHERE d.[PartyGUID] = T050.[PartyGUID]
          AND d.[CompanyGUID] = T050.[CompanyGUID]
          AND d.[DocumentTypeId] IN (2, 5)
          AND d.[ComptabilisationStatus] = 'COMPTABILISE'
      ) AS Solde

     WHERE T050.[Type] IN (2, 3)
       AND T050.[CompanyGUID] = @CompanyGUID
       AND T050.[Name] + ' ' + ISNULL(Addr.Address12, '') LIKE '%' + @Search + '%';
END
GO

PRINT N's0011GetSuppliers.sql : termine.';
GO
