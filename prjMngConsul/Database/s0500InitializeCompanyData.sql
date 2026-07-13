SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[s0500InitializeCompanyData]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @CreatedBy      NVARCHAR(200) = N'system'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ModelGUID UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';
    DECLARE @nb INT;   -- compteur réutilisable pour les PRINT

    -- ==========================================================
    -- VÉRIFICATIONS PRÉLIMINAIRES
    -- ==========================================================
    IF @CompanyGUID IS NULL OR @CompanyGUID = '00000000-0000-0000-0000-000000000000'
    BEGIN
        RAISERROR('CompanyGUID invalide.', 16, 1);
        RETURN;
    END

    IF @CompanyGUID = @ModelGUID
    BEGIN
        RAISERROR('Impossible d''initialiser la compagnie modèle elle-même.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID)
    BEGIN
        RAISERROR('La compagnie cible n''existe pas dans T010Company.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @ModelGUID)
    BEGIN
        RAISERROR('La compagnie modèle n''existe pas (GUID 00000000-0000-0000-0000-000000000001).', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.T121PlanComptable WHERE CompanyGUID = @CompanyGUID)
    BEGIN
        --RAISERROR('Cette compagnie a déjà été initialisée (T121PlanComptable contient déjà des données).', 16, 1);
        RETURN;
    END

    -- Vérifier que la DÉFINITION FISCAL_YEAR_END existe dans la compagnie modèle.
    -- La VALEUR est facultative : l'Étape 9 applique une valeur par défaut si absente.
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.T100ParamComptable p
        WHERE p.CompanyGUID = @ModelGUID
          AND p.ShortName   = N'FISCAL_YEAR_END'
    )
    BEGIN
        RAISERROR('La définition FISCAL_YEAR_END est introuvable dans la compagnie modèle (T100ParamComptable).', 16, 1);
        RETURN;
    END


    BEGIN TRY
        BEGIN TRANSACTION;

        -- ==========================================================
        -- ÉTAPE 1 : T068TaxeStatus
        -- ==========================================================
        INSERT INTO dbo.T068TaxeStatus (TaxStatus, Name, ShortName, Description, CompanyGUID)
        SELECT TaxStatus, Name, ShortName, Description, @CompanyGUID
        FROM dbo.T068TaxeStatus
        WHERE CompanyGUID = @ModelGUID;

        PRINT '✓ T068TaxeStatus : ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' lignes copiées';


        -- ==========================================================
        -- ÉTAPE 2 : T069TaxeRate
        -- ==========================================================
        INSERT INTO dbo.T069TaxeRate (StateId, TPS_Rate, TVQ_Rate, DateValide, CompanyGUID)
        SELECT StateId, TPS_Rate, TVQ_Rate, DateValide, @CompanyGUID
        FROM dbo.T069TaxeRate
        WHERE CompanyGUID = @ModelGUID;

        PRINT '✓ T069TaxeRate : ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' lignes copiées';


        -- ==========================================================
        -- ÉTAPES 3-4 : Paramètres comptables (T100 définitions + T101 valeurs)
        -- Ne cloner QUE si la compagnie n'a encore AUCUN paramètre. Sinon ils ont
        -- déjà été provisionnés par s0150GetParamsForCompany (éviter les doublons).
        -- ==========================================================
        IF NOT EXISTS (SELECT 1 FROM dbo.T100ParamComptable WHERE CompanyGUID = @CompanyGUID)
        BEGIN

        -- ÉTAPE 3 : T100ParamComptable (avec mapping pour T101)
        DECLARE @MapT100 TABLE (OldId INT NOT NULL, NewId INT NOT NULL);

        -- 1) Capturer les anciens Id ordonnés
        DECLARE @SrcT100 TABLE (rn INT NOT NULL, OldId INT NOT NULL);
        INSERT INTO @SrcT100 (rn, OldId)
        SELECT ROW_NUMBER() OVER (ORDER BY Id), Id
        FROM dbo.T100ParamComptable
        WHERE CompanyGUID = @ModelGUID;

        -- 2) INSERT simple
        INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
        SELECT ShortName, Name, ParamType, Categorie, Ordre, @CompanyGUID
        FROM dbo.T100ParamComptable
        WHERE CompanyGUID = @ModelGUID
        ORDER BY Id;

        -- 3) Construire le mapping (alignement par ROW_NUMBER)
        INSERT INTO @MapT100 (OldId, NewId)
        SELECT s.OldId, n.Id
        FROM @SrcT100 s
        INNER JOIN (
            SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS rn
            FROM dbo.T100ParamComptable
            WHERE CompanyGUID = @CompanyGUID
        ) n ON n.rn = s.rn;

        SELECT @nb = COUNT(*) FROM @MapT100;
        PRINT '✓ T100ParamComptable : ' + CAST(@nb AS VARCHAR(10)) + ' lignes copiées';


        -- ==========================================================
        -- ÉTAPE 4 : T101ParamValues
        -- ==========================================================
        INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
        SELECT m.NewId, @CompanyGUID, v.iVal, v.sVal, v.dVal, v.fVal
        FROM dbo.T101ParamValues v
        INNER JOIN @MapT100 m ON m.OldId = v.T100Id
        WHERE v.CompanyGUID = @ModelGUID;

        PRINT '✓ T101ParamValues : ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' lignes copiées';

        END
        ELSE
            PRINT 'i T100/T101 : paramètres déjà présents (provisionnés par s0150) — clonage ignoré';


        -- ==========================================================
        -- ÉTAPE 5 : T120PlanComptable_Classe (pas d'IDENTITY)
        -- ==========================================================
        DECLARE @MapT120 TABLE (OldId INT NOT NULL, NewId INT NOT NULL PRIMARY KEY);
        DECLARE @NextT120Id INT;
        SELECT @NextT120Id = ISNULL(MAX(Id) + 1, 1) FROM dbo.T120PlanComptable_Classe;

        -- 5a : insérer SANS ParentId (auto-référence)
        INSERT INTO dbo.T120PlanComptable_Classe
            (Id, Code, Description, TypeBilan, Sens, Ordre, Actif,
             NumeroDebut, NumeroFin, GroupeEtatFinancier, ParentId, Niveau, CompanyGUID)
        SELECT
            @NextT120Id - 1 + ROW_NUMBER() OVER (ORDER BY Id),
            Code, Description, TypeBilan, Sens, Ordre, Actif,
            NumeroDebut, NumeroFin, GroupeEtatFinancier,
            NULL,
            Niveau, @CompanyGUID
        FROM dbo.T120PlanComptable_Classe
        WHERE CompanyGUID = @ModelGUID
        ORDER BY Id;

        -- 5b : construire le mapping
        ;WITH OldData AS (
            SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS rn
            FROM dbo.T120PlanComptable_Classe WHERE CompanyGUID = @ModelGUID
        ),
        NewData AS (
            SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS rn
            FROM dbo.T120PlanComptable_Classe WHERE CompanyGUID = @CompanyGUID
        )
        INSERT INTO @MapT120 (OldId, NewId)
        SELECT o.Id, n.Id
        FROM OldData o
        INNER JOIN NewData n ON n.rn = o.rn;

        -- 5c : remettre les ParentId via le mapping
        UPDATE c
        SET c.ParentId = m.NewId
        FROM dbo.T120PlanComptable_Classe c
        INNER JOIN dbo.T120PlanComptable_Classe orig ON orig.CompanyGUID = @ModelGUID
        INNER JOIN @MapT120 mOld ON mOld.OldId = orig.Id AND mOld.NewId = c.Id
        INNER JOIN @MapT120 m ON m.OldId = orig.ParentId
        WHERE c.CompanyGUID = @CompanyGUID
          AND orig.ParentId IS NOT NULL;

        SELECT @nb = COUNT(*) FROM @MapT120;
        PRINT '✓ T120PlanComptable_Classe : ' + CAST(@nb AS VARCHAR(10)) + ' lignes copiées';


        -- ==========================================================
        -- ÉTAPE 6 : T121PlanComptable (pas d'IDENTITY)
        -- ==========================================================
        DECLARE @NextT121Id INT;
        SELECT @NextT121Id = ISNULL(MAX(Id) + 1, 1) FROM dbo.T121PlanComptable;

        INSERT INTO dbo.T121PlanComptable
            (Id, Compte, Nom, ClasseId, ClasseParentId, TypeBilan, Sens, Ordre, Actif, Systeme, Description, CompanyGUID)
        SELECT
            @NextT121Id - 1 + ROW_NUMBER() OVER (ORDER BY p.Id),
            p.Compte, p.Nom,
            mClasse.NewId,
            mParent.NewId,
            p.TypeBilan, p.Sens, p.Ordre, p.Actif, p.Systeme, p.Description,
            @CompanyGUID
        FROM dbo.T121PlanComptable p
        LEFT JOIN @MapT120 mClasse ON mClasse.OldId = p.ClasseId
        LEFT JOIN @MapT120 mParent ON mParent.OldId = p.ClasseParentId
        WHERE p.CompanyGUID = @ModelGUID
        ORDER BY p.Id;

        PRINT '✓ T121PlanComptable : ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' lignes copiées';


        -- ==========================================================
        -- ÉTAPE 7 : T130Journaux (IDENTITY) - même technique mapping
        -- ==========================================================
        DECLARE @MapT130 TABLE (OldId INT NOT NULL, NewId INT NOT NULL);

        DECLARE @SrcT130 TABLE (rn INT NOT NULL, OldId INT NOT NULL);
        INSERT INTO @SrcT130 (rn, OldId)
        SELECT ROW_NUMBER() OVER (ORDER BY Id), Id
        FROM dbo.T130Journaux
        WHERE CompanyGUID = @ModelGUID;

        INSERT INTO dbo.T130Journaux (CompanyGUID, Code, Libelle, Type, Actif)
        SELECT @CompanyGUID, Code, Libelle, Type, Actif
        FROM dbo.T130Journaux
        WHERE CompanyGUID = @ModelGUID
        ORDER BY Id;

        INSERT INTO @MapT130 (OldId, NewId)
        SELECT s.OldId, n.Id
        FROM @SrcT130 s
        INNER JOIN (
            SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS rn
            FROM dbo.T130Journaux
            WHERE CompanyGUID = @CompanyGUID
        ) n ON n.rn = s.rn;

        SELECT @nb = COUNT(*) FROM @MapT130;
        PRINT '✓ T130Journaux : ' + CAST(@nb AS VARCHAR(10)) + ' lignes copiées';


        -- ==========================================================
        -- ÉTAPE 8 : T138EcrituresTemplate + T139TemplateLignes
        -- (Placeholder - à compléter quand structure connue)
        -- ==========================================================
        IF EXISTS (SELECT 1 FROM dbo.T138EcrituresTemplate WHERE CompanyGUID = @ModelGUID)
        BEGIN
            PRINT '⚠ T138EcrituresTemplate : données présentes dans le modèle mais structure non implémentée';
            PRINT '   (envoyer EXEC sp_columns T138EcrituresTemplate pour activer la copie)';
        END
        ELSE
        BEGIN
            PRINT 'ℹ T138EcrituresTemplate : aucune donnée dans la compagnie modèle (ignoré)';
        END


        -- ==========================================================
        -- ÉTAPE 9 : T111Exercices
        --   La fin d'année fiscale est lue depuis les paramètres
        --   comptables (T100ParamComptable / T101ParamValues),
        --   copiés aux Étapes 3 et 4 pour @CompanyGUID.
        -- ==========================================================
        DECLARE @FiscalYearEnd DATE;

        SELECT @FiscalYearEnd = TRY_CONVERT(DATE, v.dVal)
        FROM dbo.T100ParamComptable p
        INNER JOIN dbo.T101ParamValues v
                ON v.T100Id = p.Id AND v.CompanyGUID = p.CompanyGUID
        WHERE p.CompanyGUID = @CompanyGUID
          AND p.ShortName   = N'FISCAL_YEAR_END';
       
      IF @FiscalYearEnd IS NULL
	    begin
            SET @FiscalYearEnd = DATEFROMPARTS(YEAR(GETDATE()), 12, 31);
			declare @T100Id int 
             select @T100Id = id  from [dbo].[T100ParamComptable] where ShortName = 'FISCAL_YEAR_END' and CompanyGUID =@CompanyGUID
			 -- DATE stockée dans la colonne typée dVal
			 update [dbo].[T101ParamValues] set dVal = @FiscalYearEnd   where [T100Id]  = @T100Id   and CompanyGUID =@CompanyGUID
		end

        IF @FiscalYearEnd IS NULL
        BEGIN
            RAISERROR('La valeur du paramètre FISCAL_YEAR_END est absente ou n''est pas une date valide (T101ParamValues.sVal).', 16, 1);
            RETURN;  -- XACT_ABORT + TRY/CATCH => rollback automatique
        END

        DECLARE @FiscalYear INT = YEAR(@FiscalYearEnd);
        DECLARE @FiscalStart DATE = DATEADD(DAY, 1, DATEADD(YEAR, -1, @FiscalYearEnd));
        DECLARE @ExerciceId INT;

        INSERT INTO dbo.T111Exercices (annee, date_debut, date_fin, statut, CompanyGUID)
        VALUES (@FiscalYear, @FiscalStart, @FiscalYearEnd, 'OUVERT', @CompanyGUID);

        SET @ExerciceId = SCOPE_IDENTITY();

        PRINT '✓ T111Exercices : exercice ' + CAST(@FiscalYear AS VARCHAR(4)) +
              ' (' + CONVERT(VARCHAR, @FiscalStart, 23) + ' → ' + CONVERT(VARCHAR, @FiscalYearEnd, 23) + ')' +
              ' [FISCAL_YEAR_END lu depuis T100/T101]';


        -- ==========================================================
        -- ÉTAPE 10 : T112Periodes (12 mois) — suit l'exercice fiscal
        -- ==========================================================
        DECLARE @MoisFR TABLE (Mois INT PRIMARY KEY, Libelle VARCHAR(50));
        INSERT INTO @MoisFR VALUES
            (1, 'Janvier'),   (2, 'Février'),   (3, 'Mars'),       (4, 'Avril'),
            (5, 'Mai'),       (6, 'Juin'),      (7, 'Juillet'),    (8, 'Août'),
            (9, 'Septembre'), (10,'Octobre'),   (11,'Novembre'),   (12,'Décembre');

        -- Générer les 12 mois de l'exercice à partir de @FiscalStart
        ;WITH Sequence AS (
            SELECT 0 AS Offset
            UNION ALL
            SELECT Offset + 1 FROM Sequence WHERE Offset < 11
        ),
        PeriodesExercice AS (
            SELECT
                Offset,
                DATEADD(MONTH, Offset, @FiscalStart) AS DateMois
            FROM Sequence
        )
        INSERT INTO dbo.T112Periodes (exercice_id, mois, statut, Libelle, CompanyGUID)
        SELECT
            @ExerciceId,
            MONTH(pe.DateMois),
            'OUVERTE',
            m.Libelle + ' ' + CAST(YEAR(pe.DateMois) AS VARCHAR(4)),
            @CompanyGUID
        FROM PeriodesExercice pe
        INNER JOIN @MoisFR m ON m.Mois = MONTH(pe.DateMois)
        ORDER BY pe.Offset;

        PRINT '✓ T112Periodes : 12 périodes créées (exercice ' +
              CONVERT(VARCHAR, @FiscalStart, 23) + ' → ' +
              CONVERT(VARCHAR, @FiscalYearEnd, 23) + ')';


        COMMIT TRANSACTION;
        PRINT '';
        PRINT '=== INITIALISATION TERMINÉE AVEC SUCCÈS ===';
        PRINT 'CompanyGUID : ' + CAST(@CompanyGUID AS VARCHAR(50));

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @ErrLine INT = ERROR_LINE();

        PRINT '❌ ERREUR à la ligne ' + CAST(@ErrLine AS VARCHAR(10)) + ' : ' + @ErrMsg;
        THROW;
    END CATCH
END

GO
