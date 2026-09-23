-- =============================================================================
-- T267 — L'édition d'un compte du plan (wbfPlanComptableEdit) suit la vraie table
--
-- Vu chez Pierre : « Invalid column name 'Numero' » à l'ouverture d'un compte.
-- Les trois procédures de l'écran d'édition dataient de l'ancienne table
-- T121PlanComptable_Compte (colonne Numero, sans compagnie). La table est
-- aujourd'hui T121PlanComptable : colonne Compte, une ligne par compagnie,
-- Id sans IDENTITY. s0050 (supprimer) avait déjà été réécrite ; pas les trois
-- autres.
--
--   · s0049GetOneCompte     lit Compte, le rend sous l'alias Numero que
--                           l'écran attend, et vérifie la compagnie ;
--   · s0054Insert…          crée dans T121PlanComptable, pour la compagnie,
--                           avec un numéro unique DANS la compagnie ;
--   · s0055Update…          met à jour Compte, pour la compagnie seulement.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0049GetOneCompte]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.[Id],
           c.[Compte]               AS [Numero],
           c.[Nom], c.[TypeBilan], c.[Sens], c.[Actif], c.[Systeme], c.[Description],
           c.[ClasseId], c.[ClasseParentId], c.[Ordre],
           sc.[Code]                AS [ClasseCode],
           sc.[Description]         AS [SousClasseDescription],
           p.[Description]          AS [ClasseDescription],
           p.[GroupeEtatFinancier],
           CAST(NULL AS DATETIME)   AS [Created]
      FROM [dbo].[T121PlanComptable] c
      LEFT JOIN [dbo].[T120PlanComptable_Classe] sc ON sc.[Id] = c.[ClasseId]
      LEFT JOIN [dbo].[T120PlanComptable_Classe] p  ON p.[Id]  = c.[ClasseParentId]
     WHERE c.[Id] = @Id
       AND c.[CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0054InsertPlanComptableCompte]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Numero         VARCHAR(10),
    @Nom            VARCHAR(150),
    @ClasseId       INT,
    @ClasseParentId INT,
    @TypeBilan      VARCHAR(10),
    @Sens           VARCHAR(10),
    @Actif          BIT = 1,
    @Description    VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @Numero)
    BEGIN
        RAISERROR('Le numéro de compte "%s" existe déjà.', 16, 1, @Numero);
        RETURN;
    END

    -- La classe doit être celle de la compagnie : un Id d'une autre compagnie
    -- rangerait le compte hors de son plan.
    IF NOT EXISTS (SELECT 1 FROM [dbo].[T120PlanComptable_Classe]
                    WHERE [Id] = @ClasseId AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        RAISERROR('La classe choisie n''appartient pas à cette compagnie.', 16, 1);
        RETURN;
    END

    -- Id sans IDENTITY : le suivant, toutes compagnies confondues.
    DECLARE @NewId INT;
    SELECT @NewId = ISNULL(MAX([Id]), 0) + 1 FROM [dbo].[T121PlanComptable];

    INSERT INTO [dbo].[T121PlanComptable]
        ([Id], [CompanyGUID], [Compte], [Nom], [NomFr], [ClasseId], [ClasseParentId], [TypeBilan], [Sens],
         [Ordre], [Actif], [Systeme], [Description])
    VALUES
        (@NewId, @CompanyGUID, @Numero, @Nom, @Nom, @ClasseId, @ClasseParentId, @TypeBilan, @Sens,
         TRY_CONVERT(INT, @Numero), @Actif, 0, @Description);

    SELECT @NewId AS [Id];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0055UpdatePlanComptableCompte]
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Id             INT,
    @Numero         VARCHAR(10),
    @Nom            VARCHAR(150),
    @ClasseId       INT,
    @ClasseParentId INT,
    @TypeBilan      VARCHAR(10),
    @Sens           VARCHAR(10),
    @Actif          BIT = 1,
    @Description    VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                    WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID)
    BEGIN
        RAISERROR('Ce compte n''appartient pas à votre plan comptable.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM [dbo].[T121PlanComptable]
                WHERE [CompanyGUID] = @CompanyGUID AND [Compte] = @Numero AND [Id] <> @Id)
    BEGIN
        RAISERROR('Le numéro de compte "%s" est déjà utilisé par un autre compte.', 16, 1, @Numero);
        RETURN;
    END

    UPDATE [dbo].[T121PlanComptable]
       SET [Compte]         = @Numero,
           [Nom]            = @Nom,
           [NomFr]          = CASE WHEN [NomFr] IS NULL OR [NomFr] = [Nom] THEN @Nom ELSE [NomFr] END,
           [ClasseId]       = @ClasseId,
           [ClasseParentId] = @ClasseParentId,
           [TypeBilan]      = @TypeBilan,
           [Sens]           = @Sens,
           [Ordre]          = ISNULL(TRY_CONVERT(INT, @Numero), [Ordre]),
           [Actif]          = @Actif,
           [Description]    = @Description
     WHERE [Id] = @Id
       AND [CompanyGUID] = @CompanyGUID;
END
GO
