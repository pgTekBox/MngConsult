-- =============================================================================
-- SeedTestClients
-- Cree 50 clients de TEST (Type=1 CLIENT) + une adresse principale chacun,
-- pour la compagnie indiquee. Sert a tester l'export clients -> Square.
--
-- Donnees synthetiques (noms/villes du Quebec). Email/telephone/adresse
-- remplis pour que l'export Square pousse des coordonnees completes.
--
-- A lancer avec : sqlcmd ... -I -f 65001   (UTF-8, pour les accents)
-- Idempotent : purge d'abord les clients de test existants (Note marqueur)
-- de cette compagnie, puis recree 50 clients aux NOMS TOUS DISTINCTS.
-- =============================================================================

USE [MngConsul];
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;

DECLARE @CompanyGUID   UNIQUEIDENTIFIER = 'CB130D6E-FDB6-4B92-A0B8-1F821F2764A4';
DECLARE @AddressTypeId INT = 1;
DECLARE @CountryId INT, @StateId INT;

SELECT @CountryId = Id FROM dbo.T052Country WHERE LOWER(Name) = 'canada';
IF @CountryId IS NULL SELECT TOP 1 @CountryId = Id FROM dbo.T052Country ORDER BY Id;
SELECT TOP 1 @StateId = Id FROM dbo.T053State WHERE LOWER(Name) IN ('quebec', N'québec');
IF @StateId IS NULL SELECT TOP 1 @StateId = Id FROM dbo.T053State ORDER BY Id;

-- ── Purge des clients de test existants (idempotence) ───────────────────────
DECLARE @oldIds TABLE (Id INT PRIMARY KEY);
INSERT @oldIds SELECT Id FROM dbo.T050Party
WHERE CompanyGUID = @CompanyGUID AND Note = N'Client de test (seed)';
DECLARE @oldCount INT = (SELECT COUNT(*) FROM @oldIds);
DELETE FROM dbo.T054PartyAddress WHERE PartyId IN (SELECT Id FROM @oldIds);
DELETE FROM dbo.T050Party        WHERE Id     IN (SELECT Id FROM @oldIds);
PRINT CAST(@oldCount AS VARCHAR(10)) + ' ancien(s) client(s) de test supprime(s).';

-- ── Listes de composants (index 0-based) ────────────────────────────────────
DECLARE @First TABLE (i INT PRIMARY KEY, v NVARCHAR(50));
INSERT @First VALUES
 (0,N'Jean'),(1,N'Marie'),(2,N'Pierre'),(3,N'Sophie'),(4,N'Luc'),
 (5,N'Nathalie'),(6,N'Marc'),(7,N'Isabelle'),(8,N'François'),(9,N'Julie'),
 (10,N'Daniel'),(11,N'Caroline'),(12,N'Stéphane'),(13,N'Mélanie'),(14,N'Éric'),
 (15,N'Annie'),(16,N'Patrick'),(17,N'Geneviève'),(18,N'Martin'),(19,N'Chantal');

DECLARE @Last TABLE (i INT PRIMARY KEY, v NVARCHAR(50));
INSERT @Last VALUES
 (0,N'Tremblay'),(1,N'Gagnon'),(2,N'Roy'),(3,N'Côté'),(4,N'Bouchard'),
 (5,N'Gauthier'),(6,N'Morin'),(7,N'Lavoie'),(8,N'Fortin'),(9,N'Gagné'),
 (10,N'Ouellet'),(11,N'Pelletier'),(12,N'Bélanger'),(13,N'Lévesque'),(14,N'Bergeron'),
 (15,N'Leblanc'),(16,N'Paquette'),(17,N'Girard'),(18,N'Simard'),(19,N'Boucher');

DECLARE @City TABLE (i INT PRIMARY KEY, v NVARCHAR(50), pc NVARCHAR(10), area NVARCHAR(3));
INSERT @City VALUES
 (0,N'Montréal',N'H2X 1Y4',N'514'),(1,N'Laval',N'H7N 2B5',N'450'),
 (2,N'Longueuil',N'J4K 2M3',N'450'),(3,N'Québec',N'G1R 3X5',N'418'),
 (4,N'Gatineau',N'J8X 1A1',N'819'),(5,N'Sherbrooke',N'J1H 4M7',N'819'),
 (6,N'Trois-Rivières',N'G8Z 1T4',N'819'),(7,N'Saguenay',N'G7H 1B1',N'418'),
 (8,N'Lévis',N'G6V 4Z2',N'418'),(9,N'Terrebonne',N'J6W 1K9',N'450'),
 (10,N'Brossard',N'J4Z 3V6',N'450'),(11,N'Repentigny',N'J6A 1B2',N'450');

DECLARE @Street TABLE (i INT PRIMARY KEY, v NVARCHAR(30));
INSERT @Street VALUES (0,N'rue Principale'),(1,N'avenue des Érables'),(2,N'boulevard Saint-Joseph'),(3,N'rue Notre-Dame'),(4,N'chemin du Lac');

-- ── Boucle de creation ──────────────────────────────────────────────────────
DECLARE @n INT = 1, @created INT = 0;
DECLARE @fi INT, @li INT, @ci INT, @si INT;
DECLARE @fn NVARCHAR(50), @ln NVARCHAR(50), @cn NVARCHAR(50), @pc NVARCHAR(10), @area NVARCHAR(3), @st NVARCHAR(30);
DECLARE @name NVARCHAR(120), @email NVARCHAR(120), @phone NVARCHAR(30), @addr1 NVARCHAR(120), @newId INT;

WHILE @n <= 50
BEGIN
    -- Paires (prenom, nom) toutes distinctes : a chaque bloc de 20 on decale
    -- l'index du nom, donc aucune combinaison ne se repete sur 50 clients.
    SET @fi = (@n - 1) % 20;
    SET @li = (@fi + ((@n - 1) / 20)) % 20;
    SET @ci = (@n - 1) % 12;
    SET @si = (@n - 1) % 5;

    SELECT @fn = v FROM @First WHERE i = @fi;
    SELECT @ln = v FROM @Last  WHERE i = @li;
    SELECT @cn = v, @pc = pc, @area = area FROM @City WHERE i = @ci;
    SELECT @st = v FROM @Street WHERE i = @si;

    SET @name  = @fn + N' ' + @ln;
    -- Email sans accent (les courriels ne doivent pas contenir d'accents).
    SET @email = LOWER(@fn) + N'.' + LOWER(@ln) + CAST(@n AS NVARCHAR(3)) + N'@exemple.ca';
    SET @email = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                 REPLACE(REPLACE(REPLACE(REPLACE(@email,
                 N'é',N'e'),N'è',N'e'),N'ê',N'e'),N'ë',N'e'),
                 N'à',N'a'),N'â',N'a'),N'ô',N'o'),N'ç',N'c'),
                 N'î',N'i'),N'ï',N'i'),N'û',N'u'),N'ü',N'u');
    SET @phone = @area + N'-555-' + RIGHT(N'0000' + CAST(1000 + @n AS NVARCHAR(5)), 4);
    SET @addr1 = CAST(100 + @n AS NVARCHAR(5)) + N' ' + @st;

    INSERT INTO dbo.T050Party
        (CompanyGUID, Name, DisplayName, Type, Origin, Note, isDeleted)
    VALUES
        (@CompanyGUID, @name, @name, 1, 1, N'Client de test (seed)', 0);
    SET @newId = SCOPE_IDENTITY();

    INSERT INTO dbo.T054PartyAddress
        (PartyId, AddressTypeId, Name, Address1, City, StateId, CountryId, PostalCode, Phone, Email, CreatedUTC)
    VALUES
        (@newId, @AddressTypeId, N'Principale', @addr1, @cn, @StateId, @CountryId, @pc, @phone, @email, SYSUTCDATETIME());

    SET @created += 1;
    SET @n += 1;
END

PRINT CAST(@created AS VARCHAR(10)) + ' clients de test crees pour la compagnie ' + CAST(@CompanyGUID AS VARCHAR(40)) + '.';
GO
