-- =============================================================================
-- 10 — Instructions T4 de l'ARC (document par année, plateforme)
--
-- La console d'administration téléverse, par année, le document d'instructions T4
-- de l'ARC (Type 'TI', CompagnieId 0). 60secPaie le sert tel quel à toutes les
-- compagnies (Documents.aspx?doc=instructions-t4&annee=AAAA) ; il n'est ni vérifié
-- ni rempli comme les formulaires T4 et Relevé 1.
--
-- Ce script se rejoue sans dommage.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FormulaireFeuillet_Type' AND definition NOT LIKE '%TI%')
BEGIN
    ALTER TABLE paie.FormulaireFeuillet DROP CONSTRAINT CK_FormulaireFeuillet_Type;
    ALTER TABLE paie.FormulaireFeuillet ADD CONSTRAINT CK_FormulaireFeuillet_Type CHECK (Type IN ('T4', 'R1', 'TI'));
END
GO

-- Un document d'une année et d'un type, avec son contenu, pour le servir tel quel.
CREATE OR ALTER PROCEDURE paie.spFormulaireFeuillet_Get @c int, @a int, @type char(2) AS
    SELECT NomFichier, Contenu, TeleverseLe FROM paie.FormulaireFeuillet WHERE CompagnieId = @c AND Annee = @a AND Type = @type;
GO
