-- =====================================================================
-- T399 — Journal des appels Apideck
--
-- Chaque appel HTTP de l'ERP vers Apideck (clsApideck.Envoyer : sessions
-- Vault, connexions, lectures comptables, passe-plat) est inscrit ici,
-- réussi ou non : méthode, chemin, service, statut HTTP, durée, essai
-- (les 429/403/5xx sont réessayés), message d'erreur, extraits de la
-- requête et de la réponse (jamais la clé d'API), compagnie, usager, page.
-- Consulté dans la console d'admin (prjSec60Admin → wbfApideckLog).
--
--   s1020InsertApideckLog     — inscription (appelée par l'ERP, ne doit jamais bloquer)
--   s1021ListApideckLog       — liste filtrée pour l'admin
--   s1022GetApideckLogResume  — chiffres des N derniers jours
--   s1023PurgerApideckLog     — efface les entrées plus vieilles que N jours (≥ 30)
-- =====================================================================
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.T027ApideckLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T027ApideckLog (
        Id            BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T027ApideckLog PRIMARY KEY,
        Created       DATETIME2(3)     NOT NULL CONSTRAINT DF_T027_Created DEFAULT SYSUTCDATETIME(),
        CompanyGUID   UNIQUEIDENTIFIER NULL,       -- le consommateur Apideck = la compagnie
        UserId        INT              NULL,       -- T015User.Id de la session, si connue
        Page          NVARCHAR(200)    NULL,       -- page ou handler de l'ERP à l'origine de l'appel
        Methode       VARCHAR(10)      NOT NULL,
        Chemin        NVARCHAR(600)    NOT NULL,   -- ex. /vault/sessions, /accounting/ledger-accounts?limit=200
        ServiceId     VARCHAR(80)      NULL,       -- quickbooks, xero… (en-tête x-apideck-service-id)
        Aval          NVARCHAR(600)    NULL,       -- adresse du passe-plat (x-apideck-downstream-url)
        Essai         TINYINT          NOT NULL CONSTRAINT DF_T027_Essai DEFAULT 1,
        StatutHttp    INT              NULL,       -- 0 = pas de réponse (délai, réseau, configuration)
        Succes        BIT              NOT NULL,
        DureeMs       INT              NULL,
        Erreur        NVARCHAR(2000)   NULL,
        Requete       NVARCHAR(4000)   NULL,       -- extrait du corps envoyé
        Reponse       NVARCHAR(4000)   NULL,       -- extrait du corps reçu
        TailleReponse INT              NULL
    );
    CREATE INDEX IX_T027_Created ON dbo.T027ApideckLog (Created DESC);
    CREATE INDEX IX_T027_Company ON dbo.T027ApideckLog (CompanyGUID, Created DESC);
END
GO

CREATE OR ALTER PROCEDURE dbo.s1020InsertApideckLog
    @CompanyGUID   uniqueidentifier = NULL,
    @UserId        int = NULL,
    @Page          nvarchar(200) = NULL,
    @Methode       varchar(10),
    @Chemin        nvarchar(600),
    @ServiceId     varchar(80) = NULL,
    @Aval          nvarchar(600) = NULL,
    @Essai         int = 1,
    @StatutHttp    int = NULL,
    @Succes        bit,
    @DureeMs       int = NULL,
    @Erreur        nvarchar(max) = NULL,
    @Requete       nvarchar(max) = NULL,
    @Reponse       nvarchar(max) = NULL,
    @TailleReponse int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.T027ApideckLog (CompanyGUID, UserId, Page, Methode, Chemin, ServiceId, Aval, Essai,
                                    StatutHttp, Succes, DureeMs, Erreur, Requete, Reponse, TailleReponse)
    VALUES (@CompanyGUID, @UserId, LEFT(@Page, 200), LEFT(@Methode, 10), LEFT(@Chemin, 600), LEFT(@ServiceId, 80),
            LEFT(@Aval, 600), CASE WHEN @Essai BETWEEN 1 AND 255 THEN @Essai ELSE 1 END,
            @StatutHttp, @Succes, @DureeMs, LEFT(@Erreur, 2000), LEFT(@Requete, 4000), LEFT(@Reponse, 4000), @TailleReponse);
END
GO

-- @Filtre : 'tous' | 'erreurs' ; @Recherche : dans le chemin, l'erreur, la page, la compagnie ou le courriel
CREATE OR ALTER PROCEDURE dbo.s1021ListApideckLog
    @Filtre    varchar(10) = 'tous',
    @Jours     int = 7,
    @Recherche nvarchar(200) = NULL,
    @Top       int = 300
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @depuis datetime2(3) = DATEADD(DAY, -CASE WHEN @Jours BETWEEN 1 AND 3650 THEN @Jours ELSE 7 END, SYSUTCDATETIME());
    DECLARE @q nvarchar(210) = NULLIF(LTRIM(RTRIM(@Recherche)), N'');
    IF @q IS NOT NULL SET @q = N'%' + @q + N'%';

    SELECT TOP (CASE WHEN @Top BETWEEN 1 AND 2000 THEN @Top ELSE 300 END)
        l.Id, l.Created, l.CompanyGUID, ISNULL(dbo.fCompanyName(l.CompanyGUID), N'') AS Compagnie,
        l.UserId, ISNULL(u.Email, N'') AS UserEmail, l.Page, l.Methode, l.Chemin, l.ServiceId, l.Aval,
        l.Essai, l.StatutHttp, l.Succes, l.DureeMs, l.Erreur, l.Requete, l.Reponse, l.TailleReponse
    FROM dbo.T027ApideckLog l
    LEFT JOIN dbo.T015User u ON u.Id = l.UserId
    WHERE l.Created >= @depuis
      AND (@Filtre <> 'erreurs' OR l.Succes = 0)
      AND (@q IS NULL OR l.Chemin LIKE @q OR l.Erreur LIKE @q OR l.Page LIKE @q OR u.Email LIKE @q
           OR dbo.fCompanyName(l.CompanyGUID) LIKE @q OR CONVERT(varchar(10), l.StatutHttp) = LTRIM(RTRIM(@Recherche)))
    ORDER BY l.Created DESC, l.Id DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.s1022GetApideckLogResume
    @Jours int = 7
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @depuis datetime2(3) = DATEADD(DAY, -CASE WHEN @Jours BETWEEN 1 AND 3650 THEN @Jours ELSE 7 END, SYSUTCDATETIME());

    SELECT COUNT(*)                                        AS Appels,
           SUM(CASE WHEN Succes = 0 THEN 1 ELSE 0 END)     AS Erreurs,
           AVG(CAST(DureeMs AS bigint))                    AS DureeMoyenneMs,
           MAX(Created)                                    AS DernierAppel,
           MAX(CASE WHEN Succes = 0 THEN Created END)      AS DerniereErreur,
           COUNT(DISTINCT CompanyGUID)                     AS Compagnies,
           (SELECT COUNT(*) FROM dbo.T027ApideckLog)        AS TotalJournal
    FROM dbo.T027ApideckLog
    WHERE Created >= @depuis;

    -- répartition par statut HTTP (0 = pas de réponse)
    SELECT ISNULL(StatutHttp, 0) AS StatutHttp, COUNT(*) AS Appels
    FROM dbo.T027ApideckLog
    WHERE Created >= @depuis
    GROUP BY ISNULL(StatutHttp, 0)
    ORDER BY Appels DESC;
END
GO

-- Efface les entrées plus vieilles que @Jours (30 au minimum) ; renvoie le nombre effacé.
CREATE OR ALTER PROCEDURE dbo.s1023PurgerApideckLog
    @Jours int = 90
AS
BEGIN
    SET NOCOUNT ON;
    IF @Jours < 30 SET @Jours = 30;
    DELETE FROM dbo.T027ApideckLog WHERE Created < DATEADD(DAY, -@Jours, SYSUTCDATETIME());
    SELECT @@ROWCOUNT AS Effacees;
END
GO
