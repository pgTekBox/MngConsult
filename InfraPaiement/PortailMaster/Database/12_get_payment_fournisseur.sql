/* =====================================================================
   PortailMaster / webAPI - Script 12 : s0025GetPayment + nom fournisseur
   ---------------------------------------------------------------------
   Ajoute FournisseurNom au detail d'un paiement (utile pour l'API payouts
   et le payload des webhooks payout.*). Retro-compatible.
   A executer APRES 11. Pas de nouvelle proc.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0025GetPayment
    @PaymentId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  p.*, c.Nom AS ClientNom, f.Nom AS FournisseurNom
    FROM    dbo.T030Payment p
    LEFT JOIN dbo.T020Client c      ON c.Id = p.ClientId
    LEFT JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE   p.Id = @PaymentId;
END
GO

PRINT N'12_get_payment_fournisseur.sql : termine.';
GO
