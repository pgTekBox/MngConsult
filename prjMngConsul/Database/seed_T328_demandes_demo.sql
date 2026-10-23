-- =============================================================================
-- Deux demandes de nouveau rendez-vous pour la démo 1 (Informatique MG,
-- D89EB638-...), en attente : elles s'affichent dans « RDV demandé ».
-- Les plages souhaitées sont calculées à partir d'aujourd'hui : le prochain jour
-- ouvrable à 10 h et le surlendemain ouvrable à 14 h.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;

DECLARE @c UNIQUEIDENTIFIER = 'D89EB638-6B05-443D-B1C9-01A6316443BF';
DECLARE @j1 DATE = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
WHILE DATENAME(WEEKDAY, @j1) IN ('Saturday', 'Sunday', 'samedi', 'dimanche') SET @j1 = DATEADD(DAY, 1, @j1);
DECLARE @j2 DATE = DATEADD(DAY, 1, @j1);
WHILE DATENAME(WEEKDAY, @j2) IN ('Saturday', 'Sunday', 'samedi', 'dimanche') SET @j2 = DATEADD(DAY, 1, @j2);

IF NOT EXISTS (SELECT 1 FROM dbo.T328RdvDemande WHERE CompanyGUID = @c)
BEGIN
    INSERT INTO dbo.T328RdvDemande (CompanyGUID, TypeDemande, CustomerId, Canal, Message, DebutSouhaite, FinSouhaitee, RecueLe)
    VALUES
    (@c, N'Nouveau', 654, N'Texto',
     N'Bonjour, j''aimerais un rendez-vous pour une présentation de votre logiciel de caisse. Le matin m''arrange.',
     DATEADD(HOUR, 10, CAST(@j1 AS DATETIME)), DATEADD(HOUR, 11, CAST(@j1 AS DATETIME)), DATEADD(MINUTE, -25, GETDATE())),
    (@c, N'Nouveau', 656, N'Courriel',
     N'Notre terminal ne se connecte plus depuis la mise à jour. Pouvez-vous passer en après-midi ?',
     DATEADD(HOUR, 14, CAST(@j2 AS DATETIME)), DATEADD(HOUR, 15, CAST(@j2 AS DATETIME)), DATEADD(HOUR, -3, GETDATE()));
END

SELECT Id, TypeDemande, CustomerId, Canal, DebutSouhaite, Statut FROM dbo.T328RdvDemande WHERE CompanyGUID = @c;
