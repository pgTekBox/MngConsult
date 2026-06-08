-- =============================================================================
-- T144AuthorizationAutoPay
-- Conservation des autorisations de paiement automatique fournisseur via Stripe.
-- Une ligne = une autorisation active (PaymentMethod sauvegardee) pour
-- un couple (CompanyGUID, PartyId fournisseur, UserGUID payeur).
--
-- Audit trail legal complet : texte presente lors du consentement, IP,
-- date, utilisateur. Permet la traceabilite en cas de litige.
--
-- L'autorisation est specifique au compte Connect Stripe du fournisseur
-- (Direct Charge mode) : le PaymentMethod n'est utilisable QUE pour
-- ce fournisseur, pas pour les autres.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.T144AuthorizationAutoPay', 'U') IS NOT NULL
BEGIN
    PRINT 'Table T144AuthorizationAutoPay existe deja, skip.';
END
ELSE
BEGIN
    CREATE TABLE dbo.T144AuthorizationAutoPay (
        Id                          INT IDENTITY(1,1) NOT NULL,
        AuthorizationGUID           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        CompanyGUID                 UNIQUEIDENTIFIER NOT NULL,
        PartyId                     INT NOT NULL,
        PartyGUID                   UNIQUEIDENTIFIER NOT NULL,

        -- Identifiants Stripe (compte connecte fournisseur)
        StripeAccountId             VARCHAR(50)  NOT NULL,
        StripeCustomerId            VARCHAR(100) NOT NULL,
        StripePaymentMethodId       VARCHAR(100) NOT NULL,

        -- Type et identification du moyen de paiement (affichage UI)
        PaymentMethodType           VARCHAR(20)  NOT NULL,
        CardBrand                   VARCHAR(20)  NULL,
        CardLast4                   VARCHAR(4)   NULL,
        CardExpMonth                INT          NULL,
        CardExpYear                 INT          NULL,
        BankInstitutionNumber       VARCHAR(10)  NULL,
        BankTransitNumber           VARCHAR(10)  NULL,
        BankAccountLast4            VARCHAR(4)   NULL,

        -- Mandat PAD (si acss_debit)
        StripeMandateId             VARCHAR(100) NULL,
        PadAgreementUrl             VARCHAR(500) NULL,

        -- Plafonds de securite
        MaxAmountPerCharge          DECIMAL(15,2) NULL,
        MaxAmountPerMonth           DECIMAL(15,2) NULL,

        -- Audit trail legal
        AuthorizedDate              DATETIME      NOT NULL DEFAULT GETDATE(),
        AuthorizedByUserGUID        UNIQUEIDENTIFIER NOT NULL,
        AuthorizedIpAddress         VARCHAR(45)   NULL,
        AuthorizedUserAgent         VARCHAR(500)  NULL,
        AuthorizationText           NVARCHAR(MAX) NOT NULL,
        AuthorizationLanguage       VARCHAR(5)    NOT NULL DEFAULT 'fr-CA',

        -- Cycle de vie
        RevokedDate                 DATETIME      NULL,
        RevokedByUserGUID           UNIQUEIDENTIFIER NULL,
        RevokedReason               NVARCHAR(500) NULL,

        Created                     DATETIME      NOT NULL DEFAULT GETDATE(),

        CONSTRAINT PK_T144AuthorizationAutoPay PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_T144_GUID UNIQUE (AuthorizationGUID),
        CONSTRAINT chk_T144_PaymentMethodType CHECK (PaymentMethodType IN ('card','acss_debit')),
        CONSTRAINT chk_T144_PartyId CHECK (PartyId > 0)
    );

    -- Une seule autorisation active par couple (Company, Party, User, MethodType)
    CREATE UNIQUE NONCLUSTERED INDEX UX_T144_ActiveByPartyUser
        ON dbo.T144AuthorizationAutoPay (CompanyGUID, PartyId, AuthorizedByUserGUID, PaymentMethodType)
        WHERE RevokedDate IS NULL;

    -- Index pour lookup rapide depuis le scheduler
    CREATE NONCLUSTERED INDEX IX_T144_Active
        ON dbo.T144AuthorizationAutoPay (CompanyGUID, PartyId)
        INCLUDE (StripeAccountId, StripeCustomerId, StripePaymentMethodId, PaymentMethodType, MaxAmountPerCharge, MaxAmountPerMonth)
        WHERE RevokedDate IS NULL;

    -- Index pour idempotence sur PaymentMethodId Stripe
    CREATE NONCLUSTERED INDEX IX_T144_StripePaymentMethodId
        ON dbo.T144AuthorizationAutoPay (StripePaymentMethodId);

    PRINT 'Table T144AuthorizationAutoPay creee avec succes.';
END
GO
