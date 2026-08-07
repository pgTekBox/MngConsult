/* =====================================================================
   PortailMaster / webAPI - Script 14 : pagination de s0034ListDeliveries
   ---------------------------------------------------------------------
   Ajoute @Limit / @Offset (OFFSET ... FETCH) pour l'endpoint API
   /webhook/deliveries. Retro-compatible : sans @Limit, on retombe sur
   @Top (defaut 50) => la page PortailMaster reste inchangee.
   A executer APRES 10.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0034ListDeliveries
    @AbonneId INT,
    @Top      INT = 50,
    @Limit    INT = NULL,
    @Offset   INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, EventType, PaymentId, Status, Attempts, MaxAttempts,
            ResponseStatus, LastError, NextAttemptUtc, CreatedUtc, DeliveredUtc
    FROM    dbo.T042WebhookDelivery
    WHERE   AbonneId = @AbonneId
    ORDER BY Id DESC
    OFFSET ISNULL(@Offset, 0) ROWS
    FETCH NEXT COALESCE(@Limit, @Top, 50) ROWS ONLY;
END
GO

PRINT N'14_deliveries_paging.sql : termine.';
GO
