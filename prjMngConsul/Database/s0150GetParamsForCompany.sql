-- =============================================================================
-- s0150GetParamsForCompany
-- Retourne les paramètres PROPRES à une compagnie (par catégorie), pour wbfSetting.
--
-- MODÈLE DE DONNÉES (voir aussi s0500InitializeCompanyData) :
--   T100ParamComptable = définitions de paramètres, UNE COPIE PAR COMPAGNIE.
--     La compagnie modèle '00000000-0000-0000-0000-000000000001' détient le
--     catalogue de référence ; chaque compagnie possède SES PROPRES lignes.
--   T101ParamValues    = valeurs par compagnie (une ligne par param et par compagnie).
--
-- Cette proc est AUTO-PROVISIONNANTE : à l'ouverture des Réglages, toute
-- définition présente dans le modèle mais absente chez la compagnie (par
-- ShortName) est clonée pour cette compagnie, avec la valeur par défaut du
-- modèle. Ainsi chaque compagnie a toujours son jeu complet de paramètres,
-- indépendant des autres, et les nouveaux paramètres ajoutés au modèle sont
-- propagés automatiquement aux compagnies existantes.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[s0150GetParamsForCompany]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Categorie   VARCHAR(20) = NULL,
    @Lang        VARCHAR(2)  = 'fr'   -- fr | en | es (libellé retourné dans Name)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ModelGUID UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    -- On ne provisionne pas la compagnie modèle (elle EST le catalogue),
    -- ni un GUID vide/invalide.
    IF @CompanyGUID IS NOT NULL
       AND @CompanyGUID <> @ModelGUID
       AND @CompanyGUID <> '00000000-0000-0000-0000-000000000000'
    BEGIN
        -- 1. Cloner du modèle toute DÉFINITION (T100) absente chez la compagnie
        --    (comparaison par ShortName). L'Id est IDENTITY → généré ici.
        INSERT INTO dbo.T100ParamComptable (ShortName, Name, ParamType, Categorie, Ordre, CompanyGUID)
        SELECT m.ShortName, m.Name, m.ParamType, m.Categorie, m.Ordre, @CompanyGUID
        FROM dbo.T100ParamComptable m
        WHERE m.CompanyGUID = @ModelGUID
          AND m.ShortName IS NOT NULL          -- un paramètre sans clé n'est pas exploitable
          AND NOT EXISTS (
                SELECT 1 FROM dbo.T100ParamComptable c
                WHERE c.CompanyGUID = @CompanyGUID
                  AND c.ShortName   = m.ShortName);

        -- 2. Créer les VALEURS (T101) manquantes pour les définitions de la
        --    compagnie, en reprenant la valeur par défaut du modèle (même ShortName).
        INSERT INTO dbo.T101ParamValues (T100Id, CompanyGUID, iVal, sVal, dVal, fVal)
        SELECT c.Id, @CompanyGUID, vm.iVal, vm.sVal, vm.dVal, vm.fVal
        FROM dbo.T100ParamComptable c
        LEFT JOIN dbo.T100ParamComptable m
               ON m.CompanyGUID = @ModelGUID AND m.ShortName = c.ShortName
        LEFT JOIN dbo.T101ParamValues vm
               ON vm.T100Id = m.Id AND vm.CompanyGUID = @ModelGUID
        WHERE c.CompanyGUID = @CompanyGUID
          AND c.ShortName IS NOT NULL
          AND NOT EXISTS (
                SELECT 1 FROM dbo.T101ParamValues t101
                WHERE t101.T100Id = c.Id AND t101.CompanyGUID = @CompanyGUID);
    END

    -- 3. Retourne les paramètres PROPRES à la compagnie, filtrés par catégorie.
    SELECT
        t101.[Id]          AS ParamId,
        t100.[Id]          AS T100Id,
        t100.[ShortName],
        -- Libellé localisé (T102ParamI18n), repli : @Lang → FR → libellé propre à la compagnie
        COALESCE(
            CASE @Lang WHEN 'en' THEN i.[NameEn]
                       WHEN 'es' THEN i.[NameEs]
                       ELSE i.[NameFr] END,
            i.[NameFr],
            t100.[Name]
        ) AS [Name],
        t100.[ParamType],
        t100.[Categorie],
        ISNULL(t100.[Ordre], t100.[Id]) AS Ordre,
        t101.[sVal],
        t101.[iVal],
        t101.[dVal],
        t101.[fVal]
    FROM dbo.T100ParamComptable t100
    INNER JOIN dbo.T101ParamValues t101
        ON t101.[T100Id]      = t100.[Id]
       AND t101.[CompanyGUID] = @CompanyGUID
    LEFT JOIN dbo.T102ParamI18n i
        ON i.[ShortName] = t100.[ShortName]
    WHERE (@Categorie IS NULL OR t100.[Categorie] = @Categorie)
      AND t100.[CompanyGUID] = @CompanyGUID
    ORDER BY ISNULL(t100.[Ordre], t100.[Id]);
END
GO
