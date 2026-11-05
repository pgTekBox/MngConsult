-- =============================================================================
-- T359 — Facturer un RDV depuis le tableau de bord (comptabiliser le brouillon)
--
-- Le bouton « Facturer » de la boîte « Aujourd'hui » doit COMPTABILISER
-- directement le brouillon lié au RDV (créer la facture), pas seulement
-- l'ouvrir. s0972ComptabiliserFactureCompagnie valide que le document
-- appartient à la compagnie de session, puis appelle sp_ComptabiliserDocument.
-- Renvoie le numéro définitif en sortie (@Numero).
--
-- Codes d'erreur (THROW, lus par le handler ComptabiliserFacture.ashx) :
--   51001 = facture introuvable pour cette compagnie
--   51002 = CLIENT_REQUIS (brouillon sans client → l'app ouvre le brouillon)
--   50001-50011 = erreurs de sp_ComptabiliserDocument (période fermée, etc.)
-- Idempotent : un document déjà COMPTABILISE renvoie son numéro sans erreur.
-- =============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0972ComptabiliserFactureCompagnie
    @DocumentId  INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = 1,
    @Numero      VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Numero = '';

    -- Le document doit être une facture client (type 1) de CETTE compagnie.
    IF NOT EXISTS (SELECT 1 FROM dbo.T060Document
                   WHERE Id = @DocumentId AND CompanyGUID = @CompanyGUID AND DocumentTypeId = 1)
        THROW 51001, 'Facture introuvable pour cette compagnie.', 1;

    -- Déjà comptabilisé : idempotent, on renvoie simplement son numéro.
    IF EXISTS (SELECT 1 FROM dbo.T060Document
               WHERE Id = @DocumentId AND ComptabilisationStatus = 'COMPTABILISE')
    BEGIN
        SELECT @Numero = DocumentNumber FROM dbo.T060Document WHERE Id = @DocumentId;
        RETURN;
    END

    -- Sans client, la comptabilisation échouerait (sp THROW 50003) : on remonte
    -- un code dédié pour que l'app ouvre le brouillon à compléter.
    IF EXISTS (SELECT 1 FROM dbo.T060Document WHERE Id = @DocumentId AND PartyGUID IS NULL)
        THROW 51002, 'CLIENT_REQUIS', 1;

    -- Comptabilise (génère le numéro définitif, les dates et les écritures).
    EXEC dbo.sp_ComptabiliserDocument @DocumentId, @UserId;

    SELECT @Numero = DocumentNumber FROM dbo.T060Document WHERE Id = @DocumentId;
END
GO
