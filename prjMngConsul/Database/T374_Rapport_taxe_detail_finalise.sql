-- =============================================================================
-- T374 — Rapport de taxes : le détail des écritures, même finalisé ou remis
--
-- sp_GenererRapportTaxe ne renvoie aucun détail une fois le rapport FINALISE
-- ou PAYE. s0993GetRapportTaxeDetail lit le détail d'un rapport, quel que soit
-- son statut, sur la période enregistrée dans T070RapportTaxe : écritures
-- VALIDEE de la compagnie sur les comptes de taxes 2200 / 1450 / 2210 / 1460
-- (même choix de comptes et mêmes colonnes que sp_GenererRapportTaxe, avec
-- SourceType et DocumentId pour le lien vers la facture, T373).
--
-- Un rapport finalisé garde ses montants figés ; si des écritures de la
-- période ont changé depuis, la page le signale (les totaux du détail ne
-- concordent plus).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0993GetRapportTaxeDetail
    @CompanyGUID UNIQUEIDENTIFIER,
    @RapportId   INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Debut DATE, @Fin DATE;
    SELECT @Debut = [DebutPeriode], @Fin = [FinPeriode]
    FROM dbo.T070RapportTaxe WHERE [Id] = @RapportId AND [CompanyGUID] = @CompanyGUID;

    IF @Debut IS NULL THROW 51095, 'Rapport de taxes introuvable.', 1;

    -- Les comptes de taxes : ceux de la compagnie d'abord, sinon les comptes communs
    DECLARE @CpteTPS_Vte INT = (SELECT TOP 1 [Id] FROM dbo.T121PlanComptable WHERE [Compte] = '2200' AND [Actif] = 1
                                AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
                                ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);
    DECLARE @CpteTPS_Ach INT = (SELECT TOP 1 [Id] FROM dbo.T121PlanComptable WHERE [Compte] = '1450' AND [Actif] = 1
                                AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
                                ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);
    DECLARE @CpteTVQ_Vte INT = (SELECT TOP 1 [Id] FROM dbo.T121PlanComptable WHERE [Compte] = '2210' AND [Actif] = 1
                                AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
                                ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);
    DECLARE @CpteTVQ_Ach INT = (SELECT TOP 1 [Id] FROM dbo.T121PlanComptable WHERE [Compte] = '1460' AND [Actif] = 1
                                AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
                                ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END);

    SELECT
        e.[NumeroPiece],
        e.[DateEcriture],
        e.[Libelle],
        c.[Compte],
        c.[Nom] AS NomCompte, e.[SourceType], doc.[Id] AS DocumentId,
        l.[Libelle] AS LibelleLigne,
        l.[MontantDebit],
        l.[MontantCredit],
        CASE
            WHEN l.[PlanComptableId] = @CpteTPS_Vte THEN N'TPS perçue'
            WHEN l.[PlanComptableId] = @CpteTPS_Ach THEN N'TPS payée (CTI)'
            WHEN l.[PlanComptableId] = @CpteTVQ_Vte THEN N'TVQ perçue'
            WHEN l.[PlanComptableId] = @CpteTVQ_Ach THEN N'TVQ payée (RTI)'
        END AS Categorie,
        CASE
            WHEN l.[PlanComptableId] = @CpteTPS_Vte THEN 'TPS_VTE'
            WHEN l.[PlanComptableId] = @CpteTPS_Ach THEN 'TPS_ACH'
            WHEN l.[PlanComptableId] = @CpteTVQ_Vte THEN 'TVQ_VTE'
            WHEN l.[PlanComptableId] = @CpteTVQ_Ach THEN 'TVQ_ACH'
        END AS CodeCategorie
    FROM dbo.T136LignesEcriture l
    INNER JOIN dbo.T135Ecritures     e ON e.[Id] = l.[EcrituresId]
    INNER JOIN dbo.T121PlanComptable c ON c.[Id] = l.[PlanComptableId]
    LEFT JOIN dbo.T060Document doc ON doc.[Id] = e.[SourceId] AND doc.[CompanyGUID] = e.[CompanyGUID]
                                  AND e.[SourceType] IN ('FACTURE_CLIENT', 'FACTURE_FOURN')
    WHERE e.[CompanyGUID] = @CompanyGUID
      AND e.[Statut] = 'VALIDEE'
      AND e.[DateEcriture] BETWEEN @Debut AND @Fin
      AND l.[PlanComptableId] IN (@CpteTPS_Vte, @CpteTPS_Ach, @CpteTVQ_Vte, @CpteTVQ_Ach)
    ORDER BY e.[DateEcriture], e.[NumeroPiece], c.[Compte];
END
GO
