-- =============================================================================
-- T314 — Le contrôle balance ↔ plan dit quand les comptes n'ont pas de numéro
--
-- Une balance et un plan venus de QuickBooks sans numéros de compte se
-- rapprochent par le nom : la colonne « Compte » du contrôle ne montre alors
-- que le nom, et l'écran doit le dire plutôt que de laisser croire à une
-- lecture ratée. s0771ControleBalancePlan rend deux compteurs de plus dans son
-- premier jeu : BalanceSansNumero et PlanSansNumero. Recréée à l'identique de
-- T243, à ces deux colonnes près.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0771ControleBalancePlan]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Le plan comptable en préparation pour la compagnie. Il n'y en a qu'un :
    -- plus de numéro de lot à retenir.
    DECLARE @Systeme VARCHAR(20), @FichierPlan NVARCHAR(260), @DatePlan DATETIME;

    SELECT TOP 1 @Systeme     = p.[SystemeSource],
                 @FichierPlan = f.[OriginalName],
                 @DatePlan    = p.[Created]
      FROM staging.ImportPlanComptable p
      LEFT JOIN staging.ImportFiles f ON f.[Id] = p.[ImportFileId]
     WHERE p.[CompanyGUID] = @CompanyGUID
     ORDER BY p.[Id] DESC;

    DECLARE @plan TABLE (
        CleSource     NVARCHAR(400),
        Compte        VARCHAR(20),
        Nom           NVARCHAR(400),
        NomCle        NVARCHAR(400),
        TypeNormalise VARCHAR(20),
        Solde         DECIMAL(18,2)
    );

    INSERT INTO @plan
    SELECT p.[CleSource], p.[Compte], p.[Nom],
           UPPER(LTRIM(RTRIM(ISNULL(p.[Nom], '')))),
           p.[TypeNormalise], p.[Solde]
      FROM staging.ImportPlanComptable p
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND p.[Statut] IN ('OK', 'EXISTE');

    DECLARE @bal TABLE (
        Id          INT,
        Compte      VARCHAR(20),
        Nom         NVARCHAR(400),
        NomCle      NVARCHAR(400),
        Debit       DECIMAL(18,2),
        Credit      DECIMAL(18,2)
    );

    INSERT INTO @bal
    SELECT b.[Id], b.[Compte], b.[Description],
           UPPER(LTRIM(RTRIM(ISNULL(b.[Description], '')))),
           ISNULL(b.[Debit], 0), ISNULL(b.[Credit], 0)
      FROM staging.BalanceVerification b
     WHERE b.[CompanyGUID] = @CompanyGUID;

    -- Chaque ligne de la balance et le compte du plan qui lui repond.
    DECLARE @lien TABLE (BalId INT, CleSource NVARCHAR(400));

    INSERT INTO @lien
    SELECT b.Id, m.CleSource
      FROM @bal b
     OUTER APPLY (
        SELECT TOP 1 pl.CleSource
          FROM @plan pl
         WHERE (b.Compte IS NOT NULL AND pl.Compte IS NOT NULL AND pl.Compte = b.Compte)
            OR (b.NomCle <> '' AND pl.NomCle = b.NomCle)
         ORDER BY CASE WHEN b.Compte IS NOT NULL AND pl.Compte = b.Compte THEN 0 ELSE 1 END
     ) m;

    DECLARE @a TABLE (
        Gravite VARCHAR(10),
        Ordre   INT,
        Type    VARCHAR(20),
        Compte  VARCHAR(20),
        Nom     NVARCHAR(400),
        Detail  NVARCHAR(600)
    );

    -- ── Compte de la balance absent du plan ─────────────────────────────────
    --    Erreur s'il porte un solde : ce montant n'aurait nulle part ou aller.
    --    Sans solde, rien ne se perd : simple information.
    INSERT INTO @a
    SELECT CASE WHEN b.Debit - b.Credit = 0 THEN 'INFO' ELSE 'ERREUR' END,
           CASE WHEN b.Debit - b.Credit = 0 THEN 6 ELSE 1 END,
           'ABSENT_PLAN', b.Compte, b.Nom,
           CASE WHEN b.Debit - b.Credit = 0
                THEN N'Absent du plan comptable importé, mais sans solde : rien ne se perd.'
                ELSE N'Absent du plan comptable importé : son solde de ' +
                     FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $ n''aura nulle part où aller.'
           END
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
     WHERE l.CleSource IS NULL
       AND @Systeme IS NOT NULL;

    -- ── ERREUR : ignore a l'etape 2, mais porteur d'un solde ────────────────
    INSERT INTO @a
    SELECT 'ERREUR', 2, 'IGNORE_AVEC_SOLDE', b.Compte, b.Nom,
           N'Marqué « Ignorer » à la correspondance, mais porte un solde de ' +
           FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $ : ce montant disparaîtrait de la reprise.'
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
      JOIN staging.CorrespondanceCompte c
        ON c.[CompanyGUID] = @CompanyGUID
       AND c.[SystemeSource] = @Systeme
       AND c.[CleSource] = l.CleSource
     WHERE c.[Action] = 'IGNORER'
       AND b.Debit - b.Credit <> 0;

    -- ── ERREUR : compte en double dans la balance ───────────────────────────
    INSERT INTO @a
    SELECT 'ERREUR', 3, 'DOUBLON_BALANCE',
           NULLIF(MAX(ISNULL(b.Compte, '')), ''), MAX(b.Nom),
           N'Apparaît ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' fois dans la balance.'
      FROM @bal b
     GROUP BY COALESCE(b.Compte, b.NomCle)
    HAVING COUNT(*) > 1;

    -- ── VERIFIER : solde de sens contraire a la nature du compte ────────────
    INSERT INTO @a
    SELECT 'VERIFIER', 4, 'SENS', b.Compte, b.Nom,
           N'Compte de nature ' + LOWER(pl.TypeNormalise) + N', mais solde au ' +
           CASE WHEN b.Debit > b.Credit THEN N'débit' ELSE N'crédit' END + N' (' +
           FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $). Normal pour un contre-compte, sinon à vérifier.'
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
      JOIN @plan pl ON pl.CleSource = l.CleSource
     WHERE pl.TypeNormalise IS NOT NULL
       AND b.Debit <> b.Credit
       AND (CASE WHEN pl.TypeNormalise IN ('ACTIF', 'CHARGE') THEN 'DEBIT' ELSE 'CREDIT' END)
        <> (CASE WHEN b.Debit > b.Credit THEN 'DEBIT' ELSE 'CREDIT' END);

    -- ── VERIFIER : solde du plan different de celui de la balance ───────────
    INSERT INTO @a
    SELECT 'VERIFIER', 5, 'SOLDE', b.Compte, b.Nom,
           N'Le plan annonce ' + FORMAT(ABS(pl.Solde), 'N2', 'fr-CA') + N' $, la balance ' +
           FORMAT(ABS(b.Debit - b.Credit), 'N2', 'fr-CA') + N' $. Normal si les deux exports ne sont pas à la même date.'
      FROM @bal b
      JOIN @lien l ON l.BalId = b.Id
      JOIN @plan pl ON pl.CleSource = l.CleSource
     WHERE pl.Solde IS NOT NULL
       AND ABS(ABS(pl.Solde) - ABS(b.Debit - b.Credit)) > 0.01;

    -- ── INFO : compte du plan absent de la balance ──────────────────────────
    INSERT INTO @a
    SELECT 'INFO', 7, 'ABSENT_BALANCE', pl.Compte, pl.Nom,
           N'Au plan comptable, mais absent de la balance — le plus souvent un compte sans solde.'
      FROM @plan pl
     WHERE NOT EXISTS (SELECT 1 FROM @lien l WHERE l.CleSource = pl.CleSource);

    -- ── 1er jeu : le contexte de la comparaison ─────────────────────────────
    SELECT @Systeme     AS SystemePlan,
           @FichierPlan AS FichierPlan,
           @DatePlan    AS DatePlan,
           (SELECT COUNT(*) FROM @plan) AS ComptesPlan,
           (SELECT COUNT(*) FROM @bal)  AS ComptesBalance,
           (SELECT COUNT(*) FROM @bal  WHERE Compte IS NULL OR Compte = '') AS BalanceSansNumero,
           (SELECT COUNT(*) FROM @plan WHERE Compte IS NULL OR Compte = '') AS PlanSansNumero,
           (SELECT COUNT(*) FROM @lien WHERE CleSource IS NOT NULL) AS ComptesRapproches,
           (SELECT TOP 1 [NomFichier] FROM staging.BalanceVerification
             WHERE [CompanyGUID] = @CompanyGUID ORDER BY [Id] DESC) AS FichierBalance,
           (SELECT COUNT(*) FROM @a WHERE Gravite = 'ERREUR')   AS Erreurs,
           (SELECT COUNT(*) FROM @a WHERE Gravite = 'VERIFIER') AS AVerifier,
           (SELECT COUNT(*) FROM @a WHERE Gravite = 'INFO')     AS Infos;

    -- ── 2e jeu : les incoherences, les plus graves d'abord ──────────────────
    SELECT Gravite, Type, Compte, Nom, Detail
      FROM @a
     ORDER BY Ordre, Nom;
END

GO
