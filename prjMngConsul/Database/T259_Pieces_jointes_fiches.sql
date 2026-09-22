-- =============================================================================
-- T259 — Les pièces jointes rejoignent les fiches clients et fournisseurs
--
-- T258 a ramené les fichiers en préparation et dit à quel tiers chacun
-- appartient. Mais 60Sec-AI n'avait nulle part où ranger un fichier sur un
-- tiers : T050Party porte un logo (ImageGUID), rien d'autre. Ce script crée
-- l'endroit, et le geste qui y mène :
--
--   1) dbo.T057PartyDocument — un fichier attaché à un tiers, avec son contenu,
--      d'où il vient (Source / SourceId) et ce que la source en disait (note,
--      catégorie, date). Prévu pour recevoir aussi, plus tard, ce qu'on
--      déposera à la main depuis la fiche : Source = 'Manuel'.
--   2) s0839RattacherPiecesJointes — depuis la préparation vers T057, pour
--      chaque pièce qui a un fichier ET un tiers retrouvé. Retrouve d'abord ce
--      que T258 n'avait pas pu : les tiers créés AVANT T257 n'ont pas de
--      SourceId, alors on accepte le nom exact — et on le dit (Anomalie).
--      Idempotent : une pièce déjà rattachée (même tiers, même SourceId)
--      n'est pas dupliquée.
--   3) s0840GetPartyDocuments — la liste, pour la fiche.
--   4) s0841GetPartyDocumentContenu — le fichier, pour le servir.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) dbo.T057PartyDocument
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.T057PartyDocument', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T057PartyDocument
    (
        [Id]           INT IDENTITY(1,1) NOT NULL,
        [CompanyGUID]  UNIQUEIDENTIFIER  NOT NULL,
        [PartyId]      INT               NOT NULL,

        [NomFichier]   NVARCHAR(400)     NULL,
        [TypeContenu]  NVARCHAR(150)     NULL,
        [Taille]       BIGINT            NULL,
        [Contenu]      VARBINARY(MAX)    NOT NULL,

        [Note]         NVARCHAR(1000)    NULL,
        [Categorie]    NVARCHAR(100)     NULL,

        -- D'où vient le fichier : 'QuickBooks' (import), 'Manuel' (déposé sur la fiche)…
        [Source]       VARCHAR(30)       NOT NULL CONSTRAINT DF_T057_Source DEFAULT ('Manuel'),
        [SourceId]     NVARCHAR(100)     NULL,   -- l'Id de la pièce chez la source
        [SourceEntite] NVARCHAR(40)      NULL,   -- Customer, Vendor…
        [DateSource]   DATETIME          NULL,

        [Created]      DATETIME          NOT NULL CONSTRAINT DF_T057_Created DEFAULT (GETDATE()),
        [CreatedBy]    INT               NULL,
        [isDeleted]    BIT               NOT NULL CONSTRAINT DF_T057_isDeleted DEFAULT (0),

        CONSTRAINT PK_T057PartyDocument PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_T057_Party FOREIGN KEY ([PartyId]) REFERENCES dbo.T050Party ([Id])
    );

    CREATE INDEX IX_T057_Party ON dbo.T057PartyDocument ([CompanyGUID], [PartyId]) WHERE [isDeleted] = 0;
    CREATE INDEX IX_T057_Source ON dbo.T057PartyDocument ([CompanyGUID], [Source], [SourceId]);
END
GO

-- -----------------------------------------------------------------------------
-- 2) s0839RattacherPiecesJointes
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0839RattacherPiecesJointes]
    @CompanyGUID UNIQUEIDENTIFIER,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50395, 'Aucune compagnie : impossible de rattacher les pièces jointes.', 1;

    BEGIN TRANSACTION;

    -- ── a) Retrouver ce qui ne l'était pas encore ──────────────────────────
    -- Par l'identifiant source d'abord : un tiers créé par l'import APRÈS
    -- l'extraction des pièces n'avait pas pu être reconnu à ce moment-là.
    UPDATE p
       SET p.[LieTable] = 'T050Party', p.[LieId] = t.[Id]
      FROM staging.PieceJointeImport p
     CROSS APPLY (SELECT TOP 1 x.[Id] FROM dbo.T050Party x
                   WHERE x.[CompanyGUID] = @CompanyGUID AND ISNULL(x.[isDeleted], 0) = 0
                     AND x.[SourceId] = p.[DocumentExterneId]
                   ORDER BY x.[Id]) t
     WHERE p.[CompanyGUID] = @CompanyGUID AND p.[Provenance] = 'PASSERELLE'
       AND p.[LieId] IS NULL AND p.[DocumentGenre] IN ('Customer', 'Vendor')
       AND NULLIF(p.[DocumentExterneId], '') IS NOT NULL;

    -- Par le nom exact ensuite — pour les tiers d'avant T257, qui n'ont pas de
    -- SourceId. C'est une supposition raisonnable, pas une certitude : on
    -- l'écrit dans l'anomalie pour que l'écran le montre.
    UPDATE p
       SET p.[LieTable] = 'T050Party', p.[LieId] = t.[Id],
           p.[Anomalie] = N'Tiers retrouvé par son nom, faute d''identifiant source.'
      FROM staging.PieceJointeImport p
     CROSS APPLY (SELECT TOP 1 x.[Id] FROM dbo.T050Party x
                   WHERE x.[CompanyGUID] = @CompanyGUID AND ISNULL(x.[isDeleted], 0) = 0
                     AND UPPER(LTRIM(RTRIM(x.[Name]))) = UPPER(LTRIM(RTRIM(p.[EntiteNom])))
                   ORDER BY x.[Id]) t
     WHERE p.[CompanyGUID] = @CompanyGUID AND p.[Provenance] = 'PASSERELLE'
       AND p.[LieId] IS NULL AND p.[DocumentGenre] IN ('Customer', 'Vendor')
       AND NULLIF(LTRIM(RTRIM(p.[EntiteNom])), '') IS NOT NULL;

    -- ── b) Rattacher : un fichier + un tiers, pas encore là ─────────────────
    INSERT INTO dbo.T057PartyDocument
        ([CompanyGUID], [PartyId], [NomFichier], [TypeContenu], [Taille], [Contenu],
         [Note], [Categorie], [Source], [SourceId], [SourceEntite], [DateSource], [CreatedBy])
    SELECT @CompanyGUID, p.[LieId], p.[NomFichier], p.[TypeContenu], p.[Taille], p.[Contenu],
           p.[Note], p.[Categorie], 'QuickBooks', p.[ExterneId], p.[DocumentGenre], p.[DateSource], @UserId
      FROM staging.PieceJointeImport p
     WHERE p.[CompanyGUID] = @CompanyGUID AND p.[Provenance] = 'PASSERELLE'
       AND p.[LieTable] = 'T050Party' AND p.[LieId] IS NOT NULL
       AND p.[Contenu] IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.T057PartyDocument d
                        WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyId] = p.[LieId]
                          AND d.[Source] = 'QuickBooks' AND d.[SourceId] = p.[ExterneId]
                          AND d.[isDeleted] = 0);

    DECLARE @Rattachees INT = @@ROWCOUNT;

    -- ── c) Marquer tout ce qui est désormais sur une fiche ──────────────────
    UPDATE p
       SET p.[Statut] = 'RATTACHE'
      FROM staging.PieceJointeImport p
     WHERE p.[CompanyGUID] = @CompanyGUID AND p.[Provenance] = 'PASSERELLE'
       AND p.[LieTable] = 'T050Party' AND p.[LieId] IS NOT NULL
       AND p.[Statut] <> 'RATTACHE'
       AND EXISTS (SELECT 1 FROM dbo.T057PartyDocument d
                    WHERE d.[CompanyGUID] = @CompanyGUID AND d.[PartyId] = p.[LieId]
                      AND d.[Source] = 'QuickBooks' AND d.[SourceId] = p.[ExterneId]
                      AND d.[isDeleted] = 0);

    COMMIT TRANSACTION;

    -- ── d) Le compte rendu ──────────────────────────────────────────────────
    SELECT @Rattachees AS [NbRattachees],
           (SELECT COUNT(*) FROM staging.PieceJointeImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'PASSERELLE'
               AND [Statut] = 'RATTACHE') AS [NbSurFiche],
           (SELECT COUNT(*) FROM staging.PieceJointeImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'PASSERELLE'
               AND [DocumentGenre] IN ('Customer', 'Vendor') AND [LieId] IS NULL) AS [NbSansTiers],
           (SELECT COUNT(*) FROM staging.PieceJointeImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'PASSERELLE'
               AND [DocumentGenre] IN ('Customer', 'Vendor') AND [LieId] IS NOT NULL
               AND [Contenu] IS NULL) AS [NbSansFichier],
           (SELECT COUNT(*) FROM staging.PieceJointeImport
             WHERE [CompanyGUID] = @CompanyGUID AND [Provenance] = 'PASSERELLE'
               AND [DocumentGenre] NOT IN ('Customer', 'Vendor')) AS [NbAutresEntites];
END
GO

-- -----------------------------------------------------------------------------
-- 2b) s0837GetPiecesJointesToutes — « RATTACHE » n'est pas un souci
--     Même corps qu'en T258 ; seule la liste des états sans souci change.
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
           SUM(CASE WHEN [Statut] NOT IN ('TELECHARGE', 'NOUVEAU', 'RATTACHE') THEN 1 ELSE 0 END) AS [NbSoucis]
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
     ORDER BY CASE WHEN p.[Statut] NOT IN ('TELECHARGE', 'NOUVEAU', 'RATTACHE') THEN 0 ELSE 1 END,
              p.[DocumentGenre], p.[EntiteNom], p.[NomFichier];
END
GO

-- -----------------------------------------------------------------------------
-- 3) s0840GetPartyDocuments — la liste d'une fiche, sans le contenu
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0840GetPartyDocuments]
    @CompanyGUID UNIQUEIDENTIFIER,
    @PartyId     INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [NomFichier], [TypeContenu], [Taille], DATALENGTH([Contenu]) AS [Octets],
           [Note], [Categorie], [Source], [SourceId], [SourceEntite], [DateSource], [Created]
      FROM dbo.T057PartyDocument
     WHERE [CompanyGUID] = @CompanyGUID AND [PartyId] = @PartyId AND [isDeleted] = 0
     ORDER BY ISNULL([DateSource], [Created]) DESC, [Id] DESC;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0841GetPartyDocumentContenu — le fichier
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0841GetPartyDocumentContenu]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [NomFichier], [TypeContenu], [Contenu]
      FROM dbo.T057PartyDocument
     WHERE [CompanyGUID] = @CompanyGUID AND [Id] = @Id AND [isDeleted] = 0;
END
GO
