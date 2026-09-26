-- =============================================================================
-- T279 — Remettre la comptabilité d'une compagnie à zéro (Sec60Admin › Gestion des démos)
--
-- s0863ResetCompanyAccounting @CompanyGUID [, @ModifiedBy]
--
-- Efface les DONNÉES VIVANTES d'une compagnie pour repartir une comptabilité
-- neuve, et garde tout ce qu'il faut pour la démarrer :
--   GARDÉ : T010Company, T015User, T020Subscription, T100/T101 (paramètres),
--           T120/T121 (plan comptable), T130 (journaux), T111/T112 (exercices et
--           périodes — rouverts), T138/T139 (modèles d'écritures), T068/T069 (taxes),
--           T143 (banques Plaid connectées), T200-T204 (tâches), T300 (employés),
--           Appointments (rendez-vous, détachés de leur client), schéma paie.
--   EFFACÉ : clients et fournisseurs (T050, T054, T057), documents/factures et tout
--           ce qui s'y rattache (T060, T061, T062, T063, T071, T137, T141, T145),
--           compteurs de numérotation (T062DocumentNumberCounter), rapports de
--           taxes (T070), écritures (T135, T136), règlements (T140), relevé
--           bancaire (T142), journal Plaid (T144PlaidSyncLog), autorisations de
--           paiement automatique (T144), produits et catégories (T075, T076),
--           reçus (T0001, T0002), tables de préparation (staging, via s0790),
--           profil et conversations de l'assistant IA (T146, T147).
-- Garde-fous : jamais la compagnie modèle (…0001), jamais un GUID vide ou inconnu.
-- Transactionnel : tout ou rien. Rend le journal des suppressions puis un Message.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0863ResetCompanyAccounting
    @CompanyGUID uniqueidentifier,
    @ModifiedBy  nvarchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL OR @CompanyGUID = '00000000-0000-0000-0000-000000000000'
    BEGIN
        RAISERROR('CompanyGUID invalide.', 16, 1);
        RETURN;
    END
    IF @CompanyGUID = '00000000-0000-0000-0000-000000000001'
    BEGIN
        RAISERROR('La compagnie modèle (Template) ne peut pas être remise à zéro.', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID)
    BEGIN
        RAISERROR('Compagnie introuvable.', 16, 1);
        RETURN;
    END

    DECLARE @log TABLE (StepNo int IDENTITY(1,1), TableName sysname, RowsDeleted int);
    DECLARE @d uniqueidentifier = @CompanyGUID;

    -- Les reçus arrivés par courriel sans compagnie : on les rattache d'abord (T280), sinon ils resteraient.
    EXEC dbo.s0864AttribuerRecusCourriel @d;

    BEGIN TRY
        BEGIN TRAN;

        -- ===================== DOCUMENTS (factures, reçus, crédits) =====================
        DELETE FROM dbo.T071_T061DocumentLine_T070RapportTaxe
        WHERE T061DocumentLine_id IN (SELECT Id FROM dbo.T061DocumentLine
              WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d));
        INSERT @log VALUES ('T071_T061DocumentLine_T070RapportTaxe', @@ROWCOUNT);

        DELETE FROM dbo.T061DocumentLine
        WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T061DocumentLine', @@ROWCOUNT);

        DELETE FROM dbo.T062DocumentAddress
        WHERE DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T062DocumentAddress', @@ROWCOUNT);

        DELETE FROM dbo.T063DocumentPhoto WHERE CompanyGUID = @d
           OR DocumentId IN (SELECT Id FROM dbo.T060Document WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T063DocumentPhoto', @@ROWCOUNT);

        DELETE FROM dbo.T141ReglementDocument
        WHERE DocumentId  IN (SELECT Id FROM dbo.T060Document  WHERE CompanyGUID = @d)
           OR ReglementId IN (SELECT Id FROM dbo.T140Reglement WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T141ReglementDocument', @@ROWCOUNT);

        DELETE FROM dbo.T145AutoPayAttempt WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T145AutoPayAttempt', @@ROWCOUNT);

        DELETE FROM dbo.T137DocumentEcriture WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T137DocumentEcriture', @@ROWCOUNT);

        DELETE FROM dbo.T060Document WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T060Document', @@ROWCOUNT);

        DELETE FROM dbo.T062DocumentNumberCounter WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T062DocumentNumberCounter', @@ROWCOUNT);

        DELETE FROM dbo.T070RapportTaxe WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T070RapportTaxe', @@ROWCOUNT);

        -- ===================== COMPTABILITÉ (écritures, règlements, relevé) =====================
        DELETE FROM dbo.T136LignesEcriture
        WHERE EcrituresId IN (SELECT Id FROM dbo.T135Ecritures WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T136LignesEcriture', @@ROWCOUNT);

        DELETE FROM dbo.T142ReleveBancaire WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T142ReleveBancaire', @@ROWCOUNT);

        DELETE FROM dbo.T140Reglement WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T140Reglement', @@ROWCOUNT);

        DELETE FROM dbo.T135Ecritures WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T135Ecritures', @@ROWCOUNT);

        DELETE FROM dbo.T144PlaidSyncLog WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T144PlaidSyncLog', @@ROWCOUNT);

        -- Les exercices et périodes restent, mais rouverts : une comptabilité neuve doit pouvoir y écrire.
        UPDATE dbo.T112Periodes SET statut = 'OUVERTE' WHERE CompanyGUID = @d AND statut <> 'OUVERTE';
        INSERT @log VALUES ('T112Periodes (rouvertes)', @@ROWCOUNT);
        UPDATE dbo.T111Exercices SET statut = 'OUVERT' WHERE CompanyGUID = @d AND statut <> 'OUVERT';
        INSERT @log VALUES ('T111Exercices (rouverts)', @@ROWCOUNT);

        -- ===================== PRODUITS =====================
        DELETE FROM dbo.T075Products WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T075Products', @@ROWCOUNT);

        DELETE FROM dbo.T076ProductCategory WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T076ProductCategory', @@ROWCOUNT);

        -- ===================== TIERS (clients et fournisseurs) =====================
        DELETE FROM dbo.T144AuthorizationAutoPay WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T144AuthorizationAutoPay', @@ROWCOUNT);

        DELETE FROM dbo.T057PartyDocument WHERE CompanyGUID = @d
           OR PartyId IN (SELECT Id FROM dbo.T050Party WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T057PartyDocument', @@ROWCOUNT);

        DELETE FROM dbo.T054PartyAddress
        WHERE PartyId IN (SELECT Id FROM dbo.T050Party WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T054PartyAddress', @@ROWCOUNT);

        -- Les rendez-vous restent, détachés du client qui disparaît.
        UPDATE dbo.Appointments SET CustomerId = NULL
        WHERE CompanyGUID = @d AND CustomerId IS NOT NULL;
        INSERT @log VALUES ('Appointments (client détaché)', @@ROWCOUNT);

        DELETE FROM dbo.T050Party WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T050Party', @@ROWCOUNT);

        -- ===================== REÇUS =====================
        DELETE FROM dbo.T0002ReceiptProcessLog
        WHERE ReceiptId IN (SELECT Id FROM dbo.T0001Receipt WHERE CompanyGUID = @d);
        INSERT @log VALUES ('T0002ReceiptProcessLog', @@ROWCOUNT);

        DELETE FROM dbo.T0001Receipt WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T0001Receipt', @@ROWCOUNT);

        -- ===================== ASSISTANT IA =====================
        DELETE FROM dbo.T147AssistantConversation WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T147AssistantConversation', @@ROWCOUNT);
        DELETE FROM dbo.T146AssistantProfil WHERE CompanyGUID = @d;
        INSERT @log VALUES ('T146AssistantProfil', @@ROWCOUNT);

        -- ===================== PRÉPARATION (staging) =====================
        -- La proc de l'écran Importations sait vider toutes les tables de préparation de la compagnie.
        IF OBJECT_ID(N'dbo.s0790ViderStaging') IS NOT NULL
        BEGIN
            -- Ses jeux de résultats (tables vidées, total) précèdent les nôtres ; la page lit la table qui porte « Message ».
            EXEC dbo.s0790ViderStaging @CompanyGUID = @d;
            INSERT @log VALUES ('staging.* (s0790ViderStaging)', 0);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH

    SELECT StepNo, TableName, RowsDeleted FROM @log ORDER BY StepNo;

    SELECT N'Comptabilité remise à zéro : ' + CAST((SELECT ISNULL(SUM(RowsDeleted), 0) FROM @log) AS nvarchar(20))
         + N' ligne(s) effacée(s). Plan comptable, journaux, exercices, taxes, paramètres, utilisateurs et employés conservés.' AS Message;
END
GO

PRINT N'T279_Remise_a_zero_comptabilite.sql : terminé.';
