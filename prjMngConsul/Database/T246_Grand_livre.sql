-- =============================================================================
-- T246 — Le grand livre en préparation
--
-- Apideck n'expose pas ce rapport : /accounting/general-ledger-transactions
-- répond 404 pour QuickBooks. Il arrive donc par la passerelle, comme la
-- balance de vérification et les conditions de paiement.
--
-- LA FORME. QuickBooks rend le grand livre en SECTIONS, une par compte, et
-- chaque section porte ses opérations. Une même opération y figure deux fois —
-- une fois sous chaque compte qu'elle touche : la facture 1002 apparaît au
-- débit des comptes clients et au crédit des services. C'est la partie double,
-- vue depuis chaque compte.
--
-- La table garde cette forme plutôt que de recoudre les opérations : une ligne
-- par écriture d'un compte, avec sa contrepartie. Regrouper demanderait de
-- deviner quelles lignes forment une même opération, et un grand livre sert
-- justement à vérifier — pas à réinterpréter.
--
-- CE QU'ON N'EN FAIT PAS. Rien n'est créé dans la comptabilité à partir d'ici.
-- Le grand livre est une pièce de contrôle : il dit ce que la source contient,
-- compte par compte, pour qu'on puisse confronter une reprise à son origine.
--
-- Procédures : s0820 (charger), s0821 (lire).
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('staging.GrandLivreImport') IS NULL
CREATE TABLE staging.GrandLivreImport (
    [Id]            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GrandLivreImport PRIMARY KEY,
    [ImportFileId]  INT NULL,
    [RunId]         INT NULL,
    [CompanyGUID]   UNIQUEIDENTIFIER NOT NULL,

    -- La période du rapport, répétée sur chaque ligne : elle vient de l'entête
    -- que QuickBooks a réellement retenu, pas de celle qu'on croit avoir demandée.
    [PeriodeDebut]  DATE NULL,
    [PeriodeFin]    DATE NULL,
    [Devise]        VARCHAR(10) NULL,

    -- Le compte de la section, et l'ordre d'apparition — un grand livre se lit
    -- dans l'ordre où la source l'a écrit.
    [CompteOrdre]   INT NOT NULL CONSTRAINT DF_GrandLivreImport_CompteOrdre DEFAULT (0),
    [CompteNom]     NVARCHAR(400) NULL,
    [LigneOrdre]    INT NOT NULL CONSTRAINT DF_GrandLivreImport_LigneOrdre DEFAULT (0),

    -- L'opération
    [DateOperation] DATE NULL,
    [TypeOperation] NVARCHAR(100) NULL,
    [Numero]        NVARCHAR(100) NULL,
    [TiersNom]      NVARCHAR(400) NULL,
    [Memo]          NVARCHAR(1000) NULL,
    [Contrepartie]  NVARCHAR(400) NULL,   -- le compte d'en face, tel que la source le nomme
    [Debit]         DECIMAL(18,2) NULL,
    [Credit]        DECIMAL(18,2) NULL,

    [Created]       DATETIME NOT NULL CONSTRAINT DF_GrandLivreImport_Created DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GrandLivreImport_Compagnie')
    CREATE INDEX IX_GrandLivreImport_Compagnie
        ON staging.GrandLivreImport ([CompanyGUID], [CompteOrdre], [LigneOrdre]);
GO

-- -----------------------------------------------------------------------------
-- s0820ChargerGrandLivre — dépose le grand livre lu chez la source
--
-- Une seule extraction en préparation à la fois : la nouvelle remplace la
-- précédente. Un grand livre partiellement remplacé ne voudrait rien dire.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0820ChargerGrandLivre]
    @RunId        INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @ImportFileId INT = NULL,
    @Lignes       NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompanyGUID IS NULL
        THROW 50395, 'Aucune compagnie : impossible de déposer un grand livre.', 1;

    BEGIN TRANSACTION;

    DELETE FROM staging.GrandLivreImport WHERE [CompanyGUID] = @CompanyGUID;

    INSERT INTO staging.GrandLivreImport
        ([RunId], [ImportFileId], [CompanyGUID], [PeriodeDebut], [PeriodeFin], [Devise],
         [CompteOrdre], [CompteNom], [LigneOrdre],
         [DateOperation], [TypeOperation], [Numero], [TiersNom], [Memo], [Contrepartie],
         [Debit], [Credit])
    SELECT @RunId, @ImportFileId, @CompanyGUID,
           TRY_CONVERT(DATE, NULLIF(j.[debut], '')),
           TRY_CONVERT(DATE, NULLIF(j.[fin], '')),
           LEFT(j.[devise], 10),
           TRY_CONVERT(INT, NULLIF(j.[compte_ordre], '')),
           j.[compte],
           TRY_CONVERT(INT, NULLIF(j.[ligne_ordre], '')),
           TRY_CONVERT(DATE, NULLIF(j.[date], '')),
           LEFT(j.[type], 100), LEFT(j.[numero], 100), j.[tiers], j.[memo], j.[contrepartie],
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[debit], '')),
           TRY_CONVERT(DECIMAL(18,2), NULLIF(j.[credit], ''))
      FROM OPENJSON(@Lignes)
           WITH ([debut]         NVARCHAR(40)   '$.debut',
                 [fin]           NVARCHAR(40)   '$.fin',
                 [devise]        NVARCHAR(20)   '$.devise',
                 [compte_ordre]  NVARCHAR(40)   '$.compte_ordre',
                 [compte]        NVARCHAR(400)  '$.compte',
                 [ligne_ordre]   NVARCHAR(40)   '$.ligne_ordre',
                 [date]          NVARCHAR(40)   '$.date',
                 [type]          NVARCHAR(200)  '$.type',
                 [numero]        NVARCHAR(200)  '$.numero',
                 [tiers]         NVARCHAR(400)  '$.tiers',
                 [memo]          NVARCHAR(1000) '$.memo',
                 [contrepartie]  NVARCHAR(400)  '$.contrepartie',
                 [debit]         NVARCHAR(40)   '$.debit',
                 [credit]        NVARCHAR(40)   '$.credit') AS j;

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS [NbLignes],
           (SELECT COUNT(DISTINCT [CompteNom]) FROM staging.GrandLivreImport
             WHERE [CompanyGUID] = @CompanyGUID) AS [NbComptes];
END
GO

-- -----------------------------------------------------------------------------
-- s0821GetGrandLivre — ce que l'écran affiche
--
-- Deux jeux : l'entête du rapport avec ses totaux, puis les lignes dans
-- l'ordre où la source les a écrites.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0821GetGrandLivre]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MIN([PeriodeDebut])           AS [PeriodeDebut],
           MAX([PeriodeFin])             AS [PeriodeFin],
           MAX([Devise])                 AS [Devise],
           COUNT(*)                      AS [NbLignes],
           COUNT(DISTINCT [CompteNom])   AS [NbComptes],
           SUM(ISNULL([Debit], 0))       AS [TotalDebit],
           SUM(ISNULL([Credit], 0))      AS [TotalCredit],
           MAX([Created])                AS [Depose]
      FROM staging.GrandLivreImport
     WHERE [CompanyGUID] = @CompanyGUID;

    SELECT [Id], [CompteOrdre], [CompteNom], [LigneOrdre],
           [DateOperation], [TypeOperation], [Numero], [TiersNom], [Memo], [Contrepartie],
           [Debit], [Credit]
      FROM staging.GrandLivreImport
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [CompteOrdre], [LigneOrdre], [Id];
END
GO
