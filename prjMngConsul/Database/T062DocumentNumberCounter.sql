-- =============================================================================
-- Compteur de numéros de document par compagnie / type / année.
--   Annee = 0  -> compteur unique (pas de réinitialisation annuelle)
--   Annee = AAAA -> un compteur par année (réinitialisation annuelle activée)
-- Alimenté par s0695GenerateInvoiceNumber à la comptabilisation.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.T062DocumentNumberCounter', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T062DocumentNumberCounter
    (
        CompanyGUID    UNIQUEIDENTIFIER NOT NULL,
        DocumentTypeId INT              NOT NULL,
        Annee          INT              NOT NULL,   -- 0 = pas de réinitialisation annuelle
        DernierNumero  INT              NOT NULL,
        CONSTRAINT PK_T062DocumentNumberCounter
            PRIMARY KEY (CompanyGUID, DocumentTypeId, Annee)
    );
END
GO
