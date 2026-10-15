-- =============================================================================
-- T321 — Ventes › Encaissements (nouvel écran) et Ventes › Clients (refonte),
--        à la signature visuelle du « Portail du client »
--
-- Les encaissements vivent dans T140Reglement (Sens = 'ENCAISSEMENT') et
-- leurs imputations dans T141ReglementDocument ; l'ERP n'avait pas de liste.
-- La liste des clients avait besoin de ce que la maquette montre : l'adresse
-- de facturation, le courriel et le téléphone, le délai de paiement et ce
-- qui est en retard. s0010GetCustomers reste tel quel (d'autres écrans s'en
-- servent) ; la page passe par une procédure à elle.
--
--   s0905GetEncaissements (@CompanyGUID, @Search) → les paiements reçus, du
--       plus récent au plus ancien : date, montant, type, référence, statut,
--       rapproché avec la banque (RelевeBancaireId), client, factures imputées.
--   s0906GetCustomersListe (@CompanyGUID, @Search) → les clients avec adresse
--       de facturation, courriel, téléphone, délai (PaymentTermDays), à
--       recevoir, en retard (montant et nombre de factures).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0905GetEncaissements]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = ISNULL(LTRIM(RTRIM(@Search)), N'');

    SELECT r.[Id], r.[DateReglement], r.[Montant], ISNULL(r.[Reference], '') AS [Reference],
           ISNULL(r.[TypeReglement], '') AS [TypeReglement], ISNULL(r.[Statut], '') AS [Statut],
           ISNULL(r.[CompteBanque], '') AS [CompteBanque],
           CASE WHEN r.[RelевeBancaireId] IS NOT NULL THEN 1 ELSE 0 END AS [Rapproche],
           r.[PartyId], ISNULL(p.[Name], '') AS [PartyName],
           ISNULL(f.[Factures], '') AS [Factures],
           r.[Created]
      FROM dbo.T140Reglement r
      LEFT JOIN dbo.T050Party p ON p.[Id] = r.[PartyId]
      OUTER APPLY (
          SELECT STRING_AGG(d.[DocumentNumber], ', ') WITHIN GROUP (ORDER BY d.[DocumentNumber]) AS [Factures]
            FROM dbo.T141ReglementDocument rd
            JOIN dbo.T060Document d ON d.[Id] = rd.[DocumentId]
           WHERE rd.[ReglementId] = r.[Id]
      ) f
     WHERE r.[CompanyGUID] = @CompanyGUID
       AND r.[Sens] = 'ENCAISSEMENT'
       AND (@Search = N''
            OR ISNULL(p.[Name], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(r.[Reference], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(f.[Factures], '') LIKE N'%' + @Search + N'%')
     ORDER BY r.[DateReglement] DESC, r.[Id] DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0906GetCustomersListe]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = ISNULL(LTRIM(RTRIM(@Search)), N'');

    SELECT T050.[Id], T050.[Name],
           ISNULL(T050.[PaymentTermDays], 0)                         AS [DelaiJours],
           ISNULL(b.[Email], '')                                     AS [Email],
           ISNULL(b.[Phone], '')                                     AS [Phone],
           LTRIM(RTRIM(RTRIM(ISNULL(b.[Address1], '') + ' ' + ISNULL(b.[Address2], ''))
                 + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(b.[City], ''))), '') IS NOT NULL THEN ', ' + b.[City] ELSE '' END
                 + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(b.[PostalCode], ''))), '') IS NOT NULL THEN ' ' + b.[PostalCode] ELSE '' END))
                                                                     AS [AdresseFacturation],
           ISNULL(s.[ARecevoir], 0)                                  AS [ARecevoir],
           ISNULL(s.[EnRetard], 0)                                   AS [EnRetard],
           ISNULL(s.[NbRetard], 0)                                   AS [NbRetard],
           ISNULL(s.[NbOuvertes], 0)                                 AS [NbOuvertes]
      FROM dbo.T050Party T050
      OUTER APPLY (
          SELECT TOP 1 PA.[Address1], PA.[Address2], PA.[City], PA.[PostalCode], PA.[Email], PA.[Phone]
            FROM dbo.T054PartyAddress PA
           WHERE PA.[PartyId] = T050.[Id]
           ORDER BY CASE WHEN PA.[AddressTypeId] = 1 THEN 0 ELSE 1 END, PA.[Id]
      ) b
      OUTER APPLY (
          SELECT SUM(vi.[ResteAPayer])                                                   AS [ARecevoir],
                 SUM(CASE WHEN vi.[StatutPaiement] = 'EN_RETARD' THEN vi.[ResteAPayer] ELSE 0 END) AS [EnRetard],
                 SUM(CASE WHEN vi.[StatutPaiement] = 'EN_RETARD' THEN 1 ELSE 0 END)       AS [NbRetard],
                 COUNT(*)                                                                 AS [NbOuvertes]
            FROM dbo.vwCustomersInvoices vi
           WHERE vi.[PartyId] = T050.[Id]
             AND vi.[CompanyGUID] = T050.[CompanyGUID]
             AND vi.[ComptabilisationStatus] = 'COMPTABILISE'
             AND vi.[StatutPaiement] <> 'PAYEE'
      ) s
     WHERE T050.[Type] IN (1, 3)
       AND T050.[CompanyGUID] = @CompanyGUID
       AND (@Search = N''
            OR T050.[Name] LIKE N'%' + @Search + N'%'
            OR ISNULL(b.[Email], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(b.[Phone], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(b.[Address1], '') + ' ' + ISNULL(b.[City], '') LIKE N'%' + @Search + N'%')
     ORDER BY T050.[Name];
END
GO
