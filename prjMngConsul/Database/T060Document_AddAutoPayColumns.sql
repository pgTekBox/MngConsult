-- =============================================================================
-- T060Document : ajout des colonnes AutoPay (paiement automatique fournisseur)
--
-- AutoPay              BIT          : 1 = la facture est en auto-paiement
-- AutoPayDate          DATE         : date prevue du debit (typiquement = DueDate)
-- AutoPayStatus        VARCHAR(20)  : PLANIFIE / EN_COURS / PAYE / ECHEC / ANNULE / REQUIRES_3DS
-- AutoPayAttempts      INT          : nombre de tentatives effectuees (max 3)
-- AutoPayAuthorizationId INT        : FK vers T144AuthorizationAutoPay
-- AutoPayPreavisSentDate DATETIME   : date d'envoi du preavis 24h (null si non envoye)
-- AutoPayPadPreavisSentDate DATETIME : date d'envoi du preavis PAD 3-jours (null si non envoye ou n/a)
--
-- Idempotent : verifie l'existence avant chaque ALTER.
-- =============================================================================

USE [MngConsul];
GO

-- AutoPay
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPay'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPay BIT NOT NULL DEFAULT 0;
    PRINT 'Colonne AutoPay ajoutee.';
END
GO

-- AutoPayDate
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPayDate'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPayDate DATE NULL;
    PRINT 'Colonne AutoPayDate ajoutee.';
END
GO

-- AutoPayStatus
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPayStatus'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPayStatus VARCHAR(20) NULL;
    PRINT 'Colonne AutoPayStatus ajoutee.';
END
GO

-- Contrainte CHECK sur AutoPayStatus
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'chk_T060_AutoPayStatus'
)
BEGIN
    ALTER TABLE dbo.T060Document
        ADD CONSTRAINT chk_T060_AutoPayStatus CHECK (
            AutoPayStatus IS NULL
            OR AutoPayStatus IN ('PLANIFIE','EN_COURS','PAYE','ECHEC','ANNULE','REQUIRES_3DS')
        );
    PRINT 'Contrainte chk_T060_AutoPayStatus ajoutee.';
END
GO

-- AutoPayAttempts
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPayAttempts'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPayAttempts INT NOT NULL DEFAULT 0;
    PRINT 'Colonne AutoPayAttempts ajoutee.';
END
GO

-- AutoPayAuthorizationId
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPayAuthorizationId'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPayAuthorizationId INT NULL;
    PRINT 'Colonne AutoPayAuthorizationId ajoutee.';
END
GO

-- AutoPayPreavisSentDate
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPayPreavisSentDate'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPayPreavisSentDate DATETIME NULL;
    PRINT 'Colonne AutoPayPreavisSentDate ajoutee.';
END
GO

-- AutoPayPadPreavisSentDate
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'T060Document' AND COLUMN_NAME = 'AutoPayPadPreavisSentDate'
)
BEGIN
    ALTER TABLE dbo.T060Document ADD AutoPayPadPreavisSentDate DATETIME NULL;
    PRINT 'Colonne AutoPayPadPreavisSentDate ajoutee.';
END
GO

-- Index pour le scheduler (recuperation des factures dues)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE name = 'IX_T060_AutoPayScheduler' AND object_id = OBJECT_ID('dbo.T060Document')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_T060_AutoPayScheduler
        ON dbo.T060Document (AutoPayStatus, AutoPayDate)
        INCLUDE (CompanyGUID, PartyGUID, Total, AutoPayAttempts, AutoPayAuthorizationId)
        WHERE AutoPay = 1;
    PRINT 'Index IX_T060_AutoPayScheduler cree.';
END
GO

PRINT 'Migration T060Document AutoPay terminee.';
GO
