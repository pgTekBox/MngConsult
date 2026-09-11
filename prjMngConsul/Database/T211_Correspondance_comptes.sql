-- =============================================================================
-- Reprise comptable — la mise en correspondance des comptes
-- -----------------------------------------------------------------------------
-- Etape 2 : dire, pour chaque compte de l'ancien logiciel, a quel compte de
-- notre plan il correspond. C'est le seul travail de la migration qu'un
-- programme ne peut pas decider seul : il se fait avec le comptable.
--
-- La decision ne vit pas dans le lot d'importation mais dans une table a part,
-- et pour une bonne raison : les etapes suivantes en ont besoin. Quand on
-- chargera les factures et les ecritures, chacune desingera un compte de
-- l'ancien logiciel — c'est ici qu'on saura vers quoi le tourner. Le lot, lui,
-- peut etre abandonne et recharge ; la correspondance reste.
--
-- Re-executable.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La correspondance
--    Une ligne par compte de l'ancien logiciel, pour une compagnie donnee.
--    Elle survit aux lots : c'est la piece que le comptable signe.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('staging.CorrespondanceCompte', 'U') IS NULL
BEGIN
    CREATE TABLE staging.CorrespondanceCompte (
        [Id]              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CorrespondanceCompte PRIMARY KEY,
        [CompanyGUID]     UNIQUEIDENTIFIER NOT NULL,
        [SystemeSource]   VARCHAR(20) NOT NULL,

        -- le compte tel qu'il est dans l'ancien logiciel
        [CompteSource]    VARCHAR(20) NOT NULL,
        [NomSource]       NVARCHAR(200) NULL,

        -- ce qu'on en fait : LIER a un compte existant, CREER un compte, ou
        -- IGNORER (compte technique, compte vide, doublon du plan d'origine)
        [Action]          VARCHAR(10) NOT NULL CONSTRAINT DF_Corresp_Action DEFAULT ('LIER'),

        -- si LIER : le compte de notre plan
        [PlanComptableId] INT NULL,
        -- si CREER : ce qu'il faudra creer
        [CompteCible]     VARCHAR(20) NULL,
        [NomCible]        NVARCHAR(200) NULL,
        [TypeCible]       VARCHAR(20) NULL,

        [Note]            NVARCHAR(500) NULL,

        [Created]         DATETIME NOT NULL CONSTRAINT DF_Corresp_Created DEFAULT (GETDATE()),
        [CreatedBy]       INT NULL,
        [Modified]        DATETIME NULL,
        [ModifiedBy]      INT NULL,

        CONSTRAINT CK_Corresp_Action CHECK ([Action] IN ('LIER', 'CREER', 'IGNORER'))
    );

    -- Un compte d'origine n'a qu'une correspondance par compagnie et par
    -- logiciel : c'est ce qui rend la table interrogeable par les etapes
    -- suivantes sans ambiguite.
    CREATE UNIQUE INDEX UX_Corresp_Source
        ON staging.CorrespondanceCompte ([CompanyGUID], [SystemeSource], [CompteSource]);
END
GO

-- -----------------------------------------------------------------------------
-- s0756GetCorrespondances : sa definition courante vit dans T214.
--
--    En garder une copie ici faisait qu'un simple rejeu de T211 ramenait la
--    version d'origine et defaisait T214 sans le dire. Une procedure, un fichier.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- s0757SaveCorrespondances : sa definition courante vit dans T212.
--
--    En garder une copie ici faisait qu'un simple rejeu de T211 ramenait la
--    version d'origine et defaisait T212 sans le dire. Une procedure, un fichier.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- s0758StatsCorrespondance : sa definition courante vit dans T212.
--
--    En garder une copie ici faisait qu'un simple rejeu de T211 ramenait la
--    version d'origine et defaisait T212 sans le dire. Une procedure, un fichier.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 5) s0759GetPlanCompagnie
--    Le plan de la compagnie, pour la liste de saisie assistee de la page.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0759GetPlanCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Compte], [Nom], [TypeBilan], [Sens], [ClasseId], [ClasseParentId]
      FROM dbo.T121PlanComptable
     WHERE [CompanyGUID] = @CompanyGUID
       AND ISNULL([Actif], 1) = 1
     ORDER BY [Compte];
END
GO

-- -----------------------------------------------------------------------------
-- s0760AccepterPropositions : sa definition courante vit dans T212.
--
--    En garder une copie ici faisait qu'un simple rejeu de T211 ramenait la
--    version d'origine et defaisait T212 sans le dire. Une procedure, un fichier.
-- -----------------------------------------------------------------------------

PRINT N'T211_Correspondance_comptes.sql : termine.';
GO
