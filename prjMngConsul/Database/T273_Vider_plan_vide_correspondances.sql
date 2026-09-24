-- =============================================================================
-- T273 — Abandonner le plan comptable en préparation efface aussi ses
--        correspondances
--
-- Les correspondances (staging.CorrespondanceCompte) sont rattachées aux
-- comptes du plan en préparation par leur clé source. Quand on vide ce plan,
-- elles restaient : au prochain chargement, des décisions prises sur un
-- ancien fichier réapparaissaient comme « déjà décidées » sur le nouveau.
-- Vider le plan vide désormais les deux. Le refus, lui, ne change pas :
-- un plan déjà appliqué ne s'efface pas.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0755ViderImportPlan]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50304, 'Aucune compagnie : refus de vider le plan comptable en préparation.', 1;

    IF EXISTS (SELECT 1 FROM staging.ImportPlanComptable
                WHERE [CompanyGUID] = @CompanyGUID AND [AppliqueLe] IS NOT NULL)
        THROW 50303, 'Cet import a été appliqué au plan comptable : il ne peut plus être supprimé.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.CorrespondanceCompte WHERE [CompanyGUID] = @CompanyGUID;
    DECLARE @NbCorrespondances INT = @@ROWCOUNT;

    DELETE FROM staging.ImportPlanComptable WHERE [CompanyGUID] = @CompanyGUID;
    DECLARE @NbComptes INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @NbComptes AS [NbSupprimees], @NbCorrespondances AS [NbCorrespondances];
END
GO

PRINT 'T273_Vider_plan_vide_correspondances.sql : terminé.';
