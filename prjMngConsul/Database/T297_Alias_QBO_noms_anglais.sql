-- =============================================================================
-- T297 — Alias QuickBooks : le nom anglais de chaque compte par défaut
--
-- Les alias posés depuis les reprises (T292, T293) étaient presque tous en
-- français : un client dont QuickBooks est en anglais n'aurait pas été lié
-- d'office. Ce script pose le nom ANGLAIS officiel des comptes par défaut de
-- QuickBooks en ligne (Canada) en face de chaque nom français connu, sur la
-- compagnie modèle, puis le recopie sur les compagnies qui portent le même
-- alias français (leur plan a été copié ou resynchronisé depuis le modèle).
--
-- Corrections au passage :
--   6110 « Taxes et permis » avait été rangé en anglais par l'heuristique (le
--        mot « Taxes ») : il redevient le nom français, avec « Taxes & Licenses ».
--   4150 « Billable Expense Income » reçoit son nom français.
-- Laissés tels quels, à décider à la main : 4060 « Uncategorized Income-1 » et
-- 5090 « Uncategorized Expense ( 6 ) » (noms renommés chez le client, doublons
-- de 4140 et 6230) ; 5070 « Frais d'expédition et de livraison » et 5300
-- « Shipping and delivery expense » désignent le même compte QuickBooks lié à
-- deux comptes différents chez nous : on ne pose pas le même alias sur les deux.
-- Aucune ligne existante n'est écrasée : seuls les alias vides sont remplis.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- 6110 : l'heuristique s'était trompée de langue.
UPDATE dbo.T121PlanComptable
   SET [QBOCompteFR] = N'Taxes et permis', [QBOCompteEN] = N'Taxes & Licenses'
 WHERE [CompanyGUID] = @Model AND [Compte] = '6110'
   AND [QBOCompteEN] = N'Taxes et permis' AND [QBOCompteFR] IS NULL;

-- 4150 : le nom français d'un compte connu seulement en anglais.
UPDATE dbo.T121PlanComptable
   SET [QBOCompteFR] = N'Revenu de dépenses facturables'
 WHERE [CompanyGUID] = @Model AND [Compte] = '4150'
   AND [QBOCompteEN] = N'Billable Expense Income' AND [QBOCompteFR] IS NULL;

-- Le nom anglais officiel en face de chaque nom français.
DECLARE @t TABLE ([FR] NVARCHAR(200), [EN] NVARCHAR(200));
INSERT INTO @t ([FR], [EN]) VALUES
 (N'Fonds non déposés', N'Undeposited Funds'),
 (N'Actif non catégorisé', N'Uncategorized Asset'),
 (N'Dépenses prépayées', N'Prepaid Expenses'),
 (N'Bénéfices non répartis', N'Retained Earnings'),
 (N'Remboursements - Indemnités', N'Refunds-Allowances'),
 (N'Rabais', N'Discounts'),
 (N'Ventes', N'Sales'),
 (N'Revenu d''expédition et de livraison', N'Shipping and delivery income'),
 (N'Services', N'Services'),
 (N'Revenu non catégorisé', N'Uncategorized Income'),
 (N'Rabais accordés', N'Discounts given'),
 (N'Intérêts créditeurs', N'Interest earned'),
 (N'Autres revenus de portefeuille', N'Other Portfolio Income'),
 (N'Autres revenus réguliers', N'Other ordinary income'),
 (N'Achats - CDS', N'Purchases - COS'),
 (N'Autres coûts - CDS', N'Other costs - COS'),
 (N'Fournitures et matériaux - CDS', N'Supplies & Materials - COS'),
 (N'Outils', N'Tools'),
 (N'Coût de la main-d''oeuvre - CDS', N'Cost of Labour - COS'),
 (N'Sous-traitants', N'Subcontractors'),
 (N'Sous-traitants - CDS', N'Subcontractors - COS'),
 (N'Expédition et livraison - CDS', N'Shipping, Freight & Delivery - COS'),
 (N'Commissions et frais', N'Commissions and fees'),
 (N'Paiement de loyer ou de bail', N'Rent or lease payments'),
 (N'Réparation et entretien', N'Repair & Maintenance'),
 (N'Services publics', N'Utilities'),
 (N'Frais de bureau', N'Office expenses'),
 (N'Dépense sans catégorie', N'Uncategorized Expense'),
 (N'Droits d''adhésion et abonnements', N'Dues & Subscriptions'),
 (N'Fournitures', N'Supplies'),
 (N'Matériaux pour le projet', N'Job Supplies'),
 (N'Divers', N'Miscellaneous'),
 (N'Publicité', N'Advertising'),
 (N'Promotionnel', N'Promotional'),
 (N'Papeterie et impression', N'Stationery & Printing'),
 (N'Déplacement', N'Travel'),
 (N'Repas de déplacement', N'Travel Meals'),
 (N'Repas et divertissement', N'Meals and Entertainment'),
 (N'Frais juridiques et professionnels', N'Legal & Professional Fees'),
 (N'Autres dépenses générales et administratives', N'Other general and administrative expenses'),
 (N'Frais d''élimination', N'Disposal Fees'),
 (N'Assurance - Responsabilité', N'Insurance - Liability'),
 (N'Assurance', N'Insurance'),
 (N'Assurance - Invalidité', N'Insurance - Disability'),
 (N'Intérêts débiteurs', N'Interest expense'),
 (N'Frais bancaires', N'Bank charges'),
 (N'Créances irrécouvrables', N'Bad debts'),
 (N'Amendes et règlements', N'Penalties & Settlements');

-- Sur le modèle : seulement les alias anglais encore vides, et jamais un nom
-- anglais qu'un autre compte du modèle porte déjà.
UPDATE m
   SET m.[QBOCompteEN] = t.[EN]
  FROM dbo.T121PlanComptable m
  JOIN @t t ON t.[FR] = m.[QBOCompteFR]
 WHERE m.[CompanyGUID] = @Model
   AND m.[QBOCompteEN] IS NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.T121PlanComptable x
                    WHERE x.[CompanyGUID] = @Model AND x.[Id] <> m.[Id]
                      AND UPPER(ISNULL(x.[QBOCompteEN], '')) = UPPER(t.[EN]));
PRINT N'Alias anglais posés sur le modèle : ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N'.';

-- Sur les compagnies : les mêmes comptes (même numéro, même alias français), alias anglais encore vide.
UPDATE d
   SET d.[QBOCompteEN] = m.[QBOCompteEN], d.[QBOCompteFR] = m.[QBOCompteFR]
  FROM dbo.T121PlanComptable d
  JOIN dbo.T121PlanComptable m ON m.[CompanyGUID] = @Model AND m.[Compte] = d.[Compte]
 WHERE d.[CompanyGUID] <> @Model
   AND m.[QBOCompteEN] IS NOT NULL
   AND (ISNULL(d.[QBOCompteFR], '') = ISNULL(m.[QBOCompteFR], '') OR (d.[Compte] IN ('6110', '4150') AND d.[QBOCompteEN] = m.[QBOCompteEN]) OR (d.[Compte] = '6110' AND d.[QBOCompteEN] = N'Taxes et permis'))
   AND (d.[QBOCompteEN] IS NULL OR d.[QBOCompteEN] <> m.[QBOCompteEN] OR ISNULL(d.[QBOCompteFR], '') <> ISNULL(m.[QBOCompteFR], ''));
PRINT N'Alias recopiés sur les compagnies : ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' compte(s).';
GO

PRINT N'T297_Alias_QBO_noms_anglais.sql : terminé.';
