-- =============================================================================
-- T385 — Les outils d'administration ne peuvent plus laisser un cabinet sans
-- administrateur actif (suite de T384).
--   fCabinetsAvecAdmin : cabinets actifs qui ont au moins un administrateur
--                        (admin / solo) dont le compte est actif et non supprimé
--   s0658DeleteCompanyCascade (console : supprimer une compagnie)
--   s0708ResetDemoCompany     (console : remettre une démo à zéro)
--   A_DELETE_USER             (nettoyage des comptes « self-registration »)
-- Chacun note, au début de sa transaction, les cabinets qui ont un
-- administrateur ; juste avant de valider, si l'un d'eux n'en a plus, tout est
-- annulé : THROW 51141 « Refusé : le cabinet … perdrait son dernier
-- administrateur actif ». La console affiche ce message tel quel.
-- s0658 / s0708 sont modifiés sur le serveur (texte relu, 2 ancres uniques).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION dbo.fCabinetsAvecAdmin()
RETURNS TABLE
AS
RETURN
    SELECT DISTINCT m.CabinetId
    FROM dbo.T332CabinetMembre m
    JOIN dbo.T331Cabinet c ON c.Id = m.CabinetId AND c.IsActive = 1
    JOIN dbo.T015User u ON u.UserGUID = m.UserGUID AND u.IsDeleted = 0 AND u.IsActive = 1
    WHERE m.IsActive = 1 AND m.Role IN ('admin', 'solo');
GO

-- Le contrôle, partagé : à appeler avec la liste des cabinets notée au début
-- (passée en texte « 1,4,7 » pour rester simple dans les procédures patchées).
CREATE OR ALTER PROCEDURE dbo.s1011ControleAdminsCabinets
    @CabinetsAvant nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @perdus nvarchar(1000) = STUFF((
        SELECT ', ' + c.Nom
        FROM STRING_SPLIT(ISNULL(@CabinetsAvant, ''), ',') s
        JOIN dbo.T331Cabinet c ON c.Id = TRY_CAST(s.value AS int)
        WHERE TRY_CAST(s.value AS int) NOT IN (SELECT CabinetId FROM dbo.fCabinetsAvecAdmin())
        ORDER BY c.Nom
        FOR XML PATH(''), TYPE).value('.', 'nvarchar(1000)'), 1, 2, '');
    IF @perdus IS NOT NULL
    BEGIN
        DECLARE @m nvarchar(2048) = N'Refusé : le cabinet comptable « ' + @perdus +
            N' » perdrait son dernier administrateur actif. Nommez d''abord un autre administrateur dans le portail comptable (Comptables et techniciens).';
        THROW 51141, @m, 1;
    END
END
GO

-- ── s0658 / s0708 : noter au début, contrôler avant de valider ─────────────
DECLARE @noms TABLE (n sysname);
INSERT INTO @noms VALUES (N's0658DeleteCompanyCascade'), (N's0708ResetDemoCompany');
DECLARE @nom sysname, @def nvarchar(max), @p int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT n FROM @noms;
OPEN cur; FETCH NEXT FROM cur INTO @nom;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @def = OBJECT_DEFINITION(OBJECT_ID(N'dbo.' + @nom));
    IF CHARINDEX(N's1011ControleAdminsCabinets', @def) = 0
    BEGIN
        IF (LEN(@def) - LEN(REPLACE(@def, N'BEGIN TRAN;', N''))) / LEN(N'BEGIN TRAN;') <> 1
           OR (LEN(@def) - LEN(REPLACE(@def, N'COMMIT TRAN;', N''))) / LEN(N'COMMIT TRAN;') <> 1
        BEGIN
            DECLARE @e nvarchar(400) = @nom + N' : ancres BEGIN TRAN / COMMIT TRAN non uniques.';
            THROW 51142, @e, 1;
        END
        SET @def = REPLACE(@def, N'BEGIN TRAN;',
            N'BEGIN TRAN;
        -- T385 : les cabinets qui ont un administrateur actif avant l''opération
        DECLARE @cabAvant nvarchar(max) = STUFF((SELECT '','' + CAST(CabinetId AS varchar(12))
            FROM dbo.fCabinetsAvecAdmin() FOR XML PATH('''')), 1, 1, '''');');
        SET @def = REPLACE(@def, N'COMMIT TRAN;',
            N'-- T385 : aucun cabinet ne doit perdre son dernier administrateur actif
        EXEC dbo.s1011ControleAdminsCabinets @cabAvant;
        COMMIT TRAN;');
        SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
        EXEC sys.sp_executesql @def;
    END
    FETCH NEXT FROM cur INTO @nom;
END
CLOSE cur; DEALLOCATE cur;
GO

-- ── A_DELETE_USER : même logique, dans une transaction ─────────────────────
CREATE OR ALTER PROCEDURE dbo.A_DELETE_USER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRAN;
        DECLARE @cabAvant nvarchar(max) = STUFF((SELECT ',' + CAST(CabinetId AS varchar(12))
            FROM dbo.fCabinetsAvecAdmin() FOR XML PATH('')), 1, 1, '');

        DELETE dbo.T015User WHERE CreatedBy = 'self-registration';
        -- Contrôle tout de suite après la suppression des comptes
        EXEC dbo.s1011ControleAdminsCabinets @cabAvant;

        DELETE FROM dbo.T010Company
        WHERE NOT EXISTS (SELECT 1 FROM dbo.T015User u WHERE u.CompanyGUID = T010Company.CompanyGUID);

        DELETE FROM dbo.T020Subscription
        WHERE NOT EXISTS (SELECT 1 FROM dbo.T015User u WHERE u.CompanyGUID = T020Subscription.CompanyGUID);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO
