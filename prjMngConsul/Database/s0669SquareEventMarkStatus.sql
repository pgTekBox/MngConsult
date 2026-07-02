-- =============================================================================
-- s0669SquareEventMarkStatus
-- Met a jour le statut de traitement d'un evenement webhook Square.
-- @Status : 'processed' | 'skipped' | 'failed'
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0669SquareEventMarkStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0669SquareEventMarkStatus;
GO

CREATE PROCEDURE dbo.s0669SquareEventMarkStatus
    @SquareEventId VARCHAR(100),
    @Status        VARCHAR(20),
    @ErrorMessage  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tSquareEvenement
    SET ProcessingStatus = @Status,
        ProcessedOn      = GETDATE(),
        ErrorMessage     = @ErrorMessage
    WHERE SquareEventId = @SquareEventId;
END
GO
