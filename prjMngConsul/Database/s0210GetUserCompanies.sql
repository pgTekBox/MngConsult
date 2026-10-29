SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0210GetUserCompanies
-- Compagnies accessibles à un utilisateur (par email), pour le header/sélecteur.
-- Le nom affiché (Name) provient du paramètre LEGAL_NAME (T101), repli fCompanyName.
-- Portail comptable (T335) : un comptable MEMBRE d'un cabinet est scopé par le
-- périmètre du cabinet (dbo.fCabinetDossiers, selon son rôle) ; un comptable hors
-- cabinet garde la logique ComptableGUID ; un utilisateur normal, sa compagnie.
-- =============================================================================
CREATE OR ALTER PROCEDURE [dbo].[s0210GetUserCompanies]
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsAccountant BIT = 0;
    DECLARE @UserCompanyGUID UNIQUEIDENTIFIER;
    DECLARE @UserGUID UNIQUEIDENTIFIER;
    SELECT
        @IsAccountant = IsAccountant,
        @UserCompanyGUID = CompanyGUID,
        @UserGUID  = UserGUID
    FROM dbo.T015User
    WHERE email = @UserId
      AND IsDeleted = 0;

    IF @IsAccountant = 1
       AND EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m
                   JOIN dbo.T331Cabinet cab ON cab.Id = m.CabinetId AND cab.IsActive = 1
                   WHERE m.UserGUID = @UserGUID AND m.IsActive = 1)
    BEGIN
        -- Comptable membre d'un cabinet : périmètre du cabinet selon son rôle
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
            c.CompanyCode
        FROM dbo.T010Company c
        JOIN dbo.fCabinetDossiers(@UserGUID) d ON d.CompanyGUID = c.CompanyGUID
        ORDER BY Name;
    END
    ELSE IF @IsAccountant = 1
    BEGIN
        -- Comptable hors cabinet : ses compagnies (ComptableGUID)
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
            c.CompanyCode
        FROM dbo.T010Company c
        WHERE c.[ComptableGUID] = @UserGUID
        ORDER BY Name;
    END
    ELSE
    BEGIN
        -- Utilisateur normal : uniquement sa compagnie
        SELECT
            c.CompanyGUID,
            dbo.fCompanyName(c.CompanyGUID) AS Name,
            dbo.fParamS(c.CompanyGUID, 'LEGAL_NAME') AS LegalName,
            c.CompanyCode
        FROM dbo.T010Company c
        WHERE c.CompanyGUID = @UserCompanyGUID;
    END
END
