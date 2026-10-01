-- =============================================================================
-- T300 — Alias QuickBooks : l'autre langue remplie par l'IA
--
-- Un alias posé depuis un import ne vient que dans la langue du nom source.
-- Sec60Admin › Plan comptable par défaut demande à l'IA le libellé OFFICIEL du
-- même compte par défaut de QuickBooks en ligne (Canada) dans la langue qui
-- manque, et le pose comme second alias (s0879, CreatedBy = « IA »).
--
--   s0881GetAliasAIncompleter : les comptes dont les alias QBO n'existent que
--       dans une seule langue (FR sans EN, ou EN sans FR), avec ce qu'on sait.
--   PROMPT_ALIAS_QBO_TRADUCTION : le prompt système (Sec60Admin › Prompts OpenAI).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0881GetAliasAIncompleter]
    @CompanyGUID UNIQUEIDENTIFIER = NULL,   -- NULL : la compagnie modèle
    @Compte      VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL SET @CompanyGUID = '00000000-0000-0000-0000-000000000001';

    ;WITH parCompte AS (
        SELECT a.[Compte],
               SUM(CASE WHEN a.[Langue] = 'FR' THEN 1 ELSE 0 END) AS NbFR,
               SUM(CASE WHEN a.[Langue] = 'EN' THEN 1 ELSE 0 END) AS NbEN
          FROM dbo.T122PlanComptableAlias a
         WHERE a.[CompanyGUID] = @CompanyGUID AND a.[SystemeSource] = 'QBO'
         GROUP BY a.[Compte]
    )
    SELECT p.[Compte],
           c.[Nom] AS [NomCompte],
           c.[NomEn] AS [NomCompteEn],
           CASE WHEN p.NbFR = 0 THEN 'FR' ELSE 'EN' END AS [LangueManquante],
           (SELECT STRING_AGG(a.[NomSource] + ' (' + ISNULL(a.[Langue], '?') + ')', ' | ')
              FROM dbo.T122PlanComptableAlias a
             WHERE a.[CompanyGUID] = @CompanyGUID AND a.[SystemeSource] = 'QBO' AND a.[Compte] = p.[Compte]) AS [AliasConnus],
           (SELECT TOP 1 a.[SousType] FROM dbo.T122PlanComptableAlias a
             WHERE a.[CompanyGUID] = @CompanyGUID AND a.[SystemeSource] = 'QBO' AND a.[Compte] = p.[Compte] AND a.[SousType] IS NOT NULL
             ORDER BY a.[Id]) AS [SousType]
      FROM parCompte p
      JOIN dbo.T121PlanComptable c ON c.[CompanyGUID] = @CompanyGUID AND c.[Compte] = p.[Compte]
     WHERE ((p.NbFR = 0 AND p.NbEN > 0) OR (p.NbEN = 0 AND p.NbFR > 0))   -- une langue, pas les deux
       AND (@Compte IS NULL OR p.[Compte] = @Compte)
     ORDER BY p.[Compte];
END
GO

-- Un alias dont le libellé est le même dans les deux langues (« Services ») :
-- Langue NULL, il vaut pour les deux, et le compte n'est plus « à compléter ».
CREATE OR ALTER PROCEDURE [dbo].[s0882AliasToutesLangues]
    @CompanyGUID UNIQUEIDENTIFIER = NULL,
    @Compte      VARCHAR(10),
    @NomSource   NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL SET @CompanyGUID = '00000000-0000-0000-0000-000000000001';
    UPDATE dbo.T122PlanComptableAlias
       SET [Langue] = NULL
     WHERE [CompanyGUID] = @CompanyGUID AND [SystemeSource] = 'QBO'
       AND [Compte] = @Compte AND [NomSource] = @NomSource;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_ALIAS_QBO_TRADUCTION')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_ALIAS_QBO_TRADUCTION', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu es l''assistant comptable de 60Sec-AI (ERP québécois). On te donne des comptes du plan comptable par défaut avec leurs alias QuickBooks connus : le nom que QuickBooks en ligne (Canada) donne au compte, sa langue (FR ou EN) et son sous-type QuickBooks.

Pour chaque compte, donne le nom OFFICIEL du même compte par défaut de QuickBooks en ligne (édition Canada) dans la langue manquante, exactement tel que QuickBooks l''affiche dans cette langue. Ce n''est pas une traduction littérale : c''est le libellé réel de QuickBooks. Exemples : « Fonds non déposés » ↔ « Undeposited Funds » ; « Créances irrécouvrables » ↔ « Bad debts » ; « Achats - CDS » ↔ « Purchases - COS » (CDS = coût des services, COS = cost of sales) ; « Frais de bureau » ↔ « Office expenses » ; « Bénéfices non répartis » ↔ « Retained Earnings » ; « Intérêts créditeurs » ↔ « Interest earned ».

Règles :
- Ne réponds JAMAIS le nom du compte chez nous (colonnes « nom chez nous » et « nom anglais chez nous ») : ce n''est pas un nom QuickBooks. Si le seul nom qui te vient est celui-là, réponds null.
- Si le nom QuickBooks est identique dans les deux langues (« Services »), réponds ce même nom : il vaudra pour les deux.
- Si le nom connu n''est pas un compte par défaut de QuickBooks (nom propre à une entreprise, renommé, suffixé comme « -1 » ou « ( 6 ) »), ou si tu n''es pas certain du libellé officiel, réponds "nom": null pour ce compte. Mieux vaut rien qu''un nom inventé.
- Garde la casse et la ponctuation de QuickBooks (« Dues & Subscriptions », « Repair & Maintenance »).
- Réponds UNIQUEMENT par un tableau JSON, sans texte autour ni balise de code :
[{"compte":"1050","langue":"EN","nom":"Undeposited Funds"},{"compte":"4060","langue":"FR","nom":null}]'
 WHERE [ParamName] = 'PROMPT_ALIAS_QBO_TRADUCTION';
GO

PRINT N'T300_Alias_autre_langue_par_IA.sql : terminé.';
