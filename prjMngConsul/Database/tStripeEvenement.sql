-- =============================================================================
-- tStripeEvenement
-- Table d'audit + idempotence pour les webhooks Stripe.
-- Stripe peut envoyer le meme event plusieurs fois (retries reseau, etc.).
-- L'unicite sur StripeEventId garantit qu'on ne traite chaque event qu'une fois.
--
-- Statuts ProcessingStatus :
--   'received'   : recu mais pas encore traite (en cours)
--   'processed'  : traite avec succes
--   'failed'     : echec (sera potentiellement reessaye par Stripe)
--   'skipped'    : type d'event non gere (info seulement)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.tStripeEvenement', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tStripeEvenement (
        Id                  INT IDENTITY(1,1)   NOT NULL PRIMARY KEY,

        -- Identifiants Stripe
        StripeEventId       VARCHAR(50)         NOT NULL,           -- evt_xxx
        EventType           VARCHAR(100)        NOT NULL,           -- 'checkout.session.completed', etc.
        StripeCreated       DATETIME            NULL,               -- event.created (timestamp Stripe)

        -- Traitement
        ProcessingStatus    VARCHAR(20)         NOT NULL DEFAULT 'received',
        ErrorMessage        NVARCHAR(MAX)       NULL,
        Payload             NVARCHAR(MAX)       NULL,               -- JSON brut pour debug

        -- Contexte
        StripeCustomerId    VARCHAR(50)         NULL,               -- cus_xxx (extrait pour requetes rapides)
        StripeSubscriptionId VARCHAR(50)        NULL,               -- sub_xxx
        UserId              INT                 NULL,               -- Resolu si trouvable

        -- Audit
        ReceivedOn          DATETIME            NOT NULL DEFAULT GETDATE(),
        ProcessedOn         DATETIME            NULL,

        CONSTRAINT UQ_tStripeEvenement_EventId UNIQUE (StripeEventId)
    );

    PRINT 'Table dbo.tStripeEvenement creee.';
END
ELSE
BEGIN
    PRINT 'Table dbo.tStripeEvenement existe deja - skip CREATE.';
END
GO

-- Index pour recherche par type d'event (utile pour monitoring/debug)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tStripeEvenement_Type_Received' AND object_id = OBJECT_ID('dbo.tStripeEvenement'))
BEGIN
    CREATE INDEX IX_tStripeEvenement_Type_Received
        ON dbo.tStripeEvenement(EventType, ReceivedOn DESC);
    PRINT 'Index IX_tStripeEvenement_Type_Received cree.';
END
GO

-- Index pour recherche par customer (audit / support)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tStripeEvenement_CustomerId' AND object_id = OBJECT_ID('dbo.tStripeEvenement'))
BEGIN
    CREATE INDEX IX_tStripeEvenement_CustomerId
        ON dbo.tStripeEvenement(StripeCustomerId)
        WHERE StripeCustomerId IS NOT NULL;
    PRINT 'Index IX_tStripeEvenement_CustomerId cree.';
END
GO
