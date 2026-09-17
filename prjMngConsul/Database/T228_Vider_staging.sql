-- =============================================================================
-- T228 — Vider la préparation d'une compagnie
--
-- Le staging est un brouillon : on y relit la même comptabilité plusieurs fois
-- avant que quoi que ce soit ne soit appliqué. Il fallait donc pouvoir l'effacer
-- et recommencer proprement, sans passer par SQL.
--
-- Deux règles gouvernent cette procédure.
--
-- 1. **Une compagnie à la fois.** Jamais de TRUNCATE : les tables de staging
--    sont partagées par toutes les compagnies. Chaque suppression est filtrée
--    par CompanyGUID, directement ou par son parent.
--
-- 2. **Rien en comptabilité.** Vider la préparation n'annule pas ce qui en a
--    déjà été tiré : les documents créés dans T060Document, les tiers dans
--    T050Party, les comptes dans T121PlanComptable restent. On efface le
--    brouillon, pas l'oeuvre. C'est aussi pourquoi la procédure rend le compte
--    de ce qu'elle a supprimé : l'appelant doit pouvoir le dire à l'écran.
--
-- Procédure : s0790.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0790ViderStaging]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50370, 'Aucune compagnie : refus de vider la préparation.', 1;

    DECLARE @Compte TABLE ([Ordre] INT, [Table] VARCHAR(60), [Lignes] INT);

    BEGIN TRANSACTION;

    -- L'ordre est celui des dépendances : l'enfant avant le parent. Une clé
    -- étrangère laissée pendante ferait échouer tout le lot.

    DELETE cc
      FROM staging.CorrespondanceCompte cc
     WHERE cc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (1, 'CorrespondanceCompte', @@ROWCOUNT);

    DELETE pc
      FROM staging.ImportPlanComptable pc
     WHERE pc.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (2, 'ImportPlanComptable', @@ROWCOUNT);

    DELETE l
      FROM staging.ImportLot l
     WHERE l.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (3, 'ImportLot', @@ROWCOUNT);

    -- Les lignes de document ne portent pas la compagnie : on passe par l'entête.
    DELETE dl
      FROM staging.DocumentImportLigne dl
      JOIN staging.DocumentImport di ON di.[Id] = dl.[EnteteId]
     WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (4, 'DocumentImportLigne', @@ROWCOUNT);

    DELETE di
      FROM staging.DocumentImport di
     WHERE di.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (5, 'DocumentImport', @@ROWCOUNT);

    DELETE si
      FROM staging.SocieteImport si
     WHERE si.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (6, 'SocieteImport', @@ROWCOUNT);

    -- Tiers et produits sont rattachés au fichier, pas à la compagnie.
    DELETE pi
      FROM staging.PartyImport pi
      JOIN staging.ImportFiles f ON f.[Id] = pi.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (7, 'PartyImport', @@ROWCOUNT);

    DELETE pr
      FROM staging.ProductImport pr
      JOIN staging.ImportFiles f ON f.[Id] = pr.[ImportFileId]
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (8, 'ProductImport', @@ROWCOUNT);

    DELETE cd
      FROM staging.ConnecteurDonnee cd
     WHERE cd.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (9, 'ConnecteurDonnee', @@ROWCOUNT);

    DELETE cr
      FROM staging.ConnecteurRun cr
     WHERE cr.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (10, 'ConnecteurRun', @@ROWCOUNT);

    DELETE bv
      FROM staging.BalanceVerification bv
     WHERE bv.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (11, 'BalanceVerification', @@ROWCOUNT);

    -- Le registre en dernier : tout le reste y pointait.
    DELETE f
      FROM staging.ImportFiles f
     WHERE f.[CompanyGUID] = @CompanyGUID;
    INSERT INTO @Compte VALUES (12, 'ImportFiles', @@ROWCOUNT);

    COMMIT TRANSACTION;

    SELECT [Table], [Lignes] FROM @Compte WHERE [Lignes] > 0 ORDER BY [Ordre];
    SELECT SUM([Lignes]) AS [Total] FROM @Compte;
END
GO
