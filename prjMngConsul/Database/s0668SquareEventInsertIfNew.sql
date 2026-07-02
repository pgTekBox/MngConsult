-- =============================================================================
-- s0668SquareEventInsertIfNew
-- Insere un evenement webhook Square s'il n'existe pas deja (idempotence).
-- Retourne WasInserted = 1 si nouvel evenement, 0 si deja recu.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0668SquareEventInsertIfNew', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0668SquareEventInsertIfNew;
GO

CREATE PROCEDURE dbo.s0668SquareEventInsertIfNew
    @SquareEventId   VARCHAR(100),
    @EventType       VARCHAR(100),
    @MerchantId      VARCHAR(100) = NULL,
    @SquareCreatedAt DATETIME     = NULL,
    @Payload         NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.tSquareEvenement WHERE SquareEventId = @SquareEventId)
    BEGIN
        SELECT CAST(0 AS BIT) AS WasInserted;
        RETURN;
    END

    INSERT INTO dbo.tSquareEvenement (SquareEventId, EventType, MerchantId, SquareCreatedAt, Payload, ProcessingStatus)
    VALUES (@SquareEventId, @EventType, @MerchantId, @SquareCreatedAt, @Payload, 'received');

    SELECT CAST(1 AS BIT) AS WasInserted;
END
GO
