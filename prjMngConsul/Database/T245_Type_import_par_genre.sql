-- =============================================================================
-- T245 — Le registre des imports accepte un type par genre
--
-- staging.ImportFiles.TypeImport est contrôlé par une liste blanche. Deux
-- ressources qui partagent un type s'effacent mutuellement depuis T244, qui
-- remplace « la précédente extraction DU MÊME TYPE » :
--
--   BalanceAgee  ->  clients ET fournisseurs
--   Rapport      ->  bilan ET état des résultats
--
-- Le remède est de donner son type à chaque genre. Mais la liste blanche les
-- refuse, et la colonne fait VARCHAR(20) — « BalanceAgeeFournisseur » en
-- compte vingt-deux. D'où ce script :
--
--   1) la colonne passe à VARCHAR(30) ;
--   2) la liste blanche accueille les cinq nouveaux types ;
--   3) s0600InsertImportFile et s0772GetImportFichiers suivent la colonne.
--
-- « BalanceVerification » y entre aussi : la balance de vérification par la
-- passerelle s'inscrivait au registre sous un type que la liste refusait —
-- les lignes étaient chargées, puis l'inscription échouait.
--
-- LES ANCIENS TYPES RESTENT VALIDES. « BalanceAgee » et « Rapport » demeurent
-- dans la liste : les fichiers déjà inscrits sous ces noms ne doivent pas
-- devenir invalides pour une règle écrite après eux. Ils ne seront simplement
-- plus jamais remplacés, et la prochaine extraction en créera un à côté.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La contrainte cède la place le temps d'élargir la colonne
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_staging_ImportFiles_TypeImport')
    ALTER TABLE staging.ImportFiles DROP CONSTRAINT CK_staging_ImportFiles_TypeImport;
GO

ALTER TABLE staging.ImportFiles ALTER COLUMN [TypeImport] VARCHAR(30) NOT NULL;
GO

-- -----------------------------------------------------------------------------
-- 2) La liste blanche, avec les nouveaux venus
-- -----------------------------------------------------------------------------
ALTER TABLE staging.ImportFiles WITH CHECK
    ADD CONSTRAINT CK_staging_ImportFiles_TypeImport CHECK ([TypeImport] IN (
        -- Structure
        'PlanComptable', 'Societe', 'Taxe', 'ModePaiement', 'ConditionPaiement',
        'CategorieSuivi', 'Departement', 'Emplacement',
        -- Tiers et articles
        'Client', 'Fournisseur', 'Produit',
        -- Ventes et achats
        'FactureClient', 'FactureFournisseur', 'AvoirClient', 'AvoirFournisseur',
        'Depense', 'RecuVente', 'Soumission', 'BonCommande',
        'Encaissement', 'Decaissement', 'Remboursement',
        -- Grand livre et contrôles
        'EcritureJournal', 'PieceJointe',
        'BalanceVerification',
        'BalanceAgeeClient', 'BalanceAgeeFournisseur',
        'RapportBilan', 'RapportResultats',
        -- Anciens types : gardés pour les fichiers déjà inscrits
        'BalanceAgee', 'Rapport'
    ));
GO

-- -----------------------------------------------------------------------------
-- 3) Les procédures suivent la colonne
--
--    Un paramètre resté en VARCHAR(20) tronque AVANT l'insertion, et la faute
--    ressort en violation de contrainte sur une valeur qu'on n'a pas écrite.
-- -----------------------------------------------------------------------------
GO
CREATE OR ALTER PROCEDURE dbo.s0600InsertImportFile
    @TypeImport     VARCHAR(30),
    @OriginalName   NVARCHAR(255),
    @FileExtension  VARCHAR(10),
    @FileSize       BIGINT,
    @ContentType    VARCHAR(100)    = NULL,
    @FileContent    VARBINARY(MAX),
    @UploadedBy     INT             = NULL,
    @CompanyGUID    UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO staging.ImportFiles
        (TypeImport, OriginalName, FileExtension, FileSize, ContentType,
         FileContent, UploadDate, UploadedBy, CompanyGUID, Status)
    OUTPUT INSERTED.Id
    VALUES
        (@TypeImport, @OriginalName, @FileExtension, @FileSize, @ContentType,
         @FileContent, GETDATE(), @UploadedBy, @CompanyGUID, 'Pending');
END
GO
-- -----------------------------------------------------------------------------
-- s0772GetImportFichiers - les fichiers importes par la compagnie, d'un type
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0772GetImportFichiers]
    @CompanyGUID UNIQUEIDENTIFIER,
    @TypeImport  VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT f.[Id], f.[OriginalName], f.[UploadDate], f.[ModelUsed], f.[EstimatedCostUsd],
           ISNULL(c.Lignes, 0)    AS Lignes,
           ISNULL(c.EnAttente, 0) AS EnAttente,
           ISNULL(c.Crees, 0)     AS Crees,
           ISNULL(c.Ecartes, 0)   AS Ecartes,
           ISNULL(c.Erreurs, 0)   AS Erreurs
      FROM staging.ImportFiles f
     OUTER APPLY (
        SELECT COUNT(*) AS Lignes,
               SUM(CASE WHEN s.[Status] = 'Pending'  THEN 1 ELSE 0 END) AS EnAttente,
               SUM(CASE WHEN s.[Status] = 'Migrated' THEN 1 ELSE 0 END) AS Crees,
               SUM(CASE WHEN s.[Status] = 'Skipped'  THEN 1 ELSE 0 END) AS Ecartes,
               SUM(CASE WHEN s.[Status] = 'Error'    THEN 1 ELSE 0 END) AS Erreurs
          FROM (SELECT [Status] FROM staging.PartyImport   WHERE [ImportFileId] = f.[Id]
                UNION ALL
                SELECT [Status] FROM staging.ProductImport WHERE [ImportFileId] = f.[Id]) s
     ) c
     WHERE f.[CompanyGUID] = @CompanyGUID
       AND f.[TypeImport]  = @TypeImport
     ORDER BY f.[Id] DESC;
END

GO
