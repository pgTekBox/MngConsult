-- =============================================================================
-- T299 — T121PlanComptable : retrait des trois colonnes d'alias QuickBooks
--
-- QBOCompteFR, QBOCompteEN et QBOSousType (T292) ont été migrées dans
-- dbo.T122PlanComptableAlias (T298). Plus aucune procédure ni aucun écran ne les
-- lit : elles s'en vont. Garde-fou : refus si la table d'alias est vide alors
-- que les colonnes portent encore des valeurs sur la compagnie modèle.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.T121PlanComptable', 'QBOCompteFR') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.T122PlanComptableAlias)
       AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable
                    WHERE [CompanyGUID] = '00000000-0000-0000-0000-000000000001'
                      AND ([QBOCompteFR] IS NOT NULL OR [QBOCompteEN] IS NOT NULL))
        THROW 50390, 'Les alias n''ont pas été migrés dans T122PlanComptableAlias : exécutez T298 avant de retirer les colonnes.', 1;

    ALTER TABLE dbo.T121PlanComptable DROP COLUMN [QBOCompteFR], [QBOCompteEN], [QBOSousType];
    PRINT N'T121PlanComptable : colonnes QBOCompteFR, QBOCompteEN, QBOSousType retirées.';
END
ELSE
    PRINT N'T121PlanComptable : colonnes déjà absentes.';
GO

PRINT N'T299_T121_retrait_colonnes_alias.sql : terminé.';
