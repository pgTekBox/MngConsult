-- =============================================================================
-- T222 — Suppression des tables staging.Sage*
--
-- Reliquat de la reprise Sage, abandonnee : plus aucune procedure, vue ni page
-- ne les nommait. Les deux qui portaient encore des donnees — l'ancien plan
-- comptable modele — sont sauvegardees dans T221_Sauvegarde_staging_Sage.sql,
-- et remplacees depuis par dbo.T120PlanComptable_Classe et dbo.T121PlanComptable.
--
-- Un DROP par lot : une erreur de compilation de plan (8624) ferait echouer
-- tout un lot groupe, et on ne saurait pas laquelle a bloque.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('staging.Ancien_SageComptes', 'U') IS NOT NULL DROP TABLE staging.Ancien_SageComptes;
GO
IF OBJECT_ID('staging.Ancien_SageComptesClasse', 'U') IS NOT NULL DROP TABLE staging.Ancien_SageComptesClasse;
GO
IF OBJECT_ID('staging.SageFactureLines', 'U') IS NOT NULL DROP TABLE staging.SageFactureLines;
GO
IF OBJECT_ID('staging.SageFactures', 'U') IS NOT NULL DROP TABLE staging.SageFactures;
GO
IF OBJECT_ID('staging.SageParties', 'U') IS NOT NULL DROP TABLE staging.SageParties;
GO
IF OBJECT_ID('staging.SageProduits', 'U') IS NOT NULL DROP TABLE staging.SageProduits;
GO
IF OBJECT_ID('staging.SageClasseCompte', 'U') IS NOT NULL DROP TABLE staging.SageClasseCompte;
GO