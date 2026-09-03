SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================
-- sp_ComptabiliserDocument — Version v5
-- Adapté au nouveau plan comptable (numéros corrigés)
--
-- TABLE INCHANGÉE : T121PlanComptable, colonne [Compte]
-- SEULS les numéros de comptes sont mis à jour :
--
--   Ancien → Nouveau   Description
--   1020   → 1010      Banque - Compte chèques
--   1100   → 1100      Comptes clients (INCHANGÉ)
--   1200   → 1450      TPS à recevoir
--   1205   → 1460      TVQ à recevoir
--   3010   → 2000      Comptes fournisseurs
--   3100   → 2200      TPS à payer
--   3105   → 2210      TVQ à payer
--   6020   → 4000      Ventes de produits (fallback revenus)
--   7010   → 5000      Achats de marchandises (fallback charges)
-- ============================================================
--    sp_ComptabiliserDocument 92
CREATE OR ALTER PROCEDURE [dbo].[sp_ComptabiliserDocument]
    @DocumentId   INT,
    @UserId       INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY

        -- ── Variables en-tête ──────────────────────────────────
        DECLARE
            @CompanyGUID        UNIQUEIDENTIFIER,
            @PartyId            INT,
            @DocumentTypeId     INT,
            @DocumentDate       DATE,
            @DocumentNumber     VARCHAR(200),
            @DejaCompta         VARCHAR(20),
            @TypeOperation      VARCHAR(20),
            @JournalType        VARCHAR(20),
            @TypeEcriture       VARCHAR(20),
            @JournauxId         INT,
            @PeriodeId          INT,
            @EcrituresId        INT;

        -- ── Montants globaux depuis T060Document (Option A) ────
        DECLARE
            @SubTotal           DECIMAL(15,2),
            @TPS_Doc            DECIMAL(15,2),
            @TVQ_Doc            DECIMAL(15,2),
            @TotalTTC           DECIMAL(15,2),
            @TotalTTCAbs        DECIMAL(15,2);

        -- ── Variables par ligne ────────────────────────────────
        DECLARE
            @LineId             INT,
            @Description        VARCHAR(1000),
            @Amount             DECIMAL(15,4),
            @AmountAbs          DECIMAL(15,4),
            @TaxeStatus         INT,
            @CompteNumero       VARCHAR(20),
            @CompteHtId         INT,
            @EstNegatif         BIT,
            @SensInverse        BIT,
            @DebitHT            DECIMAL(15,2),
            @CreditHT           DECIMAL(15,2),
            @Ordre              INT;

        -- ── Variables comptes ──────────────────────────────────
        DECLARE
            @CompteClientId     INT,
            @CompteFournId      INT,
            @CompteTPS_VId      INT,
            @CompteQST_VId      INT,
            @CompteTPS_AId      INT,
            @CompteQST_AId      INT,
            @CompteRevenuId     INT,
            @CompteChargeId     INT,
            @CompteBankId       INT,
            @CompteTiersId      INT,
            @SensTiers          BIT;

        -- ----------------------------------------------------
        -- 1. Récupère l'en-tête + montants de T060Document
        -- ----------------------------------------------------
        SELECT
            @CompanyGUID    = d.[CompanyGUID],
            @DocumentTypeId = d.[DocumentTypeId],
            @DocumentDate   = CAST(d.[DocumentDate] AS DATE),
            @DocumentNumber = d.[DocumentNumber],
            @DejaCompta     = d.[ComptabilisationStatus],
            @SubTotal       = CAST(ISNULL(d.[SubTotal], 0) AS DECIMAL(15,2)),
            @TPS_Doc        = CAST(ISNULL(d.[TPS],      0) AS DECIMAL(15,2)),
            @TVQ_Doc        = CAST(ISNULL(d.[TVQ],      0) AS DECIMAL(15,2)),
            @TotalTTC       = CAST(ISNULL(d.[Total],    0) AS DECIMAL(15,2)),
            @PartyId        = p.[Id]
        FROM [dbo].[T060Document] d
        LEFT JOIN [dbo].[T050Party] p ON p.[PartyGUID] = d.[PartyGUID]
        WHERE d.[Id] = @DocumentId;

        IF @@ROWCOUNT = 0
            THROW 50001, 'Document introuvable dans T060Document.', 1;

        IF @DejaCompta = 'COMPTABILISE'
            THROW 50002, 'Ce document est déjà comptabilisé.', 1;

        IF @PartyId IS NULL
            THROW 50003, 'Tiers introuvable dans T050Party.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[T061DocumentLine]
            WHERE [DocumentId] = @DocumentId
        )
            THROW 50004, 'Aucune ligne dans T061DocumentLine.', 1;

        IF ABS(@TotalTTC) = 0
            THROW 50005, 'Total TTC = 0 dans T060Document.', 1;

        IF ABS(@SubTotal + @TPS_Doc + @TVQ_Doc - @TotalTTC) > 0.02
            THROW 50006, 'Incohérence montants. Exécuter sp_RecalculerTotauxDocument.', 1;
        -- ----------------------------------------------------
        -- 1bis. Numéro officiel (factures clients) généré ICI, à la
        --       comptabilisation seulement. Remplace le numéro provisoire
        --       (BROUILLON-xxx ou Id) une seule fois, avant l'écriture au journal.
        -- ----------------------------------------------------
        DECLARE @DraftPrefix VARCHAR(20) =
            NULLIF(LTRIM(RTRIM(ISNULL(dbo.fParamS(@CompanyGUID, 'INV_DRAFT_PREFIX'), ''))), '');
        IF @DraftPrefix IS NULL SET @DraftPrefix = 'BRO';

        -- ----------------------------------------------------
        -- 1ter. Dates attribuees ICI, a la transformation en facture :
        --       un brouillon n'a ni date de facture ni date d'echeance.
        --         DocumentDate : aujourd'hui, si vide
        --         DueDate      : DocumentDate + delai du tiers
        --                        (T050Party.PaymentTermDays, 0 par defaut), si vide
        --       Une date deja saisie n'est jamais ecrasee.
        -- ----------------------------------------------------
        IF @DocumentDate IS NULL
        BEGIN
            SET @DocumentDate = CAST(GETDATE() AS DATE);
            UPDATE dbo.T060Document SET DocumentDate = @DocumentDate WHERE Id = @DocumentId;
        END

        IF EXISTS (SELECT 1 FROM dbo.T060Document WHERE Id = @DocumentId AND DueDate IS NULL)
        BEGIN
            DECLARE @TermDays INT = ISNULL((
                SELECT TOP 1 p.PaymentTermDays
                FROM dbo.T050Party p
                JOIN dbo.T060Document d ON d.PartyGUID = p.PartyGUID
                WHERE d.Id = @DocumentId), 0);
            IF @TermDays < 0 SET @TermDays = 0;

            UPDATE dbo.T060Document
               SET DueDate = DATEADD(DAY, @TermDays, CAST(@DocumentDate AS DATE))
             WHERE Id = @DocumentId;
        END

        IF @DocumentTypeId = 1
           AND (@DocumentNumber IS NULL
                OR @DocumentNumber LIKE 'BROUILLON-%'                                  -- ancien prefixe, documents deja en base
                OR LEFT(@DocumentNumber, LEN(@DraftPrefix) + 1) = @DraftPrefix + '-'   -- prefixe configure (LEFT : pas de joker LIKE)
                OR @DocumentNumber = CAST(@DocumentId AS VARCHAR(20)))
        BEGIN
            EXEC dbo.s0695GenerateInvoiceNumber
                 @CompanyGUID    = @CompanyGUID,
                 @DocumentTypeId = @DocumentTypeId,
                 @RefDate        = @DocumentDate,
                 @Number         = @DocumentNumber OUTPUT;

            UPDATE dbo.T060Document
               SET DocumentNumber = @DocumentNumber
             WHERE Id = @DocumentId;
        END

        -- ----------------------------------------------------
        -- 2. TypeOperation selon T065DocumentType
        -- ----------------------------------------------------
        SELECT
            @TypeOperation = CASE @DocumentTypeId
                WHEN 1 THEN 'VENTE'
                WHEN 2 THEN 'ACHAT'
                WHEN 3 THEN 'AVOIR_CLIENT'
                WHEN 4 THEN 'AVOIR_FOURN'
                WHEN 5 THEN 'ACHAT'
                WHEN 6 THEN 'DEPENSE'
                WHEN 9 THEN 'MANUEL'
                ELSE NULL
            END,
            @JournalType = CASE @DocumentTypeId
                WHEN 1 THEN 'VENTE'
                WHEN 2 THEN 'ACHAT'
                WHEN 3 THEN 'VENTE'
                WHEN 4 THEN 'ACHAT'
                WHEN 5 THEN 'ACHAT'
                WHEN 6 THEN 'BANQUE'
                WHEN 9 THEN 'OD'
                ELSE NULL
            END,
            @TypeEcriture = CASE @DocumentTypeId
                WHEN 3 THEN 'AVOIR'
                WHEN 4 THEN 'AVOIR'
                ELSE        'COMPTABILISATION'
            END;

        IF @TypeOperation IS NULL
            THROW 50007, 'DocumentTypeId non reconnu dans T065DocumentType.', 1;

        IF @TypeOperation = 'MANUEL'
            THROW 50008, 'Type Autre (Id=9) : saisie manuelle requise.', 1;

        -- ----------------------------------------------------
        -- 3. Journal dans T130Journaux
        -- ----------------------------------------------------
        SELECT TOP 1 @JournauxId = [Id]
        FROM [dbo].[T130Journaux]
        WHERE [Type]  = @JournalType AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END;

        IF @JournauxId IS NULL
            THROW 50009, 'Journal introuvable dans T130Journaux.', 1;

        -- ----------------------------------------------------
        -- 4. Période ouverte
        -- ----------------------------------------------------
        SELECT @PeriodeId = p.[id]
        FROM [dbo].[T112Periodes]  p
        JOIN [dbo].[T111Exercices] ex ON ex.[id] = p.[exercice_id]
        WHERE p.[mois]    = MONTH(@DocumentDate)
          AND ex.[annee]  = YEAR(@DocumentDate)
          AND p.[statut]  = 'OUVERTE'
          AND ex.[statut] = 'OUVERT';

        IF @PeriodeId IS NULL
            THROW 50010, 'Période comptable clôturée ou inexistante.', 1;

        -- ----------------------------------------------------
        -- 4b. Résout les comptes de toutes les lignes
        -- ----------------------------------------------------
        EXEC [dbo].[sp_ResoudreComptesDocument]
            @DocumentId = @DocumentId;

        -- ----------------------------------------------------
        -- 4c. Vérifie qu aucune ligne n a de compte manquant
        -- ----------------------------------------------------
        IF EXISTS (
            SELECT 1
            FROM [dbo].[T061DocumentLine]
            WHERE [DocumentId]      = @DocumentId
              AND [CompteComptable]  IS NULL
        )
            THROW 50011,
                'Certaines lignes n ont pas de compte comptable résolu. Vérifier les produits et catégories.',
                1;

        -- ----------------------------------------------------
        -- 5. Comptes fixes dans T121PlanComptable
        --    *** NUMÉROS MIS À JOUR ***
        -- ----------------------------------------------------

        -- 1100 Comptes clients (inchangé)
        SELECT @CompteClientId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '1100' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 2000 Comptes fournisseurs (était 3010)
        SELECT @CompteFournId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '2000' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 2200 TPS à payer (était 3100)[Id]
        SELECT @CompteTPS_VId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '2200' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 2210 TVQ à payer (était 3105)
        SELECT @CompteQST_VId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '2210' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 1450 TPS à recevoir (était 1200)
        SELECT @CompteTPS_AId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '1450' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 1460 TVQ à recevoir (était 1205)
        SELECT @CompteQST_AId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '1460' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 4000 Ventes de produits — fallback revenus (était 6020)
        SELECT @CompteRevenuId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '4000' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 5000 Achats de marchandises — fallback charges (était 7010)
        SELECT @CompteChargeId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '5000' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

        -- 1010 Banque - Compte chèques (était 1020)
        SELECT @CompteBankId = [Id] FROM [dbo].[T121PlanComptable]
        WHERE [Compte] = '1010' AND [Actif] = 1
          AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
        ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
        OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;
		-- --------------------------------------------------
		--    sp_ComptabiliserDocument 92
		--select @CompanyGUID,@JournauxId,@PeriodeId,
  --          @PartyId,@DocumentDate,@DocumentNumber,
  --          CASE @TypeOperation
  --              WHEN 'VENTE'        THEN 'Facture client — '
  --              WHEN 'ACHAT'        THEN 'Facture fournisseur — '
  --              WHEN 'AVOIR_CLIENT' THEN 'Avoir client — '
  --              WHEN 'AVOIR_FOURN'  THEN 'Avoir fournisseur — '
  --              WHEN 'DEPENSE'      THEN 'Dépense — '
  --          END + ISNULL(@DocumentNumber,''),
  --          'BROUILLON',
  --          CASE WHEN @TypeOperation IN ('VENTE','AVOIR_CLIENT')
  --               THEN 'FACTURE_CLIENT'
  --               ELSE 'FACTURE_FOURN'
  --          END,
  --          @DocumentId,GETDATE(),@UserId
		--	rollback 
		--return 
        -- ----------------------------------------------------
        -- 6. Crée l'en-tête dans T135Ecritures
        -- ----------------------------------------------------
        INSERT INTO [dbo].[T135Ecritures] (
            [EcrituresGUID],[CompanyGUID],[JournauxId],[PeriodeId],
            [PartyId],[DateEcriture],[NumeroPiece],[Libelle],
            [Statut],[SourceType],[SourceId],[Created],[CreatedBy]
        )
        VALUES (
            NEWID(),@CompanyGUID,@JournauxId,@PeriodeId,
            @PartyId,@DocumentDate,@DocumentNumber,
            CASE @TypeOperation
                WHEN 'VENTE'        THEN 'Facture client — '
                WHEN 'ACHAT'        THEN 'Facture fournisseur — '
                WHEN 'AVOIR_CLIENT' THEN 'Avoir client — '
                WHEN 'AVOIR_FOURN'  THEN 'Avoir fournisseur — '
                WHEN 'DEPENSE'      THEN 'Dépense — '
            END + ISNULL(@DocumentNumber,''),
            'BROUILLON',
            CASE WHEN @TypeOperation IN ('VENTE','AVOIR_CLIENT')
                 THEN 'FACTURE_CLIENT'
                 ELSE 'FACTURE_FOURN'
            END,
            @DocumentId,GETDATE(),@UserId
        );
        SET @EcrituresId = SCOPE_IDENTITY();
        SET @Ordre = 1;
		
        -- ----------------------------------------------------
        -- 7. Ligne tiers — ordre 0, ABS(TotalTTC)
        -- ----------------------------------------------------
        SET @TotalTTCAbs = ABS(@TotalTTC);

        SET @CompteTiersId = CASE
            WHEN @TypeOperation IN ('VENTE','AVOIR_CLIENT') THEN @CompteClientId
            WHEN @TypeOperation IN ('ACHAT','AVOIR_FOURN')  THEN @CompteFournId
            WHEN @TypeOperation = 'DEPENSE'                 THEN @CompteBankId
        END;

        SET @SensTiers = CASE
            WHEN @TypeOperation = 'VENTE'        AND @TotalTTC >= 0 THEN 0
            WHEN @TypeOperation = 'VENTE'        AND @TotalTTC <  0 THEN 1
            WHEN @TypeOperation = 'AVOIR_CLIENT' AND @TotalTTC >= 0 THEN 1
            WHEN @TypeOperation = 'AVOIR_CLIENT' AND @TotalTTC <  0 THEN 0
            WHEN @TypeOperation = 'ACHAT'        AND @TotalTTC >= 0 THEN 1
            WHEN @TypeOperation = 'ACHAT'        AND @TotalTTC <  0 THEN 0
            WHEN @TypeOperation = 'AVOIR_FOURN'  AND @TotalTTC >= 0 THEN 0
            WHEN @TypeOperation = 'AVOIR_FOURN'  AND @TotalTTC <  0 THEN 1
            WHEN @TypeOperation = 'DEPENSE'                          THEN 1
            ELSE 0
        END;

        INSERT INTO [dbo].[T136LignesEcriture] (
            [LignesEcritureGUID],[EcrituresId],[PlanComptableId],
            [PartyId],[Libelle],[MontantDebit],[MontantCredit],
            [Ordre],[Created],[CreatedBy]
        )
        VALUES (
            NEWID(),@EcrituresId,@CompteTiersId,@PartyId,
            CASE @TypeOperation
                WHEN 'VENTE'        THEN 'Créance — '
                WHEN 'AVOIR_CLIENT' THEN 'Avoir — '
                WHEN 'ACHAT'        THEN 'Dette — '
                WHEN 'AVOIR_FOURN'  THEN 'Avoir fourn. — '
                WHEN 'DEPENSE'      THEN 'Dépense — '
            END + ISNULL(@DocumentNumber,''),
            CASE @SensTiers WHEN 0 THEN @TotalTTCAbs ELSE 0 END,
            CASE @SensTiers WHEN 1 THEN @TotalTTCAbs ELSE 0 END,
            0,GETDATE(),@UserId
        );

        -- ----------------------------------------------------
        -- 8. Lignes HT — curseur sur T061DocumentLine
        --    *** FALLBACK NUMÉROS MIS À JOUR ***
        -- ----------------------------------------------------
        DECLARE cur_lines CURSOR FOR
            SELECT
                l.[Id],
                l.[Description],
                CAST(ISNULL(l.[Amount], 0) AS DECIMAL(15,4)),
                l.[TaxeStatus],
                ISNULL(
                    l.[CompteComptable],
                    CASE @TypeOperation
                        WHEN 'VENTE'        THEN '4000'   -- était 6020
                        WHEN 'AVOIR_CLIENT' THEN '4000'   -- était 6020
                        ELSE '5000'                        -- était 7010
                    END
                ) AS CompteNumero
            FROM [dbo].[T061DocumentLine] l
            WHERE l.[DocumentId] = @DocumentId
            ORDER BY l.[Id];

        OPEN cur_lines;
        FETCH NEXT FROM cur_lines INTO
            @LineId,@Description,@Amount,@TaxeStatus,@CompteNumero;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @AmountAbs  = ABS(@Amount);
            SET @EstNegatif = CASE WHEN @Amount < 0 THEN 1 ELSE 0 END;

            IF @AmountAbs > 0
            BEGIN
                SELECT @CompteHtId = [Id]
                FROM [dbo].[T121PlanComptable]
                WHERE [Compte] = @CompteNumero AND [Actif] = 1
                  AND ([CompanyGUID] = @CompanyGUID OR [CompanyGUID] IS NULL)
                ORDER BY CASE WHEN [CompanyGUID] = @CompanyGUID THEN 0 ELSE 1 END
                OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

                IF @CompteHtId IS NULL
                    SET @CompteHtId = CASE
                        WHEN @TypeOperation IN ('VENTE','AVOIR_CLIENT')
                        THEN @CompteRevenuId
                        ELSE @CompteChargeId
                    END;

                SET @SensInverse = CASE
                    WHEN @TypeOperation = 'VENTE'
                     AND @EstNegatif = 0 THEN 0
                    WHEN @TypeOperation = 'VENTE'
                     AND @EstNegatif = 1 THEN 1
                    WHEN @TypeOperation = 'AVOIR_CLIENT'
                     AND @EstNegatif = 0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_CLIENT'
                     AND @EstNegatif = 1 THEN 0
                    WHEN @TypeOperation IN ('ACHAT','DEPENSE')
                     AND @EstNegatif = 0 THEN 0
                    WHEN @TypeOperation IN ('ACHAT','DEPENSE')
                     AND @EstNegatif = 1 THEN 1
                    WHEN @TypeOperation = 'AVOIR_FOURN'
                     AND @EstNegatif = 0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_FOURN'
                     AND @EstNegatif = 1 THEN 0
                    ELSE 0
                END;

                IF @TypeOperation IN ('VENTE','AVOIR_CLIENT')
                BEGIN
                    SET @DebitHT  = CASE @SensInverse WHEN 1 THEN @AmountAbs ELSE 0 END;
                    SET @CreditHT = CASE @SensInverse WHEN 0 THEN @AmountAbs ELSE 0 END;
                END
                ELSE
                BEGIN
                    SET @DebitHT  = CASE @SensInverse WHEN 0 THEN @AmountAbs ELSE 0 END;
                    SET @CreditHT = CASE @SensInverse WHEN 1 THEN @AmountAbs ELSE 0 END;
                END;

                INSERT INTO [dbo].[T136LignesEcriture] (
                    [LignesEcritureGUID],[EcrituresId],[PlanComptableId],
                    [Libelle],[MontantDebit],[MontantCredit],
                    [Ordre],[Created],[CreatedBy]
                )
                VALUES (
                    NEWID(),@EcrituresId,@CompteHtId,
                    ISNULL(@Description,
                        CASE @EstNegatif
                            WHEN 1 THEN 'Rabais/Escompte'
                            ELSE CASE @TypeOperation
                                WHEN 'VENTE'        THEN 'Vente'
                                WHEN 'AVOIR_CLIENT' THEN 'Avoir'
                                ELSE 'Achat'
                            END
                        END),
                    @DebitHT,@CreditHT,
                    @Ordre,GETDATE(),@UserId
                );
                SET @Ordre = @Ordre + 1;
            END

            FETCH NEXT FROM cur_lines INTO
                @LineId,@Description,@Amount,@TaxeStatus,@CompteNumero;
        END

        CLOSE cur_lines;
        DEALLOCATE cur_lines;

        -- ----------------------------------------------------
        -- 9. Taxes globales Option A
        --    Comptes identiques à section 5 (déjà corrigés)
        -- ----------------------------------------------------
        IF @TypeOperation IN ('VENTE','AVOIR_CLIENT')
        BEGIN
            IF @TPS_Doc <> 0
            BEGIN
                SET @SensInverse = CASE
                    WHEN @TypeOperation = 'VENTE'        AND @TPS_Doc >= 0 THEN 0
                    WHEN @TypeOperation = 'VENTE'        AND @TPS_Doc <  0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_CLIENT' AND @TPS_Doc >= 0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_CLIENT' AND @TPS_Doc <  0 THEN 0
                END;
                INSERT INTO [dbo].[T136LignesEcriture] (
                    [LignesEcritureGUID],[EcrituresId],[PlanComptableId],
                    [Libelle],[MontantDebit],[MontantCredit],[Ordre],[Created],[CreatedBy])
                VALUES (NEWID(),@EcrituresId,@CompteTPS_VId,
                    'TPS 5% — '+ISNULL(@DocumentNumber,''),
                    CASE @SensInverse WHEN 1 THEN ABS(@TPS_Doc) ELSE 0 END,
                    CASE @SensInverse WHEN 0 THEN ABS(@TPS_Doc) ELSE 0 END,
                    @Ordre,GETDATE(),@UserId);
                SET @Ordre = @Ordre + 1;
            END

            IF @TVQ_Doc <> 0
            BEGIN
                SET @SensInverse = CASE
                    WHEN @TypeOperation = 'VENTE'        AND @TVQ_Doc >= 0 THEN 0
                    WHEN @TypeOperation = 'VENTE'        AND @TVQ_Doc <  0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_CLIENT' AND @TVQ_Doc >= 0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_CLIENT' AND @TVQ_Doc <  0 THEN 0
                END;
                INSERT INTO [dbo].[T136LignesEcriture] (
                    [LignesEcritureGUID],[EcrituresId],[PlanComptableId],
                    [Libelle],[MontantDebit],[MontantCredit],[Ordre],[Created],[CreatedBy])
                VALUES (NEWID(),@EcrituresId,@CompteQST_VId,
                    'TVQ 9,975% — '+ISNULL(@DocumentNumber,''),
                    CASE @SensInverse WHEN 1 THEN ABS(@TVQ_Doc) ELSE 0 END,
                    CASE @SensInverse WHEN 0 THEN ABS(@TVQ_Doc) ELSE 0 END,
                    @Ordre,GETDATE(),@UserId);
                SET @Ordre = @Ordre + 1;
            END
        END

        IF @TypeOperation IN ('ACHAT','AVOIR_FOURN','DEPENSE')
        BEGIN
            IF @TPS_Doc <> 0
            BEGIN
                SET @SensInverse = CASE
                    WHEN @TypeOperation IN ('ACHAT','DEPENSE') AND @TPS_Doc >= 0 THEN 0
                    WHEN @TypeOperation IN ('ACHAT','DEPENSE') AND @TPS_Doc <  0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_FOURN'        AND @TPS_Doc >= 0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_FOURN'        AND @TPS_Doc <  0 THEN 0
                END;
                INSERT INTO [dbo].[T136LignesEcriture] (
                    [LignesEcritureGUID],[EcrituresId],[PlanComptableId],
                    [Libelle],[MontantDebit],[MontantCredit],[Ordre],[Created],[CreatedBy])
                VALUES (NEWID(),@EcrituresId,@CompteTPS_AId,
                    'TPS récupérable 5% — '+ISNULL(@DocumentNumber,''),
                    CASE @SensInverse WHEN 0 THEN ABS(@TPS_Doc) ELSE 0 END,
                    CASE @SensInverse WHEN 1 THEN ABS(@TPS_Doc) ELSE 0 END,
                    @Ordre,GETDATE(),@UserId);
                SET @Ordre = @Ordre + 1;
            END

            IF @TVQ_Doc <> 0
            BEGIN
                SET @SensInverse = CASE
                    WHEN @TypeOperation IN ('ACHAT','DEPENSE') AND @TVQ_Doc >= 0 THEN 0
                    WHEN @TypeOperation IN ('ACHAT','DEPENSE') AND @TVQ_Doc <  0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_FOURN'        AND @TVQ_Doc >= 0 THEN 1
                    WHEN @TypeOperation = 'AVOIR_FOURN'        AND @TVQ_Doc <  0 THEN 0
                END;
                INSERT INTO [dbo].[T136LignesEcriture] (
                    [LignesEcritureGUID],[EcrituresId],[PlanComptableId],
                    [Libelle],[MontantDebit],[MontantCredit],[Ordre],[Created],[CreatedBy])
                VALUES (NEWID(),@EcrituresId,@CompteQST_AId,
                    'TVQ récupérable 9,975% — '+ISNULL(@DocumentNumber,''),
                    CASE @SensInverse WHEN 0 THEN ABS(@TVQ_Doc) ELSE 0 END,
                    CASE @SensInverse WHEN 1 THEN ABS(@TVQ_Doc) ELSE 0 END,
                    @Ordre,GETDATE(),@UserId);
                SET @Ordre = @Ordre + 1;
            END
        END


		-- --------------------------------------------------
		--    sp_ComptabiliserDocument 92
		--select * from T135Ecritures
		--select * from T136LignesEcriture
		--rollback
		--return
        -- ----------------------------------------------------
        -- 10. Valide l'écriture
        -- ----------------------------------------------------
        UPDATE [dbo].[T135Ecritures]
        SET [Statut]='VALIDEE',[ValidatedAt]=GETDATE(),[ValidatedBy]=@UserId
        WHERE [Id] = @EcrituresId;

        -- ----------------------------------------------------
        -- 11. Lien T137DocumentEcriture
        -- ----------------------------------------------------
        INSERT INTO [dbo].[T137DocumentEcriture] (
            [DocumentEcritureGUID],[CompanyGUID],[DocumentId],
            [EcrituresId],[TypeEcriture],[Created],[CreatedBy]
        )
        VALUES (
            NEWID(),@CompanyGUID,@DocumentId,
            @EcrituresId,@TypeEcriture,GETDATE(),@UserId
        );

        -- ----------------------------------------------------
        -- 12. Marque T060Document comme comptabilisé
        -- ----------------------------------------------------
        UPDATE [dbo].[T060Document]
        SET [ComptabilisationStatus]='COMPTABILISE',
            [ComptabiliseeAt]=GETDATE()
        WHERE [Id] = @DocumentId;

        COMMIT TRANSACTION;
        SELECT @EcrituresId AS EcrituresId, @TypeOperation AS TypeOperation;

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('global','cur_lines') >= 0
        BEGIN
            CLOSE cur_lines;
            DEALLOCATE cur_lines;
        END
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
