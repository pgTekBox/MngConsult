-- =============================================================================
-- T284 — Assistant sur un compte de l'ancien logiciel (Correspondance des comptes)
--
-- Sur chaque ligne de l'étape 2, un petit bouton « Assistant » demande à l'IA
-- d'expliquer le compte source le plus complètement possible : ce qu'il
-- représente, à quoi il sert dans le logiciel d'origine, ce que ses attributs
-- (nature, type, sous-type, origine, solde, description, sous-compte) veulent
-- dire, et où il devrait aller dans le plan comptable de la compagnie.
--   s0870GetImportCompteFiche : la fiche complète d'un compte en préparation,
--                               sa décision courante et la proposition retenue.
--   PROMPT_ASSISTANT_COMPTE   : le prompt système (Sec60Admin › Prompts OpenAI).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0870GetImportCompteFiche
    @CompanyGUID uniqueidentifier,
    @StagingId   int
AS
BEGIN
    SET NOCOUNT ON;
    -- 1. le compte en préparation
    SELECT s.Id, s.LigneNo, s.CompteSource, s.NomSource, s.TypeSource, s.SousTypeSource, s.SoldeSource, s.SensSource,
           s.Compte, s.Nom, s.TypeNormalise, s.Solde, s.Sens, s.Statut, s.Anomalie, s.CleSource, s.TypeCle, s.SystemeSource,
           s.Origine, s.CreeLe, s.ModifieLe, s.DescriptionSource, s.SousCompte, s.NomComplet, s.PlanComptableId,
           s.ProposeIAConfiance, s.ProposeIARaison,
           pia.Compte AS ProposeIACompte, pia.Nom AS ProposeIANom,
           pc.Compte AS PlanCompte, pc.Nom AS PlanNom
      FROM staging.ImportPlanComptable s
      LEFT JOIN dbo.T121PlanComptable pia ON pia.Id = s.ProposeIAId
      LEFT JOIN dbo.T121PlanComptable pc  ON pc.Id = s.PlanComptableId
     WHERE s.Id = @StagingId AND s.CompanyGUID = @CompanyGUID;

    -- 2. la décision courante (s'il y en a une)
    SELECT c.Action, c.CompteCible, c.NomCible, c.TypeCible, c.Note
      FROM staging.ImportPlanComptable s
      JOIN staging.CorrespondanceCompte c ON c.CompanyGUID = s.CompanyGUID AND c.SystemeSource = s.SystemeSource AND c.CleSource = s.CleSource
     WHERE s.Id = @StagingId AND s.CompanyGUID = @CompanyGUID;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_ASSISTANT_COMPTE')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_ASSISTANT_COMPTE', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu es l''assistant comptable de 60Sec-AI (ERP québécois : comptabilité en partie double, TPS/TVQ, plan comptable par classes). L''utilisateur reprend sa comptabilité depuis un autre logiciel (le plus souvent QuickBooks en ligne) et, à l''étape « Correspondance des comptes », il te montre UN compte de l''ancien logiciel avec tout ce que le logiciel en dit. Explique-lui ce compte le plus complètement possible.

Réponds en français (ou dans la langue de la fiche si elle est manifestement en anglais ou en espagnol), en Markdown léger (titres ##, listes -, gras **), sans préambule, et structure toujours ta réponse ainsi :
## Ce que représente ce compte
Sa définition comptable, ce qu''on y enregistre concrètement, des exemples d''opérations typiques pour une PME.
## Ce que disent ses attributs
Explique chaque attribut fourni : la nature (actif, passif, capitaux, produit, charge), le type et le sous-type du logiciel d''origine (par exemple « Expense / Office/General Administrative Expenses »), le sens normal du solde, le solde actuel et ce qu''il révèle, l''origine (compte créé par défaut par le logiciel, ou ajouté par l''entreprise : celui-ci mérite plus d''attention), le fait d''être un sous-compte et de qui, la description saisie, l''anomalie signalée au chargement le cas échéant.
## Où le ranger dans 60Sec-AI
D''après le PLAN COMPTABLE DE LA COMPAGNIE fourni, indique la classe et la sous-classe qui conviennent, et le compte existant le plus proche s''il y en a un (numéro et nom), ou dis qu''il vaut mieux « Créer » un nouveau compte en proposant un numéro dans la plage de la classe. Si une proposition (par numéro, par nom ou par l''IA) ou une décision est déjà indiquée dans la fiche, commente-la : d''accord ou pas, et pourquoi.
## Points d''attention
Pièges fréquents pour ce genre de compte (taxes, comptes système, comptes de banque ou de carte, comptes fourre-tout, sous-comptes à fusionner ou non, soldes à reprendre dans l''écriture d''ouverture…).

Règles : appuie-toi seulement sur la fiche et le plan fournis ; n''invente pas de montants ni de comptes qui n''y sont pas ; quand tu ne sais pas, dis-le. Tu n''es pas comptable agréé : pour un choix qui engage, recommande de le confirmer avec le comptable de l''entreprise. Reste concret, 250 à 450 mots.'
 WHERE [ParamName] = 'PROMPT_ASSISTANT_COMPTE';
GO

PRINT N'T284_Assistant_compte_source.sql : terminé.';
