-- =============================================================================
-- T414 — Importation 2 : les taxes et les paramètres de la compagnie viennent de
--        la source (QuickBooks), à chaque import
--
-- Demande du 2026-11-25 : à l'import, les taxes et les paramètres sont remplacés
-- par ceux de QuickBooks ; les journaux standards et les paramètres sans
-- équivalent (courriel, PDF, numérotation…) restent.
--
-- Ce que s1036 remplace, quand la source le donne :
--   · GST_RATE / QST_RATE et le taux de la compagnie (T069TaxeRate) : les taux
--     TPS et TVQ des codes de taxe reconnus (staging.TaxeImport, RECONNUE) ;
--   · QST_NO / GST_NO : le numéro d'inscription de l'agence de taxes —
--     Revenu Québec → TVQ, Agence du revenu du Canada → TPS (ressource brute
--     tax-agencies de la dernière extraction) ;
--   · FISCAL_YEAR_END : la veille de l'anniversaire de la date de début de
--     l'exercice demandée à l'import (T407DebutExerciceImport, T411) —
--     QuickBooks ne donne qu'un mois ;
--   · TAX_FREQ : la fréquence de déclaration choisie à l'import (@Frequence) ;
--   · BNR : le compte de 60secondes lié au compte « bénéfices non répartis »
--     de la source (SousTypeSource RetainedEarnings), une fois décidé.
-- Le nom, l'adresse et le téléphone sont déjà appliqués par s0791.
-- Rien n'est créé : seule la valeur des paramètres existants change.
--
--   s1036AppliquerParametresSource @CompanyGUID, @Frequence = NULL
--     → Parametre, Avant, Apres (seulement ce qui a changé)
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1036AppliquerParametresSource]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Frequence   VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Change TABLE (Parametre VARCHAR(50), Avant NVARCHAR(200), Apres NVARCHAR(200));

    -- ── Ce que dit la source ────────────────────────────────────────────────
    DECLARE @TPS DECIMAL(9,4) = (SELECT MAX(t.[TauxTPS]) FROM staging.TaxeImport t
                                  WHERE t.[CompanyGUID] = @CompanyGUID AND t.[Statut] = 'RECONNUE' AND t.[TauxTPS] > 0);
    DECLARE @TVQ DECIMAL(9,4) = (SELECT MAX(t.[TauxTVQ]) FROM staging.TaxeImport t
                                  WHERE t.[CompanyGUID] = @CompanyGUID AND t.[Statut] = 'RECONNUE' AND t.[TauxTVQ] > 0);

    DECLARE @Run INT = (SELECT MAX(d.[RunId]) FROM staging.ConnecteurDonnee d
                         WHERE d.[CompanyGUID] = @CompanyGUID AND d.[Ressource] = 'tax-agencies');
    DECLARE @NoTVQ NVARCHAR(100) = (SELECT TOP 1 NULLIF(LTRIM(RTRIM(JSON_VALUE(d.[Json], '$.TaxRegistrationNumber'))), '')
                                      FROM staging.ConnecteurDonnee d
                                     WHERE d.[RunId] = @Run AND d.[Ressource] = 'tax-agencies'
                                       AND JSON_VALUE(d.[Json], '$.DisplayName') LIKE N'%Revenu Qu%bec%'
                                       AND NULLIF(JSON_VALUE(d.[Json], '$.TaxRegistrationNumber'), '') IS NOT NULL);
    DECLARE @NoTPS NVARCHAR(100) = (SELECT TOP 1 NULLIF(LTRIM(RTRIM(JSON_VALUE(d.[Json], '$.TaxRegistrationNumber'))), '')
                                      FROM staging.ConnecteurDonnee d
                                     WHERE d.[RunId] = @Run AND d.[Ressource] = 'tax-agencies'
                                       AND (JSON_VALUE(d.[Json], '$.DisplayName') LIKE N'%Canada%'
                                            OR JSON_VALUE(d.[Json], '$.DisplayName') LIKE N'%ARC%'
                                            OR JSON_VALUE(d.[Json], '$.DisplayName') LIKE N'%CRA%')
                                       AND NULLIF(JSON_VALUE(d.[Json], '$.TaxRegistrationNumber'), '') IS NOT NULL);

    DECLARE @FinExercice DATE = (SELECT DATEADD(DAY, -1, DATEADD(YEAR, 1, e.[DebutExercice]))
                                   FROM dbo.T407DebutExerciceImport e WHERE e.[CompanyGUID] = @CompanyGUID);

    DECLARE @Freq VARCHAR(30) = CASE LOWER(ISNULL(@Frequence, ''))
                                    WHEN 'mois' THEN 'MENSUELLE'
                                    WHEN 'trimestre' THEN 'TRIMESTRIELLE'
                                    WHEN 'annee' THEN 'ANNUELLE' END;

    DECLARE @BNR VARCHAR(20) = (SELECT TOP 1 pc.[Compte]
                                  FROM staging.ImportPlanComptable i
                                  JOIN staging.CorrespondanceCompte c
                                    ON c.[CompanyGUID] = i.[CompanyGUID] AND c.[CleSource] = i.[CleSource]
                                  JOIN dbo.T121PlanComptable pc
                                    ON pc.[Id] = c.[PlanComptableId] AND pc.[CompanyGUID] = @CompanyGUID
                                 WHERE i.[CompanyGUID] = @CompanyGUID
                                   AND i.[SousTypeSource] = 'RetainedEarnings'
                                   AND c.[Action] IN ('LIER', 'CREER')
                                 ORDER BY i.[Id] DESC);

    -- ── Les valeurs, paramètre par paramètre ────────────────────────────────
    DECLARE @Valeurs TABLE (ShortName VARCHAR(50), Texte NVARCHAR(200), Nombre DECIMAL(18,6), Jour DATETIME);
    IF @TPS IS NOT NULL         INSERT INTO @Valeurs VALUES ('GST_RATE', NULL, @TPS, NULL);
    IF @TVQ IS NOT NULL         INSERT INTO @Valeurs VALUES ('QST_RATE', NULL, @TVQ, NULL);
    IF @NoTVQ IS NOT NULL       INSERT INTO @Valeurs VALUES ('QST_NO', @NoTVQ, NULL, NULL);
    IF @NoTPS IS NOT NULL       INSERT INTO @Valeurs VALUES ('GST_NO', @NoTPS, NULL, NULL);
    IF @FinExercice IS NOT NULL INSERT INTO @Valeurs VALUES ('FISCAL_YEAR_END', NULL, NULL, @FinExercice);
    IF @Freq IS NOT NULL        INSERT INTO @Valeurs VALUES ('TAX_FREQ', @Freq, NULL, NULL);
    IF @BNR IS NOT NULL         INSERT INTO @Valeurs VALUES ('BNR', @BNR, NULL, NULL);

    BEGIN TRANSACTION;

    UPDATE v
       SET v.[sVal] = CASE WHEN p.[ParamType] IN ('DECIMAL', 'DATE', 'INT') THEN v.[sVal] ELSE x.[Texte] END,
           v.[fVal] = CASE WHEN p.[ParamType] = 'DECIMAL' THEN x.[Nombre] ELSE v.[fVal] END,
           v.[dVal] = CASE WHEN p.[ParamType] = 'DATE' THEN x.[Jour] ELSE v.[dVal] END
    OUTPUT p.[ShortName],
           COALESCE(deleted.[sVal], CONVERT(NVARCHAR(40), deleted.[fVal]), CONVERT(NVARCHAR(10), deleted.[dVal], 23)),
           COALESCE(inserted.[sVal], CONVERT(NVARCHAR(40), inserted.[fVal]), CONVERT(NVARCHAR(10), inserted.[dVal], 23))
      INTO @Change
      FROM dbo.T101ParamValues v
      JOIN dbo.T100ParamComptable p ON p.[Id] = v.[T100Id] AND p.[CompanyGUID] = v.[CompanyGUID]
      JOIN @Valeurs x ON x.[ShortName] = p.[ShortName]
     WHERE v.[CompanyGUID] = @CompanyGUID
       AND (   (p.[ParamType] = 'DECIMAL' AND ISNULL(v.[fVal], -1) <> x.[Nombre])
            OR (p.[ParamType] = 'DATE'    AND ISNULL(v.[dVal], '19000101') <> x.[Jour])
            OR (p.[ParamType] NOT IN ('DECIMAL', 'DATE', 'INT') AND ISNULL(v.[sVal], '') <> ISNULL(x.[Texte], '')));

    -- Le taux de la compagnie (T069), dont se servent les factures.
    IF @TPS IS NOT NULL OR @TVQ IS NOT NULL
    BEGIN
        UPDATE r
           SET r.[TPS_Rate] = ISNULL(@TPS / 100.0, r.[TPS_Rate]),
               r.[TVQ_Rate] = ISNULL(@TVQ / 100.0, r.[TVQ_Rate])
        OUTPUT 'T069 taux', CONVERT(NVARCHAR(40), deleted.[TPS_Rate]) + N' / ' + CONVERT(NVARCHAR(40), deleted.[TVQ_Rate]),
               CONVERT(NVARCHAR(40), inserted.[TPS_Rate]) + N' / ' + CONVERT(NVARCHAR(40), inserted.[TVQ_Rate])
          INTO @Change
          FROM dbo.T069TaxeRate r
         WHERE r.[CompanyGUID] = @CompanyGUID
           AND (r.[TPS_Rate] <> ISNULL(@TPS / 100.0, r.[TPS_Rate]) OR r.[TVQ_Rate] <> ISNULL(@TVQ / 100.0, r.[TVQ_Rate]));
    END

    COMMIT TRANSACTION;

    SELECT Parametre, Avant, Apres FROM @Change;
END
GO
