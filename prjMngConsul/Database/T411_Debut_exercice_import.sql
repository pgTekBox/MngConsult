-- =============================================================================
-- T411 — Importation 2 : la date de début de l'exercice, demandée et mémorisée
--
-- QuickBooks Online n'a pas de DATE de début d'exercice : on n'y choisit que
-- le premier MOIS de l'exercice (Paramètres › Compte et paramètres › Avancé).
-- Le jour exact (un exercice qui commence le 15 juillet, par exemple) ne se
-- lit donc nulle part. Il est demandé au début de l'import et mémorisé par
-- compagnie ; il sert de début de période à la balance de vérification.
--
--   T407DebutExerciceImport (CompanyGUID PK, DebutExercice, ModifieLe, ModifiePar)
--   s1033GetDebutExercice  @CompanyGUID → DebutExercice (0 ou 1 ligne)
--   s1034SaveDebutExercice @CompanyGUID, @DebutExercice, @UserId
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.T407DebutExerciceImport', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T407DebutExerciceImport (
        [CompanyGUID]   UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_T407DebutExerciceImport PRIMARY KEY,
        [DebutExercice] DATE             NOT NULL,
        [ModifieLe]     DATETIME         NOT NULL CONSTRAINT DF_T407_ModifieLe DEFAULT (GETDATE()),
        [ModifiePar]    INT              NULL
    );
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s1033GetDebutExercice]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [DebutExercice], [ModifieLe]
      FROM dbo.T407DebutExerciceImport
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s1034SaveDebutExercice]
    @CompanyGUID   UNIQUEIDENTIFIER,
    @DebutExercice DATE,
    @UserId        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL OR @DebutExercice IS NULL
        THROW 50411, 'Compagnie et date de début de l''exercice obligatoires.', 1;

    MERGE dbo.T407DebutExerciceImport AS c
    USING (SELECT @CompanyGUID AS CompanyGUID) AS s ON c.[CompanyGUID] = s.CompanyGUID
    WHEN MATCHED THEN
        UPDATE SET [DebutExercice] = @DebutExercice, [ModifieLe] = GETDATE(), [ModifiePar] = @UserId
    WHEN NOT MATCHED THEN
        INSERT ([CompanyGUID], [DebutExercice], [ModifiePar]) VALUES (@CompanyGUID, @DebutExercice, @UserId);
END
GO
