SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0210GetUserCompanies
-- Compagnies accessibles à un utilisateur (par email), pour le header/sélecteur.
-- Le nom affiché (Name) provient désormais du paramètre LEGAL_NAME (T101),
-- source unique ; repli sur T010Company.Name si le paramètre est vide.
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
    BEGIN
        -- Comptable : toutes ses compagnies
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
GO
