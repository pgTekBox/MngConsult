-- =============================================================================
-- s0665UpdateClientSquareId
-- Enregistre, sur T050Party, l'identifiant/version Square d'un client apres un
-- create/update reussi via l'API Customers. La version est indispensable pour
-- les mises a jour futures (l'API l'utilise pour la concurrence optimiste).
--
-- COALESCE : ne pas ecraser une valeur existante avec NULL si non fournie.
-- =============================================================================

USE [MngConsul];
GO

-- QUOTED_IDENTIFIER/ANSI_NULLS sont figes a la creation de la proc. Ils DOIVENT
-- etre ON car l'UPDATE porte sur T050Party qui a un index filtre
-- (IX_T050Party_StripeAccountId). Sinon : "UPDATE failed ... QUOTED_IDENTIFIER".
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0665UpdateClientSquareId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0665UpdateClientSquareId;
GO

CREATE PROCEDURE dbo.s0665UpdateClientSquareId
    @CompanyGUID           UNIQUEIDENTIFIER,
    @PartyId               INT,
    @SquareCustomerId      VARCHAR(100) = NULL,
    @SquareCustomerVersion BIGINT       = NULL,
    @Status                VARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T050Party
    SET SquareCustomerId      = COALESCE(@SquareCustomerId, SquareCustomerId),
        SquareCustomerVersion = COALESCE(@SquareCustomerVersion, SquareCustomerVersion),
        SquareSyncStatus      = @Status,
        SquareSyncDate        = GETDATE()
    WHERE CompanyGUID = @CompanyGUID
      AND Id = @PartyId;
END
GO
