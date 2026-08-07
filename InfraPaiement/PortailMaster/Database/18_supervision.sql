/* =====================================================================
   PortailMaster - Script 18 : Tableau de bord de supervision
   ---------------------------------------------------------------------
   Agrégats opérationnels pour le staff : volumes, statuts, trésorerie,
   retours, KYB, lots EFT + listes « à surveiller ». Procs s0053+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* --- s0053GetSupervisionKpis : une ligne d'indicateurs. --- */
CREATE OR ALTER PROCEDURE dbo.s0053GetSupervisionKpis
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);
    SELECT
        (SELECT COUNT(*) FROM dbo.T030Payment) AS NbPayments,
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE Direction=N'Entrant') AS NbEntrant,
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE Direction=N'Sortant') AS NbSortant,
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE Status=N'Initie') AS NbInitie,
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE Status=N'Regle') AS NbRegle,
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE Status=N'Retourne') AS NbRetourne,
        (SELECT ISNULL(SUM(AmountCents),0) FROM dbo.T030Payment WHERE Direction=N'Entrant' AND Status=N'Regle') AS VolEntrantCents,
        (SELECT ISNULL(SUM(AmountCents),0) FROM dbo.T030Payment WHERE Direction=N'Sortant' AND Status=N'Regle') AS VolSortantCents,
        (SELECT ISNULL(SUM(pp.CreditCents - pp.DebitCents),0) FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id=pp.AccountId WHERE a.AbonneId IS NULL AND a.AccountCode='FEES') AS FeesCents,
        (SELECT ISNULL(SUM(pp.DebitCents - pp.CreditCents),0) FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id=pp.AccountId WHERE a.AbonneId IS NULL AND a.AccountCode='TRUST') AS TrustCents,
        (SELECT ISNULL(SUM(pp.CreditCents - pp.DebitCents),0) FROM dbo.T102LedgerPosting pp JOIN dbo.T100LedgerAccount a ON a.Id=pp.AccountId WHERE a.AccountCode IN ('SUBBAL','RESERVE')) AS OwedCents,
        (SELECT COUNT(*) FROM dbo.T053EftReturn WHERE Status=N'Processed') AS NbReturns,
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE Status=N'Initie' AND ExpectedSettlementDate <= @today) AS NbOverdue,
        (SELECT ISNULL(SUM(AmountCents),0) FROM dbo.T030Payment WHERE Status=N'Initie' AND ExpectedSettlementDate <= @today) AS OverdueCents,
        (SELECT COUNT(*) FROM dbo.T042WebhookDelivery WHERE Status=N'Pending') AS NbWhPending,
        (SELECT COUNT(*) FROM dbo.T042WebhookDelivery WHERE Status=N'Abandoned') AS NbWhAbandoned,
        (SELECT COUNT(*) FROM dbo.T050EftBatch WHERE Status IN (N'Open',N'Generated',N'Submitted')) AS NbBatchesOuverts,
        (SELECT COUNT(*) FROM dbo.T010Abonne) AS NbAbonnes,
        (SELECT COUNT(*) FROM dbo.T010Abonne WHERE Statut=N'Actif') AS NbAbonnesActif,
        (SELECT COUNT(*) FROM dbo.T010Abonne WHERE StatutKYB IN (N'NonDebute',N'EnCours')) AS NbKyb;
END
GO

/* --- s0054ListOverduePayments : transactions initiées échues. --- */
CREATE OR ALTER PROCEDURE dbo.s0054ListOverduePayments
    @Top INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);
    SELECT TOP (@Top)
        p.Id, p.AbonneId, ab.RaisonSociale AS Abonne, p.Direction, p.AmountCents,
        p.Status, p.Reference, p.ExpectedSettlementDate, p.InitiatedUtc,
        DATEDIFF(DAY, p.ExpectedSettlementDate, @today) AS JoursRetard
    FROM dbo.T030Payment p
    JOIN dbo.T010Abonne ab ON ab.Id = p.AbonneId
    WHERE p.Status=N'Initie' AND p.ExpectedSettlementDate <= @today
    ORDER BY p.ExpectedSettlementDate ASC, p.Id;
END
GO

/* --- s0055ListWebhookIssues : livraisons en échec / abandonnées. --- */
CREATE OR ALTER PROCEDURE dbo.s0055ListWebhookIssues
    @Top INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        d.Id, d.AbonneId, ab.RaisonSociale AS Abonne, d.EventType, d.PaymentId,
        d.Status, d.Attempts, d.MaxAttempts, d.ResponseStatus, d.LastError,
        d.NextAttemptUtc, d.CreatedUtc
    FROM dbo.T042WebhookDelivery d
    JOIN dbo.T010Abonne ab ON ab.Id = d.AbonneId
    WHERE d.Status = N'Abandoned'
       OR (d.Status = N'Pending' AND d.Attempts >= 1)
    ORDER BY d.Id DESC;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'18_supervision.sql : termine.';
GO
