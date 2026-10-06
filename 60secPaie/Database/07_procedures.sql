-- =============================================================================
-- 07 — Toutes les requêtes de l'application vivent ici, en procédures stockées
--
-- Jusqu'ici, 60secPaie.Web écrivait ses requêtes dans le code VB (Db.Table,
-- Db.Exec…). Désormais le code n'exécute que des procédures stockées (Db.vb
-- refuse tout autre texte) : une procédure par requête, dans le schéma paie,
-- nommée paie.sp<Entité>_<Action>. Les noms des paramètres sont ceux que le
-- code passait déjà (@c = paie.Compagnie.Id de la compagnie courante, @l = lot,
-- @p = paie, @e = employé…). Les requêtes qui se construisaient au vol
-- (gouvernement, période ou lot, province, catégories exclues) sont devenues
-- des procédures à paramètres facultatifs.
--
-- Les procédures qui créent une ligne se terminent par
-- SELECT CAST(SCOPE_IDENTITY() AS int) : Db.Inserer lit cette valeur.
-- Aucune procédure n'active SET NOCOUNT ON : Db.Exec rend le nombre de lignes.
--
-- Ce script se rejoue sans dommage (CREATE OR ALTER). Les tests d'intégration
-- (60secPaie.Tests) le rejouent dans leur base LocalDB.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- Compagnie
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spCompagnie_Get @c int AS
    SELECT * FROM paie.Compagnie WHERE Id = @c;
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_IdParGuid @g uniqueidentifier AS
    SELECT Id FROM paie.Compagnie WHERE CompanyGUID = @g;
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_Province @c int AS
    SELECT Province FROM paie.Compagnie WHERE Id = @c;
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_Periodes @c int AS
    SELECT PeriodesParAnnee FROM paie.Compagnie WHERE Id = @c;
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_TauxCNESST @c int AS
    SELECT TauxCNESST FROM paie.Compagnie WHERE Id = @c;
GO
-- Fréquence de remise : F = Receveur général, Q = Revenu Québec.
CREATE OR ALTER PROCEDURE paie.spCompagnie_FrequenceRemise @c int, @g char(1) AS
    SELECT CASE WHEN @g = 'F' THEN FrequenceRemiseFederale ELSE FrequenceRemiseQuebec END FROM paie.Compagnie WHERE Id = @c;
GO
-- Nom et coordonnées tels que définis dans MngConsul (paramètres LEGAL_NAME, ADDR1…).
CREATE OR ALTER PROCEDURE paie.spCompagnie_Identite @g uniqueidentifier AS
    SELECT ISNULL(dbo.fCompanyName(@g), N'') AS Nom, dbo.fParamS(@g, 'ADDR1') AS Adresse1, dbo.fParamS(@g, 'ADDR2') AS Adresse2,
           dbo.fParamS(@g, 'CITY') AS Ville, dbo.fParamS(@g, 'POSTAL') AS CodePostal, dbo.fParamS(@g, 'PHONE') AS Telephone,
           dbo.fParamS(@g, 'MAIL_FROM_EMAIL') AS Courriel, dbo.fParamS(@g, 'FED_BN') AS NumeroEntreprise;
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_Synchroniser
    @n nvarchar(200), @a1 nvarchar(200), @a2 nvarchar(200), @v nvarchar(100), @cp nvarchar(10), @t nvarchar(30), @c nvarchar(256), @id int AS
    UPDATE paie.Compagnie SET Nom = @n, Adresse1 = @a1, Adresse2 = @a2, Ville = @v, CodePostal = @cp, Telephone = @t,
           Courriel = COALESCE(@c, Courriel) WHERE Id = @id;
GO
-- Première configuration de la paie d'une compagnie de MngConsul. @Id est reçu (même jeu de paramètres que la mise à jour) et ignoré.
CREATE OR ALTER PROCEDURE paie.spCompagnie_Inserer
    @Guid uniqueidentifier, @Nom nvarchar(200), @Periodes int, @Masse decimal(14,2), @Secteur tinyint, @FacteurAE decimal(6,4),
    @TauxVacances decimal(5,2), @TauxCNESST decimal(7,4), @CNT bit, @NEFederal nvarchar(20), @NIRQ nvarchar(20), @Cheque int,
    @FreqFed char(1), @FreqQc char(1), @Province nchar(2), @ISE bit, @TauxSante decimal(7,4), @Id int = NULL AS
    INSERT INTO paie.Compagnie (CompanyGUID, Nom, PeriodesParAnnee, MasseSalarialeEstimee, SecteurFSS, FacteurAE, TauxVacancesDefaut, TauxCNESST,
                                AssujettiCNT, NumeroEntrepriseFederal, NumeroIdentificationRQ, ProchainNumeroCheque, FrequenceRemiseFederale, FrequenceRemiseQuebec,
                                Province, ISEExemptionAdmissible, TauxSanteEmployeur)
    VALUES (@Guid, @Nom, @Periodes, @Masse, @Secteur, @FacteurAE, @TauxVacances, @TauxCNESST, @CNT, @NEFederal, @NIRQ, @Cheque, @FreqFed, @FreqQc,
            @Province, @ISE, @TauxSante);
    SELECT CAST(SCOPE_IDENTITY() AS int);
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_Update
    @Guid uniqueidentifier, @Nom nvarchar(200), @Periodes int, @Masse decimal(14,2), @Secteur tinyint, @FacteurAE decimal(6,4),
    @TauxVacances decimal(5,2), @TauxCNESST decimal(7,4), @CNT bit, @NEFederal nvarchar(20), @NIRQ nvarchar(20), @Cheque int,
    @FreqFed char(1), @FreqQc char(1), @Province nchar(2), @ISE bit, @TauxSante decimal(7,4), @Id int AS
    UPDATE paie.Compagnie SET PeriodesParAnnee = @Periodes, MasseSalarialeEstimee = @Masse, SecteurFSS = @Secteur, FacteurAE = @FacteurAE,
           TauxVacancesDefaut = @TauxVacances, TauxCNESST = @TauxCNESST, AssujettiCNT = @CNT, NumeroEntrepriseFederal = @NEFederal,
           NumeroIdentificationRQ = @NIRQ, ProchainNumeroCheque = @Cheque, FrequenceRemiseFederale = @FreqFed, FrequenceRemiseQuebec = @FreqQc,
           Province = @Province, ISEExemptionAdmissible = @ISE, TauxSanteEmployeur = @TauxSante
    WHERE Id = @Id AND CompanyGUID = @Guid;
GO
-- La province d'emploi a changé : les brouillons sont à recalculer dans la nouvelle province.
CREATE OR ALTER PROCEDURE paie.spCompagnie_ChangerProvinceBrouillons @c int, @prov nchar(2) AS
    UPDATE paie.LotPaie SET Calcule = 0 WHERE CompagnieId = @c AND Statut = 'B';
    UPDATE p SET Province = @prov FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE l.CompagnieId = @c AND l.Statut = 'B';
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_UpdateDepotDirect
    @e nvarchar(10), @ct nvarchar(5), @nc nvarchar(15), @nl nvarchar(30), @i nvarchar(3), @t nvarchar(5), @p int, @c int AS
    UPDATE paie.Compagnie SET DDNumeroEmetteur = @e, DDCentreTraitement = @ct, DDNomCourt = @nc, DDNomLong = @nl, DDInstitution = @i, DDTransit = @t,
           DDProchainNumeroFichier = @p WHERE Id = @c;
GO
CREATE OR ALTER PROCEDURE paie.spCompagnie_UpdateDDCompte @v nvarchar(400), @c int AS
    UPDATE paie.Compagnie SET DDCompteChiffre = @v WHERE Id = @c;
GO

-- -----------------------------------------------------------------------------
-- Ce qu'une paie doit à chaque gouvernement (voir la section Remises plus bas)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION paie.fnDuFederal
    (@Province nchar(2), @ImpotFederal decimal(12,2), @AE decimal(12,2), @EmployeurAE decimal(12,2), @ImpotQuebec decimal(12,2),
     @RRQ decimal(12,2), @RRQ2 decimal(12,2), @EmployeurRRQ decimal(12,2), @EmployeurRRQ2 decimal(12,2))
RETURNS decimal(14,2) WITH SCHEMABINDING AS
BEGIN
    RETURN @ImpotFederal + @AE + @EmployeurAE +
           CASE WHEN @Province <> N'QC' THEN @ImpotQuebec + @RRQ + @RRQ2 + @EmployeurRRQ + @EmployeurRRQ2 ELSE 0 END;
END
GO
CREATE OR ALTER FUNCTION paie.fnDuQuebec
    (@Province nchar(2), @ImpotQuebec decimal(12,2), @RRQ decimal(12,2), @RRQ2 decimal(12,2), @EmployeurRRQ decimal(12,2), @EmployeurRRQ2 decimal(12,2),
     @RQAP decimal(12,2), @EmployeurRQAP decimal(12,2), @EmployeurFSS decimal(12,2), @EmployeurCNESST decimal(12,2))
RETURNS decimal(14,2) WITH SCHEMABINDING AS
BEGIN
    RETURN CASE WHEN @Province <> N'QC' THEN 0
                ELSE @ImpotQuebec + @RRQ + @RRQ2 + @EmployeurRRQ + @EmployeurRRQ2 + @RQAP + @EmployeurRQAP + @EmployeurFSS + @EmployeurCNESST END;
END
GO

-- -----------------------------------------------------------------------------
-- Journal d'activité
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spJournalActivite_Inserer @u nvarchar(256), @d nvarchar(400), @l nvarchar(200), @c int AS
    INSERT INTO paie.JournalActivite (Utilisateur, Description, Lien, CompagnieId) VALUES (@u, @d, @l, @c);
GO
CREATE OR ALTER PROCEDURE paie.spJournalActivite_Recents @c int AS
    SELECT TOP 8 * FROM paie.JournalActivite WHERE CompagnieId = @c ORDER BY Id DESC;
GO

-- -----------------------------------------------------------------------------
-- Connexion (comptes de MngConsul, verrouillage de 60secPaie)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spUtilisateur_CompteActif @c nvarchar(256) AS
    SELECT u.Id, u.UserGUID, u.CompanyGUID, u.Email AS Courriel, LTRIM(RTRIM(ISNULL(u.FirstName, N'') + N' ' + ISNULL(u.LastName, N''))) AS NomComplet,
           u.IsAdmin AS EstAdmin, CAST(ISNULL(u.isAccountant, 0) AS bit) AS EstComptable
    FROM dbo.T015User u WHERE u.Email = @c AND u.IsDeleted = 0 AND u.IsActive = 1;
GO
CREATE OR ALTER PROCEDURE paie.spUtilisateur_Hachage @c nvarchar(256) AS
    SELECT u.PasswordHash FROM dbo.T015User u WHERE u.Email = @c AND u.IsDeleted = 0 AND u.IsActive = 1;
GO
CREATE OR ALTER PROCEDURE paie.spTentativeConnexion_Get @c nvarchar(200) AS
    SELECT VerrouilleJusqua FROM paie.TentativeConnexion WHERE Courriel = @c;
GO
-- Un échec de plus ; au @max-ième, le compte est verrouillé @min minutes.
CREATE OR ALTER PROCEDURE paie.spTentativeConnexion_Echec @c nvarchar(200), @max int, @min int AS
    MERGE paie.TentativeConnexion AS t USING (SELECT @c AS Courriel) AS s ON t.Courriel = s.Courriel
    WHEN MATCHED THEN UPDATE SET Echecs = t.Echecs + 1, DernierEchec = sysdatetime(),
         VerrouilleJusqua = CASE WHEN t.Echecs + 1 >= @max THEN DATEADD(minute, @min, sysdatetime()) ELSE t.VerrouilleJusqua END
    WHEN NOT MATCHED THEN INSERT (Courriel, Echecs, DernierEchec) VALUES (@c, 1, sysdatetime());
GO
CREATE OR ALTER PROCEDURE paie.spTentativeConnexion_Effacer @c nvarchar(200) AS
    DELETE FROM paie.TentativeConnexion WHERE Courriel = @c;
GO

-- -----------------------------------------------------------------------------
-- Paramètres de MngConsul (clé de l'IA, prompt) et taux des provinces
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spParametre_Valeur @ParamName varchar(200) AS
    SELECT [Value] FROM dbo.T0000Parameters WHERE [ParamName] = @ParamName;
GO
CREATE OR ALTER PROCEDURE paie.spParametresProvince_Annee @a int AS
    SELECT Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable
    FROM paie.ParametresProvince WHERE Annee = @a;
GO

-- -----------------------------------------------------------------------------
-- Éléments de paie
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spElementPaie_Get @id int, @c int AS
    SELECT * FROM paie.ElementPaie WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_Liste @c int AS
    SELECT * FROM paie.ElementPaie WHERE CompagnieId = @c ORDER BY Actif DESC, Description;
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_ListeActifs @c int AS
    SELECT Id, Description, CategorieCode, ISNULL(CompteGL, '') AS CompteGL FROM paie.ElementPaie WHERE CompagnieId = @c AND Actif = 1 ORDER BY Description;
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_IdParCategorie @c int, @code varchar(40) AS
    SELECT TOP 1 Id FROM paie.ElementPaie WHERE CompagnieId = @c AND CategorieCode = @code AND Actif = 1 ORDER BY Id;
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_Categorie @id int AS
    SELECT CategorieCode FROM paie.ElementPaie WHERE Id = @id;
GO
-- Élément de base créé par le logiciel (configuration de la compagnie, ligne par défaut d'une paie).
CREATE OR ALTER PROCEDURE paie.spElementPaie_Inserer @c int, @d nvarchar(100), @code varchar(40) AS
    INSERT INTO paie.ElementPaie (CompagnieId, Description, CategorieCode) VALUES (@c, @d, @code);
    SELECT CAST(SCOPE_IDENTITY() AS int);
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_InsererComplet @c int, @d nvarchar(100), @cat varchar(40), @a bit, @m bit, @gl nvarchar(30) AS
    INSERT INTO paie.ElementPaie (CompagnieId, Description, CategorieCode, Actif, MasquerSurTalon, CompteGL) VALUES (@c, @d, @cat, @a, @m, @gl);
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_Update @d nvarchar(100), @cat varchar(40), @a bit, @m bit, @gl nvarchar(30), @id int, @c int AS
    UPDATE paie.ElementPaie SET Description = @d, CategorieCode = @cat, Actif = @a, MasquerSurTalon = @m, CompteGL = @gl WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_UpdateCompteGL @v nvarchar(30), @id int, @c int AS
    UPDATE paie.ElementPaie SET CompteGL = @v WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_NbUtilisations @id int AS
    SELECT (SELECT COUNT(*) FROM paie.PaieLigne WHERE ElementPaieId = @id) + (SELECT COUNT(*) FROM paie.EmployeElement WHERE ElementPaieId = @id);
GO
CREATE OR ALTER PROCEDURE paie.spElementPaie_Supprimer @id int, @c int AS
    DELETE FROM paie.ElementPaie WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spPaieLigne_NbParElement @id int AS
    SELECT COUNT(*) FROM paie.PaieLigne WHERE ElementPaieId = @id;
GO

-- -----------------------------------------------------------------------------
-- Unités de classification CNESST (ou classes de la commission de la province)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Liste @c int AS
    SELECT u.Id, u.Code, u.Description, u.Taux, u.Actif,
           (SELECT COUNT(*) FROM paie.EmployePaie ep WHERE ep.UniteCNESSTId = u.Id) AS NbEmployes
    FROM paie.UniteCNESST u WHERE u.CompagnieId = @c ORDER BY u.Actif DESC, u.Code;
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Toutes @c int AS
    SELECT Code, Description, Taux, Actif FROM paie.UniteCNESST WHERE CompagnieId = @c ORDER BY Code;
GO
-- Les unités actives, plus celle (@u) déjà choisie par l'employé même si elle est inactive.
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Choix @c int, @u int AS
    SELECT Id, Code, Description, Taux, Actif FROM paie.UniteCNESST WHERE CompagnieId = @c AND (Actif = 1 OR Id = @u) ORDER BY Code;
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Get @id int, @c int AS
    SELECT * FROM paie.UniteCNESST WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Doublon @c int, @code nvarchar(10), @id int AS
    SELECT COUNT(*) FROM paie.UniteCNESST WHERE CompagnieId = @c AND Code = @code AND Id <> @id;
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Update @code nvarchar(10), @d nvarchar(200), @t decimal(7,4), @a bit, @id int, @c int AS
    UPDATE paie.UniteCNESST SET Code = @code, Description = @d, Taux = @t, Actif = @a WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Inserer @c int, @code nvarchar(10), @d nvarchar(200), @t decimal(7,4), @a bit AS
    INSERT INTO paie.UniteCNESST (CompagnieId, Code, Description, Taux, Actif) VALUES (@c, @code, @d, @t, @a);
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_NbUtilisations @id int AS
    SELECT (SELECT COUNT(*) FROM paie.EmployePaie WHERE UniteCNESSTId = @id) + (SELECT COUNT(*) FROM paie.Paie WHERE UniteCNESSTId = @id);
GO
CREATE OR ALTER PROCEDURE paie.spUniteCNESST_Supprimer @id int, @c int AS
    DELETE FROM paie.UniteCNESST WHERE Id = @id AND CompagnieId = @c;
GO

-- -----------------------------------------------------------------------------
-- Plan comptable de la paie
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spCompteGL_Liste @c int AS
    SELECT Cle, Compte FROM paie.CompteGL WHERE CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spCompteGL_Supprimer @c int, @k varchar(30) AS
    DELETE FROM paie.CompteGL WHERE CompagnieId = @c AND Cle = @k;
GO
CREATE OR ALTER PROCEDURE paie.spCompteGL_Inserer @c int, @k varchar(30), @v nvarchar(30) AS
    INSERT INTO paie.CompteGL (CompagnieId, Cle, Compte) VALUES (@c, @k, @v);
GO

-- -----------------------------------------------------------------------------
-- Employés (paie.Employe est une vue : identité de dbo.T300Employees + paie.EmployePaie)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spEmploye_Get @id int, @c int AS
    SELECT * FROM paie.Employe WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_Nom @id int, @c int AS
    SELECT Prenom, Nom FROM paie.Employe WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_Tous @c int AS
    SELECT * FROM paie.Employe WHERE CompagnieId = @c ORDER BY Nom, Prenom;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_NbActifs @c int AS
    SELECT COUNT(*) FROM paie.Employe WHERE CompagnieId = @c AND Actif = 1;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_Liste @c int, @inactifs bit AS
    SELECT e.Id, e.Nom, e.Prenom, e.Poste, e.Actif, e.PaieConfiguree, e.TauxHoraire, e.SalaireAnnuel, e.DateEmbauche,
           ISNULL(e.PeriodesParAnnee, c.PeriodesParAnnee) AS Periodes
    FROM paie.Employe e JOIN paie.Compagnie c ON c.Id = e.CompagnieId
    WHERE e.CompagnieId = @c AND (e.Actif = 1 OR @inactifs = 1) ORDER BY e.Actif DESC, e.Nom, e.Prenom;
GO
-- Pour le profil de l'assistant IA : actifs d'abord, dans l'ordre qui fixe les codes E1, E2…
CREATE OR ALTER PROCEDURE paie.spEmploye_ProfilIA @c int AS
    SELECT e.*, ISNULL(e.PeriodesParAnnee, c.PeriodesParAnnee) AS Periodes
    FROM paie.Employe e JOIN paie.Compagnie c ON c.Id = e.CompagnieId
    WHERE e.CompagnieId = @c ORDER BY e.Actif DESC, e.Id;
GO
-- Employés à mettre dans un nouveau lot : actifs, paie configurée, payés à cette fréquence, en emploi pendant la période.
CREATE OR ALTER PROCEDURE paie.spEmploye_PourLot @c int, @pDefaut int, @p int, @fin date, @debut date AS
    SELECT * FROM paie.Employe WHERE CompagnieId = @c AND Actif = 1 AND PaieConfiguree = 1 AND ISNULL(PeriodesParAnnee, @pDefaut) = @p
      AND (DateEmbauche IS NULL OR DateEmbauche <= @fin) AND (DateFinEmploi IS NULL OR DateFinEmploi >= @debut) ORDER BY Nom, Prenom;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_ProvincesCanada AS
    SELECT Id, Name FROM dbo.T053State WHERE CountryId = 1 ORDER BY Name;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_CodeExiste @g uniqueidentifier, @n varchar(50) AS
    SELECT COUNT(*) FROM dbo.T300Employees WHERE CompanyGUID = @g AND EmployeeNumber = @n;
GO
CREATE OR ALTER PROCEDURE paie.spEmploye_Homonyme @g uniqueidentifier, @p varchar(150), @n varchar(150) AS
    SELECT TOP 1 Id FROM dbo.T300Employees WHERE CompanyGUID = @g AND ISNULL(Active, 1) = 1
      AND LTRIM(RTRIM(ISNULL(FirstName, ''))) = @p AND LTRIM(RTRIM(ISNULL(LastName, ''))) = @n;
GO
-- Création d'un employé dans MngConsul (dbo.T300Employees) depuis la paie.
CREATE OR ALTER PROCEDURE paie.spEmploye_Creer
    @g uniqueidentifier, @code varchar(50), @prenom varchar(150), @nom varchar(150), @disp varchar(300), @naissance date, @courriel varchar(200),
    @tel varchar(50), @a1 varchar(500), @a2 varchar(500), @ville varchar(100), @etat int, @cp varchar(20), @poste varchar(150), @embauche date, @par int AS
    INSERT INTO dbo.T300Employees
        (EmployeeGUID, CompanyGUID, EmployeeNumber, FirstName, LastName, DisplayName, DateOfBirth, Email, Phone,
         Address1, Address2, City, StateId, CountryId, PostalCode, JobTitle, HireDate, Active, Created, CreatedBy)
    VALUES (NEWID(), @g, @code, @prenom, @nom, @disp, @naissance, @courriel, @tel,
            @a1, @a2, @ville, @etat, 1, @cp, @poste, @embauche, 1, GETDATE(), @par);
    SELECT CAST(SCOPE_IDENTITY() AS int);
GO

-- -----------------------------------------------------------------------------
-- Paramètres de paie d'un employé (paie.EmployePaie)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spEmployePaie_Periodes @e int AS
    SELECT PeriodesParAnnee FROM paie.EmployePaie WHERE EmployeId = @e;
GO
CREATE OR ALTER PROCEDURE paie.spEmployePaie_Enregistrer
    @Id int, @Langue nchar(2), @DateNaissance date, @NAS nvarchar(400), @Periodes int, @HeuresSemaine decimal(6,2), @TauxHoraire decimal(10,4),
    @SalaireAnnuel decimal(12,2), @TauxVacances decimal(5,2), @Unite int,
    @ExFed bit, @ExQc bit, @ExRRQ bit, @ExRQAP bit, @ExAE bit, @ExFSS bit, @ExCNESST bit,
    @TD1Montant decimal(12,2), @TD1L decimal(10,2), @TD1HD decimal(12,2), @TD1F1 decimal(12,2), @TD1K3 decimal(12,2), @Dentaire tinyint,
    @TPMontant decimal(12,2), @TPL decimal(10,2), @TPJ decimal(12,2), @TPJ1 decimal(12,2), @TPK1 decimal(12,2),
    @ONMontant decimal(12,2), @ONK3P decimal(12,2), @ONY tinyint,
    @Depot bit, @Transit nvarchar(5), @Institution nvarchar(3), @Compte nvarchar(400), @TalonCourriel bit, @Note nvarchar(max), @Par nvarchar(200) AS
    SET XACT_ABORT ON;
    BEGIN TRAN;
    IF NOT EXISTS (SELECT 1 FROM paie.EmployePaie WHERE EmployeId = @Id) INSERT INTO paie.EmployePaie (EmployeId) VALUES (@Id);
    UPDATE paie.EmployePaie SET Langue = @Langue, DateNaissance = @DateNaissance, NASChiffre = @NAS, PeriodesParAnnee = @Periodes, HeuresSemaine = @HeuresSemaine,
        TauxHoraire = @TauxHoraire, SalaireAnnuel = @SalaireAnnuel, TauxVacances = @TauxVacances, UniteCNESSTId = @Unite,
        ExemptImpotFederal = @ExFed, ExemptImpotQuebec = @ExQc, ExemptRRQ = @ExRRQ, ExemptRQAP = @ExRQAP, ExemptAE = @ExAE, ExemptFSS = @ExFSS, ExemptCNESST = @ExCNESST,
        TD1MontantDemande = @TD1Montant, TD1ImpotAdditionnel = @TD1L, TD1DeductionZone = @TD1HD, TD1DeductionsAnnuelles = @TD1F1, TD1AutresCredits = @TD1K3,
        CodeDentaireT4 = @Dentaire, TP1015Montant = @TPMontant, TP1015ImpotAdditionnel = @TPL, TP1015DeductionsLigne19 = @TPJ, TP1016Deductions = @TPJ1,
        TP1016Credits = @TPK1, TD1ONMontantDemande = @ONMontant, TD1ONAutresCredits = @ONK3P, TD1ONPersonnesACharge = @ONY,
        DepotDirect = @Depot, Transit = @Transit, Institution = @Institution, CompteChiffre = @Compte, TalonParCourriel = @TalonCourriel,
        Note = @Note, ModifiePar = @Par, ModifieLe = sysdatetime()
    WHERE EmployeId = @Id;
    COMMIT;
GO

-- -----------------------------------------------------------------------------
-- Éléments récurrents d'un employé (gabarit de sa paie)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spEmployeElement_Liste @e int AS
    SELECT ee.Id, el.Description, el.CategorieCode, ee.Heures, ee.Taux, ee.Montant, ee.Montant AS Total
    FROM paie.EmployeElement ee JOIN paie.ElementPaie el ON el.Id = ee.ElementPaieId WHERE ee.EmployeId = @e ORDER BY ee.Id;
GO
CREATE OR ALTER PROCEDURE paie.spEmployeElement_Compagnie @c int AS
    SELECT ee.EmployeId, el.Description, el.CategorieCode, ee.Heures, ee.Taux, ee.Montant
    FROM paie.EmployeElement ee JOIN paie.ElementPaie el ON el.Id = ee.ElementPaieId
    JOIN paie.Employe e ON e.Id = ee.EmployeId WHERE e.CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spEmployeElement_Inserer @e int, @el int, @h decimal(8,2), @t decimal(10,4), @m decimal(12,2) AS
    INSERT INTO paie.EmployeElement (EmployeId, ElementPaieId, Heures, Taux, Montant) VALUES (@e, @el, @h, @t, @m);
GO
CREATE OR ALTER PROCEDURE paie.spEmployeElement_Supprimer @id int, @e int AS
    DELETE FROM paie.EmployeElement WHERE Id = @id AND EmployeId = @e;
GO

-- -----------------------------------------------------------------------------
-- Cumulatifs de départ
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spCumulatifDepart_Get @e int, @a int AS
    SELECT * FROM paie.CumulatifDepart WHERE EmployeId = @e AND Annee = @a;
GO
CREATE OR ALTER PROCEDURE paie.spCumulatifDepart_Annee @c int, @a int AS
    SELECT d.* FROM paie.CumulatifDepart d JOIN paie.Employe e ON e.Id = d.EmployeId WHERE e.CompagnieId = @c AND d.Annee = @a;
GO
CREATE OR ALTER PROCEDURE paie.spCumulatifDepart_Enregistrer
    @e int, @a int, @Brut decimal(12,2), @Fed decimal(12,2), @Qc decimal(12,2), @RRQ decimal(12,2), @RRQ2 decimal(12,2), @GainsRRQ decimal(12,2),
    @AE decimal(12,2), @RQAP decimal(12,2), @RQAPE decimal(12,2), @CNESST decimal(12,2), @Vac decimal(12,2), @Province nchar(2) AS
    DELETE FROM paie.CumulatifDepart WHERE EmployeId = @e AND Annee = @a;
    INSERT INTO paie.CumulatifDepart (EmployeId, Annee, Brut, ImpotFederal, ImpotQuebec, RRQ, RRQ2, GainsRRQ, AE, RQAP, RQAPEmployeur, GainsCNESST, VacancesSolde, Province)
    VALUES (@e, @a, @Brut, @Fed, @Qc, @RRQ, @RRQ2, @GainsRRQ, @AE, @RQAP, @RQAPE, @CNESST, @Vac, @Province);
GO

-- -----------------------------------------------------------------------------
-- Lots de paie
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spLotPaie_Get @l int, @c int AS
    SELECT * FROM paie.LotPaie WHERE Id = @l AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Confirme @l int, @c int AS
    SELECT * FROM paie.LotPaie WHERE Id = @l AND CompagnieId = @c AND Statut = 'C';
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Brouillon @c int AS
    SELECT TOP 1 * FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'B' ORDER BY Id DESC;
GO
-- La paie confirmée la plus récente (toute la ligne ; Id en première colonne).
CREATE OR ALTER PROCEDURE paie.spLotPaie_DernierConfirme @c int AS
    SELECT TOP 1 * FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY DatePaie DESC, Id DESC;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_DernierePaieConfirmee @c int AS
    SELECT MAX(DatePaie) FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C';
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_NbConfirmesAnnee @c int, @a int AS
    SELECT COUNT(*) FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' AND YEAR(DatePaie) = @a;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_AnneesConfirmees @c int AS
    SELECT DISTINCT YEAR(DatePaie) AS Annee FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY Annee DESC;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Recents @c int AS
    SELECT TOP 60 Id, DatePaie, DateFinPeriode FROM paie.LotPaie WHERE CompagnieId = @c AND Statut = 'C' ORDER BY DatePaie DESC, Id DESC;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Historique @c int AS
    SELECT l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode, l.PeriodesParAnnee, l.Statut,
           COUNT(p.Id) AS NbEmployes, ISNULL(SUM(p.BrutVerse), 0) AS Brut, ISNULL(SUM(p.Net), 0) AS Net,
           ISNULL(SUM(p.EmployeurRRQ + p.EmployeurRRQ2 + p.EmployeurAE + p.EmployeurRQAP + p.EmployeurFSS + p.EmployeurCNESST + p.EmployeurCNT), 0) AS Employeur
    FROM paie.LotPaie l LEFT JOIN paie.Paie p ON p.LotPaieId = l.Id AND p.Inclus = 1 WHERE l.CompagnieId = @c
    GROUP BY l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode, l.PeriodesParAnnee, l.Statut ORDER BY l.DatePaie DESC, l.Id DESC;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_PourEnvoi @l int, @c int AS
    SELECT l.*, c.Nom AS CompagnieNom, c.Courriel AS CompagnieCourriel FROM paie.LotPaie l JOIN paie.Compagnie c ON c.Id = l.CompagnieId
    WHERE l.Id = @l AND l.CompagnieId = @c AND l.Statut = 'C';
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Inserer @c int, @p int, @debut date, @fin date, @paie date, @u nvarchar(256) AS
    INSERT INTO paie.LotPaie (CompagnieId, PeriodesParAnnee, DateDebutPeriode, DateFinPeriode, DatePaie, CreePar) VALUES (@c, @p, @debut, @fin, @paie, @u);
    SELECT CAST(SCOPE_IDENTITY() AS int);
GO
-- Une ligne a changé : le lot (en brouillon) est à recalculer.
CREATE OR ALTER PROCEDURE paie.spLotPaie_MarquerNonCalcule @p int AS
    UPDATE l SET Calcule = 0 FROM paie.LotPaie l JOIN paie.Paie p ON p.LotPaieId = l.Id WHERE p.Id = @p AND l.Statut = 'B';
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Calcule @l int AS
    UPDATE paie.LotPaie SET Calcule = 1 WHERE Id = @l;
GO
-- Confirmation : retire les employés exclus, numérote les chèques, fige la paie — en une transaction.
CREATE OR ALTER PROCEDURE paie.spLotPaie_Confirmer @l int, @c int AS
    SET XACT_ABORT ON;
    BEGIN TRAN;
    DELETE FROM paie.Paie WHERE LotPaieId = @l AND Inclus = 0;
    DECLARE @prochain int = (SELECT ProchainNumeroCheque FROM paie.Compagnie WHERE Id = @c);
    WITH x AS (SELECT p.Id, ROW_NUMBER() OVER (ORDER BY e.Nom, e.Prenom) AS rn FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId
               WHERE p.LotPaieId = @l AND e.DepotDirect = 0)
    UPDATE p SET NumeroCheque = @prochain + x.rn - 1 FROM paie.Paie p JOIN x ON x.Id = p.Id;
    UPDATE paie.Compagnie SET ProchainNumeroCheque = @prochain + (SELECT COUNT(*) FROM paie.Paie WHERE LotPaieId = @l AND NumeroCheque IS NOT NULL) WHERE Id = @c;
    UPDATE paie.LotPaie SET Statut = 'C', DateConfirmation = sysdatetime() WHERE Id = @l AND Statut = 'B';
    COMMIT;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_SupprimerBrouillon @l int AS
    DELETE FROM paie.LotPaie WHERE Id = @l AND Statut = 'B';
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_Annuler @l int, @c int AS
    UPDATE paie.LotPaie SET Statut = 'A' WHERE Id = @l AND Statut = 'C' AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spLotPaie_DepotDirectGenere @n int, @c int, @f int, @l int AS
    UPDATE paie.Compagnie SET DDProchainNumeroFichier = @n WHERE Id = @c;
    UPDATE paie.LotPaie SET DepotDirectNumeroFichier = @f, DepotDirectGenereLe = sysdatetime() WHERE Id = @l;
GO

-- -----------------------------------------------------------------------------
-- Paies d'un lot
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spPaie_Inserer @l int, @e int, @v decimal(5,2), @prov nchar(2) AS
    INSERT INTO paie.Paie (LotPaieId, EmployeId, TauxVacances, Province) VALUES (@l, @e, @v, @prov);
    SELECT CAST(SCOPE_IDENTITY() AS int);
GO
CREATE OR ALTER PROCEDURE paie.spPaie_LotId @p int, @c int AS
    SELECT p.LotPaieId FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE p.Id = @p AND l.CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_DuLotSimple @p int, @l int AS
    SELECT p.Id, e.Prenom, e.Nom FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId WHERE p.Id = @p AND p.LotPaieId = @l;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_DuLot @l int, @c int AS
    SELECT p.*, e.Prenom, e.Nom, e.DepotDirect FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId
    JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE p.LotPaieId = @l AND p.Inclus = 1 AND l.CompagnieId = @c ORDER BY e.Nom, e.Prenom;
GO
-- Étape 2 de l'assistant : chaque employé du lot, le brut prévu et le résumé de ses lignes.
CREATE OR ALTER PROCEDURE paie.spPaie_Saisie @l int AS
    SELECT p.Id, p.LotPaieId, p.Inclus, e.Nom, e.Prenom,
           ISNULL((SELECT SUM(pl.Montant) FROM paie.PaieLigne pl WHERE pl.PaieId = p.Id AND pl.CategorieCode NOT LIKE 'DED[_]%' AND pl.CategorieCode NOT LIKE 'AV[_]%'), 0) AS BrutPrevu,
           ISNULL(STUFF((SELECT ', ' + pl.Description FROM paie.PaieLigne pl WHERE pl.PaieId = p.Id ORDER BY pl.Id FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 2, ''), N'Aucune ligne') AS Resume
    FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId WHERE p.LotPaieId = @l ORDER BY e.Nom, e.Prenom;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_Inclure @i bit, @p int, @l int, @c int AS
    UPDATE p SET Inclus = @i FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE p.Id = @p AND p.LotPaieId = @l AND l.Statut = 'B' AND l.CompagnieId = @c;
GO
-- Les paies incluses du lot avec la fiche de l'employé, pour le calcul.
CREATE OR ALTER PROCEDURE paie.spPaie_ACalculer @l int AS
    SELECT p.Id AS PaieId, p.TauxVacances AS TauxVacancesPaie, e.* FROM paie.Paie p JOIN paie.Employe e ON e.Id = p.EmployeId
    WHERE p.LotPaieId = @l AND p.Inclus = 1;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_UniteCNESST @u int, @t decimal(7,4), @p int AS
    UPDATE paie.Paie SET UniteCNESSTId = @u, TauxCNESST = @t WHERE Id = @p;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_NbInclus @l int AS
    SELECT COUNT(*) FROM paie.Paie WHERE LotPaieId = @l AND Inclus = 1;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_NbNetNegatif @l int AS
    SELECT COUNT(*) FROM paie.Paie WHERE LotPaieId = @l AND Inclus = 1 AND Net < 0;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_RetenuesPayees @l int AS
    SELECT COUNT(*) FROM paie.Paie WHERE LotPaieId = @l AND (RemiseFederaleId IS NOT NULL OR RemiseQuebecId IS NOT NULL);
GO
CREATE OR ALTER PROCEDURE paie.spPaie_TalonEnvoye @p int AS
    UPDATE paie.Paie SET TalonEnvoyeLe = sysdatetime() WHERE Id = @p;
GO
-- Résultat du moteur de paie, figé sur la paie.
CREATE OR ALTER PROCEDURE paie.spPaie_Enregistrer
    @Province nchar(2), @Heures decimal(8,2), @BrutVerse decimal(12,2), @Avantages decimal(12,2), @ImpotFederal decimal(12,2), @ImpotQuebec decimal(12,2),
    @RRQ decimal(12,2), @RRQ2 decimal(12,2), @AE decimal(12,2), @RQAP decimal(12,2), @Autres decimal(12,2), @Net decimal(12,2),
    @ERRQ decimal(12,2), @ERRQ2 decimal(12,2), @EAE decimal(12,2), @ERQAP decimal(12,2), @EFSS decimal(12,2), @ECNESST decimal(12,2), @ECNT decimal(12,2),
    @GRRQ decimal(12,2), @GAE decimal(12,2), @GRQAP decimal(12,2), @GFSS decimal(12,2), @GCNESST decimal(12,2), @BFed decimal(12,2), @BQc decimal(12,2),
    @FFed decimal(12,2), @FQc decimal(12,2), @CSB decimal(12,2), @VacAcc decimal(12,2), @VacPay decimal(12,2),
    @Verif nvarchar(max), @Avert nvarchar(max), @Id int AS
    UPDATE paie.Paie SET Province = @Province, Heures = @Heures, BrutVerse = @BrutVerse, AvantagesNonMonetaires = @Avantages, ImpotFederal = @ImpotFederal, ImpotQuebec = @ImpotQuebec,
        RRQ = @RRQ, RRQ2 = @RRQ2, AE = @AE, RQAP = @RQAP, AutresDeductions = @Autres, Net = @Net,
        EmployeurRRQ = @ERRQ, EmployeurRRQ2 = @ERRQ2, EmployeurAE = @EAE, EmployeurRQAP = @ERQAP, EmployeurFSS = @EFSS, EmployeurCNESST = @ECNESST, EmployeurCNT = @ECNT,
        GainsRRQ = @GRRQ, GainsAE = @GAE, GainsRQAP = @GRQAP, GainsFSS = @GFSS, GainsCNESST = @GCNESST, BrutImposableFederal = @BFed, BrutImposableQuebec = @BQc,
        ForfaitairesFederal = @FFed, ForfaitairesQuebec = @FQc, CSBForfaitaires = @CSB, VacancesAccumulees = @VacAcc, VacancesPayees = @VacPay,
        Verification = @Verif, Avertissements = @Avert
    WHERE Id = @Id;
GO
-- Cumulatifs de l'année d'un employé : paies confirmées (sauf le lot @lot). Le salaire assurable aux accidents du
-- travail ne compte que pour la province @prov ; le RQAP, que sur les paies du Québec.
CREATE OR ALTER PROCEDURE paie.spPaie_Cumulatifs @e int, @a int, @lot int, @prov nchar(2) AS
    SELECT ISNULL(SUM(p.RRQ), 0) RRQ, ISNULL(SUM(p.RRQ2), 0) RRQ2, ISNULL(SUM(p.GainsRRQ), 0) GainsRRQ, ISNULL(SUM(p.AE), 0) AE,
           ISNULL(SUM(CASE WHEN p.Province = N'QC' THEN p.RQAP ELSE 0 END), 0) RQAP, ISNULL(SUM(p.EmployeurRQAP), 0) RQAPEmployeur,
           ISNULL(SUM(CASE WHEN p.Province = @prov THEN p.GainsCNESST ELSE 0 END), 0) GainsCNESST,
           ISNULL(SUM(p.ForfaitairesFederal), 0) ForfFed, ISNULL(SUM(p.ForfaitairesQuebec), 0) ForfQc, ISNULL(SUM(p.CSBForfaitaires), 0) CSB
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE p.EmployeId = @e AND p.Inclus = 1 AND l.Statut = 'C' AND YEAR(l.DatePaie) = @a AND l.Id <> @lot;
GO
-- Totaux d'un lot pour le sommaire.
CREATE OR ALTER PROCEDURE paie.spPaie_TotauxLot @l int, @c int AS
    SELECT ISNULL(SUM(ImpotFederal), 0) ImpotFederal, ISNULL(SUM(ImpotQuebec), 0) ImpotQuebec, ISNULL(SUM(RRQ), 0) RRQ, ISNULL(SUM(RRQ2), 0) RRQ2,
           ISNULL(SUM(AE), 0) AE, ISNULL(SUM(RQAP), 0) RQAP, ISNULL(SUM(EmployeurRRQ), 0) EmployeurRRQ, ISNULL(SUM(EmployeurRRQ2), 0) EmployeurRRQ2,
           ISNULL(SUM(EmployeurAE), 0) EmployeurAE, ISNULL(SUM(EmployeurRQAP), 0) EmployeurRQAP, ISNULL(SUM(EmployeurFSS), 0) EmployeurFSS,
           ISNULL(SUM(EmployeurCNESST), 0) EmployeurCNESST, ISNULL(SUM(EmployeurCNT), 0) EmployeurCNT, ISNULL(MAX(p.Province), N'QC') Province
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE p.LotPaieId = @l AND p.Inclus = 1 AND l.CompagnieId = @c;
GO
-- Le talon : la paie, son lot, l'employé et la compagnie.
CREATE OR ALTER PROCEDURE paie.spPaie_Talon @p int, @c int AS
    SELECT p.*, p.Province AS ProvincePaie, l.DateDebutPeriode, l.DateFinPeriode, l.DatePaie, l.Statut, l.Id AS LotId,
           e.Prenom, e.Nom, e.Code, e.Adresse1, e.Adresse2, e.Ville, e.Province AS EmployeProvince, e.CodePostal, e.DepotDirect,
           c.Nom AS CompagnieNom, c.Adresse1 AS CAdresse1, c.Ville AS CVille, c.Province AS CProvince, c.CodePostal AS CCodePostal
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId JOIN paie.Employe e ON e.Id = p.EmployeId JOIN paie.Compagnie c ON c.Id = l.CompagnieId
    WHERE p.Id = @p AND l.CompagnieId = @c;
GO
-- Cumulatifs de l'année jusqu'à cette paie incluse (paies confirmées antérieures, puis celle-ci même en brouillon).
CREATE OR ALTER PROCEDURE paie.spPaie_CumulTalon @e int, @a int, @p int, @d date, @lot int AS
    SELECT ISNULL(SUM(x.BrutVerse), 0) Brut, ISNULL(SUM(x.ImpotFederal), 0) ImpotFederal, ISNULL(SUM(x.ImpotQuebec), 0) ImpotQuebec,
           ISNULL(SUM(x.RRQ + x.RRQ2), 0) RRQ, ISNULL(SUM(x.AE), 0) AE, ISNULL(SUM(CASE WHEN x.Province = N'QC' THEN x.RQAP ELSE 0 END), 0) RQAP,
           ISNULL(SUM(CASE WHEN x.Province <> N'QC' THEN x.RQAP ELSE 0 END), 0) ImpotPaie, ISNULL(SUM(x.AutresDeductions), 0) Autres, ISNULL(SUM(x.Net), 0) Net
    FROM paie.Paie x JOIN paie.LotPaie lx ON lx.Id = x.LotPaieId
    WHERE x.EmployeId = @e AND x.Inclus = 1 AND YEAR(lx.DatePaie) = @a AND (x.Id = @p OR (lx.Statut = 'C' AND (lx.DatePaie < @d OR (lx.DatePaie = @d AND lx.Id < @lot))));
GO
CREATE OR ALTER PROCEDURE paie.spPaie_SoldeVacances @e int, @p int, @d date, @lot int AS
    SELECT ISNULL((SELECT SUM(VacancesSolde) FROM paie.CumulatifDepart WHERE EmployeId = @e), 0) +
           ISNULL((SELECT SUM(x.VacancesAccumulees - x.VacancesPayees) FROM paie.Paie x JOIN paie.LotPaie lx ON lx.Id = x.LotPaieId
                   WHERE x.EmployeId = @e AND x.Inclus = 1 AND (x.Id = @p OR (lx.Statut = 'C' AND (lx.DatePaie < @d OR (lx.DatePaie = @d AND lx.Id < @lot))))), 0);
GO
CREATE OR ALTER PROCEDURE paie.spPaie_Depots @l int, @c int AS
    SELECT p.Id AS PaieId, p.Net, e.Id AS EmployeId, e.Code, e.Prenom, e.Nom, e.Institution, e.Transit, e.CompteChiffre, e.CompteMngConsul
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId JOIN paie.Employe e ON e.Id = p.EmployeId
    WHERE l.Id = @l AND l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND e.DepotDirect = 1 AND p.Net > 0 ORDER BY e.Nom, e.Prenom;
GO
CREATE OR ALTER PROCEDURE paie.spPaie_Destinataires @l int, @c int AS
    SELECT p.Id AS PaieId, p.TalonEnvoyeLe, e.Prenom, e.Nom, e.Courriel, e.Langue FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    JOIN paie.Employe e ON e.Id = p.EmployeId WHERE l.Id = @l AND l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND e.TalonParCourriel = 1
    ORDER BY e.Nom, e.Prenom;
GO
-- Paies confirmées dont les retenues ne sont pas remises à ce gouvernement (F ou Q). Une paie hors Québec ne doit rien à Revenu Québec.
CREATE OR ALTER PROCEDURE paie.spPaie_NonRemises @c int, @g char(1) AS
    SELECT COUNT(*) AS Nb, MIN(l.DatePaie) AS Plus_ancienne FROM paie.LotPaie l JOIN paie.Paie p ON p.LotPaieId = l.Id
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1
      AND ((@g = 'F' AND p.RemiseFederaleId IS NULL) OR (@g <> 'F' AND p.RemiseQuebecId IS NULL AND p.Province = N'QC'));
GO
CREATE OR ALTER PROCEDURE paie.spPaie_CntAccumulee @c int, @a int AS
    SELECT ISNULL(SUM(p.EmployeurCNT), 0) FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a;
GO
-- Hors Québec : ce qui s'accumule dans l'année sans faire partie des remises au Receveur général, une ligne par province.
CREATE OR ALTER PROCEDURE paie.spPaie_HorsRemiseProvinces @c int, @a int AS
    SELECT p.Province, ISNULL(SUM(p.EmployeurFSS), 0) AS Sante, ISNULL(SUM(p.GainsFSS), 0) AS MasseSante,
           ISNULL(SUM(p.EmployeurCNESST), 0) AS Accidents, ISNULL(SUM(p.GainsCNESST), 0) AS AssurableAccidents,
           ISNULL(SUM(p.RQAP), 0) AS ImpotPaie, ISNULL(SUM(p.GainsRQAP), 0) AS GainsImpotPaie
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND p.Province <> N'QC' AND YEAR(l.DatePaie) = @a
    GROUP BY p.Province ORDER BY p.Province;
GO

-- -----------------------------------------------------------------------------
-- Lignes d'une paie
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spPaieLigne_Liste @p int AS
    SELECT * FROM paie.PaieLigne WHERE PaieId = @p ORDER BY Id;
GO
CREATE OR ALTER PROCEDURE paie.spPaieLigne_Talon @p int AS
    SELECT * FROM paie.PaieLigne WHERE PaieId = @p AND MasquerSurTalon = 0 ORDER BY Id;
GO
CREATE OR ALTER PROCEDURE paie.spPaieLigne_Inserer @p int, @e int, @d nvarchar(100), @c varchar(40), @h decimal(8,2), @t decimal(10,4), @m decimal(12,2), @masquer bit AS
    INSERT INTO paie.PaieLigne (PaieId, ElementPaieId, Description, CategorieCode, Heures, Taux, Montant, MasquerSurTalon)
    VALUES (@p, @e, @d, @c, @h, @t, @m, @masquer);
GO
-- Copie le gabarit de l'employé dans sa paie. @CodesExclus : catégories (séparées par des virgules) qui n'ont pas
-- leur place dans la province de la paie (avantage imposable au Québec seulement) ; rien n'est exclu si NULL.
CREATE OR ALTER PROCEDURE paie.spPaieLigne_CopierGabarit @paie int, @e int, @CodesExclus nvarchar(max) = NULL AS
    INSERT INTO paie.PaieLigne (PaieId, ElementPaieId, Description, CategorieCode, Heures, Taux, Montant, MasquerSurTalon)
    SELECT @paie, el.Id, el.Description, el.CategorieCode, ee.Heures, ee.Taux, ee.Montant, el.MasquerSurTalon
    FROM paie.EmployeElement ee JOIN paie.ElementPaie el ON el.Id = ee.ElementPaieId
    WHERE ee.EmployeId = @e AND el.Actif = 1
      AND (@CodesExclus IS NULL OR CHARINDEX(',' + el.CategorieCode + ',', ',' + @CodesExclus + ',') = 0);
GO
CREATE OR ALTER PROCEDURE paie.spPaieLigne_Supprimer @id int, @p int AS
    DELETE FROM paie.PaieLigne WHERE Id = @id AND PaieId = @p;
GO
-- Sommaire d'un lot : chaque description de ligne, revenus et déductions séparés.
CREATE OR ALTER PROCEDURE paie.spPaieLigne_SommaireLot @l int, @c int AS
    SELECT pl.Description, CASE WHEN pl.CategorieCode LIKE 'DED[_]%' THEN 1 ELSE 0 END AS EstDeduction, SUM(pl.Montant) AS Montant
    FROM paie.PaieLigne pl JOIN paie.Paie p ON p.Id = pl.PaieId JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE p.LotPaieId = @l AND p.Inclus = 1 AND l.CompagnieId = @c
    GROUP BY pl.Description, CASE WHEN pl.CategorieCode LIKE 'DED[_]%' THEN 1 ELSE 0 END ORDER BY pl.Description;
GO

-- -----------------------------------------------------------------------------
-- Écritures comptables : un lot (@lot, non annulé) ou une période (@du..@au, paies confirmées)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spGL_Totaux @c int, @lot int = NULL, @du date = NULL, @au date = NULL AS
    SELECT ISNULL(SUM(p.ImpotFederal), 0) ImpotFederal, ISNULL(SUM(p.ImpotQuebec), 0) ImpotQuebec, ISNULL(SUM(p.RRQ + p.RRQ2), 0) RRQ, ISNULL(SUM(p.AE), 0) AE,
           ISNULL(SUM(p.RQAP), 0) RQAP, ISNULL(SUM(p.Net), 0) Net, ISNULL(SUM(p.EmployeurRRQ + p.EmployeurRRQ2), 0) ERRQ, ISNULL(SUM(p.EmployeurAE), 0) EAE,
           ISNULL(SUM(p.EmployeurRQAP), 0) ERQAP, ISNULL(SUM(p.EmployeurFSS), 0) FSS, ISNULL(SUM(p.EmployeurCNESST), 0) CNESST, ISNULL(SUM(p.EmployeurCNT), 0) CNT,
           ISNULL(SUM(p.VacancesAccumulees), 0) Vacances
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND p.Inclus = 1
      AND ((@lot IS NOT NULL AND l.Id = @lot AND l.Statut <> 'A') OR (@lot IS NULL AND l.Statut = 'C' AND l.DatePaie BETWEEN @du AND @au));
GO
CREATE OR ALTER PROCEDURE paie.spGL_Lignes @c int, @lot int = NULL, @du date = NULL, @au date = NULL AS
    SELECT el.Description, el.CompteGL, pl.CategorieCode, SUM(pl.Montant) AS Montant
    FROM paie.PaieLigne pl JOIN paie.ElementPaie el ON el.Id = pl.ElementPaieId
    JOIN paie.Paie p ON p.Id = pl.PaieId JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND p.Inclus = 1
      AND ((@lot IS NOT NULL AND l.Id = @lot AND l.Statut <> 'A') OR (@lot IS NULL AND l.Statut = 'C' AND l.DatePaie BETWEEN @du AND @au))
    GROUP BY el.Description, el.CompteGL, pl.CategorieCode ORDER BY el.Description;
GO

-- -----------------------------------------------------------------------------
-- Déclaration des salaires à la CNESST (ou à la commission de la province @prov)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spCNESST_ParEmploye @c int, @a int, @prov nchar(2) AS
    SELECT e.Id, e.Nom, e.Prenom, e.ExemptCNESST, ISNULL(u.Code, N'') AS Unite, ISNULL(u.Description, N'') AS UniteDescription,
           ISNULL(p.UniteCNESSTId, 0) AS UniteId, SUM(p.GainsCNESST) AS Assurable, SUM(p.EmployeurCNESST) AS Cotisation,
           CAST(0 AS decimal(14,2)) AS Brut, CAST(0 AS decimal(14,2)) AS Excedent
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId JOIN paie.Employe e ON e.Id = p.EmployeId
    LEFT JOIN paie.UniteCNESST u ON u.Id = p.UniteCNESSTId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a AND p.Province = @prov
    GROUP BY e.Id, e.Nom, e.Prenom, e.ExemptCNESST, u.Code, u.Description, ISNULL(p.UniteCNESSTId, 0) ORDER BY e.Nom, e.Prenom, u.Code;
GO
CREATE OR ALTER PROCEDURE paie.spCNESST_LignesParEmploye @c int, @a int, @prov nchar(2) AS
    SELECT p.EmployeId, ISNULL(p.UniteCNESSTId, 0) AS UniteId, pl.CategorieCode, SUM(pl.Montant) AS Montant
    FROM paie.PaieLigne pl JOIN paie.Paie p ON p.Id = pl.PaieId JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a AND p.Province = @prov
    GROUP BY p.EmployeId, ISNULL(p.UniteCNESSTId, 0), pl.CategorieCode;
GO
CREATE OR ALTER PROCEDURE paie.spCNESST_ParUnite @c int, @a int, @prov nchar(2) AS
    SELECT ISNULL(u.Code, N'') AS Code, ISNULL(u.Description, N'Taux de la compagnie') AS Description, MAX(p.TauxCNESST) AS Taux,
           COUNT(DISTINCT p.EmployeId) AS NbEmployes, SUM(p.GainsCNESST) AS Assurable, SUM(p.EmployeurCNESST) AS Cotisation
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId LEFT JOIN paie.UniteCNESST u ON u.Id = p.UniteCNESSTId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a AND p.Province = @prov
    GROUP BY u.Code, u.Description ORDER BY CASE WHEN u.Code IS NULL THEN 1 ELSE 0 END, u.Code;
GO
CREATE OR ALTER PROCEDURE paie.spCNESST_ParMois @c int, @a int, @prov nchar(2) AS
    SELECT MONTH(l.DatePaie) AS Mois, SUM(p.GainsCNESST) AS Assurable, SUM(p.EmployeurCNESST) AS Cotisation
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a AND p.Province = @prov
    GROUP BY MONTH(l.DatePaie) ORDER BY Mois;
GO
CREATE OR ALTER PROCEDURE paie.spCNESST_VersementsPayes @c int, @a int AS
    SELECT ISNULL(SUM(rl.Montant), 0) FROM paie.RemiseLigne rl JOIN paie.Remise r ON r.Id = rl.RemiseId
    WHERE r.CompagnieId = @c AND r.Statut = 'P' AND rl.Code = 'CNESST' AND YEAR(r.DateFinPeriode) = @a;
GO

-- -----------------------------------------------------------------------------
-- Feuillets de fin d'année (T4, Relevé 1)
-- Les colonnes ImpotQuebec, RRQ et RQAP portent l'impôt provincial, le régime de pension et, dans un territoire,
-- l'impôt sur la paie de la province de la paie : on les sépare ici (Québec / hors Québec).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spFeuillet_Totaux @c int, @a int AS
    SELECT p.EmployeId, SUM(p.BrutImposableFederal) BrutFed, SUM(p.ImpotFederal) ImpotFederal, SUM(p.AE) AE, SUM(p.GainsAE) GainsAE,
           SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.RQAP END) RQAP, SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.GainsRQAP END) GainsRQAP,
           SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.BrutImposableQuebec END) BrutQc, SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.ImpotQuebec END) ImpotQuebec,
           SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.AE END) AEQc,
           SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.RRQ END) RRQ, SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.RRQ2 END) RRQ2,
           SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.GainsRRQ END) GainsRRQ,
           SUM(CASE WHEN p.Province <> N'QC' THEN p.ImpotQuebec ELSE 0 END) ImpotProvince,
           SUM(CASE WHEN p.Province <> N'QC' THEN p.RRQ ELSE 0 END) RPC, SUM(CASE WHEN p.Province <> N'QC' THEN p.RRQ2 ELSE 0 END) RPC2,
           SUM(CASE WHEN p.Province <> N'QC' THEN p.GainsRRQ ELSE 0 END) GainsRPC
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a GROUP BY p.EmployeId;
GO
CREATE OR ALTER PROCEDURE paie.spFeuillet_ProvincesPayees @c int, @a int AS
    SELECT DISTINCT p.EmployeId, p.Province FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a;
GO
CREATE OR ALTER PROCEDURE paie.spFeuillet_Lignes @c int, @a int AS
    SELECT p.EmployeId, p.Province, pl.CategorieCode, SUM(pl.Montant) AS Montant FROM paie.PaieLigne pl JOIN paie.Paie p ON p.Id = pl.PaieId
    JOIN paie.LotPaie l ON l.Id = p.LotPaieId WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a
    GROUP BY p.EmployeId, p.Province, pl.CategorieCode;
GO
-- Sommaire de l'employeur : parts de l'employeur et conciliation avec les remises enregistrées.
CREATE OR ALTER PROCEDURE paie.spFeuillet_SommaireEmployeur @c int, @a int AS
    SELECT ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.EmployeurRRQ + p.EmployeurRRQ2 END), 0) EmployeurRRQ,
           ISNULL(SUM(p.EmployeurAE), 0) EmployeurAE, ISNULL(SUM(p.EmployeurRQAP), 0) EmployeurRQAP,
           ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.EmployeurFSS END), 0) FSS,
           ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.GainsFSS END), 0) MasseFSS,
           ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN 0 ELSE p.EmployeurCNESST END), 0) CNESST, ISNULL(SUM(p.EmployeurCNT), 0) CNT,
           ISNULL(SUM(CASE WHEN p.Province <> N'QC' THEN p.EmployeurRRQ + p.EmployeurRRQ2 ELSE 0 END), 0) EmployeurRPC,
           ISNULL(SUM(paie.fnDuFederal(p.Province, p.ImpotFederal, p.AE, p.EmployeurAE, p.ImpotQuebec, p.RRQ, p.RRQ2, p.EmployeurRRQ, p.EmployeurRRQ2)), 0) DuFederal,
           ISNULL(SUM(paie.fnDuQuebec(p.Province, p.ImpotQuebec, p.RRQ, p.RRQ2, p.EmployeurRRQ, p.EmployeurRRQ2, p.RQAP, p.EmployeurRQAP, p.EmployeurFSS, p.EmployeurCNESST)), 0) DuQuebec,
           (SELECT ISNULL(SUM(Total), 0) FROM paie.Remise WHERE CompagnieId = @c AND Statut = 'P' AND Gouvernement = 'F' AND YEAR(DateFinPeriode) = @a) PayeFederal,
           (SELECT ISNULL(SUM(Total), 0) FROM paie.Remise WHERE CompagnieId = @c AND Statut = 'P' AND Gouvernement = 'Q' AND YEAR(DateFinPeriode) = @a) PayeQuebec
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND YEAR(l.DatePaie) = @a;
GO

-- -----------------------------------------------------------------------------
-- Remises gouvernementales
--
--   Receveur général (F) : impôt fédéral + AE (employés et employeur) ; hors Québec s'y ajoutent l'impôt
--   de la province et le RPC — l'ARC perçoit l'impôt provincial, rien ne va à Revenu Québec.
--   Revenu Québec (Q) : impôt du Québec + RRQ + RQAP (employés et employeur) + FSS + CNESST, pour les paies du Québec.
--   Rappel : hors Québec, l'impôt provincial et le RPC occupent les colonnes ImpotQuebec et RRQ de paie.Paie ;
--   dans un territoire, l'impôt sur la paie occupe la colonne RQAP et ne va à aucun gouvernement.
-- -----------------------------------------------------------------------------
-- Les lignes d'une remise (code, libellé, ordre, montant) pour les paies visées :
--   @RemiseId NULL : paies confirmées de la compagnie non encore remises à @g, payées au plus tard le @fin ;
--   @RemiseId donné : paies rattachées à cette remise.
-- @LibellesImpot : « ON=Impôt de l'Ontario|AB=Impôt de l'Alberta|… », fourni par le code (une ligne d'impôt
-- provincial par province, car une compagnie qui a changé de province peut en remettre deux à la fois).
CREATE OR ALTER FUNCTION paie.fnRemiseLignes (@g char(1), @c int, @fin date, @RemiseId int, @LibellesImpot nvarchar(max))
RETURNS TABLE AS RETURN
    SELECT v.Code, v.Libelle, v.Ordre, SUM(v.Montant) AS Montant
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    CROSS APPLY (VALUES
        ('F', 'IMPOT_FED', N'Impôt fédéral', 1, p.ImpotFederal),
        ('F', CASE WHEN p.Province = N'QC' THEN 'IMPOT_PROV' ELSE 'IMPOT_' + RTRIM(p.Province) END,
              ISNULL((SELECT TOP 1 SUBSTRING(s.value, 4, 100) FROM STRING_SPLIT(@LibellesImpot, '|') s WHERE LEFT(s.value, 2) = p.Province), N'Impôt provincial'),
              2, CASE WHEN p.Province <> N'QC' THEN p.ImpotQuebec ELSE 0 END),
        ('F', 'RPC_EMPLOYE', N'RPC - cotisations des employés', 3, CASE WHEN p.Province <> N'QC' THEN p.RRQ + p.RRQ2 ELSE 0 END),
        ('F', 'RPC_EMPLOYEUR', N'RPC - cotisation de l''employeur', 4, CASE WHEN p.Province <> N'QC' THEN p.EmployeurRRQ + p.EmployeurRRQ2 ELSE 0 END),
        ('F', 'AE_EMPLOYE', N'Assurance-emploi - cotisations des employés', 5, p.AE),
        ('F', 'AE_EMPLOYEUR', N'Assurance-emploi - cotisation de l''employeur', 6, p.EmployeurAE),
        ('Q', 'IMPOT_QC', N'Impôt du Québec', 1, p.ImpotQuebec),
        ('Q', 'RRQ_EMPLOYE', N'RRQ - cotisations des employés', 2, p.RRQ + p.RRQ2),
        ('Q', 'RRQ_EMPLOYEUR', N'RRQ - cotisation de l''employeur', 3, p.EmployeurRRQ + p.EmployeurRRQ2),
        ('Q', 'RQAP_EMPLOYE', N'RQAP - cotisations des employés', 4, p.RQAP),
        ('Q', 'RQAP_EMPLOYEUR', N'RQAP - cotisation de l''employeur', 5, p.EmployeurRQAP),
        ('Q', 'FSS', N'Fonds des services de santé (FSS)', 6, p.EmployeurFSS),
        ('Q', 'CNESST', N'CNESST - versement périodique', 7, p.EmployeurCNESST)
    ) v(Gouv, Code, Libelle, Ordre, Montant)
    WHERE v.Gouv = @g AND l.CompagnieId = @c
      AND ((@RemiseId IS NULL AND l.Statut = 'C' AND p.Inclus = 1 AND l.DatePaie <= @fin
            AND ((@g = 'F' AND p.RemiseFederaleId IS NULL) OR (@g = 'Q' AND p.RemiseQuebecId IS NULL AND p.Province = N'QC')))
        OR (@RemiseId IS NOT NULL AND ((@g = 'F' AND p.RemiseFederaleId = @RemiseId) OR (@g = 'Q' AND p.RemiseQuebecId = @RemiseId))))
    GROUP BY v.Code, v.Libelle, v.Ordre
    -- Les lignes hors Québec valent 0 pour une paie du Québec : elles n'apparaissent pas.
    HAVING NOT (@g = 'F' AND (v.Code IN ('IMPOT_PROV', 'RPC_EMPLOYE', 'RPC_EMPLOYEUR') OR v.Code LIKE 'IMPOT[_]__') AND SUM(v.Montant) = 0);
GO
-- Solde dû à un gouvernement : montant, nombre de paies non remises et la plus ancienne.
CREATE OR ALTER PROCEDURE paie.spRemise_Solde @c int, @fin date, @g char(1) AS
    SELECT ISNULL(SUM(CASE WHEN @g = 'F'
                           THEN paie.fnDuFederal(p.Province, p.ImpotFederal, p.AE, p.EmployeurAE, p.ImpotQuebec, p.RRQ, p.RRQ2, p.EmployeurRRQ, p.EmployeurRRQ2)
                           ELSE paie.fnDuQuebec(p.Province, p.ImpotQuebec, p.RRQ, p.RRQ2, p.EmployeurRRQ, p.EmployeurRRQ2, p.RQAP, p.EmployeurRQAP, p.EmployeurFSS, p.EmployeurCNESST) END), 0) AS Montant,
           COUNT(*) AS NbPaies, MIN(l.DatePaie) AS PlusAncienne
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND l.DatePaie <= @fin
      AND ((@g = 'F' AND p.RemiseFederaleId IS NULL) OR (@g = 'Q' AND p.RemiseQuebecId IS NULL AND p.Province = N'QC'));
GO
-- Détail des montants à payer pour les retenues accumulées jusqu'au @fin (rien n'est enregistré).
CREATE OR ALTER PROCEDURE paie.spRemise_LignesAPayer @c int, @fin date, @g char(1), @LibellesImpot nvarchar(max) = NULL AS
    SELECT Code, Libelle, Ordre, Montant FROM paie.fnRemiseLignes(@g, @c, @fin, NULL, @LibellesImpot) ORDER BY Ordre;
GO
-- Lots de paie visés : à payer (@fin) ou couverts par une remise enregistrée (@id).
CREATE OR ALTER PROCEDURE paie.spRemise_Lots @c int, @g char(1), @fin date = NULL, @id int = NULL AS
    SELECT l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode, COUNT(*) AS NbEmployes, SUM(p.BrutVerse + p.AvantagesNonMonetaires) AS Brut
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c
      AND ((@id IS NULL AND l.Statut = 'C' AND p.Inclus = 1 AND l.DatePaie <= @fin
            AND ((@g = 'F' AND p.RemiseFederaleId IS NULL) OR (@g = 'Q' AND p.RemiseQuebecId IS NULL AND p.Province = N'QC')))
        OR (@id IS NOT NULL AND ((@g = 'F' AND p.RemiseFederaleId = @id) OR (@g = 'Q' AND p.RemiseQuebecId = @id))))
    GROUP BY l.Id, l.DatePaie, l.DateDebutPeriode, l.DateFinPeriode ORDER BY l.DatePaie, l.Id;
GO
-- Enregistre le paiement : rattache les paies à la remise et fige les montants, en une seule transaction.
-- Rend l'identifiant de la remise, ou 0 s'il n'y avait rien à payer.
CREATE OR ALTER PROCEDURE paie.spRemise_Enregistrer
    @c int, @g char(1), @fin date, @paiement date, @parCheque bit, @ref nvarchar(60), @u nvarchar(256), @LibellesImpot nvarchar(max) = NULL AS
    SET XACT_ABORT ON;
    BEGIN TRAN;
    DECLARE @cheque int = NULL;
    IF @parCheque = 1 BEGIN
        SELECT @cheque = ProchainNumeroCheque FROM paie.Compagnie WHERE Id = @c;
        UPDATE paie.Compagnie SET ProchainNumeroCheque = ProchainNumeroCheque + 1 WHERE Id = @c;
    END;
    INSERT INTO paie.Remise (CompagnieId, Gouvernement, DateFinPeriode, DatePaiement, ModePaiement, NumeroCheque, Reference, CreePar)
    VALUES (@c, @g, @fin, @paiement, CASE WHEN @parCheque = 1 THEN 'C' ELSE 'E' END, @cheque, @ref, @u);
    DECLARE @id int = SCOPE_IDENTITY();
    UPDATE p SET RemiseFederaleId = CASE WHEN @g = 'F' THEN @id ELSE p.RemiseFederaleId END,
                 RemiseQuebecId = CASE WHEN @g = 'Q' THEN @id ELSE p.RemiseQuebecId END
    FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId
    WHERE l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND l.DatePaie <= @fin
      AND ((@g = 'F' AND p.RemiseFederaleId IS NULL) OR (@g = 'Q' AND p.RemiseQuebecId IS NULL AND p.Province = N'QC'));
    IF @@ROWCOUNT = 0 BEGIN ROLLBACK; SELECT 0; RETURN; END;
    INSERT INTO paie.RemiseLigne (RemiseId, Code, Libelle, Ordre, Montant)
    SELECT @id, x.Code, x.Libelle, x.Ordre, x.Montant FROM paie.fnRemiseLignes(@g, @c, NULL, @id, @LibellesImpot) x;
    UPDATE paie.Remise SET
        Total = (SELECT ISNULL(SUM(Montant), 0) FROM paie.RemiseLigne WHERE RemiseId = @id),
        RemunerationBrute = (SELECT ISNULL(SUM(p.BrutVerse + p.AvantagesNonMonetaires), 0) FROM paie.Paie p
                             WHERE (@g = 'F' AND p.RemiseFederaleId = @id) OR (@g = 'Q' AND p.RemiseQuebecId = @id)),
        NbPaies = (SELECT COUNT(*) FROM paie.Paie p WHERE (@g = 'F' AND p.RemiseFederaleId = @id) OR (@g = 'Q' AND p.RemiseQuebecId = @id)),
        NbEmployesDernierePaie = (SELECT COUNT(*) FROM paie.Paie p
                                  WHERE ((@g = 'F' AND p.RemiseFederaleId = @id) OR (@g = 'Q' AND p.RemiseQuebecId = @id)) AND p.LotPaieId =
                                        (SELECT TOP 1 l.Id FROM paie.Paie p2 JOIN paie.LotPaie l ON l.Id = p2.LotPaieId
                                         WHERE (@g = 'F' AND p2.RemiseFederaleId = @id) OR (@g = 'Q' AND p2.RemiseQuebecId = @id)
                                         ORDER BY l.DatePaie DESC, l.Id DESC))
    WHERE Id = @id;
    COMMIT;
    SELECT @id;
GO
CREATE OR ALTER PROCEDURE paie.spRemise_Total @id int AS
    SELECT Total FROM paie.Remise WHERE Id = @id;
GO
CREATE OR ALTER PROCEDURE paie.spRemise_Get @id int, @c int AS
    SELECT * FROM paie.Remise WHERE Id = @id AND CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spRemise_Detail @id int, @c int AS
    SELECT r.*, c.NumeroEntrepriseFederal, c.NumeroIdentificationRQ FROM paie.Remise r JOIN paie.Compagnie c ON c.Id = r.CompagnieId
    WHERE r.Id = @id AND r.CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spRemise_Historique @c int AS
    SELECT * FROM paie.Remise WHERE CompagnieId = @c ORDER BY DatePaiement DESC, Id DESC;
GO
-- Annule une remise : les paies redeviennent « à payer ». Le numéro de chèque n'est pas réutilisé.
CREATE OR ALTER PROCEDURE paie.spRemise_Annuler @id int AS
    SET XACT_ABORT ON;
    BEGIN TRAN;
    UPDATE paie.Paie SET RemiseFederaleId = NULL WHERE RemiseFederaleId = @id;
    UPDATE paie.Paie SET RemiseQuebecId = NULL WHERE RemiseQuebecId = @id;
    UPDATE paie.Remise SET Statut = 'A' WHERE Id = @id;
    COMMIT;
GO
CREATE OR ALTER PROCEDURE paie.spRemiseLigne_Liste @id int AS
    SELECT Libelle, Montant FROM paie.RemiseLigne WHERE RemiseId = @id ORDER BY Ordre;
GO

-- -----------------------------------------------------------------------------
-- Assistant IA : profil de la compagnie et journal des conversations
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE paie.spProfilIA_Get @c int AS
    SELECT * FROM paie.ProfilIA WHERE CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spProfilIA_ProfilGenere @c int AS
    SELECT ProfilGenere FROM paie.ProfilIA WHERE CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spProfilIA_GenereLe @c int AS
    SELECT GenereLe FROM paie.ProfilIA WHERE CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spProfilIA_Particularites @c int AS
    SELECT Particularites FROM paie.ProfilIA WHERE CompagnieId = @c;
GO
CREATE OR ALTER PROCEDURE paie.spProfilIA_EnregistrerProfil @c int, @p nvarchar(max), @e nvarchar(max) AS
    IF EXISTS (SELECT 1 FROM paie.ProfilIA WHERE CompagnieId = @c)
        UPDATE paie.ProfilIA SET ProfilGenere = @p, EmpreinteEmployes = @e, GenereLe = sysdatetime() WHERE CompagnieId = @c;
    ELSE
        INSERT INTO paie.ProfilIA (CompagnieId, ProfilGenere, EmpreinteEmployes, GenereLe) VALUES (@c, @p, @e, sysdatetime());
GO
CREATE OR ALTER PROCEDURE paie.spProfilIA_EnregistrerParticularites @c int, @t nvarchar(max), @u nvarchar(256) AS
    IF EXISTS (SELECT 1 FROM paie.ProfilIA WHERE CompagnieId = @c)
        UPDATE paie.ProfilIA SET Particularites = @t, ModifieLe = sysdatetime(), ModifiePar = @u WHERE CompagnieId = @c;
    ELSE
        INSERT INTO paie.ProfilIA (CompagnieId, Particularites, ModifieLe, ModifiePar) VALUES (@c, @t, sysdatetime(), @u);
GO
CREATE OR ALTER PROCEDURE paie.spConversationIA_Inserer @c int, @u nvarchar(256), @l char(2), @q nvarchar(max), @m nvarchar(60) AS
    INSERT INTO paie.ConversationIA (CompagnieId, Utilisateur, Langue, Question, Modele) VALUES (@c, @u, @l, @q, @m);
    SELECT CAST(SCOPE_IDENTITY() AS int);
GO
CREATE OR ALTER PROCEDURE paie.spConversationIA_Reponse @r nvarchar(max), @i int, @o int, @cout decimal(10,6), @d int, @id int AS
    UPDATE paie.ConversationIA SET Reponse = @r, InputTokens = @i, OutputTokens = @o, CoutUsd = @cout, DureeMs = @d WHERE Id = @id;
GO
CREATE OR ALTER PROCEDURE paie.spConversationIA_Erreur @e nvarchar(1000), @d int, @id int AS
    UPDATE paie.ConversationIA SET Erreur = @e, DureeMs = @d WHERE Id = @id;
GO
CREATE OR ALTER PROCEDURE paie.spConversationIA_CoutDepuis @c int, @d date AS
    SELECT ISNULL(SUM(CoutUsd), 0) FROM paie.ConversationIA WHERE CompagnieId = @c AND CreeLe >= @d;
GO
