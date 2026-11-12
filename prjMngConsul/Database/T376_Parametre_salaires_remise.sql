-- =============================================================================
-- T376 — Paramètres : onglet « Salaires » et fréquence de remise des retenues
--
-- Nouvelle catégorie SALAIRES dans le catalogue des paramètres (compagnie
-- modèle …0001) ; s0150GetParamsForCompany la recopie chez chaque compagnie à
-- l'ouverture de Paramètres (comme les autres paramètres).
--
--   SAL_REMISE_FREQ — fréquence de remise des retenues à la source et des
--   cotisations de l'employeur (DAS) à Revenu Québec et à l'ARC, selon le
--   type de remettant attribué par les gouvernements :
--     TRIMESTRIELLE  remettant trimestriel (petit employeur admissible)
--     MENSUELLE      remettant régulier — le 15 du mois suivant (défaut)
--     BIMENSUELLE    remettant accéléré, seuil 1 — deux fois par mois
--     HEBDOMADAIRE   remettant accéléré, seuil 2 — jusqu'à quatre fois par mois
--
-- Idempotent : rien n'est recréé si la définition existe déjà.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @Modele UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

IF NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable WHERE CompanyGUID = @Modele AND ShortName = 'SAL_REMISE_FREQ')
    INSERT INTO dbo.T100ParamComptable (Created, ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
    VALUES (GETDATE(), 'SAL_REMISE_FREQ', 'Fréquence de remise des retenues à la source (DAS)', 'STRING', 'SALAIRES', 10, @Modele);

DECLARE @Id INT = (SELECT Id FROM dbo.T100ParamComptable WHERE CompanyGUID = @Modele AND ShortName = 'SAL_REMISE_FREQ');

IF NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues WHERE T100Id = @Id AND CompanyGUID = @Modele)
    INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, sVal) VALUES (@Id, @Modele, 'MENSUELLE');

IF NOT EXISTS (SELECT 1 FROM dbo.T102ParamI18n WHERE ShortName = 'SAL_REMISE_FREQ')
    INSERT INTO dbo.T102ParamI18n (ShortName, NameFr, NameEn, NameEs)
    VALUES ('SAL_REMISE_FREQ',
            N'Fréquence de remise des retenues à la source (DAS)',
            N'Source deductions remittance frequency',
            N'Frecuencia de remesa de las retenciones en la fuente');
GO
