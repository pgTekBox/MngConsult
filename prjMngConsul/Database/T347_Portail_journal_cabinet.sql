-- =============================================================================
-- T347_Portail_journal_cabinet.sql — Portail comptable
-- s0961GetCabinetJournal : le journal d'événements (T340DossierJournal) de TOUS
-- les dossiers du périmètre du cabinet, pour la page « Activités de l'Avatar 60 ».
--
-- s0945ListJournal existe déjà mais est borné à UN dossier (@CompanyGUID) ; ici on
-- rassemble le journal de tout le périmètre (via dbo.fCabinetDossiers), scopé par
-- rôle comme « Ma journée » (s0956). Lecture seule. Premier numéro libre : s0961.
-- Idempotent (CREATE OR ALTER). Rejouable sans dommage.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.s0961GetCabinetJournal
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid uniqueidentifier;
    SELECT TOP 1 @uid = u.UserGUID
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @uid IS NULL RETURN;

    SELECT TOP 200
        j.Id,
        j.Utc,
        j.[Type],
        j.Texte,
        CONVERT(varchar(40), j.CompanyGUID) AS CompanyGUID,
        dbo.fCompanyName(j.CompanyGUID)     AS DossierNom,
        LTRIM(RTRIM(ISNULL(u2.FirstName, N'') + N' ' + ISNULL(u2.LastName, N''))) AS ParNom
    FROM dbo.T340DossierJournal j
    JOIN dbo.fCabinetDossiers(@uid) f ON f.CompanyGUID = j.CompanyGUID
    LEFT JOIN dbo.T015User u2 ON u2.UserGUID = j.UserGUID
    ORDER BY j.Utc DESC, j.Id DESC;
END
GO
