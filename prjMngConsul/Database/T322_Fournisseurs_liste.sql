-- =============================================================================
-- T322 — Achats › Fournisseurs à la signature « Portail du client »
--
-- La liste des fournisseurs montre maintenant l'adresse de facturation, le
-- courriel et le téléphone, le délai de paiement, ce que vous devez et ce qui
-- est en retard. s0011GetSuppliers reste tel quel (d'autres écrans s'en
-- servent) ; la page passe par une procédure à elle, jumelle de s0906 pour
-- les clients.
--
--   s0907GetSuppliersListe (@CompanyGUID, @Search) → les fournisseurs (Type 2
--       ou 3) avec adresse de facturation, courriel, téléphone, délai
--       (PaymentTermDays), à payer (factures d'achat comptabilisées non
--       soldées, règlements DECAISSEMENT non annulés), en retard (échéance
--       passée) montant et nombre, et le compte Stripe.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0907GetSuppliersListe]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = ISNULL(LTRIM(RTRIM(@Search)), N'');

    SELECT T050.[Id], T050.[Name],
           ISNULL(T050.[PaymentTermDays], 0)                         AS [DelaiJours],
           ISNULL(T050.[StripeAccountId], '')                        AS [StripeAccountId],
           ISNULL(b.[Email], '')                                     AS [Email],
           ISNULL(b.[Phone], '')                                     AS [Phone],
           LTRIM(RTRIM(RTRIM(ISNULL(b.[Address1], '') + ' ' + ISNULL(b.[Address2], ''))
                 + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(b.[City], ''))), '') IS NOT NULL THEN ', ' + b.[City] ELSE '' END
                 + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(b.[PostalCode], ''))), '') IS NOT NULL THEN ' ' + b.[PostalCode] ELSE '' END))
                                                                     AS [AdresseFacturation],
           ISNULL(s.[APayer], 0)                                     AS [APayer],
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
          SELECT SUM(x.[Reste])                                                        AS [APayer],
                 SUM(CASE WHEN x.[DueDate] < CAST(GETDATE() AS DATE) THEN x.[Reste] ELSE 0 END) AS [EnRetard],
                 SUM(CASE WHEN x.[DueDate] < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END)        AS [NbRetard],
                 COUNT(*)                                                              AS [NbOuvertes]
            FROM (
                SELECT d.[DueDate],
                       CAST(ISNULL(d.[Total], 0) - ISNULL(pc.[DejaPaye], 0) AS DECIMAL(15, 2)) AS [Reste]
                  FROM dbo.T060Document d
                  OUTER APPLY (
                      SELECT SUM(rd.[MontantImpute]) AS [DejaPaye]
                        FROM dbo.T141ReglementDocument rd
                        JOIN dbo.T140Reglement r ON r.[Id] = rd.[ReglementId]
                       WHERE rd.[DocumentId] = d.[Id]
                         AND r.[Statut] <> 'ANNULE'
                         AND r.[Sens] = 'DECAISSEMENT'
                  ) pc
                 WHERE d.[PartyGUID] = T050.[PartyGUID]
                   AND d.[CompanyGUID] = T050.[CompanyGUID]
                   AND d.[DocumentTypeId] IN (2, 5)
                   AND d.[ComptabilisationStatus] = 'COMPTABILISE'
            ) x
           WHERE x.[Reste] > 0.005
      ) s
     WHERE T050.[Type] IN (2, 3)
       AND T050.[CompanyGUID] = @CompanyGUID
       AND (@Search = N''
            OR T050.[Name] LIKE N'%' + @Search + N'%'
            OR ISNULL(b.[Email], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(b.[Phone], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(b.[Address1], '') + ' ' + ISNULL(b.[City], '') LIKE N'%' + @Search + N'%')
     ORDER BY T050.[Name];
END
GO
