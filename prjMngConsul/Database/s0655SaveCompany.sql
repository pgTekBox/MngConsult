SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0655SaveCompany (édition admin)
-- Écrit les champs entreprise dans T101 (source unique) :
--   TRADE_NAME←@Name, LEGAL_NAME←@LegalName, STRUCTURE←@Structure,
--   FED_BN←@BusinessNumber, NEQ←@NEQ.
-- CompanyCode reste l'identité de l'enregistrement (T010Company).
-- Provisionne d'abord les paramètres de la compagnie s'ils sont absents.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0655SaveCompany
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Name           NVARCHAR(200),
    @LegalName      NVARCHAR(200) = NULL,
    @CompanyCode    NVARCHAR(50)  = NULL,
    @Structure      NVARCHAR(50)  = NULL,
    @BusinessNumber NVARCHAR(50)  = NULL,
    @NEQ            NVARCHAR(50)  = NULL,
    @ModifiedBy     NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- CompanyCode = identité de l'enregistrement (reste dans T010Company)
    UPDATE dbo.T010Company
    SET CompanyCode = @CompanyCode,
        ModifiedOn  = GETDATE(),
        ModifiedBy  = @ModifiedBy
    WHERE CompanyGUID = @CompanyGUID;

    -- Provisionnement des paramètres si absents (clone du modèle)
    IF @CompanyGUID <> @Model AND @CompanyGUID <> '00000000-0000-0000-0000-000000000000'
    BEGIN
        INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
        SELECT m.ShortName, m.Name, m.ParamType, m.Categorie, m.Ordre, @CompanyGUID
        FROM dbo.T100ParamComptable m
        WHERE m.CompanyGUID = @Model AND m.ShortName IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable c
                          WHERE c.CompanyGUID = @CompanyGUID AND c.ShortName = m.ShortName);

        INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
        SELECT c.Id, @CompanyGUID, vm.iVal, vm.sVal, vm.dVal, vm.fVal
        FROM dbo.T100ParamComptable c
        LEFT JOIN dbo.T100ParamComptable m ON m.CompanyGUID = @Model AND m.ShortName = c.ShortName
        LEFT JOIN dbo.T101ParamValues   vm ON vm.T100Id = m.Id AND vm.CompanyGUID = @Model
        WHERE c.CompanyGUID = @CompanyGUID AND c.ShortName IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues t
                          WHERE t.T100Id = c.Id AND t.CompanyGUID = @CompanyGUID);
    END

    -- Écriture des valeurs (par ShortName)
    UPDATE v SET v.sVal = @Name           FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'TRADE_NAME';
    UPDATE v SET v.sVal = @LegalName       FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'LEGAL_NAME';
    UPDATE v SET v.sVal = @Structure       FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'STRUCTURE';
    UPDATE v SET v.sVal = @BusinessNumber  FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'FED_BN';
    UPDATE v SET v.sVal = @NEQ             FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'NEQ';
END
GO
