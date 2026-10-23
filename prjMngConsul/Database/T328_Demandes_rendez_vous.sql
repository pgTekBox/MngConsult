-- =============================================================================
-- T328 — Demandes de rendez-vous des clients
--
-- Un client demande un nouveau RDV, la modification (déplacement) d'un RDV ou son
-- annulation, par texto, courriel, téléphone ou le web. La demande attend la
-- décision de l'entreprise : acceptée (le RDV est créé, déplacé ou annulé) ou
-- refusée. Affichées dans la fenêtre de 60 (« RDV demandé ») et dans l'Agenda.
--
--   T328RdvDemande               la demande
--   s0910GetRdvDemandes          les demandes en attente d'une compagnie
--   s0911TraiterRdvDemande       accepter ou refuser une demande
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T328RdvDemande', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T328RdvDemande (
        Id             INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T328RdvDemande PRIMARY KEY,
        CompanyGUID    UNIQUEIDENTIFIER NOT NULL,
        TypeDemande    NVARCHAR(20)     NOT NULL,          -- Nouveau, Modification, Annulation
        AppointmentId  INT              NULL,              -- le RDV visé (Modification, Annulation)
        CustomerId     INT              NULL,              -- le client, s'il est connu
        NomClient      NVARCHAR(150)    NULL,              -- le nom donné par le client, sinon
        Canal          NVARCHAR(20)     NOT NULL CONSTRAINT DF_T328_Canal DEFAULT (N'Courriel'),
        Message        NVARCHAR(1000)   NULL,              -- les mots du client
        DebutSouhaite  DATETIME         NULL,              -- la plage souhaitée (Nouveau, Modification)
        FinSouhaitee   DATETIME         NULL,
        Statut         NVARCHAR(20)     NOT NULL CONSTRAINT DF_T328_Statut DEFAULT (N'EnAttente'),
        RecueLe        DATETIME         NOT NULL CONSTRAINT DF_T328_RecueLe DEFAULT (GETDATE()),
        TraiteeLe      DATETIME         NULL,
        TraiteePar     NVARCHAR(100)    NULL,
        CONSTRAINT CK_T328_Type   CHECK (TypeDemande IN (N'Nouveau', N'Modification', N'Annulation')),
        CONSTRAINT CK_T328_Canal  CHECK (Canal IN (N'Texto', N'Courriel', N'Telephone', N'Web')),
        CONSTRAINT CK_T328_Statut CHECK (Statut IN (N'EnAttente', N'Acceptee', N'Refusee')),
        CONSTRAINT CK_T328_Rdv    CHECK (TypeDemande = N'Nouveau' OR AppointmentId IS NOT NULL),
        CONSTRAINT FK_T328_Appointment FOREIGN KEY (AppointmentId) REFERENCES dbo.Appointments (Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_T328RdvDemande_Company ON dbo.T328RdvDemande (CompanyGUID, Statut, RecueLe);
END
GO

-- -----------------------------------------------------------------------------
-- Les demandes en attente, les plus anciennes d'abord, avec le RDV visé.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0910GetRdvDemandes
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        d.Id,
        d.TypeDemande,
        d.Canal,
        d.Message,
        d.DebutSouhaite,
        d.FinSouhaitee,
        d.RecueLe,
        DATEDIFF(MINUTE, d.RecueLe, GETDATE())                    AS MinutesDepuis,
        d.CustomerId,
        COALESCE(NULLIF(c.Name, ''), NULLIF(ca.Name, ''), d.NomClient, N'') AS NomClient,
        d.AppointmentId,
        a.Title                                                   AS RdvTitre,
        a.StartDateTime                                           AS RdvDebut,
        a.EndDateTime                                             AS RdvFin,
        a.EmployeeId                                              AS RdvEmployeId,
        ISNULL(e.FirstName + ' ' + e.LastName, '')                AS RdvEmploye
    FROM dbo.T328RdvDemande d
    LEFT JOIN dbo.Appointments  a  ON a.Id = d.AppointmentId AND a.CompanyGUID = d.CompanyGUID
    LEFT JOIN dbo.vwCustomers   c  ON c.Id = d.CustomerId
    LEFT JOIN dbo.vwCustomers   ca ON ca.Id = a.CustomerId
    LEFT JOIN dbo.T300Employees e  ON e.Id = a.EmployeeId
    WHERE d.CompanyGUID = @CompanyGUID
      AND d.Statut = N'EnAttente'
      AND (d.AppointmentId IS NULL OR (a.Id IS NOT NULL AND a.IsDeleted = 0))
    ORDER BY d.RecueLe;
END
GO

-- -----------------------------------------------------------------------------
-- Accepter ou refuser une demande.
--   Acceptee + Nouveau       : crée le RDV (plage @Debut/@Fin, sinon la plage souhaitée)
--   Acceptee + Modification  : déplace le RDV (plage @Debut/@Fin, sinon la plage souhaitée)
--   Acceptee + Annulation    : passe le RDV à « Annulé »
--   Refusee                  : rien ne change dans l'agenda
-- Renvoie Ok (1/0), Msg et AppointmentId.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0911TraiterRdvDemande
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT,
    @Decision    NVARCHAR(20),          -- Acceptee, Refusee
    @Debut       DATETIME      = NULL,
    @Fin         DATETIME      = NULL,
    @UserName    NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Type NVARCHAR(20), @Rdv INT, @Client INT, @Nom NVARCHAR(150), @Msg NVARCHAR(1000),
            @DS DATETIME, @FS DATETIME, @Statut NVARCHAR(20);
    SELECT @Type = TypeDemande, @Rdv = AppointmentId, @Client = CustomerId, @Nom = NomClient, @Msg = Message,
           @DS = DebutSouhaite, @FS = FinSouhaitee, @Statut = Statut
    FROM dbo.T328RdvDemande WHERE Id = @Id AND CompanyGUID = @CompanyGUID;

    IF @Type IS NULL
        BEGIN SELECT CAST(0 AS BIT) AS Ok, N'Demande introuvable.' AS Msg, CAST(NULL AS INT) AS AppointmentId; RETURN; END
    IF @Statut <> N'EnAttente'
        BEGIN SELECT CAST(0 AS BIT) AS Ok, N'Demande déjà traitée.' AS Msg, @Rdv AS AppointmentId; RETURN; END
    IF @Decision NOT IN (N'Acceptee', N'Refusee')
        BEGIN SELECT CAST(0 AS BIT) AS Ok, N'Décision inconnue.' AS Msg, @Rdv AS AppointmentId; RETURN; END

    IF NULLIF(@Nom, N'') IS NULL AND @Client IS NOT NULL
        SELECT @Nom = Name FROM dbo.vwCustomers WHERE Id = @Client;

    SET @Debut = COALESCE(@Debut, @DS);
    SET @Fin   = COALESCE(@Fin, @FS, DATEADD(HOUR, 1, @Debut));

    BEGIN TRANSACTION;

    IF @Decision = N'Acceptee'
    BEGIN
        IF @Type = N'Nouveau'
        BEGIN
            IF @Debut IS NULL OR @Fin <= @Debut
                BEGIN ROLLBACK; SELECT CAST(0 AS BIT) AS Ok, N'Choisissez la plage du rendez-vous.' AS Msg, CAST(NULL AS INT) AS AppointmentId; RETURN; END
            INSERT INTO dbo.Appointments (CompanyGUID, Title, Description, StartDateTime, EndDateTime, CustomerId, Status, CreatedBy)
            VALUES (@CompanyGUID, LEFT(N'RDV demandé' + ISNULL(N' — ' + NULLIF(@Nom, N''), N''), 200), @Msg, @Debut, @Fin, @Client, N'Planifié', @UserName);
            SET @Rdv = SCOPE_IDENTITY();
            UPDATE dbo.T328RdvDemande SET AppointmentId = @Rdv WHERE Id = @Id;
        END
        ELSE IF @Type = N'Modification'
        BEGIN
            IF @Debut IS NULL OR @Fin <= @Debut
                BEGIN ROLLBACK; SELECT CAST(0 AS BIT) AS Ok, N'Choisissez la nouvelle plage.' AS Msg, @Rdv AS AppointmentId; RETURN; END
            UPDATE dbo.Appointments SET StartDateTime = @Debut, EndDateTime = @Fin, ModifiedOn = GETDATE(), ModifiedBy = @UserName
            WHERE Id = @Rdv AND CompanyGUID = @CompanyGUID;
        END
        ELSE -- Annulation
            UPDATE dbo.Appointments SET Status = N'Annulé', ModifiedOn = GETDATE(), ModifiedBy = @UserName
            WHERE Id = @Rdv AND CompanyGUID = @CompanyGUID;
    END

    UPDATE dbo.T328RdvDemande SET Statut = @Decision, TraiteeLe = GETDATE(), TraiteePar = @UserName WHERE Id = @Id;
    COMMIT;

    SELECT CAST(1 AS BIT) AS Ok, N'' AS Msg, @Rdv AS AppointmentId;
END
GO
