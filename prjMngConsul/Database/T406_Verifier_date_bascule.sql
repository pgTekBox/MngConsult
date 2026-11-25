-- =============================================================================
-- T406 — Importation 2, étape 2 : vérifier la date de bascule avant d'aller plus loin
--
-- Deux erreurs ne se voyaient qu'à la fin, quand la balance restait vide ou
-- que l'écriture d'ouverture était refusée :
--   1) une date AVANT le début des livres de la source : la balance de
--      vérification lue à cette date est vide (QuickBooks : NoReportData) ;
--   2) une date hors de tout exercice ouvert de 60secondes : l'écriture
--      d'ouverture n'a aucune période où tomber (s1025 : BLOQUE).
--
-- Le début des livres vient de la dernière fiche de la source en préparation
-- (staging.SocieteImport, « Début des livres (source) ») ; sans extraction
-- préalable, ce contrôle est sauté — il n'y a rien pour le faire.
-- La période suit la même règle que s1025 : exercice OUVERT qui contient la
-- date, période du mois OUVERTE.
--
-- La DATE PROPOSÉE (T406, 2e version) : la clôture des livres de la source + 1 jour
-- si elle existe ; sinon le début de l'exercice en cours (mois de début d'exercice
-- de la source) ; jamais avant le début des livres. Une compagnie qui a deux ans
-- d'historique part ainsi d'une balance qui contient cet historique, au lieu
-- d'une balance presque vide au tout début de ses livres.
--
--   s1030VerifierDateBascule @CompanyGUID, @Date
--   → Ok (BIT), Motif (VARCHAR : OK | AVANT_LIVRES | SANS_PERIODE),
--     DebutLivres (DATE), ExerciceDebut, ExerciceFin (le dernier exercice ouvert),
--     DateProposee (DATE), ClotureLivres (DATE), MoisExercice (INT)
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1030VerifierDateBascule]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Date        DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Le début des livres chez la source, d'après la dernière fiche chargée.
    DECLARE @DebutLivres DATE =
        (SELECT TOP 1 TRY_CONVERT(DATE, s.[ValeurSource], 23)
           FROM staging.SocieteImport s
          WHERE s.[CompanyGUID] = @CompanyGUID
            AND s.[Libelle] LIKE N'Début des livres%'
          ORDER BY s.[ImportFileId] DESC, s.[Id] DESC);

    DECLARE @Cloture DATE =
        (SELECT TOP 1 TRY_CONVERT(DATE, s.[ValeurSource], 23)
           FROM staging.SocieteImport s
          WHERE s.[CompanyGUID] = @CompanyGUID
            AND s.[Libelle] LIKE N'Clôture des livres%'
          ORDER BY s.[ImportFileId] DESC, s.[Id] DESC);

    DECLARE @MoisNom NVARCHAR(50) =
        (SELECT TOP 1 LTRIM(RTRIM(s.[ValeurSource]))
           FROM staging.SocieteImport s
          WHERE s.[CompanyGUID] = @CompanyGUID
            AND s.[Libelle] LIKE N'Mois de début d''exercice%'
          ORDER BY s.[ImportFileId] DESC, s.[Id] DESC);
    DECLARE @Mois INT = CASE LOWER(@MoisNom)
        WHEN 'january' THEN 1 WHEN 'february' THEN 2 WHEN 'march' THEN 3 WHEN 'april' THEN 4
        WHEN 'may' THEN 5 WHEN 'june' THEN 6 WHEN 'july' THEN 7 WHEN 'august' THEN 8
        WHEN 'september' THEN 9 WHEN 'october' THEN 10 WHEN 'november' THEN 11 WHEN 'december' THEN 12
        ELSE ISNULL(TRY_CAST(@MoisNom AS INT), 1) END;
    IF @Mois NOT BETWEEN 1 AND 12 SET @Mois = 1;

    -- Le début de l'exercice en cours chez la source.
    DECLARE @Auj DATE = CAST(GETDATE() AS DATE);
    DECLARE @DebutExercice DATE = DATEFROMPARTS(YEAR(@Auj), @Mois, 1);
    IF @DebutExercice > @Auj SET @DebutExercice = DATEADD(YEAR, -1, @DebutExercice);

    DECLARE @Proposee DATE = CASE WHEN @Cloture IS NOT NULL THEN DATEADD(DAY, 1, @Cloture) ELSE @DebutExercice END;
    IF @DebutLivres IS NOT NULL AND @Proposee < @DebutLivres SET @Proposee = @DebutLivres;

    DECLARE @Periode INT = (SELECT TOP 1 p.[id] FROM dbo.T112Periodes p
                              JOIN dbo.T111Exercices ex ON ex.[id] = p.[exercice_id]
                             WHERE p.[CompanyGUID] = @CompanyGUID
                               AND @Date BETWEEN ex.[date_debut] AND ex.[date_fin]
                               AND p.[mois] = MONTH(@Date)
                               AND p.[statut] = 'OUVERTE' AND ex.[statut] = 'OUVERT');

    -- Pour le message : le dernier exercice ouvert de la compagnie.
    DECLARE @ExDebut DATE, @ExFin DATE;
    SELECT TOP 1 @ExDebut = ex.[date_debut], @ExFin = ex.[date_fin]
      FROM dbo.T111Exercices ex
     WHERE ex.[CompanyGUID] = @CompanyGUID AND ex.[statut] = 'OUVERT'
     ORDER BY ex.[date_fin] DESC;

    SELECT CAST(CASE WHEN (@DebutLivres IS NULL OR @Date >= @DebutLivres) AND @Periode IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS Ok,
           CASE WHEN @DebutLivres IS NOT NULL AND @Date < @DebutLivres THEN 'AVANT_LIVRES'
                WHEN @Periode IS NULL THEN 'SANS_PERIODE'
                ELSE 'OK' END AS Motif,
           @DebutLivres AS DebutLivres,
           @ExDebut     AS ExerciceDebut,
           @ExFin       AS ExerciceFin,
           @Proposee    AS DateProposee,
           @Cloture     AS ClotureLivres,
           @Mois        AS MoisExercice;
END
GO
