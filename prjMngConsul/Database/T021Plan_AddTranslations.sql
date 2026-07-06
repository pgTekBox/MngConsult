-- =============================================================
-- T021Plan : colonnes de traduction EN/ES pour l'affichage des forfaits.
-- Le français reste dans les colonnes de base (Name, Tagline, ...).
-- Si une traduction est NULL/vide, s0630 retombe sur le français (COALESCE).
-- Idempotent : n'ajoute que les colonnes manquantes. Types identiques aux bases.
-- =============================================================
IF COL_LENGTH('dbo.T021Plan','Name_en')            IS NULL ALTER TABLE dbo.T021Plan ADD Name_en            NVARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T021Plan','Name_es')            IS NULL ALTER TABLE dbo.T021Plan ADD Name_es            NVARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T021Plan','Tagline_en')         IS NULL ALTER TABLE dbo.T021Plan ADD Tagline_en         NVARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T021Plan','Tagline_es')         IS NULL ALTER TABLE dbo.T021Plan ADD Tagline_es         NVARCHAR(200)  NULL;
IF COL_LENGTH('dbo.T021Plan','Description_en')      IS NULL ALTER TABLE dbo.T021Plan ADD Description_en      NVARCHAR(500)  NULL;
IF COL_LENGTH('dbo.T021Plan','Description_es')      IS NULL ALTER TABLE dbo.T021Plan ADD Description_es      NVARCHAR(500)  NULL;
IF COL_LENGTH('dbo.T021Plan','DescriptionLong_en') IS NULL ALTER TABLE dbo.T021Plan ADD DescriptionLong_en NVARCHAR(MAX)  NULL;
IF COL_LENGTH('dbo.T021Plan','DescriptionLong_es') IS NULL ALTER TABLE dbo.T021Plan ADD DescriptionLong_es NVARCHAR(MAX)  NULL;
IF COL_LENGTH('dbo.T021Plan','EmployeeRange_en')   IS NULL ALTER TABLE dbo.T021Plan ADD EmployeeRange_en   NVARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T021Plan','EmployeeRange_es')   IS NULL ALTER TABLE dbo.T021Plan ADD EmployeeRange_es   NVARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T021Plan','BadgeText_en')       IS NULL ALTER TABLE dbo.T021Plan ADD BadgeText_en       NVARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T021Plan','BadgeText_es')       IS NULL ALTER TABLE dbo.T021Plan ADD BadgeText_es       NVARCHAR(100)  NULL;
IF COL_LENGTH('dbo.T021Plan','Features_en')        IS NULL ALTER TABLE dbo.T021Plan ADD Features_en        NVARCHAR(MAX)  NULL;
IF COL_LENGTH('dbo.T021Plan','Features_es')        IS NULL ALTER TABLE dbo.T021Plan ADD Features_es        NVARCHAR(MAX)  NULL;
GO
