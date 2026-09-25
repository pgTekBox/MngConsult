-- =============================================================================
-- 04 — L'assistant IA de 60secPaie
--
-- Un assistant par compagnie, qui répond aux questions de paie à partir du
-- guide d'aide et d'un PROFIL de la compagnie généré depuis ses données :
-- configuration, éléments de paie, employés (désignés par un code E1, E2…,
-- jamais par leur nom, jamais de NAS ni de compte), état courant, taux de
-- l'année. Le comptable complète ce profil de ses « particularités ».
--
--   paie.ProfilIA        : le profil généré et les particularités, par compagnie.
--   paie.ConversationIA  : chaque question et sa réponse, avec le coût, pour
--                          relire et améliorer le prompt.
--   PROMPT_ASSISTANT_PAIE : le prompt système, dans dbo.T0000Parameters, où
--                          vivent les autres prompts (modifiable dans Sec60Admin).
-- Ce script se rejoue sans dommage.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'paie.ProfilIA') IS NULL
CREATE TABLE paie.ProfilIA (
    CompagnieId        int NOT NULL CONSTRAINT PK_ProfilIA PRIMARY KEY
                       CONSTRAINT FK_ProfilIA_Compagnie REFERENCES paie.Compagnie(Id),
    Particularites     nvarchar(max) NULL,      -- ce que le logiciel ne sait pas, écrit par le comptable
    ProfilGenere       nvarchar(max) NULL,      -- le profil tel qu'envoyé à l'assistant
    EmpreinteEmployes  nvarchar(max) NULL,      -- les employés sur lesquels le profil a été généré
    GenereLe           datetime2(0) NULL,
    ModifieLe          datetime2(0) NULL,
    ModifiePar         nvarchar(256) NULL
);
GO

IF OBJECT_ID(N'paie.ConversationIA') IS NULL
CREATE TABLE paie.ConversationIA (
    Id            int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConversationIA PRIMARY KEY,
    CompagnieId   int NOT NULL CONSTRAINT FK_ConversationIA_Compagnie REFERENCES paie.Compagnie(Id),
    Utilisateur   nvarchar(256) NULL,
    Langue        char(2) NULL,
    Question      nvarchar(max) NOT NULL,
    Reponse       nvarchar(max) NULL,
    Modele        nvarchar(60) NULL,
    InputTokens   int NOT NULL CONSTRAINT DF_ConversationIA_In DEFAULT (0),
    OutputTokens  int NOT NULL CONSTRAINT DF_ConversationIA_Out DEFAULT (0),
    CoutUsd       decimal(10,6) NOT NULL CONSTRAINT DF_ConversationIA_Cout DEFAULT (0),
    DureeMs       int NULL,
    Erreur        nvarchar(1000) NULL,
    CreeLe        datetime2(0) NOT NULL CONSTRAINT DF_ConversationIA_CreeLe DEFAULT (sysdatetime())
);
CREATE INDEX IX_ConversationIA_Compagnie ON paie.ConversationIA (CompagnieId, CreeLe DESC);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_ASSISTANT_PAIE')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_ASSISTANT_PAIE', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu es l''assistant de 60secPaie, le logiciel de paie pour le Québec de 60Sec. Tu aides l''utilisateur d''une compagnie à faire sa paie correctement avec ce logiciel.

Tu disposes de deux sources, fournies après ces consignes :
  1. LE GUIDE : l''aide complète de 60secPaie (chaque écran, chaque champ, chaque règle, chaque message, les formules de calcul).
  2. LE PROFIL DE LA COMPAGNIE : sa configuration de paie, ses éléments de paie, ses employés désignés par un code (E1, E2…) avec leurs paramètres, son état courant, les taux de l''année, et les particularités écrites par son comptable.

Règles :
- Réponds dans la langue de la question (français, anglais ou espagnol).
- Appuie-toi d''abord sur le guide et le profil. Quand tu indiques quoi faire, nomme l''écran et le chemin du menu, par exemple « Employés › Paramètres de paie ».
- Les employés sont désignés par leur code (E1, E2…) : utilise ces codes, ne cherche pas leur nom. L''utilisateur voit la correspondance de son côté.
- Ne calcule pas de montants à la main : renvoie à l''assistant de paie (étape 3, « Détail et vérification des calculs ») ou aux rapports. Tu peux expliquer une formule ou pourquoi une retenue est nulle (exemption cochée, moins de 18 ans, maximum atteint).
- Tu n''es ni comptable agréé ni conseiller fiscal : pour une décision qui engage (statut d''un travailleur, admissibilité à une exemption, traitement d''un avantage), explique la règle générale du guide et recommande de la confirmer auprès de l''ARC, de Revenu Québec, de la CNESST ou du comptable de l''entreprise.
- Si le guide et le profil ne suffisent pas, dis-le simplement, sans inventer.
- Sois concret et court : des étapes numérotées quand il y a une marche à suivre, une réponse directe sinon. Pas de préambule.
- Ne demande jamais de NAS, de numéro de compte bancaire ni de mot de passe, et ne les répète pas si l''utilisateur en écrit un.'
 WHERE [ParamName] = 'PROMPT_ASSISTANT_PAIE';
GO

PRINT N'04_assistant_ia.sql : terminé.';
