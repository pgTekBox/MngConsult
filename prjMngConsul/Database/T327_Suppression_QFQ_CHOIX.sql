-- =============================================================================
-- T327 — Suppression du paramètre QFQ_CHOIX (T324)
--
-- QFQ_CHOIX gardait tous les choix de « Qui fait quoi » dans un seul JSON. Il est
-- remplacé par un paramètre par action (T326, QFQ:<id>) et n'est plus lu par
-- l'application. On retire ses valeurs (T101), ses définitions (T100, toutes les
-- compagnies et le modèle) et, s'il y en a, ses lignes du cliché des démos.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

DELETE v FROM dbo.T101ParamValues v
JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id
WHERE t.ShortName = 'QFQ_CHOIX';

DELETE FROM dbo.T100ParamComptable WHERE ShortName = 'QFQ_CHOIX';

DELETE v FROM dbo.DEMO_T101ParamValues v
JOIN dbo.DEMO_T100ParamComptable t ON t.Id = v.T100Id
WHERE t.ShortName = 'QFQ_CHOIX';

DELETE FROM dbo.DEMO_T100ParamComptable WHERE ShortName = 'QFQ_CHOIX';

DELETE FROM dbo.T102ParamI18n WHERE ShortName = 'QFQ_CHOIX';

COMMIT;
GO
