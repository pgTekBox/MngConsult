/* =====================================================================
   PortailMaster / webAPI - Script 10 : Webhooks de statut de paiement
   ---------------------------------------------------------------------
   Notifie l'application de l'abonne des transitions de paiement
   (payment.initiated / payment.settled / payment.returned) par un POST
   HTTP signe (HMAC-SHA256) vers une URL configuree.

   - T041WebhookEndpoint : 1 endpoint (URL + secret) par abonne.
   - T042WebhookDelivery : file de livraisons (statut, tentatives, backoff).
   - Un TRIGGER sur T030Payment met en file une livraison a chaque
     transition (aucune modif des procs de paiement).
   - L'envoi reel est fait par le dispatcher applicatif (clsWebhookDispatcher
     / WebhookDispatcher.ashx) qui lit les livraisons dues, signe et POST.

   A executer APRES 01-09. Procs s0030+.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---- Endpoint par abonne ---- */
IF OBJECT_ID(N'dbo.T041WebhookEndpoint', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T041WebhookEndpoint
    (
        Id         INT           IDENTITY(1,1) NOT NULL,
        AbonneId   INT           NOT NULL,
        Url        NVARCHAR(500) NOT NULL,
        Secret     NVARCHAR(100) NOT NULL,        -- pour la signature HMAC
        IsActive   BIT           NOT NULL CONSTRAINT DF_T041_Active DEFAULT (1),
        CreatedUtc DATETIME2(0)  NOT NULL CONSTRAINT DF_T041_Created DEFAULT (SYSUTCDATETIME()),
        UpdatedUtc DATETIME2(0)  NULL,
        CONSTRAINT PK_T041WebhookEndpoint PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UX_T041_Abonne UNIQUE (AbonneId),
        CONSTRAINT FK_T041_Abonne FOREIGN KEY (AbonneId) REFERENCES dbo.T010Abonne(Id)
    );
END
GO

/* ---- File de livraisons ---- */
IF OBJECT_ID(N'dbo.T042WebhookDelivery', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T042WebhookDelivery
    (
        Id             BIGINT        IDENTITY(1,1) NOT NULL,
        AbonneId       INT           NOT NULL,
        EndpointId     INT           NOT NULL,
        EventType      NVARCHAR(40)  NOT NULL,       -- payment.initiated / payment.settled / payment.returned
        PaymentId      BIGINT        NULL,
        Status         NVARCHAR(20)  NOT NULL CONSTRAINT DF_T042_Status DEFAULT (N'Pending'), -- Pending/Delivered/Failed/Abandoned
        Attempts       INT           NOT NULL CONSTRAINT DF_T042_Attempts DEFAULT (0),
        MaxAttempts    INT           NOT NULL CONSTRAINT DF_T042_Max DEFAULT (5),
        NextAttemptUtc DATETIME2(0)  NOT NULL CONSTRAINT DF_T042_Next DEFAULT (SYSUTCDATETIME()),
        ResponseStatus INT           NULL,
        LastError      NVARCHAR(500) NULL,
        CreatedUtc     DATETIME2(0)  NOT NULL CONSTRAINT DF_T042_Created DEFAULT (SYSUTCDATETIME()),
        DeliveredUtc   DATETIME2(0)  NULL,
        CONSTRAINT PK_T042WebhookDelivery PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_T042_Abonne   FOREIGN KEY (AbonneId)   REFERENCES dbo.T010Abonne(Id),
        CONSTRAINT FK_T042_Endpoint FOREIGN KEY (EndpointId) REFERENCES dbo.T041WebhookEndpoint(Id),
        CONSTRAINT FK_T042_Payment  FOREIGN KEY (PaymentId)  REFERENCES dbo.T030Payment(Id)
    );
    CREATE INDEX IX_T042_Due ON dbo.T042WebhookDelivery (Status, NextAttemptUtc);
    CREATE INDEX IX_T042_Abonne ON dbo.T042WebhookDelivery (AbonneId, Id);
END
GO

/* ---- Trigger : met en file une livraison a chaque transition de paiement.
        INSERT  -> payment.initiated
        UPDATE (Status change) -> payment.settled / payment.returned
        Uniquement si l'abonne a un endpoint ACTIF.                        ---- */
IF OBJECT_ID(N'dbo.TR_T030_Webhook', N'TR') IS NOT NULL DROP TRIGGER dbo.TR_T030_Webhook;
GO
CREATE TRIGGER dbo.TR_T030_Webhook ON dbo.T030Payment
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Initiation (lignes nouvellement inserees)
    INSERT INTO dbo.T042WebhookDelivery (AbonneId, EndpointId, EventType, PaymentId)
    SELECT i.AbonneId, e.Id, N'payment.initiated', i.Id
    FROM inserted i
    JOIN dbo.T041WebhookEndpoint e ON e.AbonneId = i.AbonneId AND e.IsActive = 1
    WHERE NOT EXISTS (SELECT 1 FROM deleted);

    -- Transitions (mise a jour du statut)
    INSERT INTO dbo.T042WebhookDelivery (AbonneId, EndpointId, EventType, PaymentId)
    SELECT i.AbonneId, e.Id,
           CASE i.Status WHEN N'Regle' THEN N'payment.settled'
                         WHEN N'Retourne' THEN N'payment.returned' END,
           i.Id
    FROM inserted i
    JOIN deleted d ON d.Id = i.Id
    JOIN dbo.T041WebhookEndpoint e ON e.AbonneId = i.AbonneId AND e.IsActive = 1
    WHERE i.Status <> d.Status AND i.Status IN (N'Regle', N'Retourne');
END
GO

/* =====================================================================
   PROCEDURES
   ===================================================================== */

/* --- s0030SaveWebhookEndpoint : upsert de l'endpoint d'un abonne. --- */
CREATE OR ALTER PROCEDURE dbo.s0030SaveWebhookEndpoint
    @AbonneId INT,
    @Url      NVARCHAR(500),
    @Secret   NVARCHAR(100),
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.T041WebhookEndpoint WHERE AbonneId = @AbonneId)
        UPDATE dbo.T041WebhookEndpoint
        SET Url = @Url, Secret = @Secret, IsActive = @IsActive, UpdatedUtc = SYSUTCDATETIME()
        WHERE AbonneId = @AbonneId;
    ELSE
        INSERT INTO dbo.T041WebhookEndpoint (AbonneId, Url, Secret, IsActive)
        VALUES (@AbonneId, @Url, @Secret, @IsActive);
END
GO

/* --- s0031GetWebhookEndpoint --- */
CREATE OR ALTER PROCEDURE dbo.s0031GetWebhookEndpoint
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, AbonneId, Url, Secret, IsActive, CreatedUtc, UpdatedUtc
    FROM dbo.T041WebhookEndpoint WHERE AbonneId = @AbonneId;
END
GO

/* --- s0032GetDueDeliveries : livraisons a envoyer (Pending, echues).
       Renvoie l'URL + le secret de l'endpoint pour la signature.        --- */
CREATE OR ALTER PROCEDURE dbo.s0032GetDueDeliveries
    @Max INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Max)
        d.Id, d.AbonneId, d.EventType, d.PaymentId, d.Attempts, d.MaxAttempts,
        e.Url, e.Secret
    FROM dbo.T042WebhookDelivery d
    JOIN dbo.T041WebhookEndpoint e ON e.Id = d.EndpointId AND e.IsActive = 1
    WHERE d.Status = N'Pending' AND d.NextAttemptUtc <= SYSUTCDATETIME()
    ORDER BY d.Id;
END
GO

/* --- s0033MarkDeliveryResult : succes -> Delivered ; echec -> relance
       (backoff exponentiel en minutes) ou Abandoned au-dela de MaxAttempts. --- */
CREATE OR ALTER PROCEDURE dbo.s0033MarkDeliveryResult
    @Id             BIGINT,
    @Success        BIT,
    @ResponseStatus INT           = NULL,
    @Error          NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Success = 1
    BEGIN
        UPDATE dbo.T042WebhookDelivery
        SET Status = N'Delivered', Attempts = Attempts + 1,
            ResponseStatus = @ResponseStatus, LastError = NULL, DeliveredUtc = SYSUTCDATETIME()
        WHERE Id = @Id;
    END
    ELSE
    BEGIN
        UPDATE dbo.T042WebhookDelivery
        SET Attempts = Attempts + 1,
            ResponseStatus = @ResponseStatus,
            LastError = @Error,
            Status = CASE WHEN Attempts + 1 >= MaxAttempts THEN N'Abandoned' ELSE N'Pending' END,
            NextAttemptUtc = DATEADD(MINUTE, POWER(2, CASE WHEN Attempts > 6 THEN 6 ELSE Attempts END), SYSUTCDATETIME())
        WHERE Id = @Id;
    END
END
GO

/* --- s0034ListDeliveries : suivi (UI). --- */
CREATE OR ALTER PROCEDURE dbo.s0034ListDeliveries
    @AbonneId INT,
    @Top      INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        Id, EventType, PaymentId, Status, Attempts, MaxAttempts,
        ResponseStatus, LastError, NextAttemptUtc, CreatedUtc, DeliveredUtc
    FROM dbo.T042WebhookDelivery
    WHERE AbonneId = @AbonneId
    ORDER BY Id DESC;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'10_webhooks.sql : termine.';
GO
