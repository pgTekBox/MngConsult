-- =============================================================================
-- T242 — Une chaîne vide n'est pas un zéro non plus
--
-- T234 avait corrigé les dates : TRY_CONVERT(DATE, '') rend 1900-01-01, pas NULL.
-- Le sondage complet montre que le problème est plus large, et qu'il ne suit
-- AUCUNE logique évidente :
--
--     TRY_CONVERT(INT,      '')  ->  0
--     TRY_CONVERT(BIGINT,   '')  ->  0
--     TRY_CONVERT(MONEY,    '')  ->  0.00
--     TRY_CONVERT(BIT,      '')  ->  0
--     TRY_CONVERT(DATE,     '')  ->  1900-01-01
--     TRY_CONVERT(DATETIME, '')  ->  1900-01-01 00:00
--     TRY_CONVERT(DECIMAL,  '')  ->  NULL        <-- le seul qui se comporte bien
--
-- Autrement dit : DECIMAL est l'exception, pas la règle. Et comme le côté VB
-- envoie "" pour tout champ absent chez la source, une taille de fichier
-- inconnue devenait « 0 octet » et un jour du mois inconnu devenait « le 0 ».
-- Des valeurs qui ont l'air de données.
--
-- Remède, partout où un nombre vient d'un JSON externe : NULLIF(x, '') AVANT la
-- conversion. Corrigé ici dans s0812, s0814 et s0817.
--
-- ⚠️ RÈGLE À RETENIR : TRY_CONVERT protège d'une valeur ILLISIBLE, jamais d'une
--    valeur VIDE. Toujours NULLIF d'abord — sauf pour DECIMAL, où c'est inutile
--    mais inoffensif.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 6) s0817ChargerConditionsPaiement
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0817ChargerConditionsPaiement]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL, @Conditions NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50393, 'Aucune compagnie : impossible de déposer ces conditions.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.ConditionPaiementImport WHERE [CompanyGUID] = @CompanyGUID;

    ;WITH Lu AS (
        SELECT j.*, ROW_NUMBER() OVER (PARTITION BY NULLIF(j.[externe_id], '') ORDER BY j.[rang]) AS [Occ]
          FROM OPENJSON(@Conditions)
               WITH ([rang]        INT           '$.rang',
                     [externe_id]  NVARCHAR(200) '$.externe_id',
                     [nom]         NVARCHAR(200) '$.nom',
                     [type]        NVARCHAR(40)  '$.type',
                     [jours]       NVARCHAR(40)  '$.jours',
                     [jours_esc]   NVARCHAR(40)  '$.jours_escompte',
                     [pct_esc]     NVARCHAR(40)  '$.pourcent_escompte',
                     [jour_mois]   NVARCHAR(40)  '$.jour_du_mois',
                     [actif]       NVARCHAR(20)  '$.actif') AS j
    )
    INSERT INTO staging.ConditionPaiementImport
        ([RunId], [ImportFileId], [CompanyGUID], [Rang], [ExterneId], [Nom], [TypeSource],
         [JoursEcheance], [JoursEscompte], [PourcentEscompte], [JourDuMois], [Actif],
         [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID, l.[rang],
           NULLIF(l.[externe_id], ''), NULLIF(l.[nom], ''), NULLIF(l.[type], ''),
           TRY_CONVERT(INT, NULLIF(l.[jours], '')),
           TRY_CONVERT(INT, NULLIF(l.[jours_esc], '')),
           TRY_CONVERT(DECIMAL(9,4), l.[pct_esc]),
           TRY_CONVERT(INT, NULLIF(l.[jour_mois], '')),
           CASE WHEN LOWER(ISNULL(l.[actif], '')) IN ('true', '1') THEN 1
                WHEN LOWER(ISNULL(l.[actif], '')) IN ('false', '0') THEN 0 END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL THEN 'INVALIDE'
                WHEN l.[Occ] > 1 THEN 'DOUBLON' ELSE 'NOUVEAU' END,
           CASE WHEN NULLIF(l.[nom], '') IS NULL
                     THEN N'Condition sans nom : rien pour la désigner.'
                WHEN l.[Occ] > 1
                     THEN N'Cet identifiant apparaît plusieurs fois dans la même extraction.'
                ELSE NULL END
      FROM Lu l;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbConditions],
           SUM(CASE WHEN [Statut] = 'NOUVEAU' THEN 1 ELSE 0 END)  AS [NbNouvelles],
           SUM(CASE WHEN [Actif] = 1 THEN 1 ELSE 0 END)           AS [NbActives],
           SUM(CASE WHEN [Statut] <> 'NOUVEAU' THEN 1 ELSE 0 END) AS [NbAnomalies]
      FROM staging.ConditionPaiementImport
     WHERE [CompanyGUID] = @CompanyGUID;
END

GO


-- -----------------------------------------------------------------------------
-- 5) s0814ChargerPiecesJointes
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

    DELETE FROM staging.PieceJointeImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.PieceJointeImport
        ([RunId], [ImportFileId], [CompanyGUID], [DocumentGenre], [DocumentExterneId],
         [DocumentNumero], [ExterneId], [NomFichier], [Description], [TypeContenu],
         [Taille], [Url], [DateSource], [Statut], [Anomalie])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           LEFT(j.[genre], 30), LEFT(j.[document_id], 100), LEFT(j.[document_numero], 60),
           LEFT(j.[externe_id], 100), j.[nom], j.[description], LEFT(j.[type], 150),
           TRY_CONVERT(BIGINT, NULLIF(j.[taille], '')),
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
     WHERE [CompanyGUID] = @CompanyGUID;
END

GO


-- -----------------------------------------------------------------------------
-- 4) s0812ChargerBalanceAgee
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0812ChargerBalanceAgee]
    @RunId INT, @CompanyGUID UNIQUEIDENTIFIER, @Genre VARCHAR(20),
    @ImportFileId INT = NULL, @Lignes NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL THROW 50390, 'Aucune compagnie : impossible de déposer cette balance.', 1;
    IF @Genre NOT IN ('Client', 'Fournisseur') THROW 50391, 'Genre de balance âgée inconnu.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.BalanceAgeeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;

    INSERT INTO staging.BalanceAgeeImport
        ([RunId], [ImportFileId], [CompanyGUID], [Genre], [DateArrete], [LongueurPeriode],
         [TiersExterneId], [TiersNom], [Devise], [TotalTiers],
         [PeriodeOrdre], [PeriodeDebut], [PeriodeFin], [Montant])
    SELECT @RunId, @ImportFileId, @CompanyGUID, @Genre,
           TRY_CONVERT(DATE, NULLIF(j.[arrete], '')),
           TRY_CONVERT(INT, NULLIF(j.[longueur], '')),
           LEFT(j.[tiers_id], 100), j.[tiers], LEFT(j.[devise], 10),
           TRY_CONVERT(DECIMAL(18,2), j.[total_tiers]),
           TRY_CONVERT(INT, NULLIF(j.[ordre], '')),
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           TRY_CONVERT(DECIMAL(18,2), j.[montant])
      FROM OPENJSON(@Lignes)
           WITH ([arrete]      NVARCHAR(40)  '$.arrete',
                 [longueur]    NVARCHAR(40)  '$.longueur',
                 [tiers_id]    NVARCHAR(200) '$.tiers_id',
                 [tiers]       NVARCHAR(500) '$.tiers',
                 [devise]      NVARCHAR(20)  '$.devise',
                 [total_tiers] NVARCHAR(40)  '$.total_tiers',
                 [ordre]       NVARCHAR(40)  '$.ordre',
                 [debut]       NVARCHAR(40)  '$.debut',
                 [fin]         NVARCHAR(40)  '$.fin',
                 [montant]     NVARCHAR(40)  '$.montant') AS j;

    -- Le tiers retrouvé par son nom, comme partout ailleurs.
    UPDATE b
       SET b.[PartyGUID] = p.[PartyGUID]
      FROM staging.BalanceAgeeImport b
      JOIN dbo.T050Party p
        ON p.[CompanyGUID] = @CompanyGUID
       AND (p.[Name] = b.[TiersNom] OR p.[DisplayName] = b.[TiersNom])
     WHERE b.[CompanyGUID] = @CompanyGUID AND b.[Genre] = @Genre
       AND b.[TiersNom] IS NOT NULL;

    COMMIT TRANSACTION;

    SELECT COUNT(*) AS [NbLignes],
           COUNT(DISTINCT [TiersExterneId]) AS [NbTiers],
           SUM(CASE WHEN [PartyGUID] IS NULL THEN 1 ELSE 0 END) AS [NbSansTiers],
           SUM([Montant]) AS [Total]
      FROM staging.BalanceAgeeImport
     WHERE [CompanyGUID] = @CompanyGUID AND [Genre] = @Genre;
END

GO

