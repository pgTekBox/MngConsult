-- =============================================================================
-- T145AutoPayAttempt
-- Log de chaque tentative de prelevement automatique (succes ou echec).
-- Sert d'historique pour la page wbfAutoPayHistory.aspx et au debug.
--
-- Un attempt est cree par le scheduler (AutoPayProcessor.ashx) avant
-- d'appeler Stripe. Mis a jour selon le retour.
--
-- Conserve aussi le PaymentIntent retourne par Stripe pour faciliter
-- les rapprochements avec le webhook.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.T145AutoPayAttempt', 'U') IS NOT NULL
BEGIN
    PRINT 'Table T145AutoPayAttempt existe deja, skip.';
END
ELSE
BEGIN
    CREATE TABLE dbo.T145AutoPayAttempt (
        Id                          INT IDENTITY(1,1) NOT NULL,
        AttemptGUID                 UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        CompanyGUID                 UNIQUEIDENTIFIER NOT NULL,
        DocumentId                  INT NOT NULL,
        AuthorizationId             INT NOT NULL,
        PartyId                     INT NOT NULL,

        AttemptDate                 DATETIME      NOT NULL DEFAULT GETDATE(),
        AttemptNumber               INT           NOT NULL DEFAULT 1,
        Amount                      DECIMAL(15,2) NOT NULL,
        AmountGross                 DECIMAL(15,2) NOT NULL,
        FeeAmount                   DECIMAL(15,2) NOT NULL,
        Currency                    VARCHAR(3)    NOT NULL DEFAULT 'cad',
        PaymentMethodType           VARCHAR(20)   NOT NULL,

        -- Resultat
        Result                      VARCHAR(30)   NOT NULL DEFAULT 'PENDING',
        StripePaymentIntentId       VARCHAR(100)  NULL,
        StripeChargeId              VARCHAR(100)  NULL,

        FailureCode                 VARCHAR(50)   NULL,
        FailureMessage              NVARCHAR(MAX) NULL,
        Requires3DSUrl              VARCHAR(500)  NULL,

        ProcessedDate               DATETIME      NULL,
        ReglementId                 INT           NULL,

        Created                     DATETIME      NOT NULL DEFAULT GETDATE(),

        CONSTRAINT PK_T145AutoPayAttempt PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_T145_GUID UNIQUE (AttemptGUID),
        CONSTRAINT chk_T145_Result CHECK (Result IN
            ('PENDING','SUCCESS','FAILED','REQUIRES_ACTION','BLOCKED_CAP','CANCELLED')),
        CONSTRAINT chk_T145_PaymentMethodType CHECK (PaymentMethodType IN ('card','acss_debit')),
        CONSTRAINT FK_T145_T144 FOREIGN KEY (AuthorizationId)
            REFERENCES dbo.T144AuthorizationAutoPay (Id)
    );

    -- Index principal pour scheduler et historique
    CREATE NONCLUSTERED INDEX IX_T145_Document
        ON dbo.T145AutoPayAttempt (DocumentId, AttemptDate DESC);

    -- Index pour rapprochement webhook
    CREATE NONCLUSTERED INDEX IX_T145_PaymentIntent
        ON dbo.T145AutoPayAttempt (StripePaymentIntentId)
        WHERE StripePaymentIntentId IS NOT NULL;

    -- Index pour calcul plafond mensuel par fournisseur
    CREATE NONCLUSTERED INDEX IX_T145_MonthlyCap
        ON dbo.T145AutoPayAttempt (CompanyGUID, PartyId, AttemptDate)
        INCLUDE (Amount, Result)
        WHERE Result = 'SUCCESS';

    PRINT 'Table T145AutoPayAttempt creee avec succes.';
END
GO
