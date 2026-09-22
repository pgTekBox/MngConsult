-- =============================================================================
-- T258 — Les pièces jointes de TOUTES les entités, par la passerelle, fichiers compris
--
-- L'API unifiée d'Apideck ne rend les pièces jointes que pour quatre types de
-- document (invoice, bill, expense, quote), et seulement leurs métadonnées.
-- Un contrat attaché à la fiche d'un client, une soumission scannée sur un
-- fournisseur, une photo sur un article : invisibles.
--
-- L'entité native Attachable de QuickBooks, elle, liste tout ce qui est
-- attaché, à qui que ce soit, avec une adresse de téléchargement temporaire.
-- Ce script prépare la table pour cette seconde provenance :
--
--   1) staging.PieceJointeImport gagne la provenance (UNIFIE / PASSERELLE),
--      l'entité porteuse en clair, la note, la catégorie, l'étiquette — et le
--      FICHIER lui-même (Contenu), téléchargé pendant l'extraction tant qu'il
--      pèse moins de 25 Mo. La table cesse d'être une liste : c'est une archive.
--   2) s0814 (la voie unifiée) ne remplace plus que SES lignes.
--   3) s0835 vide les lignes de la passerelle avant une relecture ;
--      s0836 dépose une pièce, avec son fichier, et la rattache quand elle peut
--      (un client ou fournisseur déjà créé ici par son SourceId, un document
--      encore en préparation par son ExterneId) ;
--      s0837 rend le sommaire par entité et la liste, sans le contenu ;
--      s0838 rend le contenu d'une pièce, pour la servir.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La table : deux provenances, et le fichier
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.PieceJointeImport', 'Provenance') IS NULL
    ALTER TABLE staging.PieceJointeImport ADD [Provenance] VARCHAR(20) NOT NULL
        CONSTRAINT DF_PieceJointe_Provenance DEFAULT ('UNIFIE');
IF COL_LENGTH('staging.PieceJointeImport', 'EntiteNom')    IS NULL ALTER TABLE staging.PieceJointeImport ADD [EntiteNom]    NVARCHAR(500)  NULL;   -- le nom du client, du fournisseur, de l'article…
IF COL_LENGTH('staging.PieceJointeImport', 'Note')         IS NULL ALTER TABLE staging.PieceJointeImport ADD [Note]         NVARCHAR(1000) NULL;
IF COL_LENGTH('staging.PieceJointeImport', 'Categorie')    IS NULL ALTER TABLE staging.PieceJointeImport ADD [Categorie]    NVARCHAR(100)  NULL;   -- Contract, Receipt, Photo…
IF COL_LENGTH('staging.PieceJointeImport', 'Etiquette')    IS NULL ALTER TABLE staging.PieceJointeImport ADD [Etiquette]    NVARCHAR(100)  NULL;
IF COL_LENGTH('staging.PieceJointeImport', 'Contenu')      IS NULL ALTER TABLE staging.PieceJointeImport ADD [Contenu]      VARBINARY(MAX) NULL;   -- le fichier
IF COL_LENGTH('staging.PieceJointeImport', 'TelechargeLe') IS NULL ALTER TABLE staging.PieceJointeImport ADD [TelechargeLe] DATETIME       NULL;
IF COL_LENGTH('staging.PieceJointeImport', 'LieTable')     IS NULL ALTER TABLE staging.PieceJointeImport ADD [LieTable]     VARCHAR(40)    NULL;   -- où l'entité porteuse a été retrouvée ici
IF COL_LENGTH('staging.PieceJointeImport', 'LieId')        IS NULL ALTER TABLE staging.PieceJointeImport ADD [LieId]        INT            NULL;
GO

-- -----------------------------------------------------------------------------
-- 2) s0814ChargerPiecesJointes — la voie unifiée ne remplace plus que la sienne
--    Même corps qu'en T240, à un filtre près sur le DELETE.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0814ChargerPiecesJointes]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL, @Pieces NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50392, 'Aucune compagnie : impossible de déposer ces pièces jointes.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.PieceJointeImport WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'UNIFIE';

    INSERT INTO staging.PieceJointeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Provenance], [DocumentGenre], [DocumentExterneId],
         [DocumentNumero], [ExterneId], [NomFichier], [Description], [TypeContenu],
         [Taille], [Url], [DateSource], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID, 'UNIFIE',
           LEFT(j.[genre], 30), LEFT(j.[document_id], 100), LEFT(j.[document_numero], 60),
           LEFT(j.[externe_id], 100), j.[nom], j.[description], LEFT(j.[type], 150),
           TRY_CONVERT(BIGINT, j.[taille]),
           j.[url],
           TRY_CONVERT(DATETIME, NULLIF(j.[date], '')),
           CASE WHEN NULLIF(j.[url], '') IS NULL THEN 'SANS_LIEN' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(j.[url], '') IS NULL
                THEN N'La source ne donne pas d''adresse de téléchargement : le fichier restera inaccessible.' END
      FROM OPENJSON(@Pieces)
           WITH ([genre]           NVARCHAR(40)   '$.genre',
                 [document_id]     NVARCHAR(200)  '$.document_id',
                 [document_numero] NVARCHAR(100)  '$.document_numero',
                 [externe_id]      NVARCHAR(200)  '$.externe_id',
                 [nom]             NVARCHAR(400)  '$.nom',
                 [description]     NVARCHAR(1000) '$.description',
                 [type]            NVARCHAR(200)  '$.type',
                 [taille]          NVARCHAR(40)   '$.taille',
                 [url]             NVARCHAR(2000) '$.url',
                 [date]            NVARCHAR(60)   '$.date') AS j;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbPieces],
           COUNT(DISTINCT [DocumentExterneId]) AS [NbDocuments],
           SUM(CASE WHEN [Statut] = 'SANS_LIEN' THEN 1 ELSE 0 END) AS [NbSansLien],
           SUM(ISNULL([Taille], 0)) AS [TailleTotale]
      FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'UNIFIE';
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0835ViderPiecesJointesPasserelle — avant une relecture
--    Une extraction relit toute la source : la précédente n'a plus rien à
--    apprendre. Les lignes de la voie unifiée ne sont pas touchées.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0835ViderPiecesJointesPasserelle]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL THROW 50393, 'Aucune compagnie.', 1;

    DELETE FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'PASSERELLE';

    SELECT @@ROWCOUNT AS [NbSupprimees];
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0836ChargerPieceJointePasserelle — une pièce, avec son fichier
--
--    Une pièce à la fois parce que le fichier voyage en VARBINARY, pas en JSON
--    : un contrat de 20 Mo en base64 dans un OPENJSON ne serait ni sobre ni
--    sûr. Le rattachement est tenté ici, en SQL, où les deux côtés sont :
--      · Customer / Vendor  → dbo.T050Party par SourceId (posé par T257) ;
--      · un document        → staging.DocumentImport par ExterneId.
--    Rien n'est deviné par le nom.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0836ChargerPieceJointePasserelle]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Genre        NVARCHAR(40),
    @EntiteId     NVARCHAR(200),
    @EntiteNom    NVARCHAR(500) = NULL,
    @ExterneId    NVARCHAR(200),
    @Nom          NVARCHAR(400) = NULL,
    @Note         NVARCHAR(1000) = NULL,
    @Type         NVARCHAR(200) = NULL,
    @Taille       BIGINT = NULL,
    @Url          NVARCHAR(2000) = NULL,
    @Date         DATETIME = NULL,
    @Categorie    NVARCHAR(100) = NULL,
    @Etiquette    NVARCHAR(100) = NULL,
    @Statut       VARCHAR(20),
    @Anomalie     NVARCHAR(400) = NULL,
    @Contenu      VARBINARY(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL THROW 50394, 'Aucune compagnie : impossible de déposer cette pièce jointe.', 1;

    DECLARE @LieTable VARCHAR(40) = NULL, @LieId INT = NULL;

    IF @Genre IN ('Customer', 'Vendor') AND NULLIF(@EntiteId, '') IS NOT NULL
        SELECT TOP 1 @LieTable = 'T050Party', @LieId = [Id]
          FROM dbo.T050Party
         WHERE [CompanyGUID] = @CompanyGUID AND ISNULL([isDeleted], 0) = 0 AND [SourceId] = @EntiteId
         ORDER BY [Id];

    IF @LieId IS NULL AND @Genre IN ('Invoice', 'Bill', 'CreditMemo', 'VendorCredit', 'Purchase', 'SalesReceipt')
       AND NULLIF(@EntiteId, '') IS NOT NULL
        SELECT TOP 1 @LieTable = 'DocumentImport', @LieId = [Id]
          FROM staging.DocumentImport
         WHERE [CompanyGUID] = @CompanyGUID AND [ExterneId] = @EntiteId
         ORDER BY [Id];

    INSERT INTO staging.PieceJointeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Provenance],
         [DocumentGenre], [DocumentExterneId], [DocumentNumero], [EntiteNom],
         [ExterneId], [NomFichier], [Description], [Note], [TypeContenu], [Taille], [Url], [DateSource],
         [Categorie], [Etiquette], [Contenu], [TelechargeLe], [LieTable], [LieId], [Statut], [Anomalie])
    VALUES
        (@RunId, @ImportFileId, @CompanyGUID, 'PASSERELLE',
         LEFT(ISNULL(NULLIF(@Genre, ''), 'Aucune'), 30), LEFT(ISNULL(@EntiteId, ''), 100), NULL, @EntiteNom,
         LEFT(@ExterneId, 100), @Nom, @Note, @Note, LEFT(@Type, 150), @Taille, @Url, @Date,
         @Categorie, @Etiquette, @Contenu, CASE WHEN @Contenu IS NULL THEN NULL ELSE GETDATE() END,
         @LieTable, @LieId, @Statut, @Anomalie);

    SELECT SCOPE_IDENTITY() AS [Id], @LieTable AS [LieTable], @LieId AS [LieId];
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0837GetPiecesJointesToutes — le sommaire par entité, puis la liste
--    Sans le contenu : DATALENGTH suffit à dire qu'il est là.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0837GetPiecesJointesToutes]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Genre       NVARCHAR(40) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [DocumentGenre] AS [Genre],
           COUNT(*) AS [Nb],
           SUM(ISNULL([Taille], 0)) AS [Taille],
           SUM(CASE WHEN [Contenu] IS NOT NULL THEN 1 ELSE 0 END) AS [NbTelechargees],
           SUM(CASE WHEN [Statut] NOT IN ('TELECHARGE', 'NOUVEAU') THEN 1 ELSE 0 END) AS [NbSoucis]
      FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'PASSERELLE'
     GROUP BY [DocumentGenre]
     ORDER BY [DocumentGenre];

    SELECT p.[Id], p.[DocumentGenre] AS [Genre], p.[DocumentExterneId] AS [EntiteId], p.[EntiteNom],
           p.[ExterneId], p.[NomFichier], p.[Note], p.[TypeContenu], p.[Taille],
           DATALENGTH(p.[Contenu]) AS [Octets], p.[TelechargeLe],
           p.[Url], p.[DateSource], p.[Categorie], p.[Etiquette],
           p.[LieTable], p.[LieId],
           CASE p.[LieTable] WHEN 'T050Party' THEN t.[Name]
                             WHEN 'DocumentImport' THEN d.[Numero] END AS [LieNom],
           p.[Statut], p.[Anomalie], p.[Created]
      FROM staging.PieceJointeImport p
      LEFT JOIN dbo.T050Party t ON p.[LieTable] = 'T050Party' AND t.[Id] = p.[LieId]
      LEFT JOIN staging.DocumentImport d ON p.[LieTable] = 'DocumentImport' AND d.[Id] = p.[LieId]
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Provenance] = 'PASSERELLE'
       AND (@Genre IS NULL OR p.[DocumentGenre] = @Genre)
     ORDER BY CASE WHEN p.[Statut] NOT IN ('TELECHARGE', 'NOUVEAU') THEN 0 ELSE 1 END,
              p.[DocumentGenre], p.[EntiteNom], p.[NomFichier];
END
GO

-- -----------------------------------------------------------------------------
-- 6) s0838GetPieceJointeContenu — le fichier, pour le servir
--    Toujours scopé par compagnie : un Id deviné ne donne rien d'une autre.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0838GetPieceJointeContenu]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [NomFichier], [TypeContenu], [Contenu]
      FROM staging.PieceJointeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Id] = @Id;
END
GO
