-- =============================================================================
-- 08 — Feuillets T4 et Relevé 1 en PDF, envoyés par courriel aux employés
--
-- 60secPaie produit désormais les feuillets de fin d'année en PDF (copie de
-- l'employé, copie de l'employeur) et envoie la copie de l'employé par courriel
-- à ceux qui reçoivent leur talon par courriel. Cette table garde la trace de
-- chaque envoi (un par employé et par année) : l'écran le montre, et un envoi
-- déjà fait n'est pas refait sans le demander.
--
-- Ce script se rejoue sans dommage.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'paie.FeuilletEnvoi') IS NULL
CREATE TABLE paie.FeuilletEnvoi (
    EmployeId  int           NOT NULL,
    Annee      int           NOT NULL,
    EnvoyeLe   datetime2(0)  NOT NULL CONSTRAINT DF_FeuilletEnvoi_EnvoyeLe DEFAULT (sysdatetime()),
    Courriel   nvarchar(256) NOT NULL,
    CONSTRAINT PK_FeuilletEnvoi PRIMARY KEY (EmployeId, Annee)
);
GO

-- Un envoi par employé et par année : un renvoi remplace la date.
CREATE OR ALTER PROCEDURE paie.spFeuilletEnvoi_Enregistrer @e int, @a int, @courriel nvarchar(256) AS
    MERGE paie.FeuilletEnvoi AS t USING (SELECT @e AS EmployeId, @a AS Annee) AS s ON t.EmployeId = s.EmployeId AND t.Annee = s.Annee
    WHEN MATCHED THEN UPDATE SET EnvoyeLe = sysdatetime(), Courriel = @courriel
    WHEN NOT MATCHED THEN INSERT (EmployeId, Annee, EnvoyeLe, Courriel) VALUES (@e, @a, sysdatetime(), @courriel);
GO

-- Les envois de l'année pour les employés de la compagnie.
CREATE OR ALTER PROCEDURE paie.spFeuilletEnvoi_Annee @c int, @a int AS
    SELECT f.EmployeId, f.EnvoyeLe, f.Courriel
    FROM paie.FeuilletEnvoi f JOIN paie.Employe e ON e.Id = f.EmployeId
    WHERE e.CompagnieId = @c AND f.Annee = @a;
GO