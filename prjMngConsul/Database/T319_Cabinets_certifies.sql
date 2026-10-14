-- =============================================================================
-- T319 — Cabinets certifiés : l'annuaire des cabinets comptables certifiés
--        60secondes, ouvert depuis l'en-tête de l'ERP (bouton « Cabinets
--        certifiés », à côté d'Entreprise) dans une fenêtre par-dessus la page.
--
-- Le site public présente déjà cet annuaire (section « Cabinets », liste de
-- démonstration dans le script de la page). L'ERP le montre maintenant à
-- l'utilisateur connecté, depuis la base : un cabinet par ligne, avec le
-- responsable, la ville, les langues parlées, les spécialités et les moyens
-- de le joindre. L'annuaire est le même pour toutes les compagnies : il
-- n'est pas borné à la compagnie de session.
--
--   T319CabinetCertifie : Langues = codes séparés par des virgules (FR,EN,ES) ;
--       Specialites = codes (ta, soc, paie, constr, sante), traduits à l'écran.
--   s0900ListCabinetsCertifies → les cabinets actifs, par nom.
--
-- Les cinq cabinets de démonstration du site public sont semés une fois (par
-- nom) ; adresses, courriels et numéros sont fictifs (.example, 555).
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T319CabinetCertifie', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T319CabinetCertifie (
        Id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_T319CabinetCertifie PRIMARY KEY,
        Nom             NVARCHAR(150)  NOT NULL,
        Responsable     NVARCHAR(150)  NULL,
        Ville           NVARCHAR(100)  NULL,
        Province        NVARCHAR(50)   NOT NULL CONSTRAINT DF_T319_Province DEFAULT (N'QC'),
        Courriel        NVARCHAR(200)  NULL,
        Telephone       NVARCHAR(40)   NULL,
        SiteWeb         NVARCHAR(250)  NULL,
        Langues         NVARCHAR(50)   NOT NULL CONSTRAINT DF_T319_Langues DEFAULT (N'FR'),
        Specialites     NVARCHAR(200)  NULL,
        [Description]   NVARCHAR(500)  NULL,
        CertifieDepuis  DATE           NULL,
        IsActive        BIT            NOT NULL CONSTRAINT DF_T319_IsActive DEFAULT (1),
        CreatedUtc      DATETIME2(0)   NOT NULL CONSTRAINT DF_T319_CreatedUtc DEFAULT (SYSUTCDATETIME())
    );
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0900ListCabinetsCertifies]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.[Id], c.[Nom], c.[Responsable], c.[Ville], c.[Province], c.[Courriel],
           c.[Telephone], c.[SiteWeb], c.[Langues], c.[Specialites], c.[Description],
           c.[CertifieDepuis]
      FROM dbo.T319CabinetCertifie c
     WHERE c.[IsActive] = 1
     ORDER BY c.[Nom];
END
GO

-- Les cabinets de démonstration du site public (une fois, par nom).
MERGE dbo.T319CabinetCertifie AS t
USING (VALUES
    (N'Lachance CPA inc.',         N'Geneviève Lachance, CPA',  N'Montréal',   N'contact@lachance-cpa.example',    N'514 555-0142', N'https://lachance-cpa.example',    N'FR,EN',    N'ta,soc,sante',      N'Travailleurs autonomes et professionnels de la santé ; fiscalité personnelle et de société.',                 '2025-03-01'),
    (N'Gagnon Bérubé comptables',  N'Philippe Gagnon, CPA',     N'Québec',     N'info@gagnonberube.example',        N'418 555-0177', N'https://gagnonberube.example',    N'FR',       N'soc,paie,constr',   N'PME de la construction et des services ; paie, DAS et relevés, fin d''exercice.',                            '2025-05-01'),
    (N'Tanguay Comptabilité',      N'Marie-Ève Tanguay',        N'Sherbrooke', N'bonjour@tanguay-compta.example',  N'819 555-0119', N'https://tanguay-compta.example',  N'FR,EN',    N'ta,soc',            N'Démarrage d''entreprise, taxes et première année ; rencontres en vidéo.',                                    '2025-09-01'),
    (N'Ouellet Roy CPA',           N'Karim Ouellet, CPA',       N'Laval',      N'info@ouelletroy.example',          N'450 555-0163', N'https://ouelletroy.example',      N'FR,EN,ES', N'paie,soc,sante',    N'Cliniques, salons et commerces avec employés ; paie et remises.',                                            '2026-01-01'),
    (N'Comptabilité Rive-Sud',     N'Nathalie Brisson, CPA',    N'Longueuil',  N'info@compta-rivesud.example',      N'450 555-0128', NULL,                               N'FR',       N'ta,constr',         N'Entrepreneurs en construction et travailleurs autonomes ; CCQ et acomptes provisionnels.',                    '2026-04-01')
) AS s (Nom, Responsable, Ville, Courriel, Telephone, SiteWeb, Langues, Specialites, [Description], CertifieDepuis)
   ON t.[Nom] = s.Nom
WHEN NOT MATCHED THEN
    INSERT ([Nom], [Responsable], [Ville], [Courriel], [Telephone], [SiteWeb], [Langues], [Specialites], [Description], [CertifieDepuis])
    VALUES (s.Nom, s.Responsable, s.Ville, s.Courriel, s.Telephone, s.SiteWeb, s.Langues, s.Specialites, s.[Description], s.CertifieDepuis);
GO
