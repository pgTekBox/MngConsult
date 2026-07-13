SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0220RegisterUser
-- Inscription : crée la compagnie (T010Company = identité seule), l'utilisateur
-- admin, et un abonnement en attente de paiement.
-- Le NOM de l'entreprise saisi (@CompanyName) est désormais provisionné et écrit
-- dans les PARAMÈTRES (T101) LEGAL_NAME et TRADE_NAME — source unique — au lieu
-- de l'ancienne colonne T010Company.Name (supprimée).
-- =============================================================================
CREATE OR ALTER PROCEDURE [dbo].[s0220RegisterUser]
    @Email           NVARCHAR(200),
    @PasswordHash    NVARCHAR(500),
    @FirstName       NVARCHAR(100) = NULL,
    @LastName        NVARCHAR(100) = NULL,
    @CompanyName     NVARCHAR(100) = NULL,
    @Abonnement      VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewUserId       INT = 0;
    DECLARE @NewCompanyGUID   UNIQUEIDENTIFIER = NULL;
    DECLARE @ActivationToken  UNIQUEIDENTIFIER = NULL;
    DECLARE @Errorcode        INT = 0;
    DECLARE @Model            UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- Email déjà utilisé ?
    IF EXISTS (SELECT 1 FROM dbo.T015User WHERE Email = @Email AND IsDeleted = 0)
    BEGIN
        SET @Errorcode = 1;
        SELECT @NewUserId NewUserId, @NewCompanyGUID NewCompanyGUID, @ActivationToken ActivationToken, @Errorcode Errorcode;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Créer la compagnie (identité seule)
        DECLARE @CompanyGUID UNIQUEIDENTIFIER = NEWID();

        INSERT INTO dbo.T010Company (CompanyGUID) VALUES (@CompanyGUID);

        -- 1b. Nom d'entreprise (repli : prénom+nom, puis « Mon entreprise »)
        DECLARE @CompName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(ISNULL(@CompanyName, ''))), '');
        IF @CompName IS NULL
            SET @CompName = NULLIF(LTRIM(RTRIM(ISNULL(@FirstName, '') + ' ' + ISNULL(@LastName, ''))), '');
        IF @CompName IS NULL
            SET @CompName = N'Mon entreprise';

        -- 1c. Provisionner les paramètres de la compagnie (clone du modèle)
        INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
        SELECT m.ShortName, m.Name, m.ParamType, m.Categorie, m.Ordre, @CompanyGUID
        FROM dbo.T100ParamComptable m
        WHERE m.CompanyGUID = @Model AND m.ShortName IS NOT NULL;

        INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
        SELECT c.Id, @CompanyGUID, vm.iVal, vm.sVal, vm.dVal, vm.fVal
        FROM dbo.T100ParamComptable c
        LEFT JOIN dbo.T100ParamComptable m ON m.CompanyGUID = @Model AND m.ShortName = c.ShortName
        LEFT JOIN dbo.T101ParamValues   vm ON vm.T100Id = m.Id AND vm.CompanyGUID = @Model
        WHERE c.CompanyGUID = @CompanyGUID AND c.ShortName IS NOT NULL;

        -- 1d. Écrire le nom saisi dans LEGAL_NAME et TRADE_NAME
        UPDATE v SET v.sVal = @CompName
        FROM dbo.T101ParamValues v INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
        WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName IN ('LEGAL_NAME', 'TRADE_NAME');

        -- 2. Token d'activation
        DECLARE @Token UNIQUEIDENTIFIER = NEWID();

        -- 3. Créer l'utilisateur (admin de sa compagnie)
        INSERT INTO dbo.T015User
            (CompanyGUID, Email, PasswordHash, FirstName, LastName,
             IsAdmin, IsAccountant, IsActive, IsEmailVerified,
             ActivationToken, ActivationExpires, CreatedBy)
        VALUES
            (@CompanyGUID, @Email, @PasswordHash, @FirstName, @LastName,
             1, 0, 0, 0,
             @Token, DATEADD(HOUR, 24, GETDATE()),
             N'self-registration');

        SET @NewUserId       = SCOPE_IDENTITY();
        SET @NewCompanyGUID  = @CompanyGUID;
        SET @ActivationToken = @Token;

        -- 4. Abonnement en attente de paiement
        INSERT INTO dbo.[T020Subscription] ([CompanyGUID], [UserId], [PlanCode], [Status], [Amount])
        VALUES (@CompanyGUID, @NewUserId, @Abonnement, 'Paiement', 0);

        COMMIT TRANSACTION;

        SELECT @NewUserId NewUserId, @NewCompanyGUID NewCompanyGUID, @ActivationToken ActivationToken, @Errorcode Errorcode;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Errorcode = 10000;
        SELECT @NewUserId NewUserId, @NewCompanyGUID NewCompanyGUID, @ActivationToken ActivationToken, @Errorcode Errorcode, ERROR_MESSAGE() ErrorMessage;
    END CATCH
END
GO
