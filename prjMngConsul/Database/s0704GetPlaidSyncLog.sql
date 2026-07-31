SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0704GetPlaidSyncLog
-- Journal des erreurs / evenements de synchro Plaid (console Admin — diagnostic).
-- Source : T144PlaidSyncLog (alimentee par PlaidWebhook sur ITEM error / sync error).
--
-- Filtres :
--   @SinceHours : fenetre en heures (24, 168=7j, 720=30j)
--   @MaxRows    : limite (default 200)
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0704GetPlaidSyncLog
    @SinceHours INT = 168,
    @MaxRows    INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SinceDate DATETIME = DATEADD(HOUR, -@SinceHours, GETDATE());

    SELECT TOP (@MaxRows)
        l.Id,
        l.CompanyGUID,
        COALESCE(dbo.fParamS(l.CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(l.CompanyGUID)) AS CompanyName,
        l.ItemId,
        l.ErrorMessage,
        l.Created
    FROM dbo.T144PlaidSyncLog l
    WHERE l.Created >= @SinceDate
    ORDER BY l.Created DESC;
END
GO
