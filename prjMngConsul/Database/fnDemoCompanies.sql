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
);
GO
