-- =============================================================================
-- T219 — Importer les clients, les fournisseurs, les produits et services
--
-- Trois ecrans (ImportClients, ImportFournisseurs, ImportProduits) reposent sur
-- la chaine deja en place : le fichier va dans staging.ImportFiles (s0600), ce
-- qui en est lu -- par lecture directe ou par l'IA -- y est range en JSON
-- (s0602), passe en preparation dans staging.PartyImport / ProductImport
-- (s0604), et de la dans l'application (s0607 / s0608).
--
-- Ce qui manquait, et que ce script ajoute :
--
--   1) La compagnie. Les procedures de lecture et de suppression de la chaine
--      ne prenaient qu'un identifiant de fichier : on pouvait lire ou effacer
--      le fichier d'une autre compagnie en changeant un nombre. Les nouvelles
--      verifient d'abord que le fichier appartient a la compagnie.
--
--   2) Le rapprochement avec l'existant. Chaque ligne dit si un tiers ou un
--      produit du meme nom existe deja, et si le fichier la repete.
--
--   3) Les doublons de produits. s0608 creait un produit par ligne, meme deja
--      present. s0774 ecarte d'abord ce qui existe, puis confie le reste a
--      s0607 / s0608, inchangees.
--
--   4) Des prompts qui rendent ce que s0604 attend. PROMPT_FILE_CUSTOMER et
--      PROMPT_FILE_SUPPLIER sont des prompts de recus : ils ne rendent pas de
--      tableau "rows", et la lecture des tiers par l'IA ne produisait rien.
--      Les nouveaux prompts vivent a cote ; les anciens restent a l'ancien
--      ecran wbfImport.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- s0772GetImportFichiers — les fichiers importes par la compagnie, d'un type
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0772GetImportFichiers]
    @CompanyGUID UNIQUEIDENTIFIER,
    @TypeImport  VARCHAR(20)
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

-- -----------------------------------------------------------------------------
-- s0773GetImportLignes — un fichier et ses lignes, rapprochees de l'existant
--
--   1er jeu : le fichier et ses comptes -- nouveaux, deja presents, doublons
--             du fichier, crees, ecartes, en erreur ;
--   2e jeu  : les lignes. ExistantId dit qu'un tiers (ou un produit) du meme
--             nom est deja dans l'application ; Doublon, que le fichier a deja
--             donne ce nom plus haut.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0773GetImportLignes]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Type VARCHAR(20);

    SELECT @Type = [TypeImport]
      FROM staging.ImportFiles
     WHERE [Id] = @ImportFileId
       AND [CompanyGUID] = @CompanyGUID;

    IF @Type IS NULL
        THROW 50360, 'Ce fichier n''existe pas pour cette compagnie.', 1;

    DECLARE @r TABLE (Statut VARCHAR(20), Existant BIT, Doublon BIT);

    IF @Type = 'Produit'
    BEGIN
        SELECT p.[Id], p.[LineNumber], p.[Name], p.[Description], p.[Price], p.[Taxable],
               p.[Status], p.[ErrorMessage],
               ex.[Id] AS ExistantId,
               CAST(NULL AS VARCHAR(100)) AS ExistantType,
               CASE WHEN ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM(ISNULL(p.[Name], ''))))
                                           ORDER BY ISNULL(p.[LineNumber], 0), p.[Id]) > 1
                    THEN 1 ELSE 0 END AS Doublon
          INTO #lp
          FROM staging.ProductImport p
         OUTER APPLY (SELECT TOP 1 t.[Id]
                        FROM dbo.T075Products t
                       WHERE t.[CompanyGUID] = @CompanyGUID
                         AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name])))
                       ORDER BY t.[Id]) ex
         WHERE p.[ImportFileId] = @ImportFileId;

        INSERT INTO @r
        SELECT [Status], CASE WHEN ExistantId IS NULL THEN 0 ELSE 1 END, Doublon FROM #lp;
    END
    ELSE
    BEGIN
        SELECT p.[Id], p.[LineNumber], p.[Name], p.[Attention], p.[Address1], p.[Address2],
               p.[City], p.[Province], p.[PostalCode], p.[Phone], p.[Email], p.[TPS], p.[TVQ],
               p.[Balance], p.[Status], p.[ErrorMessage],
               ex.[Id] AS ExistantId,
               ex.TypeNom AS ExistantType,
               CASE WHEN ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM(ISNULL(p.[Name], ''))))
                                           ORDER BY ISNULL(p.[LineNumber], 0), p.[Id]) > 1
                    THEN 1 ELSE 0 END AS Doublon
          INTO #lt
          FROM staging.PartyImport p
         OUTER APPLY (SELECT TOP 1 t.[Id], ty.[Name] AS TypeNom
                        FROM dbo.T050Party t
                        LEFT JOIN dbo.T055PartyType ty ON ty.[Id] = t.[Type]
                       WHERE t.[CompanyGUID] = @CompanyGUID
                         AND ISNULL(t.[isDeleted], 0) = 0
                         AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name])))
                       ORDER BY t.[Id]) ex
         WHERE p.[ImportFileId] = @ImportFileId;

        INSERT INTO @r
        SELECT [Status], CASE WHEN ExistantId IS NULL THEN 0 ELSE 1 END, Doublon FROM #lt;
    END

    SELECT f.[Id], f.[TypeImport], f.[OriginalName], f.[UploadDate], f.[ModelUsed], f.[EstimatedCostUsd],
           (SELECT COUNT(*) FROM @r)                                                          AS Lignes,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Pending' AND Existant = 0 AND Doublon = 0) AS Nouveaux,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Pending' AND Existant = 1)                AS Existants,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Pending' AND Existant = 0 AND Doublon = 1) AS Doublons,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Migrated')                                AS Crees,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Skipped')                                 AS Ecartes,
           (SELECT COUNT(*) FROM @r WHERE Statut = 'Error')                                   AS Erreurs
      FROM staging.ImportFiles f
     WHERE f.[Id] = @ImportFileId;

    IF @Type = 'Produit'
        SELECT * FROM #lp ORDER BY ISNULL([LineNumber], 0), [Id];
    ELSE
        SELECT * FROM #lt ORDER BY ISNULL([LineNumber], 0), [Id];
END
GO

-- -----------------------------------------------------------------------------
-- s0774AppliquerImportFichier — creer pour de bon ce qui est nouveau
--
--   Ecarte d'abord ce qui ne doit pas etre cree : la repetition d'un nom dans
--   le fichier, et -- pour les produits -- ce qui existe deja. Les tiers deja
--   presents sont ecartes par s0607 elle-meme. Puis confie le reste a s0607
--   ou s0608, dont le resume est rendu tel quel.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0774AppliquerImportFichier]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Type VARCHAR(20);

    SELECT @Type = [TypeImport]
      FROM staging.ImportFiles
     WHERE [Id] = @ImportFileId
       AND [CompanyGUID] = @CompanyGUID;

    IF @Type IS NULL
        THROW 50361, 'Ce fichier n''existe pas pour cette compagnie.', 1;

    IF @Type IN ('Client', 'Fournisseur')
    BEGIN
        ;WITH d AS (
            SELECT [Status], [ErrorMessage],
                   ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM([Name])))
                                      ORDER BY ISNULL([LineNumber], 0), [Id]) AS Rang
              FROM staging.PartyImport
             WHERE [ImportFileId] = @ImportFileId
               AND [Status] = 'Pending'
               AND LTRIM(RTRIM(ISNULL([Name], ''))) <> ''
        )
        UPDATE d
           SET [Status] = 'Skipped',
               [ErrorMessage] = N'Doublon : le fichier répète ce nom, seule la première ligne est créée.'
         WHERE Rang > 1;

        EXEC dbo.s0607MigratePartyImportToProd
             @ImportFileId = @ImportFileId,
             @CompanyGUID  = @CompanyGUID;
    END
    ELSE IF @Type = 'Produit'
    BEGIN
        ;WITH d AS (
            SELECT [Status], [ErrorMessage],
                   ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM([Name])))
                                      ORDER BY ISNULL([LineNumber], 0), [Id]) AS Rang
              FROM staging.ProductImport
             WHERE [ImportFileId] = @ImportFileId
               AND [Status] = 'Pending'
               AND LTRIM(RTRIM(ISNULL([Name], ''))) <> ''
        )
        UPDATE d
           SET [Status] = 'Skipped',
               [ErrorMessage] = N'Doublon : le fichier répète ce nom, seule la première ligne est créée.'
         WHERE Rang > 1;

        UPDATE p
           SET [Status] = 'Skipped',
               [MigratedToProductId] = ex.[Id],
               [ErrorMessage] = N'Existe déjà dans vos produits et services (Id=' + CAST(ex.[Id] AS NVARCHAR(10)) + N') : laissé tel quel.'
          FROM staging.ProductImport p
         CROSS APPLY (SELECT TOP 1 t.[Id]
                        FROM dbo.T075Products t
                       WHERE t.[CompanyGUID] = @CompanyGUID
                         AND UPPER(LTRIM(RTRIM(t.[Name]))) = UPPER(LTRIM(RTRIM(p.[Name])))
                       ORDER BY t.[Id]) ex
         WHERE p.[ImportFileId] = @ImportFileId
           AND p.[Status] = 'Pending';

        EXEC dbo.s0608MigrateProductImportToProd
             @ImportFileId = @ImportFileId,
             @CompanyGUID  = @CompanyGUID;
    END
END
GO

-- -----------------------------------------------------------------------------
-- s0775SupprimerImportFichier — abandonner un fichier et sa preparation
--
--   Ce qui a deja ete cree dans l'application reste en place : on ne retire
--   que le fichier et ses lignes en preparation.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0775SupprimerImportFichier]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ImportFiles
                    WHERE [Id] = @ImportFileId AND [CompanyGUID] = @CompanyGUID)
        THROW 50362, 'Ce fichier n''existe pas pour cette compagnie.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.PartyImport   WHERE [ImportFileId] = @ImportFileId;
    DECLARE @nt INT = @@ROWCOUNT;

    DELETE FROM staging.ProductImport WHERE [ImportFileId] = @ImportFileId;
    DECLARE @np INT = @@ROWCOUNT;

    DELETE FROM staging.ImportFiles
     WHERE [Id] = @ImportFileId AND [CompanyGUID] = @CompanyGUID;

    COMMIT TRANSACTION;

    SELECT @nt + @np AS LignesSupprimees;
END
GO

-- -----------------------------------------------------------------------------
-- Les prompts d'extraction par l'IA, ranges ou vivent les autres
--
--   Ils rendent exactement ce que s0604 lit : un tableau "rows". Quoi qu'ils
--   disent, l'ecran refuse une ligne dont le nom ne figure pas dans le
--   fichier, et un montant qu'il n'y retrouve pas.
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_IMPORT_CLIENTS')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_IMPORT_CLIENTS', N'');
IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_IMPORT_FOURNISSEURS')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_IMPORT_FOURNISSEURS', N'');
IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_IMPORT_PRODUITS')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value]) VALUES ('PROMPT_IMPORT_PRODUITS', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu reçois le contenu brut d''un fichier exporté d''un logiciel comptable ou d''un tableur : la liste des clients d''une entreprise. Le fichier peut être mal formaté : lignes de titre, colonnes décalées, séparateurs incohérents, adresse complète dans une seule cellule.

Extrais chaque client.

Règles :
- Un client = un élément de "rows". Ignore les lignes de titre, d''en-tête, de total et de pied de page.
- "name" est le nom du client (l''entreprise, ou la personne s''il n''y a pas d''entreprise), recopié EXACTEMENT comme dans le fichier.
- "contact_name" est la personne à joindre, si le fichier la distingue du nom du client.
- Si l''adresse tient dans une seule cellule (« 123 rue Principale, Montréal QC H2X 1Y4 »), découpe-la : rue dans "address1", ville dans "city", province en code de deux lettres (QC, ON…) dans "province", code postal dans "postal_code". Pour une adresse hors du Canada et des États-Unis, ou si le découpage n''est pas certain, laisse "province" à null et recopie le code postal en entier, tel qu''il figure.
- Recopie téléphones, courriels, numéros de TPS et de TVQ tels qu''ils figurent au fichier.
- "balance" est le solde du client s''il figure au fichier, en nombre décimal avec un point (1,234.56 devient 1234.56 ; 1 234,56 devient 1234.56), sinon null. N''invente et ne calcule aucun montant.
- Une valeur absente vaut null. N''invente rien.

Réponds UNIQUEMENT par un objet JSON, sans texte autour ni bloc de code :
{"rows":[{"name":"...","contact_name":null,"address1":null,"address2":null,"city":null,"province":null,"postal_code":null,"phone":null,"email":null,"tps":null,"tvq":null,"balance":null}]}'
 WHERE [ParamName] = 'PROMPT_IMPORT_CLIENTS';
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu reçois le contenu brut d''un fichier exporté d''un logiciel comptable ou d''un tableur : la liste des fournisseurs d''une entreprise. Le fichier peut être mal formaté : lignes de titre, colonnes décalées, séparateurs incohérents, adresse complète dans une seule cellule.

Extrais chaque fournisseur.

Règles :
- Un fournisseur = un élément de "rows". Ignore les lignes de titre, d''en-tête, de total et de pied de page.
- "name" est le nom du fournisseur (l''entreprise, ou la personne s''il n''y a pas d''entreprise), recopié EXACTEMENT comme dans le fichier.
- "contact_name" est la personne à joindre, si le fichier la distingue du nom du fournisseur.
- Si l''adresse tient dans une seule cellule (« 123 rue Principale, Montréal QC H2X 1Y4 »), découpe-la : rue dans "address1", ville dans "city", province en code de deux lettres (QC, ON…) dans "province", code postal dans "postal_code". Pour une adresse hors du Canada et des États-Unis, ou si le découpage n''est pas certain, laisse "province" à null et recopie le code postal en entier, tel qu''il figure.
- Recopie téléphones, courriels, numéros de TPS et de TVQ tels qu''ils figurent au fichier.
- "balance" est le solde dû au fournisseur s''il figure au fichier, en nombre décimal avec un point (1,234.56 devient 1234.56 ; 1 234,56 devient 1234.56), sinon null. N''invente et ne calcule aucun montant.
- Une valeur absente vaut null. N''invente rien.

Réponds UNIQUEMENT par un objet JSON, sans texte autour ni bloc de code :
{"rows":[{"name":"...","contact_name":null,"address1":null,"address2":null,"city":null,"province":null,"postal_code":null,"phone":null,"email":null,"tps":null,"tvq":null,"balance":null}]}'
 WHERE [ParamName] = 'PROMPT_IMPORT_FOURNISSEURS';
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu reçois le contenu brut d''un fichier exporté d''un logiciel comptable ou d''un tableur : la liste des produits et services qu''une entreprise vend. Le fichier peut être mal formaté : lignes de titre, colonnes décalées, séparateurs incohérents.

Extrais chaque produit ou service.

Règles :
- Un produit ou service = un élément de "rows". Ignore les lignes de titre, d''en-tête, de catégorie, de total et de pied de page.
- "name" est le nom du produit ou du service, recopié EXACTEMENT comme dans le fichier.
- "description" est la description de vente, sinon null.
- "price" est le prix de vente (ou le tarif), en nombre décimal avec un point (1,234.56 devient 1234.56 ; 1 234,56 devient 1234.56), sinon null. N''invente et ne calcule aucun prix.
- "taxable" vaut true si le fichier indique que l''article est taxable (Oui, Yes, Taxable, TPS/TVQ…), false s''il est indiqué non taxable ou exonéré (Non, No, Exempt, Exonéré), sinon null.
- Une valeur absente vaut null. N''invente rien.

Réponds UNIQUEMENT par un objet JSON, sans texte autour ni bloc de code :
{"rows":[{"name":"...","description":null,"price":null,"taxable":null}]}'
 WHERE [ParamName] = 'PROMPT_IMPORT_PRODUITS';
GO

PRINT 'T219_Import_clients_fournisseurs_produits.sql : termine.';
GO
