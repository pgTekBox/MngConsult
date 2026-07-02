-- =============================================================================
-- tSquareEvenement
-- Journal des webhooks Square (idempotence + audit), calque sur tStripeEvenement.
-- UNIQUE sur SquareEventId : un meme evenement renvoye par Square n'est traite
-- qu'une fois.
-- Idempotent : peut etre re-execute.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.tSquareEvenement', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tSquareEvenement
    (
        Id               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tSquareEvenement PRIMARY KEY,
        SquareEventId    VARCHAR(100)      NOT NULL,
        EventType        VARCHAR(100)      NULL,
        MerchantId       VARCHAR(100)      NULL,
        SquareCreatedAt  DATETIME          NULL,
        Payload          NVARCHAR(MAX)     NULL,
        ProcessingStatus VARCHAR(20)       NOT NULL CONSTRAINT DF_tSquareEvenement_Status DEFAULT ('received'),
        ReceivedOn       DATETIME          NOT NULL CONSTRAINT DF_tSquareEvenement_Received DEFAULT (GETDATE()),
        ProcessedOn      DATETIME          NULL,
        ErrorMessage     NVARCHAR(MAX)     NULL,
        CONSTRAINT UQ_tSquareEvenement_EventId UNIQUE (SquareEventId)
    );
    PRINT 'Table tSquareEvenement creee.';
END
ELSE
    PRINT 'Table tSquareEvenement existe deja.';
GO
