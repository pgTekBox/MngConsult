SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0707UpdateSupplierInvoiceRefs
-- Persiste les references d'une facture FOURNISSEUR saisies dans wbfSupplierInvoinceEdit :
--   @RefNo    -> T060Document.DocumentNumber (numero de reference du fournisseur ;
--               seulement si non vide, pour ne pas ecraser une valeur existante)
--   @PoNumber -> T060Document.PoNumber (numero de bon de commande)
-- Appelee par le code-behind APRES s0040SaveInvoiceItems (qui renvoie l'InvoiceId),
-- pour eviter de modifier la proc de sauvegarde partagee client/fournisseur.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.s0707UpdateSupplierInvoiceRefs
    @InvoiceId INT,
    @RefNo     VARCHAR(200) = NULL,
    @PoNumber  VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T060Document
    SET DocumentNumber = CASE
                             WHEN NULLIF(LTRIM(RTRIM(@RefNo)), '') IS NOT NULL THEN @RefNo
                             ELSE DocumentNumber
                         END,
        PoNumber       = @PoNumber
    WHERE Id = @InvoiceId;
END
GO
