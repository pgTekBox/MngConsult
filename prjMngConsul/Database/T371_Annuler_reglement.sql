-- =============================================================================
-- T371 — Annuler un règlement (encaissement ou paiement)
--
-- s0992AnnulerReglement défait un règlement enregistré par erreur :
--   - T140Reglement.Statut = 'ANNULE' : il ne compte plus dans le « déjà reçu /
--     déjà payé » des factures (vwCustomersInvoices, s0023… excluent ANNULE),
--     la facture redevient ouverte ;
--   - son écriture passe 'EXTOURNEE' : les états financiers, le grand livre,
--     la balance et la conciliation ne comptent que les écritures VALIDEE ;
--     elle reste visible au Journal général avec le badge « Extournée » ;
--   - le lettrage posé par le règlement est retiré (ligne de l'écriture du
--     règlement, et ligne client/fournisseur de la facture si plus aucun
--     règlement actif ne la touche).
-- Refusé si le règlement est relié à une ligne du relevé bancaire (le délier
-- d'abord) ou si sa période comptable est clôturée.
--
-- Exécuté à la création : annulation de ENC-000054, 55 et 56 (Massothérapie
-- Sérénité), trois « Encaisser et relier » du 2026-11-10 faits sur le même
-- dépôt SIM-J20261001-TPV puis déliés, demandée par l'utilisateur.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0992AnnulerReglement
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReglementId INT,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Statut VARCHAR(20), @EcrituresId INT;
    SELECT @Statut = Statut, @EcrituresId = EcrituresId
    FROM dbo.T140Reglement WHERE Id = @ReglementId AND CompanyGUID = @CompanyGUID;

    IF @Statut IS NULL THROW 51080, 'Règlement introuvable.', 1;
    IF @Statut = 'ANNULE' THROW 51081, 'Ce règlement est déjà annulé.', 1;
    IF EXISTS (SELECT 1 FROM dbo.T208ReleveLien WHERE ReglementId = @ReglementId)
        THROW 51082, 'Ce règlement est relié au relevé bancaire : déliez-le d''abord.', 1;
    IF @EcrituresId IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.T135Ecritures e
        JOIN dbo.T112Periodes p ON p.id = e.PeriodeId
        JOIN dbo.T111Exercices ex ON ex.id = p.exercice_id
        WHERE e.Id = @EcrituresId AND (p.statut <> 'OUVERTE' OR ex.statut <> 'OUVERT'))
        THROW 51083, 'La période comptable du règlement est clôturée.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Lettrage de l'écriture du règlement
        IF @EcrituresId IS NOT NULL
            UPDATE dbo.T136LignesEcriture SET LettreCode = NULL, LettreDate = NULL
            WHERE EcrituresId = @EcrituresId AND LettreCode IS NOT NULL;

        UPDATE dbo.T140Reglement SET Statut = 'ANNULE'
        WHERE Id = @ReglementId AND CompanyGUID = @CompanyGUID;

        -- Lettrage de la facture : seulement si plus aucun règlement actif ne la touche
        UPDATE le SET LettreCode = NULL, LettreDate = NULL
        FROM dbo.T141ReglementDocument rd
        JOIN dbo.T137DocumentEcriture de ON de.DocumentId = rd.DocumentId AND de.CompanyGUID = @CompanyGUID
                                         AND de.TypeEcriture = 'COMPTABILISATION'
        JOIN dbo.T136LignesEcriture le ON le.EcrituresId = de.EcrituresId AND le.LettreCode = rd.LettreCode
        WHERE rd.ReglementId = @ReglementId
          AND NOT EXISTS (SELECT 1 FROM dbo.T141ReglementDocument x
                          JOIN dbo.T140Reglement r ON r.Id = x.ReglementId
                          WHERE x.DocumentId = rd.DocumentId AND r.Statut <> 'ANNULE');

        -- L'écriture sort des livres (VALIDEE seulement dans les états)
        IF @EcrituresId IS NOT NULL
            UPDATE dbo.T135Ecritures SET Statut = 'EXTOURNEE'
            WHERE Id = @EcrituresId AND CompanyGUID = @CompanyGUID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH

    SELECT @ReglementId AS ReglementId, @EcrituresId AS EcrituresId;
END
GO

-- Annulation demandée : ENC-000054, 55 et 56 de Massothérapie Sérénité
DECLARE @c UNIQUEIDENTIFIER = 'd2d2d2d2-0000-4000-8000-000000000002';
IF EXISTS (SELECT 1 FROM dbo.T140Reglement WHERE Id = 54 AND CompanyGUID = @c AND Statut <> 'ANNULE' AND Reference = 'SIM-J20261001-TPV')
    EXEC dbo.s0992AnnulerReglement @c, 54;
IF EXISTS (SELECT 1 FROM dbo.T140Reglement WHERE Id = 55 AND CompanyGUID = @c AND Statut <> 'ANNULE' AND Reference = 'SIM-J20261001-TPV')
    EXEC dbo.s0992AnnulerReglement @c, 55;
IF EXISTS (SELECT 1 FROM dbo.T140Reglement WHERE Id = 56 AND CompanyGUID = @c AND Statut <> 'ANNULE' AND Reference = 'SIM-J20261001-TPV')
    EXEC dbo.s0992AnnulerReglement @c, 56;
GO
