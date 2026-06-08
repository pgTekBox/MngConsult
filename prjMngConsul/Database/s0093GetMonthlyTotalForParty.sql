-- =============================================================================
-- s0093GetMonthlyTotalForParty
-- Retourne le total cumule des auto-paiements SUCCESS pour un fournisseur
-- sur le mois calendrier en cours.
--
-- Utilise par le scheduler AVANT chaque debit pour verifier que
-- @MontantADebiter + @TotalDuMois <= MaxAmountPerMonth.
-- Si depasse -> resultat BLOCKED_CAP, ne pas debiter.
--
-- @ReferenceDate (optionnel) : si fourni, calcule sur le mois de cette
-- date. Sinon, mois courant (GETDATE).
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0093GetMonthlyTotalForParty', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0093GetMonthlyTotalForParty;
GO

CREATE PROCEDURE dbo.s0093GetMonthlyTotalForParty
    @CompanyGUID    UNIQUEIDENTIFIER,
    @PartyId        INT,
    @ReferenceDate  DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ref DATE = ISNULL(@ReferenceDate, CAST(GETDATE() AS DATE));
    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Ref), MONTH(@Ref), 1);
    DECLARE @MonthEnd   DATE = EOMONTH(@Ref);

    SELECT
        ISNULL(SUM(Amount), 0) AS TotalCharged,
        COUNT(*) AS ChargeCount,
        @MonthStart AS PeriodStart,
        @MonthEnd AS PeriodEnd
    FROM dbo.T145AutoPayAttempt
    WHERE CompanyGUID = @CompanyGUID
      AND PartyId = @PartyId
      AND Result = 'SUCCESS'
      AND CAST(AttemptDate AS DATE) BETWEEN @MonthStart AND @MonthEnd;
END
GO
