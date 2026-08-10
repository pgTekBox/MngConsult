/* =====================================================================
   PortailMaster - Script 37 : export des données d'un abonné (RGPD art. 20)
   ---------------------------------------------------------------------
   Portabilité : rassemble en UNE proc (plusieurs jeux de résultats) toutes
   les données d'un abonné, à sérialiser en JSON par le handler
   AbonneExport.ashx. Utile à fournir à l'abonné, notamment AVANT une clôture.

   ⚠️ Aucun SECRET n'est exporté : ni hash de mot de passe (T011), ni hash de
   clé d'API (T040), ni secret de webhook (T041). Seules les métadonnées.

   Jeux de résultats (dans l'ordre) :
     0 Abonné · 1 Utilisateurs · 2 Clients · 3 Fournisseurs · 4 Paiements
     5 Journal (grand livre de l'abonné) · 6 Clés d'API (méta) · 7 Webhook
     8 Retours EFT

   s0091ExportAbonneData. A executer APRES 35. Procs numerotees s0091+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0091ExportAbonneData
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 0) Abonné
    SELECT Id, TenantGUID, RaisonSociale, NomAffichage, NumeroEntreprise,
           CourrielContact, Telephone, Adresse1, Adresse2, Ville, Province, CodePostal, Pays,
           Devise, Statut, StatutKYB, CreatedUtc, ClosedUtc, AnonymizedUtc
    FROM   dbo.T010Abonne WHERE Id = @AbonneId;

    -- 1) Utilisateurs (SANS hash de mot de passe)
    SELECT Id, Email, FirstName, LastName, IsAdmin, IsActive, LastLoginUtc, CreatedUtc
    FROM   dbo.T011AbonneUser WHERE AbonneId = @AbonneId ORDER BY Id;

    -- 2) Clients
    SELECT Id, ClientGUID, TypeClient, Nom, ReferenceExterne, CourrielContact, Telephone,
           Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut,
           BankInstitution, BankTransit, BankAccount, Notes, CreatedUtc
    FROM   dbo.T020Client WHERE AbonneId = @AbonneId ORDER BY Id;

    -- 3) Fournisseurs
    SELECT Id, FournisseurGUID, TypeFournisseur, Nom, ReferenceExterne, CourrielContact, Telephone,
           Adresse1, Adresse2, Ville, Province, CodePostal, Pays, Statut,
           BankInstitution, BankTransit, BankAccount, Notes, CreatedUtc
    FROM   dbo.T021Fournisseur WHERE AbonneId = @AbonneId ORDER BY Id;

    -- 4) Paiements (encaissements + décaissements)
    SELECT p.Id, p.PaymentGUID, p.Direction, p.Method, p.AmountCents, p.FeeCents, p.NetCents,
           p.Devise, p.Status, p.Description, p.Reference, p.ExpectedSettlementDate,
           p.InitiatedUtc, p.SettledUtc, p.ReturnedUtc, p.ReturnReason,
           p.ClientId, c.Nom AS ClientNom, p.FournisseurId, f.Nom AS FournisseurNom
    FROM   dbo.T030Payment p
    LEFT JOIN dbo.T020Client c      ON c.Id = p.ClientId
    LEFT JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE  p.AbonneId = @AbonneId ORDER BY p.Id;

    -- 5) Journal (grand livre de l'abonné) : Δ solde / Δ réserve par transaction
    SELECT t.Id, t.EffectiveDate, t.TxnType, t.Description, t.CreatedUtc,
           ISNULL((SELECT SUM(pp.CreditCents - pp.DebitCents)
                   FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id = pp.AccountId
                   WHERE pp.TransactionId = t.Id AND a.AbonneId = @AbonneId AND a.AccountCode = 'SUBBAL'), 0) AS DeltaSoldeCents,
           ISNULL((SELECT SUM(pp.CreditCents - pp.DebitCents)
                   FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id = pp.AccountId
                   WHERE pp.TransactionId = t.Id AND a.AbonneId = @AbonneId AND a.AccountCode = 'RESERVE'), 0) AS DeltaReserveCents
    FROM   dbo.T101LedgerTransaction t WHERE t.AbonneId = @AbonneId ORDER BY t.Id;

    -- 6) Clés d'API (méta seulement : ni KeyHash)
    SELECT Id, Prefix, Label, Environment, IsActive, CreatedUtc, LastUsedUtc, RevokedUtc
    FROM   dbo.T040ApiKey WHERE AbonneId = @AbonneId ORDER BY Id;

    -- 7) Webhook (méta : URL + état ; PAS le secret)
    SELECT Id, Url, IsActive, CreatedUtc, UpdatedUtc
    FROM   dbo.T041WebhookEndpoint WHERE AbonneId = @AbonneId;

    -- 8) Retours EFT concernant les paiements de l'abonné
    SELECT r.Id, r.PaymentId, r.RecordType, r.AmountCents, r.ReasonCode, r.Status, r.Message, r.ImportedUtc
    FROM   dbo.T053EftReturn r
    WHERE  r.PaymentId IN (SELECT Id FROM dbo.T030Payment WHERE AbonneId = @AbonneId)
    ORDER BY r.Id;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'37_abonne_export.sql : termine.';
GO
