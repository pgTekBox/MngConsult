-- =============================================================================
-- T323 — Mon cabinet comptable : le cabinet choisi et la répartition des tâches
--
-- La fenêtre « Mon cabinet comptable » (CabinetsCertifies.aspx) laisse la
-- compagnie choisir son cabinet et décider, activité par activité, qui fait
-- quoi (Vous / Mon cabinet / Ensemble), avec un plafond par paiement. Cet état
-- était gardé dans le navigateur ; il est maintenant enregistré par compagnie,
-- pour que tous ses utilisateurs voient la même chose sur tout poste.
--
-- L'état est un document JSON produit par js/cabinet-60s.js :
--   { cabinet: { nom, resp, init, cert, lieu, langues, courriel, site, tel } | null,
--     rep: { idActivite: 'client'|'cabinet'|'partage'|'aucun' },
--     plafonds: { idActivite: montant }, envoye: ISO, maj: ISO }
-- Le serveur le garde tel quel (vérifie seulement que c'est un JSON objet).
--
--   T323MonCabinet           une ligne par compagnie
--   s0908GetMonCabinet       (@CompanyGUID)                   → Etat, MajUtc, MajParUserId
--   s0909SaveMonCabinet      (@CompanyGUID, @Etat, @UserId)   → enregistre (upsert)
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T323MonCabinet', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T323MonCabinet (
        CompanyGUID   UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_T323MonCabinet PRIMARY KEY,
        Etat          NVARCHAR(MAX)    NOT NULL,
        MajUtc        DATETIME2(0)     NOT NULL CONSTRAINT DF_T323MonCabinet_MajUtc DEFAULT SYSUTCDATETIME(),
        MajParUserId  INT              NULL,
        CONSTRAINT CK_T323MonCabinet_Etat CHECK (ISJSON(Etat) = 1)
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.s0908GetMonCabinet
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Etat, MajUtc, MajParUserId
    FROM dbo.T323MonCabinet
    WHERE CompanyGUID = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0909SaveMonCabinet
    @CompanyGUID UNIQUEIDENTIFIER,
    @Etat        NVARCHAR(MAX),
    @UserId      INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL OR @CompanyGUID = '00000000-0000-0000-0000-000000000000'
        THROW 50323, 'Compagnie absente.', 1;
    IF ISJSON(@Etat) <> 1 OR LEFT(LTRIM(@Etat), 1) <> N'{'
        THROW 50324, 'État invalide.', 1;

    UPDATE dbo.T323MonCabinet
       SET Etat = @Etat, MajUtc = SYSUTCDATETIME(), MajParUserId = @UserId
     WHERE CompanyGUID = @CompanyGUID;

    IF @@ROWCOUNT = 0
        INSERT dbo.T323MonCabinet (CompanyGUID, Etat, MajUtc, MajParUserId)
        VALUES (@CompanyGUID, @Etat, SYSUTCDATETIME(), @UserId);
END
GO
