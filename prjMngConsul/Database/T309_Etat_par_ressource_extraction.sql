-- =============================================================================
-- T309 — L'issue de chaque ressource, à chaque extraction
--
-- T308 a donné à la carte « QuickBooks, en direct » une note qui suit la
-- dernière extraction. Les cartes « Valider… » veulent la même chose, mais
-- chacune ne regarde qu'une ou quelques ressources : il faut donc savoir, par
-- ressource, si sa dernière lecture a réussi — et ce n'était gardé nulle part.
-- staging.ConnecteurDonnee dit ce qui a été déposé, pas ce qui a échoué ; la
-- phrase laissée dans ConnecteurRun.Note nomme les fautives, mais une phrase
-- ne se filtre pas.
--
--   staging.ConnecteurRessource        une ligne par ressource et par extraction
--   s0893EnregistrerConnecteurRessources  les dépose en un appel, en JSON
--   s0894GetEtatRessources             la dernière issue de chaque ressource
--
-- Les extractions passées sont reprises une fois : ce qui a déposé des lignes
-- a réussi, ce que la phrase nomme a échoué. Les cartes ne partent donc pas
-- de zéro.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.ConnecteurRessource', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ConnecteurRessource
    (
        [Id]          INT IDENTITY(1,1) NOT NULL,
        [RunId]       INT               NOT NULL,
        [CompanyGUID] UNIQUEIDENTIFIER  NOT NULL,
        [Ressource]   VARCHAR(60)       NOT NULL,
        [Nb]          INT               NOT NULL CONSTRAINT DF_ConnecteurRessource_Nb DEFAULT (0),
        [Reussie]     BIT               NOT NULL,
        [Erreur]      NVARCHAR(2000)    NULL,
        [Quand]       DATETIME          NOT NULL CONSTRAINT DF_ConnecteurRessource_Quand DEFAULT (GETDATE()),

        CONSTRAINT PK_ConnecteurRessource PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT FK_ConnecteurRessource_Run FOREIGN KEY ([RunId])
            REFERENCES staging.ConnecteurRun ([Id]) ON DELETE CASCADE
    );

    CREATE INDEX IX_ConnecteurRessource_Etat
        ON staging.ConnecteurRessource ([CompanyGUID], [Ressource], [Quand] DESC);
END
GO

-- -----------------------------------------------------------------------------
-- s0893EnregistrerConnecteurRessources
--   Le compte rendu d'une extraction, ressource par ressource, en un appel :
--   [{ "cle": "invoices", "nb": 120, "reussie": true, "erreur": null }, …]
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0893EnregistrerConnecteurRessources]
    @RunId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Lignes      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM staging.ConnecteurRun
                    WHERE [Id] = @RunId AND [CompanyGUID] = @CompanyGUID)
        THROW 50362, 'Extraction introuvable pour cette compagnie.', 1;

    DELETE FROM staging.ConnecteurRessource WHERE [RunId] = @RunId;

    INSERT INTO staging.ConnecteurRessource ([RunId], [CompanyGUID], [Ressource], [Nb], [Reussie], [Erreur])
    SELECT @RunId, @CompanyGUID, LEFT(j.[Cle], 60), ISNULL(j.[Nb], 0), ISNULL(j.[Reussie], 0), LEFT(j.[Erreur], 2000)
      FROM OPENJSON(@Lignes)
           WITH ([Cle]     VARCHAR(100)   '$.cle',
                 [Nb]      INT            '$.nb',
                 [Reussie] BIT            '$.reussie',
                 [Erreur]  NVARCHAR(MAX)  '$.erreur') AS j
     WHERE j.[Cle] IS NOT NULL;
END
GO

-- -----------------------------------------------------------------------------
-- s0894GetEtatRessources
--   Pour chaque ressource déjà lue au moins une fois : sa dernière issue.
--   Une ressource jamais lue n'apparaît pas — c'est à l'appelant de le dire.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0894GetEtatRessources]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT x.[Ressource], x.[Nb], x.[Reussie], x.[Erreur], x.[Quand], x.[RunId]
      FROM (SELECT r.*,
                   ROW_NUMBER() OVER (PARTITION BY r.[Ressource] ORDER BY r.[Quand] DESC, r.[Id] DESC) AS rang
              FROM staging.ConnecteurRessource r
             WHERE r.[CompanyGUID] = @CompanyGUID) x
     WHERE x.rang = 1
     ORDER BY x.[Ressource];
END
GO

-- -----------------------------------------------------------------------------
-- Reprise des extractions passées, une seule fois : les ressources qui ont
-- déposé des lignes ont réussi ; celles que la phrase de clôture nomme ont
-- échoué. Une extraction déjà reprise (ou enregistrée par le moteur) est laissée.
-- -----------------------------------------------------------------------------
INSERT INTO staging.ConnecteurRessource ([RunId], [CompanyGUID], [Ressource], [Nb], [Reussie], [Erreur], [Quand])
SELECT d.[RunId], r.[CompanyGUID], d.[Ressource], COUNT(*), 1, NULL, ISNULL(r.[Fin], r.[Debut])
  FROM staging.ConnecteurDonnee d
  JOIN staging.ConnecteurRun r ON r.[Id] = d.[RunId]
 WHERE r.[Statut] <> 'EN_COURS'
   AND NOT EXISTS (SELECT 1 FROM staging.ConnecteurRessource x WHERE x.[RunId] = d.[RunId])
 GROUP BY d.[RunId], r.[CompanyGUID], d.[Ressource], ISNULL(r.[Fin], r.[Debut]);

INSERT INTO staging.ConnecteurRessource ([RunId], [CompanyGUID], [Ressource], [Nb], [Reussie], [Erreur], [Quand])
SELECT r.[Id], r.[CompanyGUID], LEFT(LTRIM(RTRIM(s.[value])), 60), 0, 0,
       N'En échec à cette extraction (détail non conservé).', ISNULL(r.[Fin], r.[Debut])
  FROM staging.ConnecteurRun r
 CROSS APPLY STRING_SPLIT(
       REPLACE(SUBSTRING(r.[Note], CHARINDEX(' : ', r.[Note]) + 3, 4000), '.', ''), ',') s
 WHERE r.[Statut] = 'PARTIEL'
   AND r.[Note] LIKE '%ressource(s) en échec sur%:%'
   AND LTRIM(RTRIM(s.[value])) <> ''
   AND NOT EXISTS (SELECT 1 FROM staging.ConnecteurRessource x
                    WHERE x.[RunId] = r.[Id] AND x.[Ressource] = LEFT(LTRIM(RTRIM(s.[value])), 60));
GO
