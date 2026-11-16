-- =============================================================================
-- T386 — Réparer la remise à zéro des démos et le nettoyage des comptes
--
-- 1) s0708ResetDemoCompany (Sérénité) échouait : PK_T076ProductCategory.
--    Le cliché de Sérénité réutilisait des Id déjà portés, en direct, par une
--    autre démo (Clinique Zénith) : 3 catégories (12-14) et 49 lignes de
--    relevé (1692-1740). Ces lignes du cliché reçoivent de nouveaux Id libres
--    (les produits du cliché suivent leur catégorie) et les compteurs
--    d'identité sont avancés au-delà.
-- 2) s0708 supprimait puis réinsérait les utilisateurs de la démo depuis le
--    cliché : un compte de cabinet comptable rattaché à la démo (ex.
--    comptable@60sec.ca → Sérénité), absent du cliché, aurait disparu. Les
--    membres d'un cabinet sont maintenant conservés tels quels.
-- 3) A_DELETE_USER aurait supprimé la compagnie modèle (Template) et la démo
--    INFORMATIQUE MG (compagnies sans utilisateur après le nettoyage) ; seul un
--    FK l'en empêchait (échec FK_T101ParamValues_T010Company). Réécrit :
--      - modèle, démos et membres de cabinet exclus ;
--      - les compagnies vidées passent par s0658DeleteCompanyCascade (toutes
--        les tables filles), jamais par un DELETE direct ;
--      - tout dans une transaction + garde « dernier admin » (T385).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ── 1) Cliché : renuméroter les lignes en conflit ──────────────────────────
BEGIN TRAN;

-- Catégories de produits
DECLARE @map76 TABLE (Ancien int PRIMARY KEY, Nouveau int);
DECLARE @base76 int = (SELECT MAX(v) FROM (VALUES (IDENT_CURRENT('dbo.T076ProductCategory')),
                       ((SELECT MAX(Id) FROM dbo.T076ProductCategory)),
                       ((SELECT MAX(Id) FROM dbo.DEMO_T076ProductCategory))) x(v));
INSERT INTO @map76 (Ancien, Nouveau)
SELECT d.Id, @base76 + ROW_NUMBER() OVER (ORDER BY d.Id)
FROM dbo.DEMO_T076ProductCategory d
JOIN dbo.T076ProductCategory l ON l.Id = d.Id AND l.CompanyGUID <> d.CompanyGUID;

UPDATE p SET CategoryId = m.Nouveau
FROM dbo.DEMO_T075Products p
JOIN dbo.DEMO_T076ProductCategory d ON d.Id = p.CategoryId AND d.CompanyGUID = p.CompanyGUID
JOIN @map76 m ON m.Ancien = d.Id
JOIN dbo.T076ProductCategory l ON l.Id = d.Id AND l.CompanyGUID <> d.CompanyGUID;

UPDATE d SET Id = m.Nouveau
FROM dbo.DEMO_T076ProductCategory d
JOIN @map76 m ON m.Ancien = d.Id
JOIN dbo.T076ProductCategory l ON l.Id = d.Id AND l.CompanyGUID <> d.CompanyGUID;

DECLARE @max76 int = (SELECT MAX(v) FROM (VALUES ((SELECT MAX(Nouveau) FROM @map76)), (@base76)) x(v));
DBCC CHECKIDENT ('dbo.T076ProductCategory', RESEED, @max76) WITH NO_INFOMSGS;
SELECT 'T076ProductCategory' AS Cliche, COUNT(*) AS Renumerotees FROM @map76;

-- Lignes de relevé bancaire
DECLARE @map142 TABLE (Ancien int PRIMARY KEY, Nouveau int);
DECLARE @base142 int = (SELECT MAX(v) FROM (VALUES (IDENT_CURRENT('dbo.T142ReleveBancaire')),
                        ((SELECT MAX(Id) FROM dbo.T142ReleveBancaire)),
                        ((SELECT MAX(Id) FROM dbo.DEMO_T142ReleveBancaire))) x(v));
INSERT INTO @map142 (Ancien, Nouveau)
SELECT d.Id, @base142 + ROW_NUMBER() OVER (ORDER BY d.Id)
FROM dbo.DEMO_T142ReleveBancaire d
JOIN dbo.T142ReleveBancaire l ON l.Id = d.Id AND l.CompanyGUID <> d.CompanyGUID;

UPDATE d SET Id = m.Nouveau
FROM dbo.DEMO_T142ReleveBancaire d
JOIN @map142 m ON m.Ancien = d.Id
JOIN dbo.T142ReleveBancaire l ON l.Id = d.Id AND l.CompanyGUID <> d.CompanyGUID;

DECLARE @max142 int = (SELECT MAX(v) FROM (VALUES ((SELECT MAX(Nouveau) FROM @map142)), (@base142)) x(v));
DBCC CHECKIDENT ('dbo.T142ReleveBancaire', RESEED, @max142) WITH NO_INFOMSGS;
SELECT 'T142ReleveBancaire' AS Cliche, COUNT(*) AS Renumerotees FROM @map142;

COMMIT;
GO

-- ── 2) s0708 : garder les comptes des membres de cabinet ───────────────────
DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID('dbo.s0708ResetDemoCompany')), @p int;
IF CHARINDEX(N'T386', @def) = 0
BEGIN
    DECLARE @a1 nvarchar(200) = N'DELETE FROM dbo.T015User                  WHERE CompanyGUID = @d;';
    DECLARE @a2 nvarchar(200) = N'(1 ,''T015User''                ,''CompanyGUID = @d''),';
    IF CHARINDEX(@a1, @def) = 0 OR CHARINDEX(@a2, @def) = 0
        THROW 51150, N's0708 : ancres T015User introuvables.', 1;
    SET @def = REPLACE(@def, @a1,
        N'-- T386 : les comptes des membres d''un cabinet comptable sont conservés
        DELETE FROM dbo.T015User                  WHERE CompanyGUID = @d
            AND UserGUID NOT IN (SELECT UserGUID FROM dbo.T332CabinetMembre WHERE UserGUID IS NOT NULL);');
    SET @def = REPLACE(@def, @a2,
        N'(1 ,''T015User''                ,''CompanyGUID = @d AND UserGUID NOT IN (SELECT UserGUID FROM dbo.T015User WHERE UserGUID IS NOT NULL)''),');
    SET @p = CHARINDEX(N'CREATE', @def); SET @def = STUFF(@def, @p, 6, N'ALTER');
    EXEC sys.sp_executesql @def;
END
GO

-- ── 3) A_DELETE_USER : nettoyage sûr des comptes « self-registration » ─────
CREATE OR ALTER PROCEDURE dbo.A_DELETE_USER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @modele uniqueidentifier = '00000000-0000-0000-0000-000000000001';
    DECLARE @protegees TABLE (CompanyGUID uniqueidentifier PRIMARY KEY);
    INSERT INTO @protegees SELECT @modele;
    INSERT INTO @protegees SELECT CompanyGUID FROM dbo.fnDemoCompanies() WHERE CompanyGUID <> @modele;

    BEGIN TRY
        BEGIN TRAN;
        DECLARE @cabAvant nvarchar(max) = STUFF((SELECT ',' + CAST(CabinetId AS varchar(12))
            FROM dbo.fCabinetsAvecAdmin() FOR XML PATH('')), 1, 1, '');

        -- Comptes visés : auto-inscrits, hors modèle / démos / membres de cabinet
        DECLARE @cibles TABLE (UserGUID uniqueidentifier, CompanyGUID uniqueidentifier);
        INSERT INTO @cibles
        SELECT u.UserGUID, u.CompanyGUID
        FROM dbo.T015User u
        WHERE u.CreatedBy = 'self-registration'
          AND u.CompanyGUID NOT IN (SELECT CompanyGUID FROM @protegees)
          AND u.UserGUID NOT IN (SELECT UserGUID FROM dbo.T332CabinetMembre WHERE UserGUID IS NOT NULL);

        -- Compagnies qui n'ont plus personne d'autre : suppression complète (cascade)
        DECLARE @co uniqueidentifier;
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT c.CompanyGUID FROM @cibles c
            WHERE NOT EXISTS (SELECT 1 FROM dbo.T015User u
                              WHERE u.CompanyGUID = c.CompanyGUID
                                AND u.UserGUID NOT IN (SELECT UserGUID FROM @cibles));
        OPEN cur; FETCH NEXT FROM cur INTO @co;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.s0658DeleteCompanyCascade @co, N'A_DELETE_USER';
            FETCH NEXT FROM cur INTO @co;
        END
        CLOSE cur; DEALLOCATE cur;

        -- Compagnies qui gardent d'autres utilisateurs : seulement les comptes visés
        DELETE u FROM dbo.T015User u JOIN @cibles c ON c.UserGUID = u.UserGUID;

        EXEC dbo.s1011ControleAdminsCabinets @cabAvant;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO
