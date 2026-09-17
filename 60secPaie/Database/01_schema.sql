/* 60secPaie - schéma SQL Server.
   Toutes les tables vivent dans le schéma « paie » : l'application peut ainsi partager une base avec d'autres
   applications (base MngConsul) sans conflit de noms, et ce script ne touche à AUCUN objet hors de ce schéma.

   Le nom de la base est passé par la variable sqlcmd Base :
     Développement : sqlcmd -S "(localdb)\MSSQLLocalDB" -f 65001 -v Base=60secPaie -i 01_schema.sql
     Serveur       : sqlcmd -S 192.168.0.203 -U MngConsul -C -f 65001 -v Base=MngConsul -i 01_schema.sql
                     (sans -P : sqlcmd demande le mot de passe, qui ne reste ainsi dans aucun fichier ni historique)
   Le script peut être relancé sans danger : il ne crée que ce qui manque. */

IF DB_ID(N'$(Base)') IS NULL
    CREATE DATABASE [$(Base)];
GO
USE [$(Base)];
GO

IF SCHEMA_ID(N'paie') IS NULL
    EXEC (N'CREATE SCHEMA paie AUTHORIZATION dbo');
GO

-- Migration de la base de développement créée avant l'adoption du schéma « paie » : les tables passent de dbo à paie.
-- Volontairement limitée à la base dédiée « 60secPaie » : dans une base partagée, une table dbo du même nom
-- appartiendrait à une autre application.
IF DB_NAME() = N'60secPaie' AND OBJECT_ID(N'dbo.LotPaie') IS NOT NULL AND OBJECT_ID(N'paie.LotPaie') IS NULL
BEGIN
    DECLARE @table sysname, @sql nvarchar(400);
    DECLARE tables_a_deplacer CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID(N'dbo') AND name IN
            (N'Utilisateur', N'Compagnie', N'ElementPaie', N'Employe', N'EmployeElement', N'CumulatifDepart', N'LotPaie',
             N'Paie', N'PaieLigne', N'JournalActivite', N'Remise', N'RemiseLigne', N'CompteGL');
    OPEN tables_a_deplacer;
    FETCH NEXT FROM tables_a_deplacer INTO @table;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'ALTER SCHEMA paie TRANSFER dbo.' + QUOTENAME(@table);
        EXEC (@sql);
        FETCH NEXT FROM tables_a_deplacer INTO @table;
    END
    CLOSE tables_a_deplacer;
    DEALLOCATE tables_a_deplacer;
    PRINT N'Tables déplacées du schéma dbo vers le schéma paie.';
END
GO

IF OBJECT_ID(N'paie.Utilisateur') IS NULL
CREATE TABLE paie.Utilisateur (
    Id            int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Utilisateur PRIMARY KEY,
    Courriel      nvarchar(256) NOT NULL CONSTRAINT UQ_Utilisateur_Courriel UNIQUE,
    NomComplet    nvarchar(200) NOT NULL,
    MotDePasse    nvarchar(400) NOT NULL,          -- PBKDF2 : iterations:sel:hachage
    Actif         bit NOT NULL CONSTRAINT DF_Utilisateur_Actif DEFAULT (1),
    EchecsConnexion int NOT NULL CONSTRAINT DF_Utilisateur_Echecs DEFAULT (0),
    VerrouilleJusqua datetime2(0) NULL,
    DateCreation  datetime2(0) NOT NULL CONSTRAINT DF_Utilisateur_Date DEFAULT (sysdatetime())
);
GO

-- Gestion des utilisateurs : rôle administrateur et changement de mot de passe forcé après une réinitialisation.
IF COL_LENGTH(N'paie.Utilisateur', N'EstAdmin') IS NULL
    ALTER TABLE paie.Utilisateur ADD EstAdmin bit NOT NULL CONSTRAINT DF_Utilisateur_EstAdmin DEFAULT (0);
IF COL_LENGTH(N'paie.Utilisateur', N'DoitChangerMotDePasse') IS NULL
    ALTER TABLE paie.Utilisateur ADD DoitChangerMotDePasse bit NOT NULL CONSTRAINT DF_Utilisateur_DoitChanger DEFAULT (0);
GO
-- Le plus ancien compte devient administrateur s'il n'y en a aucun (bases créées avant l'ajout des rôles).
IF NOT EXISTS (SELECT 1 FROM paie.Utilisateur WHERE EstAdmin = 1)
    UPDATE paie.Utilisateur SET EstAdmin = 1 WHERE Id = (SELECT MIN(Id) FROM paie.Utilisateur);
GO

IF OBJECT_ID(N'paie.Compagnie') IS NULL
CREATE TABLE paie.Compagnie (
    Id                      int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Compagnie PRIMARY KEY,
    Nom                     nvarchar(200) NOT NULL,
    Adresse1                nvarchar(200) NULL,
    Adresse2                nvarchar(200) NULL,
    Ville                   nvarchar(100) NULL,
    Province                nchar(2) NOT NULL CONSTRAINT DF_Compagnie_Province DEFAULT (N'QC'),
    CodePostal              nvarchar(10) NULL,
    Telephone               nvarchar(30) NULL,
    Courriel                nvarchar(256) NULL,
    PeriodesParAnnee        int NOT NULL CONSTRAINT DF_Compagnie_Periodes DEFAULT (26),
    MasseSalarialeEstimee   decimal(14,2) NOT NULL CONSTRAINT DF_Compagnie_Masse DEFAULT (0),
    SecteurFSS              tinyint NOT NULL CONSTRAINT DF_Compagnie_Secteur DEFAULT (0),   -- 0 général, 1 primaire/manufacturier, 2 public
    FacteurAE               decimal(6,4) NOT NULL CONSTRAINT DF_Compagnie_FacteurAE DEFAULT (1.4),
    TauxVacancesDefaut      decimal(5,2) NOT NULL CONSTRAINT DF_Compagnie_Vacances DEFAULT (4),
    TauxCNESST              decimal(7,4) NOT NULL CONSTRAINT DF_Compagnie_CNESST DEFAULT (0), -- $ par 100 $ assurables
    AssujettiCNT            bit NOT NULL CONSTRAINT DF_Compagnie_CNT DEFAULT (1),
    NumeroEntrepriseFederal nvarchar(20) NULL,     -- 123456789RP0001
    NumeroIdentificationRQ  nvarchar(20) NULL,     -- 1234567890RS0001
    ProchainNumeroCheque    int NOT NULL CONSTRAINT DF_Compagnie_Cheque DEFAULT (1)
);
GO

IF OBJECT_ID(N'paie.ElementPaie') IS NULL
CREATE TABLE paie.ElementPaie (
    Id              int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ElementPaie PRIMARY KEY,
    CompagnieId     int NOT NULL CONSTRAINT FK_ElementPaie_Compagnie REFERENCES paie.Compagnie(Id),
    Description     nvarchar(100) NOT NULL,
    CategorieCode   varchar(40) NOT NULL,          -- catégorie système (voir CategoriePaie.vb)
    Actif           bit NOT NULL CONSTRAINT DF_ElementPaie_Actif DEFAULT (1),
    MasquerSurTalon bit NOT NULL CONSTRAINT DF_ElementPaie_Masquer DEFAULT (0),
    CompteGL        nvarchar(30) NULL
);
GO

IF OBJECT_ID(N'paie.Employe') IS NULL
CREATE TABLE paie.Employe (
    Id                  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Employe PRIMARY KEY,
    CompagnieId         int NOT NULL CONSTRAINT FK_Employe_Compagnie REFERENCES paie.Compagnie(Id),
    Actif               bit NOT NULL CONSTRAINT DF_Employe_Actif DEFAULT (1),
    Code                nvarchar(20) NULL,
    Prenom              nvarchar(100) NOT NULL,
    Nom                 nvarchar(100) NOT NULL,
    Adresse1            nvarchar(200) NULL,
    Adresse2            nvarchar(200) NULL,
    Ville               nvarchar(100) NULL,
    Province            nchar(2) NOT NULL CONSTRAINT DF_Employe_Province DEFAULT (N'QC'),
    CodePostal          nvarchar(10) NULL,
    Courriel            nvarchar(256) NULL,
    Telephone           nvarchar(30) NULL,
    DateNaissance       date NULL,
    Langue              nchar(2) NOT NULL CONSTRAINT DF_Employe_Langue DEFAULT (N'FR'),
    NASChiffre          nvarchar(400) NULL,        -- chiffré par l'application (MachineKey)
    Poste               nvarchar(100) NULL,
    DateEmbauche        date NULL,
    DateFinEmploi       date NULL,
    PeriodesParAnnee    int NULL,                  -- NULL = valeur de la compagnie
    HeuresSemaine       decimal(6,2) NULL,
    TauxHoraire         decimal(10,4) NULL,
    SalaireAnnuel       decimal(12,2) NULL,
    TauxVacances        decimal(5,2) NULL,         -- NULL = valeur de la compagnie

    ExemptImpotFederal  bit NOT NULL CONSTRAINT DF_Employe_ExFed DEFAULT (0),
    ExemptImpotQuebec   bit NOT NULL CONSTRAINT DF_Employe_ExQc DEFAULT (0),
    ExemptRRQ           bit NOT NULL CONSTRAINT DF_Employe_ExRRQ DEFAULT (0),
    ExemptRQAP          bit NOT NULL CONSTRAINT DF_Employe_ExRQAP DEFAULT (0),
    ExemptAE            bit NOT NULL CONSTRAINT DF_Employe_ExAE DEFAULT (0),
    ExemptFSS           bit NOT NULL CONSTRAINT DF_Employe_ExFSS DEFAULT (0),
    ExemptCNESST        bit NOT NULL CONSTRAINT DF_Employe_ExCNESST DEFAULT (0),

    TD1MontantDemande       decimal(12,2) NULL,    -- NULL = montant personnel de base de l'année
    TD1ImpotAdditionnel     decimal(10,2) NOT NULL CONSTRAINT DF_Employe_TD1L DEFAULT (0),
    TD1DeductionZone        decimal(12,2) NOT NULL CONSTRAINT DF_Employe_TD1HD DEFAULT (0),
    TD1DeductionsAnnuelles  decimal(12,2) NOT NULL CONSTRAINT DF_Employe_TD1F1 DEFAULT (0),
    TD1AutresCredits        decimal(12,2) NOT NULL CONSTRAINT DF_Employe_TD1K3 DEFAULT (0),

    TP1015Montant           decimal(12,2) NULL,    -- NULL = montant personnel de base de l'année
    TP1015ImpotAdditionnel  decimal(10,2) NOT NULL CONSTRAINT DF_Employe_TPL DEFAULT (0),
    TP1015DeductionsLigne19 decimal(12,2) NOT NULL CONSTRAINT DF_Employe_TPJ DEFAULT (0),
    TP1016Deductions        decimal(12,2) NOT NULL CONSTRAINT DF_Employe_TPJ1 DEFAULT (0),
    TP1016Credits           decimal(12,2) NOT NULL CONSTRAINT DF_Employe_TPK1 DEFAULT (0),

    DepotDirect         bit NOT NULL CONSTRAINT DF_Employe_Depot DEFAULT (0),
    Transit             nvarchar(5) NULL,
    Institution         nvarchar(3) NULL,
    CompteChiffre       nvarchar(400) NULL,        -- chiffré par l'application
    TalonParCourriel    bit NOT NULL CONSTRAINT DF_Employe_Talon DEFAULT (0),
    Note                nvarchar(max) NULL
);
GO

IF OBJECT_ID(N'paie.EmployeElement') IS NULL
CREATE TABLE paie.EmployeElement (   -- gabarit de paie récurrent de l'employé
    Id            int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EmployeElement PRIMARY KEY,
    EmployeId     int NOT NULL CONSTRAINT FK_EmployeElement_Employe REFERENCES paie.Employe(Id) ON DELETE CASCADE,
    ElementPaieId int NOT NULL CONSTRAINT FK_EmployeElement_Element REFERENCES paie.ElementPaie(Id),
    Heures        decimal(8,2) NOT NULL CONSTRAINT DF_EmployeElement_Heures DEFAULT (0),
    Taux          decimal(10,4) NOT NULL CONSTRAINT DF_EmployeElement_Taux DEFAULT (0),
    Montant       decimal(12,2) NOT NULL CONSTRAINT DF_EmployeElement_Montant DEFAULT (0)
);
GO

IF OBJECT_ID(N'paie.CumulatifDepart') IS NULL
CREATE TABLE paie.CumulatifDepart (  -- soldes de départ lors d'une conversion en cours d'année
    Id              int IDENTITY(1,1) NOT NULL CONSTRAINT PK_CumulatifDepart PRIMARY KEY,
    EmployeId       int NOT NULL CONSTRAINT FK_CumulatifDepart_Employe REFERENCES paie.Employe(Id) ON DELETE CASCADE,
    Annee           int NOT NULL,
    Brut            decimal(12,2) NOT NULL DEFAULT (0),
    ImpotFederal    decimal(12,2) NOT NULL DEFAULT (0),
    ImpotQuebec     decimal(12,2) NOT NULL DEFAULT (0),
    RRQ             decimal(12,2) NOT NULL DEFAULT (0),
    RRQ2            decimal(12,2) NOT NULL DEFAULT (0),
    GainsRRQ        decimal(12,2) NOT NULL DEFAULT (0),
    AE              decimal(12,2) NOT NULL DEFAULT (0),
    RQAP            decimal(12,2) NOT NULL DEFAULT (0),
    RQAPEmployeur   decimal(12,2) NOT NULL DEFAULT (0),
    GainsCNESST     decimal(12,2) NOT NULL DEFAULT (0),
    VacancesSolde   decimal(12,2) NOT NULL DEFAULT (0),
    CONSTRAINT UQ_CumulatifDepart UNIQUE (EmployeId, Annee)
);
GO

IF OBJECT_ID(N'paie.LotPaie') IS NULL
CREATE TABLE paie.LotPaie (
    Id                int IDENTITY(1,1) NOT NULL CONSTRAINT PK_LotPaie PRIMARY KEY,
    CompagnieId       int NOT NULL CONSTRAINT FK_LotPaie_Compagnie REFERENCES paie.Compagnie(Id),
    PeriodesParAnnee  int NOT NULL,
    DateDebutPeriode  date NOT NULL,
    DateFinPeriode    date NOT NULL,
    DatePaie          date NOT NULL,
    Statut            char(1) NOT NULL CONSTRAINT DF_LotPaie_Statut DEFAULT ('B'),  -- B brouillon, C confirmé, A annulé
    Calcule           bit NOT NULL CONSTRAINT DF_LotPaie_Calcule DEFAULT (0),
    CreePar           nvarchar(256) NOT NULL,
    DateCreation      datetime2(0) NOT NULL CONSTRAINT DF_LotPaie_Date DEFAULT (sysdatetime()),
    DateConfirmation  datetime2(0) NULL,
    CONSTRAINT CK_LotPaie_Statut CHECK (Statut IN ('B','C','A'))
);
GO

IF OBJECT_ID(N'paie.Paie') IS NULL
CREATE TABLE paie.Paie (
    Id                  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Paie PRIMARY KEY,
    LotPaieId           int NOT NULL CONSTRAINT FK_Paie_Lot REFERENCES paie.LotPaie(Id) ON DELETE CASCADE,
    EmployeId           int NOT NULL CONSTRAINT FK_Paie_Employe REFERENCES paie.Employe(Id),
    Inclus              bit NOT NULL CONSTRAINT DF_Paie_Inclus DEFAULT (1),
    NumeroCheque        int NULL,
    Heures              decimal(8,2) NOT NULL DEFAULT (0),
    BrutVerse           decimal(12,2) NOT NULL DEFAULT (0),
    AvantagesNonMonetaires decimal(12,2) NOT NULL DEFAULT (0),
    ImpotFederal        decimal(12,2) NOT NULL DEFAULT (0),
    ImpotQuebec         decimal(12,2) NOT NULL DEFAULT (0),
    RRQ                 decimal(12,2) NOT NULL DEFAULT (0),
    RRQ2                decimal(12,2) NOT NULL DEFAULT (0),
    AE                  decimal(12,2) NOT NULL DEFAULT (0),
    RQAP                decimal(12,2) NOT NULL DEFAULT (0),
    AutresDeductions    decimal(12,2) NOT NULL DEFAULT (0),
    Net                 decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurRRQ        decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurRRQ2       decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurAE         decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurRQAP       decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurFSS        decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurCNESST     decimal(12,2) NOT NULL DEFAULT (0),
    EmployeurCNT        decimal(12,2) NOT NULL DEFAULT (0),
    GainsRRQ            decimal(12,2) NOT NULL DEFAULT (0),
    GainsAE             decimal(12,2) NOT NULL DEFAULT (0),
    GainsRQAP           decimal(12,2) NOT NULL DEFAULT (0),
    GainsFSS            decimal(12,2) NOT NULL DEFAULT (0),
    GainsCNESST         decimal(12,2) NOT NULL DEFAULT (0),
    BrutImposableFederal decimal(12,2) NOT NULL DEFAULT (0),
    BrutImposableQuebec decimal(12,2) NOT NULL DEFAULT (0),
    ForfaitairesFederal decimal(12,2) NOT NULL DEFAULT (0),
    ForfaitairesQuebec  decimal(12,2) NOT NULL DEFAULT (0),
    CSBForfaitaires     decimal(12,2) NOT NULL DEFAULT (0),
    VacancesAccumulees  decimal(12,2) NOT NULL DEFAULT (0),
    VacancesPayees      decimal(12,2) NOT NULL DEFAULT (0),
    TauxVacances        decimal(5,2) NOT NULL DEFAULT (0),
    Verification        nvarchar(max) NULL,
    Avertissements      nvarchar(max) NULL,
    CONSTRAINT UQ_Paie_Lot_Employe UNIQUE (LotPaieId, EmployeId)
);
GO

IF OBJECT_ID(N'paie.PaieLigne') IS NULL
CREATE TABLE paie.PaieLigne (
    Id              int IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaieLigne PRIMARY KEY,
    PaieId          int NOT NULL CONSTRAINT FK_PaieLigne_Paie REFERENCES paie.Paie(Id) ON DELETE CASCADE,
    ElementPaieId   int NOT NULL CONSTRAINT FK_PaieLigne_Element REFERENCES paie.ElementPaie(Id),
    Description     nvarchar(100) NOT NULL,
    CategorieCode   varchar(40) NOT NULL,
    Heures          decimal(8,2) NOT NULL DEFAULT (0),
    Taux            decimal(10,4) NOT NULL DEFAULT (0),
    Montant         decimal(12,2) NOT NULL DEFAULT (0),
    MasquerSurTalon bit NOT NULL DEFAULT (0)
);
GO

IF OBJECT_ID(N'paie.JournalActivite') IS NULL
CREATE TABLE paie.JournalActivite (
    Id          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_JournalActivite PRIMARY KEY,
    DateHeure   datetime2(0) NOT NULL CONSTRAINT DF_Journal_Date DEFAULT (sysdatetime()),
    Utilisateur nvarchar(256) NOT NULL,
    Description nvarchar(400) NOT NULL,
    Lien        nvarchar(200) NULL
);
GO

/* ---------- Remises gouvernementales (paiement des retenues) ---------- */

IF COL_LENGTH(N'paie.Compagnie', N'FrequenceRemiseFederale') IS NULL
    ALTER TABLE paie.Compagnie ADD FrequenceRemiseFederale char(1) NOT NULL CONSTRAINT DF_Compagnie_FreqFed DEFAULT ('M');  -- M mensuelle, T trimestrielle
IF COL_LENGTH(N'paie.Compagnie', N'FrequenceRemiseQuebec') IS NULL
    ALTER TABLE paie.Compagnie ADD FrequenceRemiseQuebec char(1) NOT NULL CONSTRAINT DF_Compagnie_FreqQc DEFAULT ('M');
GO

IF OBJECT_ID(N'paie.Remise') IS NULL
CREATE TABLE paie.Remise (
    Id                  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Remise PRIMARY KEY,
    CompagnieId         int NOT NULL CONSTRAINT FK_Remise_Compagnie REFERENCES paie.Compagnie(Id),
    Gouvernement        char(1) NOT NULL,              -- F fédéral (Receveur général), Q Revenu Québec
    DateFinPeriode      date NOT NULL,                 -- retenues accumulées au
    DatePaiement        date NOT NULL,
    ModePaiement        char(1) NOT NULL CONSTRAINT DF_Remise_Mode DEFAULT ('E'),   -- E en ligne, C chèque
    NumeroCheque        int NULL,
    Reference           nvarchar(60) NULL,             -- numéro de confirmation du paiement
    Total               decimal(14,2) NOT NULL CONSTRAINT DF_Remise_Total DEFAULT (0),
    RemunerationBrute   decimal(14,2) NOT NULL CONSTRAINT DF_Remise_Brut DEFAULT (0),
    NbPaies             int NOT NULL CONSTRAINT DF_Remise_NbPaies DEFAULT (0),
    NbEmployesDernierePaie int NOT NULL CONSTRAINT DF_Remise_NbEmp DEFAULT (0),
    Statut              char(1) NOT NULL CONSTRAINT DF_Remise_Statut DEFAULT ('P'), -- P payée, A annulée
    CreePar             nvarchar(256) NOT NULL,
    DateCreation        datetime2(0) NOT NULL CONSTRAINT DF_Remise_Date DEFAULT (sysdatetime()),
    CONSTRAINT CK_Remise_Gouvernement CHECK (Gouvernement IN ('F','Q')),
    CONSTRAINT CK_Remise_Statut CHECK (Statut IN ('P','A'))
);
GO

IF OBJECT_ID(N'paie.RemiseLigne') IS NULL
CREATE TABLE paie.RemiseLigne (
    Id          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_RemiseLigne PRIMARY KEY,
    RemiseId    int NOT NULL CONSTRAINT FK_RemiseLigne_Remise REFERENCES paie.Remise(Id) ON DELETE CASCADE,
    Code        varchar(30) NOT NULL,
    Libelle     nvarchar(100) NOT NULL,
    Ordre       int NOT NULL,
    Montant     decimal(14,2) NOT NULL
);
GO

-- Chaque paie est remise une fois à chaque gouvernement.
IF COL_LENGTH(N'paie.Paie', N'RemiseFederaleId') IS NULL
    ALTER TABLE paie.Paie ADD RemiseFederaleId int NULL CONSTRAINT FK_Paie_RemiseFederale REFERENCES paie.Remise(Id);
IF COL_LENGTH(N'paie.Paie', N'RemiseQuebecId') IS NULL
    ALTER TABLE paie.Paie ADD RemiseQuebecId int NULL CONSTRAINT FK_Paie_RemiseQuebec REFERENCES paie.Remise(Id);
GO

/* ---------- Feuillets, écritures comptables, dépôt direct, talons par courriel ---------- */

-- T4, case 45 : accès à un régime de soins dentaires offert par l'employeur (1 = aucun accès ... 5).
IF COL_LENGTH(N'paie.Employe', N'CodeDentaireT4') IS NULL
    ALTER TABLE paie.Employe ADD CodeDentaireT4 tinyint NOT NULL CONSTRAINT DF_Employe_Dentaire DEFAULT (1);
IF COL_LENGTH(N'paie.Paie', N'TalonEnvoyeLe') IS NULL
    ALTER TABLE paie.Paie ADD TalonEnvoyeLe datetime2(0) NULL;
IF COL_LENGTH(N'paie.LotPaie', N'DepotDirectNumeroFichier') IS NULL
    ALTER TABLE paie.LotPaie ADD DepotDirectNumeroFichier int NULL, DepotDirectGenereLe datetime2(0) NULL;
GO

-- Paramètres du fichier de dépôt direct (norme 005 de Paiements Canada), fournis par l'institution financière.
IF COL_LENGTH(N'paie.Compagnie', N'DDNumeroEmetteur') IS NULL
    ALTER TABLE paie.Compagnie ADD
        DDNumeroEmetteur        nvarchar(10) NULL,
        DDCentreTraitement      nvarchar(5) NULL,
        DDNomCourt              nvarchar(15) NULL,
        DDNomLong               nvarchar(30) NULL,
        DDInstitution           nvarchar(3) NULL,
        DDTransit               nvarchar(5) NULL,
        DDCompteChiffre         nvarchar(400) NULL,     -- chiffré par l'application
        DDProchainNumeroFichier int NOT NULL CONSTRAINT DF_Compagnie_DDFichier DEFAULT (1);
GO

-- Plan comptable : un numéro de compte par clé (voir ServiceGL.vb). Les éléments de paie ont leur propre CompteGL.
IF OBJECT_ID(N'paie.CompteGL') IS NULL
CREATE TABLE paie.CompteGL (
    CompagnieId int NOT NULL CONSTRAINT FK_CompteGL_Compagnie REFERENCES paie.Compagnie(Id),
    Cle         varchar(30) NOT NULL,
    Compte      nvarchar(30) NOT NULL,
    CONSTRAINT PK_CompteGL PRIMARY KEY (CompagnieId, Cle)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Paie_Employe' AND object_id = OBJECT_ID(N'paie.Paie'))
    CREATE INDEX IX_Paie_Employe ON paie.Paie (EmployeId) INCLUDE (LotPaieId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_LotPaie_DatePaie' AND object_id = OBJECT_ID(N'paie.LotPaie'))
    CREATE INDEX IX_LotPaie_DatePaie ON paie.LotPaie (CompagnieId, DatePaie) INCLUDE (Statut);
GO

PRINT N'Schéma 60secPaie prêt.';
GO
