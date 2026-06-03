-- =============================================================================
-- s0640StripeEventInsertIfNew
-- Tente d'inserer un event Stripe. Si le StripeEventId existe deja
-- (idempotence), retourne WasInserted = 0.
--
-- Comportement atomique grace au UNIQUE constraint sur StripeEventId.
-- Si on est le premier processeur, on insere et retourne WasInserted = 1.
--
-- Retourne :
--   WasInserted (BIT) : 1 = nouveau, 0 = deja existant
--   Id (INT)          : Id de la ligne tStripeEvenement (NULL si deja existant)
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0640StripeEventInsertIfNew', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0640StripeEventInsertIfNew;
GO

CREATE PROCEDURE dbo.s0640StripeEventInsertIfNew
    @StripeEventId          VARCHAR(50),
    @EventType              VARCHAR(100),
    @StripeCreated          DATETIME       = NULL,
    @Payload                NVARCHAR(MAX)  = NULL,
    @StripeCustomerId       VARCHAR(50)    = NULL,
    @StripeSubscriptionId   VARCHAR(50)    = NULL,
    @UserId                 INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO dbo.tStripeEvenement (
            StripeEventId, EventType, StripeCreated, Payload,
            StripeCustomerId, StripeSubscriptionId, UserId,
            ProcessingStatus, ReceivedOn
        )
        VALUES (
            @StripeEventId, @EventType, @StripeCreated, @Payload,
            @StripeCustomerId, @StripeSubscriptionId, @UserId,
            'received', GETDATE()
        );

        SELECT CAST(1 AS BIT) AS WasInserted, SCOPE_IDENTITY() AS Id;
    END TRY
    BEGIN CATCH
        -- Violation de la contrainte UNIQUE = event deja existant (normal en cas de retry)
        IF ERROR_NUMBER() = 2627 OR ERROR_NUMBER() = 2601
            SELECT CAST(0 AS BIT) AS WasInserted, CAST(NULL AS INT) AS Id;
        ELSE
            THROW;
    END CATCH
END
GO
