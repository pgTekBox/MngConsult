-- =============================================================================
-- T363_Rappel_facture_activite
--
-- Détail d'une activité « Facture en retard » du tableau de bord (Default.aspx) :
-- client, facture, retard, montant, dernier rappel, et trois boutons
-- (Envoyer un texto, Envoyer un courriel, Paiement déjà reçu).
--
--   1. T206RappelFacture : le journal des rappels envoyés pour une facture
--      (canal TEXTO ou COURRIEL, destinataire, date, usager, courriel MailService).
--   2. s0975InsertRappelFacture : inscrit un rappel (facture bornée à la compagnie).
--   3. s0976GetFactureRappel : la facture à relancer, bornée à la compagnie
--      (numéro, client, courriel, téléphone, solde, échéance, nom de la compagnie).
--   4. s0974GetActivitesAFaire : ajoute PartyId (fenêtre d'encaissement) et le
--      dernier rappel (date + canal) de chaque facture.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) T206RappelFacture
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.T206RappelFacture', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T206RappelFacture (
        [Id]           INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_T206RappelFacture PRIMARY KEY,
        [CompanyGUID]  UNIQUEIDENTIFIER   NOT NULL,
        [DocumentId]   INT                NOT NULL,
        [Canal]        VARCHAR(20)        NOT NULL,   -- TEXTO | COURRIEL
        [Destinataire] VARCHAR(200)       NULL,       -- numéro ou adresse
        [EnvoyeLe]     DATETIME           NOT NULL CONSTRAINT DF_T206_EnvoyeLe DEFAULT (GETDATE()),
        [UserId]       INT                NULL,
        [MailId]       INT                NULL,       -- courriel déposé dans MailService
        CONSTRAINT CK_T206_Canal CHECK ([Canal] IN ('TEXTO', 'COURRIEL'))
    );
    CREATE INDEX IX_T206_Document ON dbo.T206RappelFacture ([DocumentId], [EnvoyeLe] DESC);
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0975InsertRappelFacture
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0975InsertRappelFacture]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @DocumentId   INT,
    @Canal        VARCHAR(20),
    @Destinataire VARCHAR(200) = NULL,
    @UserId       INT = NULL,
    @MailId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T060Document WHERE [Id] = @DocumentId AND [CompanyGUID] = @CompanyGUID)
        THROW 51020, 'Facture introuvable.', 1;

    INSERT INTO dbo.T206RappelFacture ([CompanyGUID], [DocumentId], [Canal], [Destinataire], [UserId], [MailId])
    VALUES (@CompanyGUID, @DocumentId, UPPER(@Canal), LEFT(@Destinataire, 200), @UserId, @MailId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id, GETDATE() AS EnvoyeLe;
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0976GetFactureRappel — la facture à relancer (bornée à la compagnie)
--    Solde = même calcul que vwCustomersInvoices (encaissements non annulés).
--    Téléphone : celui de la facture, sinon le cellulaire puis l'autre numéro du client.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0976GetFactureRappel]
    @CompanyGUID UNIQUEIDENTIFIER,
    @DocumentId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.[Id],
        d.[DocumentNumber],
        COALESCE(NULLIF(LTRIM(RTRIM(d.[Name])), ''), p.[DisplayName], p.[Name], '')       AS Client,
        COALESCE(NULLIF(LTRIM(RTRIM(d.[Email])), ''), adr.[Email], '')                   AS Email,
        COALESCE(NULLIF(LTRIM(RTRIM(d.[Phone])), ''),
                 NULLIF(LTRIM(RTRIM(p.[Mobile])), ''),
                 adr.[Phone],
                 NULLIF(LTRIM(RTRIM(p.[AltPhone])), ''), '')                              AS Telephone,
        CAST(ISNULL(d.[Total], 0) - ISNULL(pay.Recu, 0) AS DECIMAL(15, 2))               AS ResteAPayer,
        d.[DueDate],
        dbo.fCompanyName(d.[CompanyGUID])                                                 AS CompanyName
    FROM dbo.T060Document d
    LEFT JOIN dbo.T050Party p ON p.[PartyGUID] = d.[PartyGUID]
    -- Les coordonnées du client, première adresse qui en porte
    OUTER APPLY (
        SELECT TOP 1 NULLIF(LTRIM(RTRIM(a.[Email])), '') AS Email,
                     NULLIF(LTRIM(RTRIM(a.[Phone])), '') AS Phone
        FROM dbo.T054PartyAddress a
        WHERE a.[PartyId] = p.[Id]
          AND (NULLIF(LTRIM(RTRIM(a.[Email])), '') IS NOT NULL OR NULLIF(LTRIM(RTRIM(a.[Phone])), '') IS NOT NULL)
        ORDER BY a.[Id]
    ) adr
    OUTER APPLY (
        SELECT SUM(rd.[MontantImpute]) AS Recu
        FROM dbo.T141ReglementDocument rd
        INNER JOIN dbo.T140Reglement r ON r.[Id] = rd.[ReglementId]
        WHERE rd.[DocumentId] = d.[Id] AND r.[Statut] <> 'ANNULE'
    ) pay
    WHERE d.[Id] = @DocumentId
      AND d.[CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0974GetActivitesAFaire — + PartyId et dernier rappel
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0974GetActivitesAFaire]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[Id],
        RTRIM(d.[JobCode])   AS JobCode,
        p.[DocumentId],
        doc.[DocumentNumber] AS NumeroSort,
        p.[Beneficiaire]     AS NameSort,
        p.[Montant]          AS ResteAPayer,
        p.[DueDate],
        p.[StatutPaiement],
        p.[Approbation],
        p.[DateExecutionPrevue],
        pa.[Id]              AS PartyId,
        rap.[EnvoyeLe]       AS DernierRappel,
        rap.[Canal]          AS DernierRappelCanal
    FROM dbo.T204JobPlanned p
    INNER JOIN dbo.T200JobDefinition d ON d.[Id] = p.[JobDefinitionId]
    LEFT JOIN dbo.T060Document doc ON doc.[Id] = p.[DocumentId]
    LEFT JOIN dbo.T050Party pa ON pa.[PartyGUID] = doc.[PartyGUID]
    OUTER APPLY (
        SELECT TOP 1 r.[EnvoyeLe], r.[Canal]
        FROM dbo.T206RappelFacture r
        WHERE r.[DocumentId] = p.[DocumentId] AND r.[CompanyGUID] = p.[CompanyGUID]
        ORDER BY r.[EnvoyeLe] DESC
    ) rap
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND p.[Statut] = 'PLANIFIE'
      AND (RTRIM(d.[JobCode]) LIKE 'ACT[_]%' OR p.[Approbation] = 'A_APPROUVER')
    ORDER BY p.[DueDate], p.[Id];
END
GO
