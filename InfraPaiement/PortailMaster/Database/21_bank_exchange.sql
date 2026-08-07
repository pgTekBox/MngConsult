/* =====================================================================
   PortailMaster - Script 21 : Couche d'echange de fichiers avec la banque
   ---------------------------------------------------------------------
   Journal des echanges (envoi des .005, reception des retours/releves) +
   transitions de lot pour la soumission. Procs s0063+.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T054FileExchangeLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T054FileExchangeLog
    (
        Id         INT           IDENTITY(1,1) NOT NULL,
        Direction  CHAR(3)       NOT NULL,          -- 'Out' / 'In'
        FileName   NVARCHAR(150) NOT NULL,
        FileType   NVARCHAR(20)  NULL,              -- AFT / Return / Statement
        BatchId    INT           NULL,
        Bytes      INT           NULL,
        Status     NVARCHAR(20)  NOT NULL,          -- Sent / Received / Processed / Error
        Message    NVARCHAR(300) NULL,
        Utc        DATETIME2(0)  NOT NULL CONSTRAINT DF_T054_Utc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T054FileExchangeLog PRIMARY KEY CLUSTERED (Id)
    );
    CREATE INDEX IX_T054_Utc ON dbo.T054FileExchangeLog (Id DESC);
END
GO

/* --- s0063MarkBatchSubmitted : lot -> Submitted apres envoi. --- */
CREATE OR ALTER PROCEDURE dbo.s0063MarkBatchSubmitted
    @BatchId INT, @FileName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T050EftBatch
    SET Status = N'Submitted',
        SubmittedUtc = SYSUTCDATETIME(),
        FileName = ISNULL(@FileName, FileName),
        GeneratedUtc = ISNULL(GeneratedUtc, SYSUTCDATETIME())
    WHERE Id = @BatchId AND Status IN (N'Open', N'Generated');
END
GO

/* --- s0064ListBatchesToSend : lots prets a envoyer. --- */
CREATE OR ALTER PROCEDURE dbo.s0064ListBatchesToSend
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, FileCreationNumber, Status, CountDebit, CountCredit, TotalDebitCents, TotalCreditCents
    FROM dbo.T050EftBatch
    WHERE Status IN (N'Open', N'Generated')
    ORDER BY Id;
END
GO

/* --- s0065SaveExchangeLog --- */
CREATE OR ALTER PROCEDURE dbo.s0065SaveExchangeLog
    @Direction CHAR(3), @FileName NVARCHAR(150), @FileType NVARCHAR(20) = NULL,
    @BatchId INT = NULL, @Bytes INT = NULL, @Status NVARCHAR(20), @Message NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T054FileExchangeLog (Direction, FileName, FileType, BatchId, Bytes, Status, Message)
    VALUES (@Direction, @FileName, @FileType, @BatchId, @Bytes, @Status, @Message);
END
GO

/* --- s0066ListExchangeLog --- */
CREATE OR ALTER PROCEDURE dbo.s0066ListExchangeLog
    @Top INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Id, Direction, FileName, FileType, BatchId, Bytes, Status, Message, Utc
    FROM dbo.T054FileExchangeLog ORDER BY Id DESC;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'21_bank_exchange.sql : termine.';
GO
