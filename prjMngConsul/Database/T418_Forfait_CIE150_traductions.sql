-- =============================================================================
-- T418 : forfait CIE 1-50 — nom et accroche anglais/espagnol alignés sur le français
-- Le français dit « Société 1–50 employés » / « 1 à 50 employés » ; l'anglais et
-- l'espagnol disaient encore « Company 1–19 » / « 1 to 9 employees » (ancien
-- forfait com119). Affichés à l'inscription, au paiement et sur la confirmation.
-- La tranche d'employés et les fonctions (« 1–19 », « jusqu'à 19 ») ne sont pas
-- touchées : elles disent la même chose dans les trois langues.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

UPDATE dbo.T021Plan
   SET Name_en    = N'Company 1–50 employees',
       Name_es    = N'Empresa 1–50 empleados',
       Tagline_en = N'1 to 50 employees',
       Tagline_es = N'1 a 50 empleados',
       ModifiedOn = GETDATE(),
       ModifiedBy = N'T418'
 WHERE Code = 'CIE 1-50'
   AND IsDeleted = 0;
GO
