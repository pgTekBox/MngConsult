-- =============================================================================
-- s0073GetPartyForOnboarding
-- Retourne les infos d'un fournisseur pour la page wbfSupplierStripeOnboarding :
-- Nom + Email (via T054PartyAddress) + StripeAccountId.
--
-- L'email est utilise pour l'invitation par courriel.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0073GetPartyForOnboarding', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0073GetPartyForOnboarding;
GO

CREATE PROCEDURE dbo.s0073GetPartyForOnboarding
    @PartyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        T050.Id,
        T050.Name,
        T050.DisplayName,
        T050.StripeAccountId,
        T050.LastPaymentMethod,
        -- Email du premier T054 disponible (peut etre null)
        (SELECT TOP 1 Email
         FROM dbo.T054PartyAddress T054
         WHERE T054.PartyId = T050.Id
           AND T054.Email IS NOT NULL
           AND T054.Email <> ''
         ORDER BY T054.Id) AS Email
    FROM dbo.T050Party T050
    WHERE T050.Id = @PartyId
      AND ISNULL(T050.isDeleted, 0) = 0;
END
GO
