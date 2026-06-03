-- =============================================================================
-- s0070UpdatePartyLastPaymentMethod
-- Memorise la derniere methode de paiement utilisee pour un fournisseur.
-- Appelee depuis wbfSupplierPaymentChoice.aspx.vb lors du clic "Payer".
--
-- Methodes valides : 'card', 'interac_present', 'acss_debit'
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0070UpdatePartyLastPaymentMethod', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0070UpdatePartyLastPaymentMethod;
GO

CREATE PROCEDURE dbo.s0070UpdatePartyLastPaymentMethod
    @PartyId           INT,
    @LastPaymentMethod VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validation : methode reconnue
    IF @LastPaymentMethod NOT IN ('card', 'interac_present', 'acss_debit')
    BEGIN
        RAISERROR('Methode de paiement invalide. Valeurs acceptees : card, interac_present, acss_debit', 16, 1);
        RETURN;
    END

    UPDATE dbo.T050Party
    SET LastPaymentMethod = @LastPaymentMethod
    WHERE Id = @PartyId;
END
GO
