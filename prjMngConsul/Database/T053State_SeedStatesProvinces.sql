SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- T053State : ajoute les provinces/territoires du Canada (CountryId = 1)
-- et les 50 États des USA (CountryId = 2).
-- Idempotent : n'insère que les entrées absentes (par Name + CountryId).
-- =============================================================

INSERT INTO dbo.T053State ([Name], CountryId, Created)
SELECT v.[Name], v.CountryId, GETDATE()
FROM (VALUES
    -- ===== Canada (CountryId = 1) =====
    ('Alberta', 1),
    ('British Columbia', 1),
    ('Manitoba', 1),
    ('New Brunswick', 1),
    ('Newfoundland and Labrador', 1),
    ('Northwest Territories', 1),
    ('Nova Scotia', 1),
    ('Nunavut', 1),
    ('Ontario', 1),
    ('Prince Edward Island', 1),
    ('Quebec', 1),
    ('Saskatchewan', 1),
    ('Yukon', 1),
    -- ===== USA (CountryId = 2) =====
    ('Alabama', 2),
    ('Alaska', 2),
    ('Arizona', 2),
    ('Arkansas', 2),
    ('California', 2),
    ('Colorado', 2),
    ('Connecticut', 2),
    ('Delaware', 2),
    ('Florida', 2),
    ('Georgia', 2),
    ('Hawaii', 2),
    ('Idaho', 2),
    ('Illinois', 2),
    ('Indiana', 2),
    ('Iowa', 2),
    ('Kansas', 2),
    ('Kentucky', 2),
    ('Louisiana', 2),
    ('Maine', 2),
    ('Maryland', 2),
    ('Massachusetts', 2),
    ('Michigan', 2),
    ('Minnesota', 2),
    ('Mississippi', 2),
    ('Missouri', 2),
    ('Montana', 2),
    ('Nebraska', 2),
    ('Nevada', 2),
    ('New Hampshire', 2),
    ('New Jersey', 2),
    ('New Mexico', 2),
    ('New York', 2),
    ('North Carolina', 2),
    ('North Dakota', 2),
    ('Ohio', 2),
    ('Oklahoma', 2),
    ('Oregon', 2),
    ('Pennsylvania', 2),
    ('Rhode Island', 2),
    ('South Carolina', 2),
    ('South Dakota', 2),
    ('Tennessee', 2),
    ('Texas', 2),
    ('Utah', 2),
    ('Vermont', 2),
    ('Virginia', 2),
    ('Washington', 2),
    ('West Virginia', 2),
    ('Wisconsin', 2),
    ('Wyoming', 2)
) AS v([Name], CountryId)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.T053State s
    WHERE s.[Name] = v.[Name] AND s.CountryId = v.CountryId
);
GO
