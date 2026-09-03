/* =====================================================================
   PortailMaster - Script 45 : chiffrement des numeros de compte bancaire
   ---------------------------------------------------------------------
   4e ecart du dossier EFT_005_APPROBATION.md : les numeros de compte
   etaient stockes EN CLAIR dans T020Client, T021Fournisseur et
   T051EftBatchItem.

   Ils sont desormais chiffres au repos (AES_256) par une cle symetrique
   protegee par certificat, lui-meme protege par la cle maitresse de la
   base. Seules les procedures qui en ont besoin ouvrent la cle :

       s0012GetClient / s0013SaveClient          (client)
       s0036GetFournisseur / s0037SaveFournisseur (fournisseur)
       s0046GetEftBatch                           (generation du 005)
       s0091ExportAbonneData                      (export RGPD : MASQUE)

   Le reste du code ne change pas : institution et transit restent en
   clair (ils designent la succursale, pas le compte), les controles
   "HasBankCoords" (IS NOT NULL) et la purge/anonymisation (SET NULL)
   fonctionnent tels quels, et s0044CreateEftBatch recopie le chiffre
   d'une table a l'autre sans jamais le dechiffrer.

   ATTENTION - AVANT D'EXECUTER :
     1. SAUVEGARDER la base.
     2. Remplacer le mot de passe de la cle maitresse ci-dessous et le
        deposer dans le coffre a mots de passe : sans lui, une restauration
        sur un AUTRE serveur ne pourra pas dechiffrer les comptes.
     3. Sauvegarder le certificat apres execution (voir la fin du script).

   A executer APRES 44. Aucune nouvelle procedure sNNNN.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   1) CLE MAITRESSE, CERTIFICAT, CLE SYMETRIQUE
   ===================================================================== */
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##')
BEGIN
    /* >>> REMPLACER CE MOT DE PASSE ET LE CONSERVER AU COFFRE <<< */
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Chang3-Moi-Avant-La-Prod!2026';
    PRINT N'Cle maitresse de base creee. Notez le mot de passe au coffre.';
END
GO

/* La cle maitresse doit s'ouvrir automatiquement pour le service SQL. */
IF EXISTS (SELECT 1 FROM sys.symmetric_keys k
           WHERE k.name = N'##MS_DatabaseMasterKey##'
             AND NOT EXISTS (SELECT 1 FROM sys.key_encryptions e
                             WHERE e.key_id = k.symmetric_key_id AND e.crypt_type = 'ESKM'))
BEGIN
    ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertEftBank')
    CREATE CERTIFICATE CertEftBank
        WITH SUBJECT = N'60secPaiement - chiffrement des coordonnees bancaires',
             EXPIRY_DATE = '2036-12-31';
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'KeyEftBank')
    CREATE SYMMETRIC KEY KeyEftBank
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE CertEftBank;
GO

/* Le compte applicatif doit pouvoir ouvrir la cle depuis les procs. */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
BEGIN
    GRANT VIEW DEFINITION ON SYMMETRIC KEY::KeyEftBank TO [MngConsul];
    GRANT CONTROL ON CERTIFICATE::CertEftBank TO [MngConsul];
END
GO
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_apiexec' AND type = 'R')
BEGIN
    GRANT VIEW DEFINITION ON SYMMETRIC KEY::KeyEftBank TO [db_apiexec];
    GRANT CONTROL ON CERTIFICATE::CertEftBank TO [db_apiexec];
END
GO

/* =====================================================================
   2) MIGRATION DES COLONNES  (NVARCHAR(12) clair -> VARBINARY(256))
   ---------------------------------------------------------------------
   Idempotent : ne fait rien si la colonne est deja binaire.
   ===================================================================== */

/* Chaque migration passe par EXEC() : sans cela, le lot ne compilerait
   pas au 2e passage (colonne BankAccountEnc inexistante = erreur de
   compilation, meme sous un IF qui ne s'execute pas). */

/* ---- T020Client ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.T020Client') AND name = N'BankAccount'
             AND TYPE_NAME(system_type_id) = N'nvarchar')
BEGIN
    EXEC(N'ALTER TABLE dbo.T020Client ADD BankAccountEnc VARBINARY(256) NULL');
    EXEC(N'OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;
           UPDATE dbo.T020Client SET BankAccountEnc = EncryptByKey(Key_GUID(''KeyEftBank''), BankAccount)
           WHERE BankAccount IS NOT NULL;
           CLOSE SYMMETRIC KEY KeyEftBank;');
    EXEC(N'ALTER TABLE dbo.T020Client DROP COLUMN BankAccount');
    EXEC sp_rename N'dbo.T020Client.BankAccountEnc', N'BankAccount', N'COLUMN';
    PRINT N'T020Client.BankAccount : chiffre.';
END
GO

/* ---- T021Fournisseur ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.T021Fournisseur') AND name = N'BankAccount'
             AND TYPE_NAME(system_type_id) = N'nvarchar')
BEGIN
    EXEC(N'ALTER TABLE dbo.T021Fournisseur ADD BankAccountEnc VARBINARY(256) NULL');
    EXEC(N'OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;
           UPDATE dbo.T021Fournisseur SET BankAccountEnc = EncryptByKey(Key_GUID(''KeyEftBank''), BankAccount)
           WHERE BankAccount IS NOT NULL;
           CLOSE SYMMETRIC KEY KeyEftBank;');
    EXEC(N'ALTER TABLE dbo.T021Fournisseur DROP COLUMN BankAccount');
    EXEC sp_rename N'dbo.T021Fournisseur.BankAccountEnc', N'BankAccount', N'COLUMN';
    PRINT N'T021Fournisseur.BankAccount : chiffre.';
END
GO

/* ---- T051EftBatchItem (instantane du compte au moment du lot) ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.T051EftBatchItem') AND name = N'BankAccount'
             AND TYPE_NAME(system_type_id) = N'nvarchar')
BEGIN
    EXEC(N'ALTER TABLE dbo.T051EftBatchItem ADD BankAccountEnc VARBINARY(256) NULL');
    EXEC(N'OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;
           UPDATE dbo.T051EftBatchItem SET BankAccountEnc = EncryptByKey(Key_GUID(''KeyEftBank''), BankAccount)
           WHERE BankAccount IS NOT NULL;
           CLOSE SYMMETRIC KEY KeyEftBank;');
    EXEC(N'ALTER TABLE dbo.T051EftBatchItem DROP COLUMN BankAccount');
    EXEC sp_rename N'dbo.T051EftBatchItem.BankAccountEnc', N'BankAccount', N'COLUMN';
    PRINT N'T051EftBatchItem.BankAccount : chiffre.';
END
GO

/* =====================================================================
   3) PROCEDURES QUI CHIFFRENT / DECHIFFRENT
   ===================================================================== */

/* --- s0012GetClient --- */
CREATE OR ALTER PROCEDURE dbo.s0012GetClient @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;

    SELECT  Id, ClientGUID, AbonneId, TypeClient, Nom, ReferenceExterne,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Statut, Notes, BankInstitution, BankTransit,
            CONVERT(NVARCHAR(12), DecryptByKey(BankAccount)) AS BankAccount,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T020Client WHERE Id = @Id;

    CLOSE SYMMETRIC KEY KeyEftBank;
END
GO

/* --- s0013SaveClient --- */
CREATE OR ALTER PROCEDURE dbo.s0013SaveClient
    @Id INT OUTPUT, @AbonneId INT, @TypeClient NVARCHAR(20) = N'Entreprise', @Nom NVARCHAR(200),
    @ReferenceExterne NVARCHAR(100) = NULL, @CourrielContact NVARCHAR(256) = NULL, @Telephone NVARCHAR(40) = NULL,
    @Adresse1 NVARCHAR(200) = NULL, @Adresse2 NVARCHAR(200) = NULL, @Ville NVARCHAR(120) = NULL,
    @Province NVARCHAR(60) = NULL, @CodePostal NVARCHAR(20) = NULL, @Pays NVARCHAR(60) = N'Canada',
    @Statut NVARCHAR(20) = N'Actif', @Notes NVARCHAR(MAX) = NULL, @AdminId INT = NULL,
    @BankInstitution CHAR(3) = NULL, @BankTransit CHAR(5) = NULL, @BankAccount NVARCHAR(12) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @acct VARBINARY(256) = NULL;
    IF @BankAccount IS NOT NULL
    BEGIN
        OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;
        SET @acct = EncryptByKey(Key_GUID(N'KeyEftBank'), @BankAccount);
        CLOSE SYMMETRIC KEY KeyEftBank;
    END

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T020Client (AbonneId, TypeClient, Nom, ReferenceExterne, CourrielContact, Telephone,
            Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, Notes, CreatedByAdminId,
            BankInstitution, BankTransit, BankAccount)
        VALUES (@AbonneId, @TypeClient, @Nom, @ReferenceExterne, @CourrielContact, @Telephone,
            @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, @Notes, @AdminId,
            @BankInstitution, @BankTransit, @acct);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
        UPDATE dbo.T020Client SET TypeClient=@TypeClient, Nom=@Nom, ReferenceExterne=@ReferenceExterne,
            CourrielContact=@CourrielContact, Telephone=@Telephone, Adresse1=@Adresse1, Adresse2=@Adresse2,
            Ville=@Ville, Province=@Province, CodePostal=@CodePostal, Pays=@Pays, Statut=@Statut, Notes=@Notes,
            BankInstitution=@BankInstitution, BankTransit=@BankTransit, BankAccount=@acct,
            ModifiedUtc=SYSUTCDATETIME(), ModifiedByAdminId=@AdminId
        WHERE Id=@Id;

    SELECT @Id AS Id;
END
GO

/* --- s0036GetFournisseur --- */
CREATE OR ALTER PROCEDURE dbo.s0036GetFournisseur @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;

    SELECT  Id, FournisseurGUID, AbonneId, TypeFournisseur, Nom, ReferenceExterne,
            CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province,
            CodePostal, Pays, Statut, Notes, BankInstitution, BankTransit,
            CONVERT(NVARCHAR(12), DecryptByKey(BankAccount)) AS BankAccount,
            CreatedUtc, CreatedByAdminId, ModifiedUtc, ModifiedByAdminId
    FROM    dbo.T021Fournisseur WHERE Id = @Id;

    CLOSE SYMMETRIC KEY KeyEftBank;
END
GO

/* --- s0037SaveFournisseur --- */
CREATE OR ALTER PROCEDURE dbo.s0037SaveFournisseur
    @Id INT OUTPUT, @AbonneId INT, @TypeFournisseur NVARCHAR(20) = N'Entreprise', @Nom NVARCHAR(200),
    @ReferenceExterne NVARCHAR(100) = NULL, @CourrielContact NVARCHAR(256) = NULL, @Telephone NVARCHAR(40) = NULL,
    @Adresse1 NVARCHAR(200) = NULL, @Adresse2 NVARCHAR(200) = NULL, @Ville NVARCHAR(120) = NULL,
    @Province NVARCHAR(60) = NULL, @CodePostal NVARCHAR(20) = NULL, @Pays NVARCHAR(60) = N'Canada',
    @Statut NVARCHAR(20) = N'Actif', @Notes NVARCHAR(MAX) = NULL, @AdminId INT = NULL,
    @BankInstitution CHAR(3) = NULL, @BankTransit CHAR(5) = NULL, @BankAccount NVARCHAR(12) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @acct VARBINARY(256) = NULL;
    IF @BankAccount IS NOT NULL
    BEGIN
        OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;
        SET @acct = EncryptByKey(Key_GUID(N'KeyEftBank'), @BankAccount);
        CLOSE SYMMETRIC KEY KeyEftBank;
    END

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T021Fournisseur (AbonneId, TypeFournisseur, Nom, ReferenceExterne, CourrielContact, Telephone,
            Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut, Notes, CreatedByAdminId,
            BankInstitution, BankTransit, BankAccount)
        VALUES (@AbonneId, @TypeFournisseur, @Nom, @ReferenceExterne, @CourrielContact, @Telephone,
            @Adresse1, @Adresse2, @Ville, @Province, @CodePostal, @Pays, @Statut, @Notes, @AdminId,
            @BankInstitution, @BankTransit, @acct);
        SET @Id = CAST(SCOPE_IDENTITY() AS INT);
    END
    ELSE
        UPDATE dbo.T021Fournisseur SET TypeFournisseur=@TypeFournisseur, Nom=@Nom, ReferenceExterne=@ReferenceExterne,
            CourrielContact=@CourrielContact, Telephone=@Telephone, Adresse1=@Adresse1, Adresse2=@Adresse2,
            Ville=@Ville, Province=@Province, CodePostal=@CodePostal, Pays=@Pays, Statut=@Statut, Notes=@Notes,
            BankInstitution=@BankInstitution, BankTransit=@BankTransit, BankAccount=@acct,
            ModifiedUtc=SYSUTCDATETIME(), ModifiedByAdminId=@AdminId
        WHERE Id=@Id;

    SELECT @Id AS Id;
END
GO

/* --- s0046GetEftBatch : dechiffre pour la generation du fichier 005. --- */
CREATE OR ALTER PROCEDURE dbo.s0046GetEftBatch
    @BatchId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.T050EftBatch WHERE Id = @BatchId;

    OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;
    SELECT Id, PaymentId, RecordType, AmountCents, CounterpartyName,
           BankInstitution, BankTransit,
           CONVERT(NVARCHAR(12), DecryptByKey(BankAccount)) AS BankAccount,
           DueDate, CrossReference
    FROM dbo.T051EftBatchItem WHERE BatchId = @BatchId ORDER BY RecordType, Id;
    CLOSE SYMMETRIC KEY KeyEftBank;
END
GO

/* --- s0091ExportAbonneData : export RGPD, numero de compte MASQUE.
       L'export sort de l'application (fichier JSON) : on ne divulgue que
       les 3 derniers chiffres, suffisants pour identifier le compte. --- */
CREATE OR ALTER PROCEDURE dbo.s0091ExportAbonneData
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 0) Abonne
    SELECT Id, TenantGUID, RaisonSociale, NomAffichage, NumeroEntreprise,
           CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province, CodePostal, Pays,
           Devise, Statut, StatutKYB, CreatedUtc, ClosedUtc, AnonymizedUtc
    FROM   dbo.T010Abonne WHERE Id = @AbonneId;

    -- 1) Utilisateurs (SANS hash de mot de passe)
    SELECT Id, Email, FirstName, LastName, IsAdmin, IsActive, LastLoginUtc, CreatedUtc
    FROM   dbo.T011AbonneUser WHERE AbonneId = @AbonneId ORDER BY Id;

    OPEN SYMMETRIC KEY KeyEftBank DECRYPTION BY CERTIFICATE CertEftBank;

    -- 2) Clients (compte masque)
    SELECT Id, ClientGUID, TypeClient, Nom, ReferenceExterne, CourrielContact, Telephone,
           Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut,
           BankInstitution, BankTransit,
           CASE WHEN BankAccount IS NULL THEN NULL
                ELSE N'****' + RIGHT(CONVERT(NVARCHAR(12), DecryptByKey(BankAccount)), 3) END AS BankAccount,
           Notes, CreatedUtc
    FROM   dbo.T020Client WHERE AbonneId = @AbonneId ORDER BY Id;

    -- 3) Fournisseurs (compte masque)
    SELECT Id, FournisseurGUID, TypeFournisseur, Nom, ReferenceExterne, CourrielContact, Telephone,
           Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut,
           BankInstitution, BankTransit,
           CASE WHEN BankAccount IS NULL THEN NULL
                ELSE N'****' + RIGHT(CONVERT(NVARCHAR(12), DecryptByKey(BankAccount)), 3) END AS BankAccount,
           Notes, CreatedUtc
    FROM   dbo.T021Fournisseur WHERE AbonneId = @AbonneId ORDER BY Id;

    CLOSE SYMMETRIC KEY KeyEftBank;

    -- 4) Paiements (encaissements + decaissements)
    SELECT p.Id, p.PaymentGUID, p.Direction, p.Method, p.AmountCents, p.FeeCents, p.NetCents,
           p.Devise, p.Status, p.Description, p.Reference, p.ExpectedSettlementDate,
           p.InitiatedUtc, p.SettledUtc, p.ReturnedUtc, p.ReturnReason,
           p.ClientId, c.Nom AS ClientNom, p.FournisseurId, f.Nom AS FournisseurNom
    FROM   dbo.T030Payment p
    LEFT JOIN dbo.T020Client c      ON c.Id = p.ClientId
    LEFT JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE  p.AbonneId = @AbonneId ORDER BY p.Id;

    -- 5) Journal (grand livre de l'abonne)
    SELECT t.Id, t.EffectiveDate, t.TxnType, t.Description, t.CreatedUtc,
           ISNULL((SELECT SUM(pp.CreditCents - pp.DebitCents)
                   FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id = pp.AccountId
                   WHERE pp.TransactionId = t.Id AND a.AbonneId = @AbonneId AND a.AccountCode = 'SUBBAL'), 0) AS DeltaSoldeCents,
           ISNULL((SELECT SUM(pp.CreditCents - pp.DebitCents)
                   FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id = pp.AccountId
                   WHERE pp.TransactionId = t.Id AND a.AbonneId = @AbonneId AND a.AccountCode = 'RESERVE'), 0) AS DeltaReserveCents
    FROM   dbo.T101LedgerTransaction t WHERE t.AbonneId = @AbonneId ORDER BY t.Id;

    -- 6) Cles d'API (meta seulement)
    SELECT Id, Prefix, Label, Environment, IsActive, CreatedUtc, LastUsedUtc, RevokedUtc
    FROM   dbo.T040ApiKey WHERE AbonneId = @AbonneId ORDER BY Id;

    -- 7) Webhook (meta : URL + etat ; PAS le secret)
    SELECT Id, Url, IsActive, CreatedUtc, UpdatedUtc
    FROM   dbo.T041WebhookEndpoint WHERE AbonneId = @AbonneId;

    -- 8) Retours EFT concernant les paiements de l'abonne
    SELECT r.Id, r.PaymentId, r.RecordType, r.AmountCents, r.ReasonCode, r.Status, r.Message, r.ImportedUtc
    FROM   dbo.T053EftReturn r
    WHERE  r.PaymentId IN (SELECT Id FROM dbo.T030Payment WHERE AbonneId = @AbonneId)
    ORDER BY r.Id;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

/* =====================================================================
   4) A FAIRE JUSTE APRES (hors script, une seule fois)
   ---------------------------------------------------------------------
   Sauvegarder le certificat et sa cle privee, puis deposer les deux
   fichiers + le mot de passe dans le coffre. Sans eux, une restauration
   de la base sur un autre serveur rendra les comptes ILLISIBLES :

     BACKUP CERTIFICATE CertEftBank
        TO FILE = 'D:\Coffre\CertEftBank.cer'
        WITH PRIVATE KEY (FILE = 'D:\Coffre\CertEftBank.pvk',
                          ENCRYPTION BY PASSWORD = '<mot de passe du coffre>');
   ===================================================================== */
PRINT N'45_bank_account_encryption.sql : termine. SAUVEGARDEZ LE CERTIFICAT.';
GO
