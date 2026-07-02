-- =============================================================================
-- T060Document_AddSquareColumns.sql
-- Sens ENTRANT Square -> app (factures + paiements). Ajoute les colonnes Square
-- sur T060Document (entete facture) pour rapatrier les factures (Invoices API)
-- ET les paiements (Payments API) comme Factures Clients (DocumentTypeId=1).
--
-- Cle d'unification = SquareOrderId (present a la fois sur les Invoices et les
-- Payments Square : une facture et son paiement partagent le meme order_id).
-- SquareInvoiceId = repli quand l'order_id manque. SquarePaymentId = paiement
-- rapproche. Idempotent : verifie l'existence de chaque colonne avant ALTER.
--
-- Cree aussi le type TVP_SquareInvoiceLine pour passer les lignes de la facture
-- Square (issues de l'Order) a la proc s0671UpsertInvoiceFromSquare.
-- =============================================================================

USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ── Colonnes Square sur T060Document ────────────────────────────────────────
IF COL_LENGTH('dbo.T060Document', 'SquareInvoiceId') IS NULL
    ALTER TABLE dbo.T060Document ADD SquareInvoiceId VARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'SquareInvoiceVersion') IS NULL
    ALTER TABLE dbo.T060Document ADD SquareInvoiceVersion BIGINT NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'SquareOrderId') IS NULL
    ALTER TABLE dbo.T060Document ADD SquareOrderId VARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'SquarePaymentId') IS NULL
    ALTER TABLE dbo.T060Document ADD SquarePaymentId VARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'SquareSyncStatus') IS NULL
    ALTER TABLE dbo.T060Document ADD SquareSyncStatus VARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.T060Document', 'SquareSyncDate') IS NULL
    ALTER TABLE dbo.T060Document ADD SquareSyncDate DATETIME NULL;
GO

-- ── Index de rapprochement (filtres : seules les factures Square) ────────────
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T060Document_SquareOrderId' AND object_id = OBJECT_ID('dbo.T060Document'))
    CREATE NONCLUSTERED INDEX IX_T060Document_SquareOrderId
        ON dbo.T060Document (SquareOrderId) WHERE SquareOrderId IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T060Document_SquareInvoiceId' AND object_id = OBJECT_ID('dbo.T060Document'))
    CREATE NONCLUSTERED INDEX IX_T060Document_SquareInvoiceId
        ON dbo.T060Document (SquareInvoiceId) WHERE SquareInvoiceId IS NOT NULL;
GO

-- ── Type table-valued pour les lignes de facture Square ──────────────────────
IF TYPE_ID('dbo.TVP_SquareInvoiceLine') IS NOT NULL
    DROP TYPE dbo.TVP_SquareInvoiceLine;
GO
CREATE TYPE dbo.TVP_SquareInvoiceLine AS TABLE
(
    Ordre        INT            NULL,
    SquareItemId VARCHAR(100)   NULL,   -- pour relier la ligne au produit local (T075Products.SquareItemId)
    Description  NVARCHAR(1000) NULL,
    Qty          DECIMAL(18,4)  NULL,
    UnitPrice    DECIMAL(18,2)  NULL,
    Amount       DECIMAL(18,2)  NULL,   -- montant de ligne (hors taxes), autoritatif Square
    HasTax       BIT            NULL    -- 1 = ligne taxee dans Square -> TaxeStatus TAXABLE, sinon EXEMPT
);
GO
