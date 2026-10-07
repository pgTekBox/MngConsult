-- =============================================================================
-- 09 — Formulaires officiels (T4 de l'ARC, Relevé 1 de Revenu Québec) téléversés
--
-- Chaque compagnie téléverse, par année, le T4 à remplir de l'ARC (t4-fill) et le
-- Relevé 1 à remplir de Revenu Québec. Le contenu conservé est la copie préparée par
-- FormulaireOfficiel.Preparer (sans chiffrement, champs reconstruits) : les feuillets
-- de l'année sortent alors sur ces formulaires plutôt que sur la mise en page maison.
--
-- Ce script se rejoue sans dommage.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'paie.FormulaireFeuillet') IS NULL
CREATE TABLE paie.FormulaireFeuillet (
    CompagnieId   int            NOT NULL,
    Annee         int            NOT NULL,
    Type          char(2)        NOT NULL,          -- T4 ou R1
    NomFichier    nvarchar(200)  NOT NULL,
    Contenu       varbinary(max) NOT NULL,
    TeleverseLe   datetime2(0)   NOT NULL CONSTRAINT DF_FormulaireFeuillet_TeleverseLe DEFAULT (sysdatetime()),
    TeleversePar  nvarchar(256)  NULL,
    CONSTRAINT PK_FormulaireFeuillet PRIMARY KEY (CompagnieId, Annee, Type),
    CONSTRAINT CK_FormulaireFeuillet_Type CHECK (Type IN ('T4', 'R1'))
);
GO

-- Un formulaire par compagnie, année et type : un nouveau téléversement remplace l'ancien.
CREATE OR ALTER PROCEDURE paie.spFormulaireFeuillet_Enregistrer @c int, @a int, @type char(2), @nom nvarchar(200), @contenu varbinary(max), @u nvarchar(256) AS
    MERGE paie.FormulaireFeuillet AS t USING (SELECT @c AS CompagnieId, @a AS Annee, @type AS Type) AS s
        ON t.CompagnieId = s.CompagnieId AND t.Annee = s.Annee AND t.Type = s.Type
    WHEN MATCHED THEN UPDATE SET NomFichier = @nom, Contenu = @contenu, TeleverseLe = sysdatetime(), TeleversePar = @u
    WHEN NOT MATCHED THEN INSERT (CompagnieId, Annee, Type, NomFichier, Contenu, TeleverseLe, TeleversePar) VALUES (@c, @a, @type, @nom, @contenu, sysdatetime(), @u);
GO

-- La liste, sans le contenu.
CREATE OR ALTER PROCEDURE paie.spFormulaireFeuillet_Liste @c int AS
    SELECT Annee, Type, NomFichier, TeleverseLe, TeleversePar, DATALENGTH(Contenu) AS Taille
    FROM paie.FormulaireFeuillet WHERE CompagnieId = @c ORDER BY Annee DESC, Type;
GO

-- Les formulaires d'une année, avec leur contenu.
CREATE OR ALTER PROCEDURE paie.spFormulaireFeuillet_Annee @c int, @a int AS
    SELECT Type, NomFichier, Contenu FROM paie.FormulaireFeuillet WHERE CompagnieId = @c AND Annee = @a;
GO

CREATE OR ALTER PROCEDURE paie.spFormulaireFeuillet_Supprimer @c int, @a int, @type char(2) AS
    DELETE FROM paie.FormulaireFeuillet WHERE CompagnieId = @c AND Annee = @a AND Type = @type;
GO