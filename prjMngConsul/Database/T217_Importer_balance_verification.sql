-- =============================================================================
-- T217 — La balance de verification : par compagnie, par procedure, et qu'on
--        retrouve en revenant
--
-- 1) La table appartient a une compagnie.
--    staging.BalanceVerification n'avait pas de colonne de compagnie : elle
--    etait commune a toutes. Une entreprise y voyait la balance des autres,
--    et « vider la table » effacait celle de tout le monde. Chaque ligne
--    porte desormais sa compagnie, et tout ce qui lit ou efface s'y borne.
--
-- 2) Chaque ligne dit d'ou elle vient et quand.
--    L'ecran n'affichait la balance qu'au moment de l'import : en revenant,
--    on repartait d'un ecran vide, comme si l'import etait perdu. Il relit
--    maintenant la balance en place, et peut dire quand et depuis quel
--    fichier elle a ete importee, et si l'IA l'a lue. L'ordre du fichier se
--    garde par un identifiant croissant.
--
-- 3) L'ecriture passe par une procedure (s0768), la lecture aussi (s0770),
--    la suppression aussi (s0769).
--
-- Rejouable : chaque colonne et l'index ne sont ajoutes que s'ils manquent.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

-- -----------------------------------------------------------------------------
-- 1) La compagnie
--
--    Obligatoire d'emblee : une ligne sans compagnie n'appartiendrait a
--    personne et se verrait de tous. Si la table contient deja des lignes,
--    on s'arrete plutot que de les attribuer au hasard.
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.BalanceVerification', 'CompanyGUID') IS NULL
BEGIN
    IF EXISTS (SELECT 1 FROM staging.BalanceVerification)
        THROW 50350, 'staging.BalanceVerification contient des lignes sans compagnie : les vider ou les attribuer avant.', 1;

    ALTER TABLE staging.BalanceVerification ADD [CompanyGUID] UNIQUEIDENTIFIER NOT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
                WHERE name = 'IX_BalanceVerification_Company'
                  AND object_id = OBJECT_ID('staging.BalanceVerification'))
    CREATE INDEX IX_BalanceVerification_Company
        ON staging.BalanceVerification ([CompanyGUID]);
GO

-- -----------------------------------------------------------------------------
-- 2) L'ordre, la date, l'origine
-- -----------------------------------------------------------------------------
IF COL_LENGTH('staging.BalanceVerification', 'Id') IS NULL
    ALTER TABLE staging.BalanceVerification ADD [Id] INT IDENTITY(1,1) NOT NULL;
GO

IF COL_LENGTH('staging.BalanceVerification', 'Created') IS NULL
    ALTER TABLE staging.BalanceVerification
        ADD [Created] DATETIME NOT NULL
            CONSTRAINT DF_BalanceVerification_Created DEFAULT (GETDATE());
GO

IF COL_LENGTH('staging.BalanceVerification', 'NomFichier') IS NULL
    ALTER TABLE staging.BalanceVerification ADD [NomFichier] NVARCHAR(260) NULL;
GO

IF COL_LENGTH('staging.BalanceVerification', 'Source') IS NULL
    ALTER TABLE staging.BalanceVerification ADD [Source] VARCHAR(10) NULL;   -- FICHIER | IA
GO

-- -----------------------------------------------------------------------------
-- 3) s0768ImporterBalanceVerification
--
--    @Lignes     : [{ "Compte": "1000" | null, "Description": "Chequing",
--                     "Debit": 21095.57, "Credit": 0 }]
--    @Vider      : 1 pour remplacer la balance deja importee -- celle de la
--                  compagnie, et d'aucune autre.
--    @NomFichier : le fichier d'origine, pour le dire en revenant.
--    @Source     : FICHIER (lecture ordinaire) ou IA.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0768ImporterBalanceVerification]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Lignes      NVARCHAR(MAX),
    @Vider       BIT = 0,
    @NomFichier  NVARCHAR(260) = NULL,
    @Source      VARCHAR(10) = 'FICHIER'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF @Vider = 1
        DELETE FROM staging.BalanceVerification
         WHERE [CompanyGUID] = @CompanyGUID;

    -- L'ordre du tableau JSON est celui du fichier : on le respecte, pour
    -- que la balance se relise telle qu'elle a ete lue.
    INSERT INTO staging.BalanceVerification
        ([CompanyGUID], [Compte], [Description], [Debit], [Credit], [NomFichier], [Source])
    SELECT @CompanyGUID,
           NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Compte, ''))), 20), ''),
           NULLIF(LEFT(LTRIM(RTRIM(ISNULL(j.Description, ''))), 200), ''),
           ISNULL(j.Debit, 0),
           ISNULL(j.Credit, 0),
           @NomFichier,
           @Source
      FROM OPENJSON(@Lignes) r
     CROSS APPLY OPENJSON(r.[value])
           WITH (
              Compte      NVARCHAR(50)  '$.Compte',
              Description NVARCHAR(400) '$.Description',
              Debit       DECIMAL(18,2) '$.Debit',
              Credit      DECIMAL(18,2) '$.Credit'
           ) j
     ORDER BY CAST(r.[key] AS INT);

    DECLARE @n INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @n AS Inserees;
END
GO

-- -----------------------------------------------------------------------------
-- 4) s0769ViderBalanceVerification — la balance de la compagnie, seulement
--
--    Remplace le TRUNCATE herite de l'ecran, qui vidait la table entiere et
--    donc la balance de toutes les compagnies.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0769ViderBalanceVerification]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM staging.BalanceVerification
     WHERE [CompanyGUID] = @CompanyGUID;

    SELECT @@ROWCOUNT AS Supprimees;
END
GO

-- -----------------------------------------------------------------------------
-- 5) s0770GetBalanceVerification — la balance en place, dans l'ordre du fichier
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0770GetBalanceVerification]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Compte], [Description], [Debit], [Credit],
           [Created], [NomFichier], [Source]
      FROM staging.BalanceVerification
     WHERE [CompanyGUID] = @CompanyGUID
     ORDER BY [Id];
END
GO

-- -----------------------------------------------------------------------------
-- 6) Le prompt de lecture par l'IA, range ou vivent les autres
--
--    Sert au bouton « Lire avec l'IA », pour les fichiers que la lecture
--    ordinaire ne sait pas demeler. Modifiable depuis la console d'admin sans
--    redeployer. Quoi qu'il dise, l'ecran refuse tout montant qu'il ne
--    retrouve pas dans le fichier d'origine.
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_BALANCE_VERIFICATION')
    INSERT INTO dbo.T0000Parameters ([ParamName], [Value])
    VALUES ('PROMPT_BALANCE_VERIFICATION', N'');
GO

UPDATE dbo.T0000Parameters
   SET [Value] = N'Tu reçois le contenu brut d''un fichier de balance de vérification exporté d''un logiciel comptable. Le fichier peut être mal formaté : colonnes décalées, séparateurs incohérents, lignes de titre, montants avec séparateurs de milliers, négatifs entre parenthèses, débit et crédit fondus en une seule colonne de solde.

Extrais chaque compte de la balance.

Règles :
- Un compte = une ligne de la balance, avec son nom (et son numéro s''il existe) et son solde.
- Ignore les lignes de titre, d''en-tête, de sous-total, de total et de pied de page.
- Recopie chaque montant EXACTEMENT tel qu''il figure dans le fichier, converti en nombre décimal avec un point : 21,095.57 devient 21095.57 ; 1 234,56 devient 1234.56. N''invente, n''arrondis et ne calcule aucun montant.
- Si le fichier n''a qu''une colonne de solde : un solde positif va au débit, un solde négatif (ou entre parenthèses) va au crédit, en valeur absolue.
- Si le numéro de compte est collé au nom (« 1000 Encaisse »), sépare-les.
- Un compte sans montant a un débit et un crédit de 0.
- Si le fichier porte une ligne TOTAL, rapporte ses montants dans totalDebit et totalCredit ; sinon mets null.

Réponds UNIQUEMENT par un objet JSON, sans texte autour ni bloc de code :
{"lignes":[{"Compte":"<numéro ou null>","Description":"<nom du compte>","Debit":<nombre>,"Credit":<nombre>}],"totalDebit":<nombre ou null>,"totalCredit":<nombre ou null>}'
 WHERE [ParamName] = 'PROMPT_BALANCE_VERIFICATION';
GO

PRINT 'T217_Importer_balance_verification.sql : termine.';
GO
