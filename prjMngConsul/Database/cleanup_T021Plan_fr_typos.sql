-- =============================================================
-- Nettoyage des coquilles de test dans les textes FR de T021Plan :
--   'Travailleur Autonome123' / 'Autonomexxx'  -> 'Travailleur Autonome'
--   'Sans incorporationxxx' / 'Avec incorporationxx' -> '... incorporation'
-- REPLACE ciblé, idempotent, ordre xxx avant xx. Toutes lignes (même IsDeleted).
-- =============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

UPDATE dbo.T021Plan SET
    Name            = REPLACE(REPLACE(REPLACE(REPLACE(Name,            'Travailleur Autonome123', 'Travailleur Autonome'), 'Autonomexxx', 'Autonome'), 'incorporationxxx', 'incorporation'), 'incorporationxx', 'incorporation'),
    Tagline         = REPLACE(REPLACE(REPLACE(REPLACE(Tagline,         'Travailleur Autonome123', 'Travailleur Autonome'), 'Autonomexxx', 'Autonome'), 'incorporationxxx', 'incorporation'), 'incorporationxx', 'incorporation'),
    DescriptionLong = REPLACE(REPLACE(REPLACE(REPLACE(DescriptionLong, 'Travailleur Autonome123', 'Travailleur Autonome'), 'Autonomexxx', 'Autonome'), 'incorporationxxx', 'incorporation'), 'incorporationxx', 'incorporation')
WHERE Name            LIKE '%Autonome123%' OR Name            LIKE '%Autonomexxx%' OR Name            LIKE '%incorporationxx%'
   OR Tagline         LIKE '%Autonome123%' OR Tagline         LIKE '%Autonomexxx%' OR Tagline         LIKE '%incorporationxx%'
   OR DescriptionLong LIKE '%Autonome123%' OR DescriptionLong LIKE '%Autonomexxx%' OR DescriptionLong LIKE '%incorporationxx%';
GO
