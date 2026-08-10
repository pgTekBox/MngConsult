/* =====================================================================
   PortailMaster - Script 39 : accusé de réception bancaire (rail EFT réel)
   ---------------------------------------------------------------------
   Étape vers le rail réel : après soumission d'un lot .005, la banque parrain
   renvoie un ACCUSÉ DE RÉCEPTION qui (a) confirme l'acceptation du fichier et
   (b) liste les items REJETÉS À L'INTAKE (coordonnées invalides) — distincts
   des retours NSF qui arrivent plus tard (E/F). Le cycle de vie du lot devient
   ainsi piloté par la banque plutôt qu'optimiste.

   États du lot enrichis : Open/Generated/Submitted -> **Acknowledged** (fichier
   accepté) ou **Rejected** (fichier refusé). Les items rejetés sont contre-
   passés via s0049ProcessReturn (réutilisé), journalisés dans T053EftReturn.

   ⚠️ Le format d'accusé est PROPRIÉTAIRE selon la banque : le format
   pipe-délimité (A|fcn|statut / R|P<id>|motif) est un GABARIT à mapper.

   T055EftAck + s0094GetBatchByFcn / s0095AckEftBatch / s0096ListEftAck.
   A executer APRES 16/17/21. Procs numerotees s0094+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T055EftAck', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T055EftAck
    (
        Id                 INT           IDENTITY(1,1) NOT NULL,
        BatchId            INT           NULL,
        FileCreationNumber INT           NULL,
        FileStatus         NVARCHAR(20)  NOT NULL,     -- Accepted / Rejected / Unmatched
        RejectedCount      INT           NOT NULL CONSTRAINT DF_T055_Rej DEFAULT (0),
        Message            NVARCHAR(300) NULL,
        FileName           NVARCHAR(150) NULL,
        Utc                DATETIME2(0)  NOT NULL CONSTRAINT DF_T055_Utc DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_T055EftAck PRIMARY KEY CLUSTERED (Id)
    );
    CREATE INDEX IX_T055_Batch ON dbo.T055EftAck (BatchId, Id DESC);
END
GO

/* ---------------------------------------------------------------------
   s0094GetBatchByFcn : retrouve un lot par son n° de création de fichier
   (le lien entre l'accusé bancaire et notre lot).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0094GetBatchByFcn
    @Fcn INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 Id, FileCreationNumber, Status
    FROM dbo.T050EftBatch WHERE FileCreationNumber = @Fcn ORDER BY Id DESC;
END
GO

/* ---------------------------------------------------------------------
   s0095AckEftBatch : journalise un accusé + met à jour le statut du lot.
   Fichier accepté -> Acknowledged ; refusé -> Rejected (uniquement depuis
   un état non terminal ; ne dégrade jamais un lot déjà Settled).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0095AckEftBatch
    @BatchId            INT           = NULL,
    @FileCreationNumber INT           = NULL,
    @FileStatus         NVARCHAR(20),
    @RejectedCount      INT           = 0,
    @Message            NVARCHAR(300) = NULL,
    @FileName           NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.T055EftAck (BatchId, FileCreationNumber, FileStatus, RejectedCount, Message, FileName)
    VALUES (@BatchId, @FileCreationNumber, @FileStatus, ISNULL(@RejectedCount, 0), @Message, @FileName);

    IF @BatchId IS NOT NULL AND @FileStatus IN (N'Accepted', N'Rejected')
    BEGIN
        UPDATE dbo.T050EftBatch
        SET Status = CASE WHEN @FileStatus = N'Rejected' THEN N'Rejected' ELSE N'Acknowledged' END
        WHERE Id = @BatchId AND Status IN (N'Open', N'Generated', N'Submitted');
    END
END
GO

/* ---------------------------------------------------------------------
   s0096ListEftAck : suivi (UI).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0096ListEftAck
    @Top INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        a.Id, a.BatchId, a.FileCreationNumber, a.FileStatus, a.RejectedCount,
        a.Message, a.FileName, a.Utc
    FROM dbo.T055EftAck a
    ORDER BY a.Id DESC;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'39_eft_ack.sql : termine.';
GO
