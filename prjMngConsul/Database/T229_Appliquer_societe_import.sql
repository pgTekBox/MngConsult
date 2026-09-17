-- =============================================================================
-- T229 — Appliquer la fiche d'entreprise retenue
--
-- s0788 a posé la comparaison. Ici on la conclut : les champs que l'utilisateur
-- a cochés remplacent la valeur en place dans les paramètres de la compagnie.
--
-- Quatre refus, et ils comptent plus que le reste :
--
--   · un champ sans nom de paramètre ne s'applique pas — ce sont les
--     informations de la source qui n'ont pas d'équivalent chez nous (devise,
--     méthode comptable). Les montrer, oui ; les écrire quelque part, non ;
--   · un paramètre qui n'existe pas pour cette compagnie ne se crée pas ici.
--     Définir un paramètre est un autre métier que reprendre une valeur ;
--   · seuls les paramètres STRING sont touchés. Écrire une chaîne dans iVal ou
--     dVal serait une corruption silencieuse ;
--   · rien ne s'applique sans valeur à la source.
--
-- Ce qui est refusé n'interrompt pas le reste : la procédure applique ce qu'elle
-- peut et rend le compte des deux.
--
-- Procédure : s0791.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0791AppliquerSocieteImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Ids         NVARCHAR(MAX),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50371, 'Aucune compagnie : refus d''appliquer la fiche d''entreprise.', 1;

    DECLARE @Choix TABLE ([Id] INT PRIMARY KEY);
    INSERT INTO @Choix ([Id])
    SELECT DISTINCT TRY_CAST([value] AS INT)
      FROM OPENJSON(ISNULL(@Ids, N'[]'))
     WHERE TRY_CAST([value] AS INT) IS NOT NULL;

    -- Ce qui est retenu ET applicable. Le tri des deux se fait ici, une fois,
    -- pour que la mise à jour n'ait plus à se poser la question.
    DECLARE @Aplat TABLE
    (
        [Id]       INT PRIMARY KEY,
        [T100Id]   INT,
        [Valeur]   NVARCHAR(500)
    );

    INSERT INTO @Aplat ([Id], [T100Id], [Valeur])
    SELECT si.[Id], p.[Id], si.[ValeurSource]
      FROM staging.SocieteImport si
      JOIN @Choix ch ON ch.[Id] = si.[Id]
      JOIN dbo.T100ParamComptable p
        ON p.[CompanyGUID] = si.[CompanyGUID]
       AND p.[ShortName] = si.[Champ]
       AND p.[ParamType] = 'STRING'
     WHERE si.[CompanyGUID] = @CompanyGUID
       AND si.[Champ] IS NOT NULL
       AND si.[ValeurSource] IS NOT NULL;

    DECLARE @Retenus INT = (SELECT COUNT(*) FROM @Choix);
    DECLARE @Appliques INT = (SELECT COUNT(*) FROM @Aplat);

    BEGIN TRANSACTION;

    -- Le paramètre existe déjà : on écrase sa valeur.
    UPDATE v
       SET v.[sVal] = a.[Valeur]
      FROM dbo.T101ParamValues v
      JOIN @Aplat a ON a.[T100Id] = v.[T100Id]
     WHERE v.[CompanyGUID] = @CompanyGUID;

    -- Le paramètre est défini mais n'a jamais reçu de valeur : on la pose.
    INSERT INTO dbo.T101ParamValues ([T100Id], [CompanyGUID], [sVal])
    SELECT a.[T100Id], @CompanyGUID, a.[Valeur]
      FROM @Aplat a
     WHERE NOT EXISTS (SELECT 1 FROM dbo.T101ParamValues v
                        WHERE v.[T100Id] = a.[T100Id]
                          AND v.[CompanyGUID] = @CompanyGUID);

    -- La comparaison se met à jour : ce qui vient d'être appliqué n'est plus un
    -- écart. Sans cela l'écran continuerait à réclamer une décision déjà prise.
    UPDATE si
       SET si.[ValeurActuelle] = a.[Valeur],
           si.[Statut]         = 'IDENTIQUE',
           si.[AppliqueLe]     = GETDATE(),
           si.[AppliquePar]    = @UserId
      FROM staging.SocieteImport si
      JOIN @Aplat a ON a.[Id] = si.[Id];

    COMMIT TRANSACTION;

    SELECT @Appliques AS [NbAppliques],
           @Retenus - @Appliques AS [NbRefuses];
END
GO
