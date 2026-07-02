-- =============================================================================
-- SquareResetSandboxData
-- Purge des donnees Square SANDBOX avant le 1er usage en PRODUCTION.
-- A executer UNE FOIS au moment du basculement Square.Environment=production.
--
-- Pourquoi : les identifiants Square crees en sandbox (tokens OAuth, ids
-- catalogue, ids clients) n'existent PAS dans l'environnement de production.
-- On les remet a NULL pour que :
--   - chaque abonne se reconnecte via OAuth (nouveaux tokens prod) ;
--   - l'export catalogue RECREE les produits dans le compte prod ;
--   - l'export clients RECREE les Square Customers dans le compte prod.
--
-- Portee : par defaut TOUTES les compagnies (@CompanyGUID = NULL).
--          Mettre un GUID precis pour ne purger qu'un seul abonne.
--
-- Script manuel (pas une proc app) : reversible-friendly, affiche les comptes.
-- Lance-le dans une transaction explicite si tu veux pouvoir annuler.
-- =============================================================================

USE [MngConsul];
GO

-- Requis pour UPDATE sur des tables a index filtre (ex. IX_T050Party_StripeAccountId).
-- sqlcmd met QUOTED_IDENTIFIER OFF par defaut, d'ou cette ligne explicite.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;

DECLARE @CompanyGUID UNIQUEIDENTIFIER = NULL;   -- NULL = toutes les compagnies

DECLARE @Companies INT = 0, @Products INT = 0, @Clients INT = 0;

-- ── 1. Tokens OAuth + location sur T010Company ──────────────────────────────
UPDATE dbo.T010Company
SET SquareMerchantId      = NULL,
    SquareAccessTokenEnc  = NULL,
    SquareRefreshTokenEnc = NULL,
    SquareTokenExpiresAt  = NULL,
    SquareLocationId      = NULL,
    SquareConnectedDate   = NULL
WHERE (@CompanyGUID IS NULL OR CompanyGUID = @CompanyGUID)
  AND (SquareMerchantId IS NOT NULL
       OR SquareAccessTokenEnc IS NOT NULL
       OR SquareRefreshTokenEnc IS NOT NULL
       OR SquareLocationId IS NOT NULL);
SET @Companies = @@ROWCOUNT;

-- ── 2. Ids catalogue sur T075Products ───────────────────────────────────────
UPDATE dbo.T075Products
SET SquareItemId           = NULL,
    SquareVariationId      = NULL,
    SquareItemVersion      = NULL,
    SquareVariationVersion = NULL,
    SquareSyncStatus       = NULL,
    SquareSyncDate         = NULL
WHERE (@CompanyGUID IS NULL OR CompanyGUID = @CompanyGUID)
  AND (SquareItemId IS NOT NULL OR SquareVariationId IS NOT NULL);
SET @Products = @@ROWCOUNT;

-- ── 3. Ids clients sur T050Party ────────────────────────────────────────────
UPDATE dbo.T050Party
SET SquareCustomerId      = NULL,
    SquareCustomerVersion = NULL,
    SquareSyncStatus      = NULL,
    SquareSyncDate        = NULL
WHERE (@CompanyGUID IS NULL OR CompanyGUID = @CompanyGUID)
  AND SquareCustomerId IS NOT NULL;
SET @Clients = @@ROWCOUNT;

PRINT 'Purge Square sandbox terminee.';
PRINT '  T010Company (tokens OAuth) remis a NULL : ' + CAST(@Companies AS VARCHAR(10));
PRINT '  T075Products (ids catalogue) remis a NULL : ' + CAST(@Products AS VARCHAR(10));
PRINT '  T050Party (ids clients) remis a NULL : ' + CAST(@Clients AS VARCHAR(10));
GO
