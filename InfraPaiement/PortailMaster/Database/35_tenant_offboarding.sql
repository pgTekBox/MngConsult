/* =====================================================================
   PortailMaster - Script 35 : offboarding de tenant (abonné)
   ---------------------------------------------------------------------
   Processus ENCADRÉ (déclenché par le staff), pas une purge automatique.
   Deux étapes distinctes :

     1) CLÔTURE (s0088OffboardAbonne) — « soft close » gardé :
        REFUSÉ tant que l'abonné détient des fonds (Solde/Réserve) ou des
        montants en compensation (EFT_IN/EFT_OUT), ou a des paiements en
        cours (Initie). Sinon : Statut=Ferme + ClosedUtc, désactive les
        utilisateurs, révoque les clés d'API, désactive le webhook, gèle
        clients/fournisseurs (Inactif). Réversible (réactivation manuelle).

     2) ANONYMISATION (s0089AnonymizeAbonne) — minimisation RGPD, après la
        période de conservation légale (jugement du staff) :
        remplace les données PERSONNELLES (raisons sociales, noms, courriels,
        adresses, coordonnées bancaires, secrets) par des marqueurs, sur
        T010/T011/T020/T021/T041 + snapshots T051. IRRÉVERSIBLE.

   ⚠️ Ce qui n'est JAMAIS touché : le GRAND LIVRE IMMUABLE (T100/T101/T102)
   et les PAIEMENTS (T030) — piste d'audit financière conservée (obligations
   FINTRAC/fiscales). L'anonymisation ne casse aucune FK (UPDATE, pas DELETE).

   s0087GetOffboardPreflight / s0088OffboardAbonne / s0089AnonymizeAbonne.
   A executer APRES 04/07/09/10/16/22. Procs numerotees s0087+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---- Colonnes de suivi de l'offboarding sur T010Abonne ---- */
IF COL_LENGTH('dbo.T010Abonne', 'ClosedUtc') IS NULL
    ALTER TABLE dbo.T010Abonne ADD ClosedUtc DATETIME2(0) NULL, ClosedByAdminId INT NULL, AnonymizedUtc DATETIME2(0) NULL;
GO

/* ---------------------------------------------------------------------
   s0087GetOffboardPreflight : état de préparation à la clôture.
   Renvoie soldes, en-cours, compteurs, et les drapeaux IsClosed /
   IsAnonymized / CanClose (fonds nuls + aucun paiement en cours).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0087GetOffboardPreflight
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH bal AS (
        SELECT a.AccountCode,
               CASE a.NormalSide WHEN 'C' THEN ISNULL(SUM(p.CreditCents - p.DebitCents), 0)
                                 ELSE ISNULL(SUM(p.DebitCents  - p.CreditCents), 0) END AS Solde,
               ISNULL(SUM(ABS(p.DebitCents - p.CreditCents)), 0) AS Raw
        FROM dbo.T100LedgerAccount a
        LEFT JOIN dbo.T102LedgerPosting p ON p.AccountId = a.Id
        WHERE a.AbonneId = @AbonneId
        GROUP BY a.AccountCode, a.NormalSide
    )
    SELECT
        ab.Id, ab.RaisonSociale, ab.Statut, ab.ClosedUtc, ab.AnonymizedUtc,
        CAST(CASE WHEN ab.Statut = N'Ferme' THEN 1 ELSE 0 END AS BIT)      AS IsClosed,
        CAST(CASE WHEN ab.AnonymizedUtc IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsAnonymized,
        ISNULL((SELECT Solde FROM bal WHERE AccountCode = 'SUBBAL'),  0) AS SoldeCents,
        ISNULL((SELECT Solde FROM bal WHERE AccountCode = 'RESERVE'), 0) AS ReserveCents,
        ISNULL((SELECT Solde FROM bal WHERE AccountCode = 'EFT_IN'),  0) AS EftInCents,
        ISNULL((SELECT Solde FROM bal WHERE AccountCode = 'EFT_OUT'), 0) AS EftOutCents,
        ISNULL((SELECT SUM(net) FROM (
            SELECT SUM(p2.DebitCents - p2.CreditCents) AS net
            FROM dbo.T100LedgerAccount a2
            JOIN dbo.T102LedgerPosting p2 ON p2.AccountId = a2.Id
            WHERE a2.AbonneId = @AbonneId AND a2.AccountCode IN ('SUBBAL','RESERVE','EFT_IN','EFT_OUT')
            GROUP BY a2.AccountCode HAVING SUM(p2.DebitCents - p2.CreditCents) <> 0) z), 0) AS OutstandingRawCents,
        (SELECT COUNT(*) FROM dbo.T030Payment     WHERE AbonneId = @AbonneId AND Status = N'Initie') AS InFlightCount,
        (SELECT COUNT(*) FROM dbo.T011AbonneUser   WHERE AbonneId = @AbonneId AND IsActive = 1)       AS ActiveUsers,
        (SELECT COUNT(*) FROM dbo.T040ApiKey        WHERE AbonneId = @AbonneId AND IsActive = 1)       AS ActiveApiKeys,
        (SELECT COUNT(*) FROM dbo.T020Client        WHERE AbonneId = @AbonneId)                        AS ClientCount,
        (SELECT COUNT(*) FROM dbo.T021Fournisseur   WHERE AbonneId = @AbonneId)                        AS FournisseurCount,
        CAST(CASE WHEN
             NOT EXISTS (SELECT 1 FROM (
                 SELECT SUM(p3.DebitCents - p3.CreditCents) AS net
                 FROM dbo.T100LedgerAccount a3
                 JOIN dbo.T102LedgerPosting p3 ON p3.AccountId = a3.Id
                 WHERE a3.AbonneId = @AbonneId AND a3.AccountCode IN ('SUBBAL','RESERVE','EFT_IN','EFT_OUT')
                 GROUP BY a3.AccountCode HAVING SUM(p3.DebitCents - p3.CreditCents) <> 0) q)
             AND NOT EXISTS (SELECT 1 FROM dbo.T030Payment WHERE AbonneId = @AbonneId AND Status = N'Initie')
             THEN 1 ELSE 0 END AS BIT) AS CanClose
    FROM dbo.T010Abonne ab
    WHERE ab.Id = @AbonneId;
END
GO

/* ---------------------------------------------------------------------
   s0088OffboardAbonne : clôture gardée. Lève une erreur si des fonds ou
   des paiements en cours subsistent ; sinon applique le « soft close ».
   Idempotent (re-jouable ; ClosedUtc figé au 1er passage).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0088OffboardAbonne
    @AbonneId INT,
    @AdminId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId)
    BEGIN RAISERROR(N'Abonné introuvable.', 16, 1); RETURN; END

    IF EXISTS (SELECT 1 FROM (
        SELECT SUM(p.DebitCents - p.CreditCents) AS net
        FROM dbo.T100LedgerAccount a
        JOIN dbo.T102LedgerPosting p ON p.AccountId = a.Id
        WHERE a.AbonneId = @AbonneId AND a.AccountCode IN ('SUBBAL','RESERVE','EFT_IN','EFT_OUT')
        GROUP BY a.AccountCode HAVING SUM(p.DebitCents - p.CreditCents) <> 0) q)
    BEGIN
        RAISERROR(N'Clôture impossible : l''abonné détient encore des fonds (solde/réserve) ou des montants en compensation. Régularisez d''abord.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.T030Payment WHERE AbonneId = @AbonneId AND Status = N'Initie')
    BEGIN
        RAISERROR(N'Clôture impossible : des paiements sont encore en cours (Initie). Réglez-les ou retournez-les d''abord.', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        UPDATE dbo.T010Abonne
        SET Statut = N'Ferme',
            ClosedUtc = ISNULL(ClosedUtc, SYSUTCDATETIME()),
            ClosedByAdminId = ISNULL(ClosedByAdminId, @AdminId),
            ModifiedUtc = SYSUTCDATETIME(),
            ModifiedByAdminId = @AdminId
        WHERE Id = @AbonneId;

        UPDATE dbo.T011AbonneUser SET IsActive = 0, ModifiedUtc = SYSUTCDATETIME()
        WHERE AbonneId = @AbonneId AND IsActive = 1;

        UPDATE dbo.T040ApiKey SET IsActive = 0, RevokedUtc = ISNULL(RevokedUtc, SYSUTCDATETIME())
        WHERE AbonneId = @AbonneId AND IsActive = 1;

        UPDATE dbo.T041WebhookEndpoint SET IsActive = 0, UpdatedUtc = SYSUTCDATETIME()
        WHERE AbonneId = @AbonneId AND IsActive = 1;

        UPDATE dbo.T020Client SET Statut = N'Inactif'
        WHERE AbonneId = @AbonneId AND Statut <> N'Inactif';

        UPDATE dbo.T021Fournisseur SET Statut = N'Inactif'
        WHERE AbonneId = @AbonneId AND Statut <> N'Inactif';
    COMMIT;

    SELECT 1 AS Closed;
END
GO

/* ---------------------------------------------------------------------
   s0089AnonymizeAbonne : minimisation RGPD d'un abonné DÉJÀ clôturé.
   Scrub des données personnelles ; conserve la piste financière.
   IRRÉVERSIBLE.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0089AnonymizeAbonne
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId AND Statut = N'Ferme')
    BEGIN
        RAISERROR(N'Anonymisation impossible : l''abonné doit d''abord être clôturé (Fermé).', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        UPDATE dbo.T010Abonne
        SET RaisonSociale    = N'Abonné clôturé #' + CAST(@AbonneId AS NVARCHAR(10)),
            NomAffichage     = NULL, NumeroEntreprise = NULL, CourrielContact = NULL, Telephone = NULL,
            Adresse1 = NULL, Adresse2 = NULL, Ville = NULL, Province = NULL, CodePostal = NULL, Notes = NULL,
            AnonymizedUtc = SYSUTCDATETIME(), ModifiedUtc = SYSUTCDATETIME()
        WHERE Id = @AbonneId;

        UPDATE dbo.T011AbonneUser
        SET Email = N'anon.u' + CAST(Id AS NVARCHAR(10)) + N'@closed.invalid',
            FirstName = NULL, LastName = NULL, PasswordHash = N'!ANONYMIZED', IsActive = 0,
            ModifiedUtc = SYSUTCDATETIME()
        WHERE AbonneId = @AbonneId;

        UPDATE dbo.T020Client
        SET Nom = N'Client anonymisé #' + CAST(Id AS NVARCHAR(10)),
            ReferenceExterne = NULL, CourrielContact = NULL, Telephone = NULL,
            Adresse1 = NULL, Adresse2 = NULL, Ville = NULL, Province = NULL, CodePostal = NULL, Notes = NULL,
            BankInstitution = NULL, BankTransit = NULL, BankAccount = NULL
        WHERE AbonneId = @AbonneId;

        UPDATE dbo.T021Fournisseur
        SET Nom = N'Fournisseur anonymisé #' + CAST(Id AS NVARCHAR(10)),
            ReferenceExterne = NULL, CourrielContact = NULL, Telephone = NULL,
            Adresse1 = NULL, Adresse2 = NULL, Ville = NULL, Province = NULL, CodePostal = NULL, Notes = NULL,
            BankInstitution = NULL, BankTransit = NULL, BankAccount = NULL
        WHERE AbonneId = @AbonneId;

        UPDATE dbo.T041WebhookEndpoint
        SET Url = N'https://anonymized.invalid', Secret = N'!ANONYMIZED', IsActive = 0, UpdatedUtc = SYSUTCDATETIME()
        WHERE AbonneId = @AbonneId;

        -- Snapshots PII dans les lignes de lot EFT (nom + coordonnées bancaires).
        UPDATE it
        SET it.CounterpartyName = NULL, it.BankInstitution = NULL, it.BankTransit = NULL, it.BankAccount = NULL
        FROM dbo.T051EftBatchItem it
        JOIN dbo.T030Payment p ON p.Id = it.PaymentId
        WHERE p.AbonneId = @AbonneId;
    COMMIT;

    SELECT 1 AS Anonymized;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'35_tenant_offboarding.sql : termine.';
GO
