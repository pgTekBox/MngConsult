-- =============================================================================
-- T324 — « Qui fait quoi » : les choix enregistrés dans les paramètres de la compagnie
--
-- La page QuiFaitQuoi.aspx (onglet « Qui fait quoi » de Mon cabinet comptable)
-- garde, par compagnie, qui s'occupe de chaque action : l'entreprise (m), son
-- cabinet (c) ou les deux (mc). Le choix est un paramètre comme les autres :
-- défini sur la compagnie modèle, cloné pour chaque compagnie par
-- s0150GetParamsForCompany, écrit par s0151UpdateParamValue.
--
--   QFQ_CHOIX  (STRING, catégorie QUIFAITQUOI)  sVal = JSON compact
--       {"v":1,"profil":"TA","metier":"…","c":{"ALL-S-05":"mc","ALL-S-07":"m",…}}
--
-- La catégorie QUIFAITQUOI n'est liée à aucun onglet de wbfSetting : le
-- paramètre n'apparaît pas dans l'écran Paramètres et ne compte pas dans la
-- progression du profil (ENTREPRISE et TAXES seulement).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @Modele UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

IF NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable WHERE CompanyGUID = @Modele AND ShortName = 'QFQ_CHOIX')
BEGIN
    INSERT dbo.T100ParamComptable (Created, ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
    VALUES (GETDATE(), 'QFQ_CHOIX', 'Qui fait quoi : choix enregistrés', 'STRING', 'QUIFAITQUOI', 9000, @Modele);
END

DECLARE @T100 INT = (SELECT Id FROM dbo.T100ParamComptable WHERE CompanyGUID = @Modele AND ShortName = 'QFQ_CHOIX');

IF NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues WHERE T100Id = @T100 AND CompanyGUID = @Modele)
BEGIN
    INSERT dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
    VALUES (@T100, @Modele, NULL, NULL, NULL, NULL);
END
GO
