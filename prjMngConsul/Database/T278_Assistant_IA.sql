-- =============================================================================
-- T278 — L'assistant IA de l'ERP (le même que dans 60secPaie)
--
-- Un assistant par compagnie, qui répond aux questions sur l'utilisation de
-- 60Sec-AI à partir de l'aide en ligne (dossier Aide/) et d'un PROFIL de la
-- compagnie généré depuis ses données : configuration, taxes, plan comptable,
-- volumes (clients, fournisseurs, factures, écritures), intégrations, état
-- courant. Le profil ne porte JAMAIS de nom de client, de fournisseur,
-- d'employé ni d'utilisateur, ni numéro de compte bancaire, NEQ, NAS, adresse
-- ou téléphone : rien qui identifie une personne. L'utilisateur y ajoute ses
-- « particularités ».
--
--   T146AssistantProfil       : le profil généré et les particularités, par compagnie.
--   T147AssistantConversation : chaque question et sa réponse, avec le coût.
--   PROMPT_ASSISTANT_ERP      : le prompt système, dans dbo.T0000Parameters, avec
--                               les autres prompts (modifiable dans Sec60Admin › Prompts OpenAI).
--   s0856..s0862              : les procédures (aucune requête inline dans l'ERP).
-- Ce script se rejoue sans dommage.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.T146AssistantProfil') IS NULL
CREATE TABLE dbo.T146AssistantProfil (
    CompanyGUID        uniqueidentifier NOT NULL CONSTRAINT PK_T146AssistantProfil PRIMARY KEY,
    Particularites     nvarchar(max) NULL,      -- ce que le logiciel ne sait pas, écrit par l'utilisateur
    ProfilGenere       nvarchar(max) NULL,      -- le profil tel qu'envoyé à l'assistant
    Empreinte          nvarchar(400) NULL,      -- résumé des volumes sur lesquels le profil a été généré
    GenereLe           datetime2(0) NULL,
    ModifieLe          datetime2(0) NULL,
    ModifiePar         nvarchar(256) NULL
);
GO

IF OBJECT_ID(N'dbo.T147AssistantConversation') IS NULL
BEGIN
    CREATE TABLE dbo.T147AssistantConversation (
        Id            int IDENTITY(1,1) NOT NULL CONSTRAINT PK_T147AssistantConversation PRIMARY KEY,
        CompanyGUID   uniqueidentifier NOT NULL,
        Utilisateur   nvarchar(256) NULL,
        Langue        char(2) NULL,
        Section       varchar(40) NULL,          -- la section d'aide d'où la question est partie
        Question      nvarchar(max) NOT NULL,
        Reponse       nvarchar(max) NULL,
        Modele        nvarchar(60) NULL,
        InputTokens   int NOT NULL CONSTRAINT DF_T147_In DEFAULT (0),
        OutputTokens  int NOT NULL CONSTRAINT DF_T147_Out DEFAULT (0),
        CoutUsd       decimal(10,6) NOT NULL CONSTRAINT DF_T147_Cout DEFAULT (0),
        DureeMs       int NULL,
        Erreur        nvarchar(1000) NULL,
        CreeLe        datetime2(0) NOT NULL CONSTRAINT DF_T147_CreeLe DEFAULT (sysdatetime())
    );
    CREATE INDEX IX_T147_Company ON dbo.T147AssistantConversation (CompanyGUID, CreeLe DESC);
END
GO

-- ---------------------------------------------------------------------------
-- s0856 : le profil enregistré d'une compagnie (0 ou 1 ligne)
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0856GetAssistantProfil
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CompanyGUID, Particularites, ProfilGenere, Empreinte, GenereLe, ModifieLe, ModifiePar
      FROM dbo.T146AssistantProfil
     WHERE CompanyGUID = @CompanyGUID;
END
GO

-- ---------------------------------------------------------------------------
-- s0857 : enregistre le profil généré (les particularités ne bougent pas)
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0857SaveAssistantProfil
    @CompanyGUID  uniqueidentifier,
    @ProfilGenere nvarchar(max),
    @Empreinte    nvarchar(400)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.T146AssistantProfil WHERE CompanyGUID = @CompanyGUID)
        UPDATE dbo.T146AssistantProfil
           SET ProfilGenere = @ProfilGenere, Empreinte = @Empreinte, GenereLe = sysdatetime()
         WHERE CompanyGUID = @CompanyGUID;
    ELSE
        INSERT INTO dbo.T146AssistantProfil (CompanyGUID, ProfilGenere, Empreinte, GenereLe)
        VALUES (@CompanyGUID, @ProfilGenere, @Empreinte, sysdatetime());
END
GO

-- ---------------------------------------------------------------------------
-- s0858 : enregistre les particularités écrites par l'utilisateur
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0858SaveAssistantParticularites
    @CompanyGUID    uniqueidentifier,
    @Particularites nvarchar(max),
    @Utilisateur    nvarchar(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.T146AssistantProfil WHERE CompanyGUID = @CompanyGUID)
        UPDATE dbo.T146AssistantProfil
           SET Particularites = @Particularites, ModifieLe = sysdatetime(), ModifiePar = @Utilisateur
         WHERE CompanyGUID = @CompanyGUID;
    ELSE
        INSERT INTO dbo.T146AssistantProfil (CompanyGUID, Particularites, ModifieLe, ModifiePar)
        VALUES (@CompanyGUID, @Particularites, sysdatetime(), @Utilisateur);
END
GO

-- ---------------------------------------------------------------------------
-- s0859 : journalise la question avant l'appel (rend l'Id)
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0859LogAssistantQuestion
    @CompanyGUID uniqueidentifier,
    @Utilisateur nvarchar(256) = NULL,
    @Langue      char(2) = NULL,
    @Section     varchar(40) = NULL,
    @Question    nvarchar(max),
    @Modele      nvarchar(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T147AssistantConversation (CompanyGUID, Utilisateur, Langue, Section, Question, Modele)
    VALUES (@CompanyGUID, @Utilisateur, @Langue, @Section, @Question, @Modele);
    SELECT CAST(SCOPE_IDENTITY() AS int) AS Id;
END
GO

-- ---------------------------------------------------------------------------
-- s0860 : complète la ligne du journal avec la réponse (ou l'erreur)
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0860UpdateAssistantReponse
    @Id           int,
    @Reponse      nvarchar(max) = NULL,
    @InputTokens  int = 0,
    @OutputTokens int = 0,
    @CoutUsd      decimal(10,6) = 0,
    @DureeMs      int = NULL,
    @Erreur       nvarchar(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T147AssistantConversation
       SET Reponse = @Reponse, InputTokens = @InputTokens, OutputTokens = @OutputTokens,
           CoutUsd = @CoutUsd, DureeMs = @DureeMs, Erreur = @Erreur
     WHERE Id = @Id;
END
GO

-- ---------------------------------------------------------------------------
-- s0861 : coût cumulé des questions de la compagnie ce mois-ci
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0861GetAssistantCoutMois
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(CoutUsd), 0) AS CoutUsd, COUNT(*) AS Questions
      FROM dbo.T147AssistantConversation
     WHERE CompanyGUID = @CompanyGUID
       AND CreeLe >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
END
GO

-- ---------------------------------------------------------------------------
-- s0862 : tout ce qu'il faut pour générer le profil, en plusieurs jeux de
--         résultats. AUCUNE donnée nominative : ni nom, ni adresse, ni numéro
--         d'identification (NEQ, NAS, BN, TPS/TVQ), ni compte bancaire.
--   1. paramètres de la compagnie (liste blanche par code)
--   2. présence des identifiants (oui/non seulement)
--   3. volumes des tiers et du catalogue
--   4. documents par type, état comptable et statut de paiement
--   5. échéances (factures clients en retard, à recevoir, à payer)
--   6. plan comptable (comptes actifs : numéro, nom, classe, sens)
--   7. exercices et périodes
--   8. journaux
--   9. écritures par statut
--  10. banque, relevé et paiements automatiques
--  11. intégrations, utilisateurs, abonnement
--  12. agenda, employés, reçus
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0862GetAssistantProfilData
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Aujourdhui date = CAST(GETDATE() AS date);

    -- 1. paramètres non nominatifs
    SELECT p.ShortName, p.Name, p.ParamType, p.Categorie,
           CASE p.ParamType
                WHEN 'BOOL'    THEN CASE WHEN ISNULL(v.iVal, 0) = 1 THEN 'Oui' ELSE 'Non' END
                WHEN 'INT'     THEN CAST(v.iVal AS varchar(20))
                WHEN 'DECIMAL' THEN CAST(v.fVal AS varchar(30))
                WHEN 'DATE'    THEN CONVERT(varchar(10), v.dVal, 23)
                ELSE v.sVal
           END AS Valeur
      FROM dbo.T100ParamComptable p
      LEFT JOIN dbo.T101ParamValues v ON v.T100Id = p.Id AND v.CompanyGUID = @CompanyGUID
     WHERE p.CompanyGUID = @CompanyGUID
       AND p.ShortName IN ('PROVINCE','COUNTRY','FISCAL_YEAR_END','INCORP_DATE','CAE','STRUCTURE',
                           'TAX_FREQ','TAX_PAY_BANK','GST_RATE','QST_RATE','TAX_ROUNDING','TAX_MODE','TPS_REG_DATE','TVQ_REG_DATE',
                           'PDF_TEMPLATE','PDF_PAYMENT_TERMS','PDF_PAID_STAMP','PDF_EMAIL_AFTER_PAY',
                           'INV_NUM_START','INV_NUM_PREFIX','INV_NUM_DIGITS','INV_NUM_FORMAT','INV_NUM_RESET_YEARLY','INV_DRAFT_PREFIX',
                           'RECEIPT_AUTO_POST','VP','AP','CC','CF','DP','BNR','BNE','JOURNAL_OD')
     ORDER BY p.Categorie, p.Ordre;

    -- 2. identifiants : renseignés ou non (jamais la valeur)
    SELECT p.ShortName, p.Name,
           CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(v.sVal, ''))), '') IS NOT NULL OR ISNULL(v.iVal, 0) <> 0 THEN 1 ELSE 0 END AS Renseigne
      FROM dbo.T100ParamComptable p
      LEFT JOIN dbo.T101ParamValues v ON v.T100Id = p.Id AND v.CompanyGUID = @CompanyGUID
     WHERE p.CompanyGUID = @CompanyGUID
       AND p.ShortName IN ('LEGAL_NAME','TRADE_NAME','NEQ','FED_BN','GST_NO','QST_NO','HST_NO','ADDR1','CITY','POSTAL','PHONE','MAIL_FROM_EMAIL','MAIL_SIGNATURE','COMPTE_BANQUE','COMPTABLE')
     ORDER BY p.Categorie, p.Ordre;

    -- 3. tiers et catalogue
    SELECT
        (SELECT COUNT(*) FROM dbo.T050Party pa JOIN dbo.T055PartyType t ON t.Id = pa.Type WHERE pa.CompanyGUID = @CompanyGUID AND ISNULL(pa.isDeleted, 0) = 0 AND t.TypeCode IN ('CLIENT','CLIENT_FOURNISSEUR')) AS Clients,
        (SELECT COUNT(*) FROM dbo.T050Party pa JOIN dbo.T055PartyType t ON t.Id = pa.Type WHERE pa.CompanyGUID = @CompanyGUID AND ISNULL(pa.isDeleted, 0) = 0 AND t.TypeCode IN ('FOURNISSEUR','CLIENT_FOURNISSEUR')) AS Fournisseurs,
        (SELECT COUNT(*) FROM dbo.T050Party pa WHERE pa.CompanyGUID = @CompanyGUID AND ISNULL(pa.isDeleted, 0) = 0 AND pa.StripeAccountId IS NOT NULL AND pa.StripeAccountId <> '') AS FournisseursStripe,
        (SELECT COUNT(*) FROM dbo.T050Party pa WHERE pa.CompanyGUID = @CompanyGUID AND ISNULL(pa.isDeleted, 0) = 0 AND pa.SquareCustomerId IS NOT NULL AND pa.SquareCustomerId <> '') AS ClientsSquare,
        (SELECT COUNT(*) FROM dbo.T075Products pr WHERE pr.CompanyGUID = @CompanyGUID AND ISNULL(pr.Actif, 1) = 1) AS ProduitsActifs,
        (SELECT COUNT(*) FROM dbo.T075Products pr WHERE pr.CompanyGUID = @CompanyGUID AND ISNULL(pr.Actif, 1) = 0) AS ProduitsInactifs,
        (SELECT COUNT(*) FROM dbo.T075Products pr WHERE pr.CompanyGUID = @CompanyGUID AND (pr.CompteVente IS NULL OR pr.CompteVente = '') AND (pr.CategoryId IS NULL OR pr.CategoryId = 0)) AS ProduitsSansCompteNiCategorie,
        (SELECT COUNT(*) FROM dbo.T076ProductCategory c WHERE c.CompanyGUID = @CompanyGUID) AS Categories,
        (SELECT COUNT(*) FROM dbo.T076ProductCategory c WHERE c.CompanyGUID = @CompanyGUID AND (c.CompteVente IS NULL OR c.CompteVente = '')) AS CategoriesSansCompteVente;

    -- 4. documents par type / état comptable / statut de paiement
    SELECT t.Name AS TypeDocument,
           ISNULL(d.ComptabilisationStatus, '') AS EtatComptable,
           ISNULL(s.Name, '') AS Statut,
           COUNT(*) AS Nb, ISNULL(SUM(d.Total), 0) AS Total
      FROM dbo.T060Document d
      JOIN dbo.T065DocumentType t ON t.Id = d.DocumentTypeId
      LEFT JOIN dbo.T066DocumentStatus s ON s.Id = d.StatusId
     WHERE d.CompanyGUID = @CompanyGUID
     GROUP BY t.Name, ISNULL(d.ComptabilisationStatus, ''), ISNULL(s.Name, '')
     ORDER BY t.Name, EtatComptable, Statut;

    -- 5. échéances (documents comptabilisés, non payés)
    SELECT t.Name AS TypeDocument,
           SUM(CASE WHEN d.DueDate < @Aujourdhui THEN 1 ELSE 0 END) AS NbEnRetard,
           SUM(CASE WHEN d.DueDate < @Aujourdhui THEN ISNULL(d.Total, 0) ELSE 0 END) AS TotalEnRetard,
           SUM(CASE WHEN d.DueDate >= @Aujourdhui THEN 1 ELSE 0 END) AS NbAVenir,
           SUM(CASE WHEN d.DueDate >= @Aujourdhui THEN ISNULL(d.Total, 0) ELSE 0 END) AS TotalAVenir,
           MIN(CASE WHEN d.DueDate < @Aujourdhui THEN d.DueDate END) AS PlusAncienneEcheance
      FROM dbo.T060Document d
      JOIN dbo.T065DocumentType t ON t.Id = d.DocumentTypeId
      LEFT JOIN dbo.T066DocumentStatus s ON s.Id = d.StatusId
     WHERE d.CompanyGUID = @CompanyGUID
       AND t.Name IN ('FactureClient','FactureFournisseur')
       AND ISNULL(s.Name, '') NOT IN ('Paid','Cancelled')
       AND ISNULL(d.ComptabilisationStatus, '') = 'COMPTABILISE'
     GROUP BY t.Name
     ORDER BY t.Name;

    -- 6. plan comptable
    SELECT pc.Compte, pc.Nom, pc.TypeBilan, pc.Sens, pc.Actif, pc.Systeme,
           cl.Code AS ClasseCode, cl.Description AS ClasseDescription, cp.Code AS ClasseParentCode
      FROM dbo.T121PlanComptable pc
      LEFT JOIN dbo.T120PlanComptable_Classe cl ON cl.Id = pc.ClasseId
      LEFT JOIN dbo.T120PlanComptable_Classe cp ON cp.Id = pc.ClasseParentId
     WHERE pc.CompanyGUID = @CompanyGUID
     ORDER BY pc.Compte;

    -- 7. exercices et périodes
    SELECT e.annee, e.date_debut, e.date_fin, e.statut,
           (SELECT COUNT(*) FROM dbo.T112Periodes p WHERE p.exercice_id = e.id) AS Periodes,
           (SELECT COUNT(*) FROM dbo.T112Periodes p WHERE p.exercice_id = e.id AND p.statut <> 'OUVERTE') AS PeriodesFermees
      FROM dbo.T111Exercices e
     WHERE e.CompanyGUID = @CompanyGUID
     ORDER BY e.annee;

    -- 8. journaux
    SELECT j.Code, j.Libelle, j.Type, j.Actif
      FROM dbo.T130Journaux j
     WHERE j.CompanyGUID = @CompanyGUID
     ORDER BY j.Code;

    -- 9. écritures par statut
    SELECT ISNULL(ec.Statut, '') AS Statut, COUNT(*) AS Nb, MIN(ec.DateEcriture) AS Premiere, MAX(ec.DateEcriture) AS Derniere
      FROM dbo.T135Ecritures ec
     WHERE ec.CompanyGUID = @CompanyGUID
     GROUP BY ISNULL(ec.Statut, '')
     ORDER BY Statut;

    -- 10. banque, relevé, paiements automatiques
    SELECT
        (SELECT COUNT(*) FROM dbo.T143PlaidAccount b WHERE b.CompanyGUID = @CompanyGUID AND ISNULL(b.Active, 0) = 1) AS ComptesBancairesActifs,
        (SELECT STRING_AGG(x.BankName, ', ') FROM (SELECT DISTINCT b.BankName FROM dbo.T143PlaidAccount b WHERE b.CompanyGUID = @CompanyGUID AND ISNULL(b.Active, 0) = 1) x) AS Banques,
        (SELECT ISNULL(c.PlaidAutoImport, 0) FROM dbo.T010Company c WHERE c.CompanyGUID = @CompanyGUID) AS ImportAutomatique,
        (SELECT COUNT(*) FROM dbo.T142ReleveBancaire r WHERE r.CompanyGUID = @CompanyGUID) AS MouvementsReleve,
        (SELECT COUNT(*) FROM dbo.T142ReleveBancaire r WHERE r.CompanyGUID = @CompanyGUID AND ISNULL(r.Statut, '') NOT IN (N'Réglé', N'Ignoré')) AS MouvementsNonRegles,
        (SELECT MAX(r.DateMouvement) FROM dbo.T142ReleveBancaire r WHERE r.CompanyGUID = @CompanyGUID) AS DernierMouvement,
        (SELECT COUNT(*) FROM dbo.T140Reglement g WHERE g.CompanyGUID = @CompanyGUID) AS Reglements,
        (SELECT COUNT(*) FROM dbo.T144AuthorizationAutoPay a WHERE a.CompanyGUID = @CompanyGUID AND a.RevokedDate IS NULL) AS AutorisationsAutoPay,
        (SELECT COUNT(*) FROM dbo.T060Document d WHERE d.CompanyGUID = @CompanyGUID AND ISNULL(d.AutoPay, 0) = 1 AND ISNULL(d.AutoPayStatus, '') IN ('PLANIFIE','SCHEDULED','PENDING')) AS PaiementsAutoProgrammes;

    -- 11. intégrations, utilisateurs, abonnement
    SELECT
        CASE WHEN c.SquareMerchantId IS NOT NULL AND c.SquareMerchantId <> '' THEN 1 ELSE 0 END AS SquareConnecte,
        c.SquareConnectedDate,
        CASE WHEN c.MailVerifiedAddress IS NOT NULL AND c.MailVerifiedAddress <> '' THEN 1 ELSE 0 END AS CourrielVerifie,
        CASE WHEN c.Sec60Email IS NOT NULL AND c.Sec60Email <> '' THEN 1 ELSE 0 END AS BoiteSec60,
        CASE WHEN c.Logo IS NOT NULL THEN 1 ELSE 0 END AS LogoPresent,
        CASE WHEN c.ComptableGUID IS NOT NULL THEN 1 ELSE 0 END AS ComptableRelie,
        (SELECT COUNT(*) FROM dbo.T015User u WHERE u.CompanyGUID = @CompanyGUID AND ISNULL(u.IsDeleted, 0) = 0 AND ISNULL(u.IsActive, 1) = 1) AS UtilisateursActifs,
        (SELECT COUNT(*) FROM dbo.T015User u WHERE u.CompanyGUID = @CompanyGUID AND ISNULL(u.IsDeleted, 0) = 0 AND ISNULL(u.IsAdmin, 0) = 1) AS Administrateurs,
        s.PlanName, s.Status AS StatutAbonnement, s.IsTrial, s.TrialEndOn, s.NextBillingDate, s.BillingCycle
      FROM dbo.T010Company c
      LEFT JOIN dbo.T020Subscription s ON s.Id = (SELECT TOP 1 Id FROM dbo.T020Subscription WHERE CompanyGUID = @CompanyGUID AND ISNULL(IsDeleted, 0) = 0 ORDER BY CreatedOn DESC)
     WHERE c.CompanyGUID = @CompanyGUID;

    -- 12. agenda, employés, reçus
    SELECT
        (SELECT COUNT(*) FROM dbo.T300Employees e WHERE e.CompanyGUID = @CompanyGUID AND ISNULL(e.Active, 1) = 1) AS EmployesActifs,
        (SELECT COUNT(*) FROM dbo.T300Employees e WHERE e.CompanyGUID = @CompanyGUID AND e.Sec60Email IS NOT NULL AND e.Sec60Email <> '') AS EmployesAvecBoite,
        (SELECT COUNT(*) FROM dbo.Appointments a WHERE a.CompanyGUID = @CompanyGUID AND ISNULL(a.IsDeleted, 0) = 0 AND a.StartDateTime >= GETDATE()) AS RendezVousAVenir,
        (SELECT COUNT(*) FROM dbo.Appointments a WHERE a.CompanyGUID = @CompanyGUID AND ISNULL(a.IsDeleted, 0) = 0 AND a.StartDateTime >= DATEADD(day, -30, GETDATE()) AND a.StartDateTime < GETDATE()) AS RendezVous30Jours,
        (SELECT COUNT(*) FROM dbo.T0001Receipt r WHERE r.CompanyGUID = @CompanyGUID) AS Recus,
        (SELECT COUNT(*) FROM dbo.T0001Receipt r WHERE r.CompanyGUID = @CompanyGUID AND r.AI_JSON IS NULL) AS RecusNonAnalyses;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_ASSISTANT_ERP')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_ASSISTANT_ERP', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu es l''assistant de 60Sec-AI, le logiciel de gestion (ERP) de 60Sec pour les PME du Québec : clients et factures, fournisseurs et achats, produits, comptabilité en partie double, taxes TPS/TVQ, rapports financiers, importation depuis QuickBooks, agenda, courriel, paiements Square/Stripe/Plaid. Tu aides l''utilisateur d''une compagnie à se servir correctement du logiciel.

Tu disposes de deux sources, fournies après ces consignes :
  1. L''AIDE : l''aide en ligne complète de 60Sec-AI, section par section (chaque écran, chaque bouton, chaque champ, chaque règle, chaque message).
  2. LE PROFIL DE LA COMPAGNIE : sa configuration (province, exercice, taxes, numérotation, comptes par défaut), son plan comptable, ses volumes (clients, fournisseurs, produits, factures par état, écritures), ses échéances, ses intégrations (Square, Plaid, Stripe, courriel), son abonnement, et les particularités écrites par l''utilisateur. Le profil ne contient aucun nom de client, de fournisseur, d''employé ou d''utilisateur, ni aucun numéro d''identification ou de compte : n''en demande pas et n''en invente pas.

Règles :
- Réponds dans la langue de la question (français, anglais ou espagnol).
- Appuie-toi d''abord sur l''aide et le profil. Quand tu indiques quoi faire, nomme l''écran et le chemin du menu, par exemple « Comptabilité › Rapport de taxes », et le libellé exact du bouton.
- La section d''aide d''où part la question t''est indiquée : privilégie-la, mais utilise le reste de l''aide si la réponse est ailleurs.
- Ne calcule pas de montants à la main : renvoie aux rapports (État des résultats, Bilan, Balance de vérification, Rapport de taxes). Tu peux expliquer une règle (pourquoi une facture n''a pas de numéro, pourquoi un bilan est déséquilibré, quand une facture devient définitive).
- Tu n''es ni comptable agréé ni conseiller fiscal : pour une décision qui engage (traitement fiscal, classement d''un compte, fermeture d''exercice), explique la règle générale de l''aide et recommande de la confirmer auprès du comptable de l''entreprise, de Revenu Québec ou de l''ARC.
- Si l''aide et le profil ne suffisent pas, dis-le simplement, sans inventer.
- Sois concret et court : des étapes numérotées quand il y a une marche à suivre, une réponse directe sinon. Pas de préambule.
- Ne demande jamais de mot de passe, de NAS, de numéro de carte ni de compte bancaire, et ne les répète pas si l''utilisateur en écrit un.'
 WHERE [ParamName] = 'PROMPT_ASSISTANT_ERP';
GO

PRINT N'T278_Assistant_IA.sql : terminé.';
