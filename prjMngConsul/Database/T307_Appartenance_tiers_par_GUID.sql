-- =============================================================================
-- T307 — Contrôle d'appartenance : un tiers désigné par son PartyGUID
--
-- L'application mobile crée ses factures en envoyant le PartyGUID du client ou
-- du fournisseur. L'API doit vérifier que ce tiers est à la compagnie du jeton
-- avant de créer la facture : s0891 reçoit le type PARTYGUID.
-- Le reste de la procédure est celui de T306.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0891AppartientCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Type        VARCHAR(20),               -- PARTY, PARTYGUID, ADRESSE, DOCUMENT, ECRITURE, TEMPLATE, PRODUIT, COMPTE, PARAM, IMPORT, RECU
    @Id          INT              = NULL,
    @Guid        UNIQUEIDENTIFIER = NULL    -- pour RECU (imageGUID) et PARTYGUID (PartyGUID)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Ok BIT = 0;

    -- Une compagnie absente ou vide ne possède rien.
    IF @CompanyGUID IS NOT NULL AND @CompanyGUID <> '00000000-0000-0000-0000-000000000000'
    BEGIN
        IF @Type = 'PARTY'    AND EXISTS (SELECT 1 FROM dbo.T050Party             WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'ADRESSE'  AND EXISTS (SELECT 1 FROM dbo.T054PartyAddress a
                                            JOIN dbo.T050Party p ON p.[Id] = a.[PartyId]
                                           WHERE a.[Id] = @Id AND p.[CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'DOCUMENT' AND EXISTS (SELECT 1 FROM dbo.T060Document          WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'ECRITURE' AND EXISTS (SELECT 1 FROM dbo.T135Ecritures         WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'TEMPLATE' AND EXISTS (SELECT 1 FROM dbo.T138EcrituresTemplate WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'PRODUIT'  AND EXISTS (SELECT 1 FROM dbo.T075Products          WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'COMPTE'   AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable     WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'PARAM'    AND EXISTS (SELECT 1 FROM dbo.T101ParamValues       WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'IMPORT'   AND EXISTS (SELECT 1 FROM staging.ImportFiles       WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'RECU'     AND EXISTS (SELECT 1 FROM dbo.T0001Receipt          WHERE [imageGUID] = @Guid AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'PARTYGUID' AND EXISTS (SELECT 1 FROM dbo.T050Party         WHERE [PartyGUID] = @Guid AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
    END

    SELECT @Ok AS Ok;
END
GO

PRINT 'T307_Appartenance_tiers_par_GUID.sql : terminé.';
