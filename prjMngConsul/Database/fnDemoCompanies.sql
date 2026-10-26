-- =============================================================================
-- fnDemoCompanies()
-- Liste blanche (codee en dur) des compagnies de DEMONSTRATION.
-- Seule source de verite des GUID de demo : s0708/s0709 refusent d'agir sur
-- toute compagnie absente de cette liste (une vraie compagnie cliente ne peut
-- jamais etre reinitialisee ni ecrasee).
-- Pour ajouter/retirer une demo : modifier CETTE fonction (un seul endroit).
-- =============================================================================
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION dbo.fnDemoCompanies()
RETURNS TABLE
AS
RETURN
(
    SELECT CAST('D89EB638-6B05-443D-B1C9-01A6316443BF' AS UNIQUEIDENTIFIER) AS CompanyGUID  -- Logiciels Cronus (demo 1)
    UNION ALL SELECT CAST('D2D2D2D2-0000-4000-8000-000000000002' AS UNIQUEIDENTIFIER)         -- Boutique Eclair (demo 2)
    UNION ALL SELECT CAST('D3D3D3D3-0000-4000-8000-000000000003' AS UNIQUEIDENTIFIER)         -- Services Nordik (demo 3)
    -- Demos 4 a 12 : clones de Cronus (DEMO_Ajout_demos_4_a_12.sql)
    UNION ALL SELECT CAST('D4D4D4D4-0000-4000-8000-000000000004' AS UNIQUEIDENTIFIER)         -- Clinique Zenith (demo 4)
    UNION ALL SELECT CAST('D5D5D5D5-0000-4000-8000-000000000005' AS UNIQUEIDENTIFIER)         -- Plomberie Laurentide (demo 5)
    UNION ALL SELECT CAST('D6D6D6D6-0000-4000-8000-000000000006' AS UNIQUEIDENTIFIER)         -- Salon Meche Folle (demo 6)
    UNION ALL SELECT CAST('D7D7D7D7-0000-4000-8000-000000000007' AS UNIQUEIDENTIFIER)         -- Bistro Le Fenouil (demo 7)
    UNION ALL SELECT CAST('D8D8D8D8-0000-4000-8000-000000000008' AS UNIQUEIDENTIFIER)         -- Construction Rive-Nord (demo 8)
    UNION ALL SELECT CAST('D9D9D9D9-0000-4000-8000-000000000009' AS UNIQUEIDENTIFIER)         -- Garage Belle-Route (demo 9)
    UNION ALL SELECT CAST('DADADADA-0000-4000-8000-000000000010' AS UNIQUEIDENTIFIER)         -- Studio Lumen (demo 10)
    UNION ALL SELECT CAST('DBDBDBDB-0000-4000-8000-000000000011' AS UNIQUEIDENTIFIER)         -- Conseils Boreal (demo 11)
    UNION ALL SELECT CAST('DCDCDCDC-0000-4000-8000-000000000012' AS UNIQUEIDENTIFIER)         -- Paysagiste Verdure (demo 12)
);
GO
