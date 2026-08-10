/* =====================================================================
   PortailMaster - Script 38 : journal d'audit des actions sensibles
   ---------------------------------------------------------------------
   Traçabilité (attendue par un régulateur) : qui a fait QUOI, sur QUEL
   abonné, QUAND. Couvre les actions de gouvernance des données :
   Export / Offboard (clôture) / Reactivate / Anonymize (+ extensible).

   Le journal est APPEND-ONLY : triggers INSTEAD OF UPDATE/DELETE qui
   refusent toute modification (comme le grand livre). Acteur mémorisé par
   Id ET par courriel-snapshot (survit à la suppression de l'admin).
   N'est PAS purgé par la maintenance (rétention longue de conformité).

   T070AuditLog + s0092WriteAuditLog + s0093ListAuditLog. Procs s0092+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.T070AuditLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.T070AuditLog
    (
        Id           BIGINT        IDENTITY(1,1) NOT NULL,
        Utc          DATETIME2(0)  NOT NULL CONSTRAINT DF_T070_Utc DEFAULT (SYSUTCDATETIME()),
        ActorAdminId INT           NULL,            -- pas de FK : le journal survit à la suppression de l'admin
        ActorEmail   NVARCHAR(256) NULL,            -- snapshot du courriel de l'acteur
        Action       NVARCHAR(40)  NOT NULL,        -- Export / Offboard / Reactivate / Anonymize / ...
        TargetType   NVARCHAR(30)  NULL,            -- ex. 'Abonne'
        TargetId     INT           NULL,
        TargetName   NVARCHAR(200) NULL,            -- snapshot du nom de la cible au moment de l'action
        Details      NVARCHAR(500) NULL,
        IpAddress    NVARCHAR(45)  NULL,
        CONSTRAINT PK_T070AuditLog PRIMARY KEY CLUSTERED (Id)
    );
    CREATE INDEX IX_T070_Target ON dbo.T070AuditLog (TargetType, TargetId, Id DESC);
    CREATE INDEX IX_T070_Action ON dbo.T070AuditLog (Action, Id DESC);
END
GO

/* ---- Append-only : refuse UPDATE et DELETE ---- */
IF OBJECT_ID(N'dbo.TR_T070_NoUpdate', N'TR') IS NOT NULL DROP TRIGGER dbo.TR_T070_NoUpdate;
GO
CREATE TRIGGER dbo.TR_T070_NoUpdate ON dbo.T070AuditLog INSTEAD OF UPDATE AS
BEGIN
    RAISERROR(N'Journal d''audit immuable : modification interdite.', 16, 1);
END
GO
IF OBJECT_ID(N'dbo.TR_T070_NoDelete', N'TR') IS NOT NULL DROP TRIGGER dbo.TR_T070_NoDelete;
GO
CREATE TRIGGER dbo.TR_T070_NoDelete ON dbo.T070AuditLog INSTEAD OF DELETE AS
BEGIN
    RAISERROR(N'Journal d''audit immuable : suppression interdite.', 16, 1);
END
GO

/* ---------------------------------------------------------------------
   s0092WriteAuditLog : enregistre une entrée d'audit.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0092WriteAuditLog
    @ActorAdminId INT           = NULL,
    @ActorEmail   NVARCHAR(256) = NULL,
    @Action       NVARCHAR(40),
    @TargetType   NVARCHAR(30)  = NULL,
    @TargetId     INT           = NULL,
    @TargetName   NVARCHAR(200) = NULL,
    @Details      NVARCHAR(500) = NULL,
    @IpAddress    NVARCHAR(45)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T070AuditLog (ActorAdminId, ActorEmail, Action, TargetType, TargetId, TargetName, Details, IpAddress)
    VALUES (@ActorAdminId, @ActorEmail, @Action, @TargetType, @TargetId, @TargetName, @Details, @IpAddress);
END
GO

/* ---------------------------------------------------------------------
   s0093ListAuditLog : liste filtrable (page globale ou vue par-abonné).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0093ListAuditLog
    @TargetType NVARCHAR(30)  = NULL,
    @TargetId   INT           = NULL,
    @Action     NVARCHAR(40)  = NULL,
    @Search     NVARCHAR(200) = NULL,
    @Top        INT           = 200
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        Id, Utc, ActorAdminId, ActorEmail, Action, TargetType, TargetId, TargetName, Details, IpAddress
    FROM dbo.T070AuditLog
    WHERE (@TargetType IS NULL OR @TargetType = N'' OR TargetType = @TargetType)
      AND (@TargetId   IS NULL OR TargetId = @TargetId)
      AND (@Action     IS NULL OR @Action = N''     OR Action = @Action)
      AND (@Search     IS NULL OR @Search = N''
           OR ActorEmail LIKE N'%' + @Search + N'%'
           OR TargetName LIKE N'%' + @Search + N'%'
           OR Details    LIKE N'%' + @Search + N'%')
    ORDER BY Id DESC;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'38_audit_log.sql : termine.';
GO
