-- =============================================================================
-- DEMO_Ajout_demos_4_a_12.sql
-- Neuf compagnies de démonstration de plus (démos 4 à 12), clonées de la démo 1
-- (Cronus, « Informatique MG ») par dbo.s0710CloneCompany, chacune avec son nom,
-- son métier et son utilisateur demoN@60sec.ca (mot de passe de demo1@60sec.ca).
--
-- Pour chaque démo absente :
--   1) s0710CloneCompany : la compagnie et tout son contenu (paramètres, plan
--      comptable, clients, fournisseurs, produits, documents, écritures,
--      employés, RDV) ; pas d'utilisateur ni d'abonnement ;
--   2) TRADE_NAME, LEGAL_NAME, MAIL_FROM_EMAIL et METIER (s'il existe dans
--      T330Metier) ;
--   3) l'utilisateur administrateur demoN@60sec.ca, comme demo2 et demo3
--      (prénom « Démo », nom = nom commercial) ;
--   4) s0709SnapshotDemoCompany : son cliché DEMO_*, pour que la console
--      d'administration puisse la réinitialiser (s0708).
-- Une démo déjà présente n'est pas touchée : le script peut être relancé.
--
-- Prérequis : fnDemoCompanies.sql (mis à jour : 12 démos), s0710CloneCompany.sql,
-- DEMO_CreateAndSnapshot.sql (s0709 et les tables DEMO_*).
-- =============================================================================
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;
GO

DECLARE @src UNIQUEIDENTIFIER = 'D89EB638-6B05-443D-B1C9-01A6316443BF';   -- démo 1 (Cronus)

DECLARE @demos TABLE (n INT PRIMARY KEY, g UNIQUEIDENTIFIER, code VARCHAR(50), nom NVARCHAR(150), metier NVARCHAR(150));
INSERT INTO @demos (n, g, code, nom, metier) VALUES
 ( 4, 'D4D4D4D4-0000-4000-8000-000000000004', 'DEMO4' , N'Clinique Zénith'        , N'Massothérapeute'),
 ( 5, 'D5D5D5D5-0000-4000-8000-000000000005', 'DEMO5' , N'Plomberie Laurentide'   , N'Plombier'),
 ( 6, 'D6D6D6D6-0000-4000-8000-000000000006', 'DEMO6' , N'Salon Mèche Folle'      , N'Coiffeuse ou coiffeur'),
 ( 7, 'D7D7D7D7-0000-4000-8000-000000000007', 'DEMO7' , N'Bistro Le Fenouil'      , N'Restaurant'),
 ( 8, 'D8D8D8D8-0000-4000-8000-000000000008', 'DEMO8' , N'Construction Rive-Nord' , N'Entrepreneur général en construction résidentielle neuve'),
 ( 9, 'D9D9D9D9-0000-4000-8000-000000000009', 'DEMO9' , N'Garage Belle-Route'     , NULL),   -- aucun métier « garage » dans T330Metier
 (10, 'DADADADA-0000-4000-8000-000000000010', 'DEMO10', N'Studio Lumen'           , N'Photographe de portrait sur rendez-vous'),
 (11, 'DBDBDBDB-0000-4000-8000-000000000011', 'DEMO11', N'Conseils Boréal'        , N'Consultant en gestion'),
 (12, 'DCDCDCDC-0000-4000-8000-000000000012', 'DEMO12', N'Paysagiste Verdure'     , N'Entretien paysager et tonte');

IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @src)
BEGIN RAISERROR('Démo 1 (Cronus) introuvable.', 16, 1); RETURN; END
IF EXISTS (SELECT 1 FROM @demos d WHERE NOT EXISTS (SELECT 1 FROM dbo.fnDemoCompanies() f WHERE f.CompanyGUID = d.g))
BEGIN RAISERROR('fnDemoCompanies() ne liste pas les 12 démos : exécuter d''abord fnDemoCompanies.sql.', 16, 1); RETURN; END

DECLARE @n INT, @g UNIQUEIDENTIFIER, @code VARCHAR(50), @nom NVARCHAR(150), @metier NVARCHAR(150), @mail NVARCHAR(100);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT n, g, code, nom, metier FROM @demos ORDER BY n;
OPEN c; FETCH NEXT FROM c INTO @n, @g, @code, @nom, @metier;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @g)
    BEGIN
        PRINT N'Démo ' + CAST(@n AS NVARCHAR(5)) + N' déjà présente : rien à faire.';
    END
    ELSE
    BEGIN
        SET @mail = N'demo' + CAST(@n AS NVARCHAR(5)) + N'@60sec.ca';

        SET XACT_ABORT ON;
        BEGIN TRAN;
            -- 1) La compagnie et son contenu
            EXEC dbo.s0710CloneCompany @src = @src, @dst = @g, @newCompanyCode = @code;

            -- 2) Son nom, son courriel d'envoi et son métier
            UPDATE v SET v.sVal = CASE p.ShortName
                                     WHEN 'TRADE_NAME'      THEN @nom
                                     WHEN 'LEGAL_NAME'      THEN UPPER(@nom)
                                     WHEN 'MAIL_FROM_EMAIL' THEN @mail
                                     WHEN 'METIER'          THEN (SELECT Nom FROM dbo.T330Metier WHERE Nom = @metier)
                                  END
            FROM dbo.T101ParamValues v
            JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
            WHERE v.CompanyGUID = @g
              AND p.ShortName IN ('TRADE_NAME', 'LEGAL_NAME', 'MAIL_FROM_EMAIL', 'METIER');

            -- 3) L'utilisateur administrateur, à partir de demo1@60sec.ca
            INSERT INTO dbo.T015User (CompanyGUID, UserGUID, Email, PasswordHash, FirstName, LastName,
                                      IsAdmin, IsActive, CreatedOn, CreatedBy, IsDeleted, isAccountant,
                                      ActivatedOn, IsEmailVerified, Address1, City, Province, PostalCode, Phone)
            SELECT TOP 1 @g, NEWID(), @mail, u.PasswordHash, N'Démo', @nom,
                   1, 1, GETDATE(), N'DEMO_Ajout_demos_4_a_12', 0, 0,
                   GETDATE(), 1, u.Address1, u.City, u.Province, u.PostalCode, u.Phone
            FROM dbo.T015User u
            WHERE u.CompanyGUID = @src AND u.Email = N'demo1@60sec.ca';
        COMMIT;

        -- 4) Son cliché, pour la réinitialisation depuis la console d'administration
        EXEC dbo.s0709SnapshotDemoCompany @CompanyGUID = @g;

        PRINT N'Démo ' + CAST(@n AS NVARCHAR(5)) + N' créée : ' + @nom + N' (' + @mail + N').';
    END
    FETCH NEXT FROM c INTO @n, @g, @code, @nom, @metier;
END
CLOSE c; DEALLOCATE c;
GO
