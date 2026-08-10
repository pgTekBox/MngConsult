/* =====================================================================
   PortailABN - Script 25 : statut d'onboarding de l'abonne
   ---------------------------------------------------------------------
   Retourne en une ligne les compteurs necessaires a l'ecran de prise en
   main (« Demarrage ») du portail des abonnes : progression de la
   configuration initiale (clients, fournisseurs, coordonnees bancaires,
   cle d'API, webhook, premiere transaction). Scopee a l'AbonneId.

   A executer APRES 22-24. Proc numerotee s0073.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0073GetOnboardingStatus
    @AbonneId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Contreparties
        (SELECT COUNT(*) FROM dbo.T020Client      WHERE AbonneId = @AbonneId) AS ClientsCount,
        (SELECT COUNT(*) FROM dbo.T021Fournisseur WHERE AbonneId = @AbonneId) AS FournisseursCount,
        -- Contreparties « pretes EFT » (institution + transit + compte)
        (SELECT COUNT(*) FROM dbo.T020Client
          WHERE AbonneId = @AbonneId
            AND BankInstitution IS NOT NULL AND BankTransit IS NOT NULL AND BankAccount IS NOT NULL)
        +
        (SELECT COUNT(*) FROM dbo.T021Fournisseur
          WHERE AbonneId = @AbonneId
            AND BankInstitution IS NOT NULL AND BankTransit IS NOT NULL AND BankAccount IS NOT NULL)
                                                                             AS EftReadyCount,
        -- Cles d'API actives
        (SELECT COUNT(*) FROM dbo.T040ApiKey
          WHERE AbonneId = @AbonneId AND IsActive = 1)                       AS ActiveApiKeys,
        -- Webhook actif ?
        CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.T041WebhookEndpoint
                                WHERE AbonneId = @AbonneId AND IsActive = 1)
                  THEN 1 ELSE 0 END AS BIT)                                  AS HasWebhook,
        -- Premiere transaction (encaissement ou decaissement)
        (SELECT COUNT(*) FROM dbo.T030Payment WHERE AbonneId = @AbonneId)    AS TxnCount;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'25_onboarding.sql : termine.';
GO
