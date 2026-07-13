SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0686SaveOnboardingProfile
-- Sauvegarde les champs de wbfNewUser :
--   IDENTITÉ   → T015User (FirstName, LastName, Phone)
--   ENTREPRISE → paramètres T100/T101 (SOURCE UNIQUE, par ShortName)
-- N'écrit PLUS rien dans T010Company. @ProfileCompleted est ignoré (métadonnée
-- obsolète, plus lue nulle part). La signature est inchangée (le code-behind
-- wbfNewUser passe les mêmes paramètres).
--
-- Les valeurs DATE vont dans dVal, les chaînes dans sVal. Si la compagnie n'a
-- pas encore ses paramètres (utilisateur arrivé avant d'ouvrir wbfSetting), on
-- les provisionne d'abord depuis le modèle (même logique que s0150).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0686SaveOnboardingProfile
    @UserId            INT,
    @CompanyGUID       UNIQUEIDENTIFIER,
    @FirstName         NVARCHAR(100),
    @LastName          NVARCHAR(100),
    @Phone             NVARCHAR(50),
    @LegalName         VARCHAR(100),
    @NEQ               NVARCHAR(50),
    @IncorporationDate DATE,
    @BusinessNumber    NVARCHAR(50),
    @FiscalYearEnd     DATE,
    @TpsNumber         NVARCHAR(50),
    @TvqNumber         NVARCHAR(50),
    @HstNumber         NVARCHAR(50),
    @ProfileCompleted  INT,
    @ModifiedBy        NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Model UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- 1. Identité (compte utilisateur)
    UPDATE dbo.T015User
    SET FirstName  = @FirstName,
        LastName   = @LastName,
        Phone      = @Phone,
        ModifiedOn = GETDATE(),
        ModifiedBy = @ModifiedBy
    WHERE Id = @UserId;

    -- 2. Provisionnement : la compagnie doit posséder ses définitions + valeurs.
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

    -- 3. Écriture des valeurs (par ShortName). Chaînes → sVal, dates → dVal.
    UPDATE v SET v.sVal = @LegalName
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'LEGAL_NAME';

    UPDATE v SET v.sVal = @NEQ
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'NEQ';

    UPDATE v SET v.dVal = @IncorporationDate
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'INCORP_DATE';

    UPDATE v SET v.sVal = @BusinessNumber
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'FED_BN';

    UPDATE v SET v.dVal = @FiscalYearEnd
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'FISCAL_YEAR_END';

    UPDATE v SET v.sVal = @TpsNumber
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'GST_NO';

    UPDATE v SET v.sVal = @TvqNumber
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'QST_NO';

    UPDATE v SET v.sVal = @HstNumber
    FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
    WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = 'HST_NO';
END
GO
