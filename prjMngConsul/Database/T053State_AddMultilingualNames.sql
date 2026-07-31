SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- T053State : noms multilingues (fr / en / es).
-- L'espagnol reprend l'anglais (demande client).
-- Idempotent : ajoute les colonnes seulement si absentes, puis (re)peuple.
-- =============================================================

IF COL_LENGTH('dbo.T053State', 'NameFr') IS NULL
    ALTER TABLE dbo.T053State ADD NameFr varchar(200) NULL;
GO
IF COL_LENGTH('dbo.T053State', 'NameEn') IS NULL
    ALTER TABLE dbo.T053State ADD NameEn varchar(200) NULL;
GO
IF COL_LENGTH('dbo.T053State', 'NameEs') IS NULL
    ALTER TABLE dbo.T053State ADD NameEs varchar(200) NULL;
GO

-- Base : anglais = Name existant ; espagnol = anglais ; français = anglais (défaut, surchargé ci-dessous)
UPDATE dbo.T053State
   SET NameEn = [Name],
       NameEs = [Name],
       NameFr = [Name];
GO

-- Surcharge des noms français (Canada + USA) là où ils diffèrent de l'anglais
;WITH fr(en, frname) AS (
    SELECT * FROM (VALUES
        -- Canada
        ('British Columbia',          N'Colombie-Britannique'),
        ('New Brunswick',             N'Nouveau-Brunswick'),
        ('Newfoundland and Labrador', N'Terre-Neuve-et-Labrador'),
        ('Northwest Territories',     N'Territoires du Nord-Ouest'),
        ('Nova Scotia',               N'Nouvelle-Écosse'),
        ('Prince Edward Island',      N'Île-du-Prince-Édouard'),
        ('Quebec',                    N'Québec'),
        -- USA
        ('California',                N'Californie'),
        ('Florida',                   N'Floride'),
        ('Georgia',                   N'Géorgie'),
        ('Hawaii',                    N'Hawaï'),
        ('Louisiana',                 N'Louisiane'),
        ('New Mexico',                N'Nouveau-Mexique'),
        ('North Carolina',            N'Caroline du Nord'),
        ('North Dakota',              N'Dakota du Nord'),
        ('Pennsylvania',              N'Pennsylvanie'),
        ('South Carolina',            N'Caroline du Sud'),
        ('South Dakota',              N'Dakota du Sud'),
        ('Virginia',                  N'Virginie'),
        ('West Virginia',             N'Virginie-Occidentale')
    ) v(en, frname)
)
UPDATE s
   SET s.NameFr = fr.frname
FROM dbo.T053State s
JOIN fr ON s.[Name] = fr.en;
GO
