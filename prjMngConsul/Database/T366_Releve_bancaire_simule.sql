-- =============================================================================
-- T366 — Relevé bancaire SIMULÉ (Plaid en pause)
--
-- Tant que Plaid est en pause, une compagnie peut recevoir un compte bancaire
-- simulé et son relevé, fabriqués dans la base :
--
--   1. Un compte dans T143PlaidAccount marqué AccessToken = 'SIMULATION'
--      (ItemId / AccountId = 'SIM-<CompanyGUID>'). Il compte comme un compte
--      branché : l'activité « brancher un compte bancaire » disparaît, le solde
--      paraît au tableau de bord. Les synchronisations Plaid (PlaidDailySync,
--      webhook, bouton Importer) ignorent ce jeton.
--
--   2. Des mouvements dans T142ReleveBancaire (Statut 'Importé', références
--      'SIM-…'), avec la convention Plaid : montant POSITIF = sortie,
--      NÉGATIF = entrée.
--        - les règlements réels de la compagnie (T140 : encaissements et
--          paiements) — ils se rapprochent des livres ;
--        - quelques virements Interac de clients pour des factures encore
--          ouvertes — à apparier (« paiement déjà reçu ») ;
--        - le train de vie d'une petite entreprise : dépôts du terminal de
--          paiement les jours ouvrables, loyer, Hydro-Québec, téléphone, paie
--          (15 et fin de mois), fournitures, frais bancaires mensuels.
--      Les montants sont pseudo-aléatoires mais STABLES (CHECKSUM de la date) :
--      relancer la procédure ne les change pas.
--
-- s0977SimulerReleveBancaire est incrémentale : elle reprend après le dernier
-- jour simulé (ou @Jours en arrière la première fois) jusqu'à aujourd'hui, et
-- n'insère jamais deux fois la même référence. @Reinitialiser = 1 efface
-- d'abord les mouvements simulés NON rapprochés du compte simulé.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0977SimulerReleveBancaire
    @CompanyGUID    UNIQUEIDENTIFIER,
    @Jours          INT = 90,
    @Reinitialiser  BIT = 0,
    @SoldeOuverture DECIMAL(15, 2) = 18500.00
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID)
        THROW 51020, 'Compagnie introuvable.', 1;

    DECLARE @Compte NVARCHAR(200) = N'SIM-' + CONVERT(NVARCHAR(36), @CompanyGUID);
    DECLARE @Auj DATE = CAST(GETDATE() AS DATE);

    -- ── 1. Le compte simulé ────────────────────────────────────────────────
    IF NOT EXISTS (SELECT 1 FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID AND AccountId = @Compte)
        INSERT INTO dbo.T143PlaidAccount
            (CompanyGUID, AccessToken, ItemId, BankName, Created, Active, AccountName, AccountId,
             AccountType, AccountSubtype, Mask, CurrencyCode, AccountNumber, InstitutionNumber, BranchNumber)
        VALUES
            (@CompanyGUID, 'SIMULATION', CONVERT(VARCHAR(200), @Compte), 'Banque simulée', GETDATE(), 1,
             N'Compte chèques', @Compte, N'depository', N'checking', N'4821', N'CAD', N'••••4821', N'815', N'30001');
    ELSE
        UPDATE dbo.T143PlaidAccount SET Active = 1
        WHERE CompanyGUID = @CompanyGUID AND AccountId = @Compte AND Active = 0;

    IF @Reinitialiser = 1
        DELETE FROM dbo.T142ReleveBancaire
        WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @Compte
          AND Reference LIKE 'SIM-%'
          AND NOT EXISTS (SELECT 1 FROM dbo.T208ReleveLien l WHERE l.ReleveId = T142ReleveBancaire.Id);

    -- ── 2. La période à simuler ────────────────────────────────────────────
    DECLARE @Debut DATE = (SELECT DATEADD(DAY, 1, MAX(DateMouvement)) FROM dbo.T142ReleveBancaire
                           WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @Compte AND Reference LIKE 'SIM-J%');
    IF @Debut IS NULL SET @Debut = DATEADD(DAY, -ABS(@Jours), @Auj);

    DECLARE @Mvt TABLE (DateMouvement DATE, Description VARCHAR(500), Reference VARCHAR(200), Montant DECIMAL(15, 2));

    -- Les jours de la période (au plus 400)
    ;WITH n AS (SELECT TOP (400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
                FROM sys.all_objects),
    j AS (SELECT DATEADD(DAY, i, @Debut) AS d FROM n WHERE DATEADD(DAY, i, @Debut) <= @Auj),
    k AS (SELECT d,
                 DATEDIFF(DAY, '19000101', d) % 7 AS dow,          -- 0 = lundi … 6 = dimanche
                 DAY(d) AS jour,
                 DAY(EOMONTH(d)) AS dernier,
                 -- MD5 : deux jours voisins donnent des montants sans rapport
                 ABS(CAST(SUBSTRING(HASHBYTES('MD5', CONVERT(VARCHAR(36), @CompanyGUID) + CONVERT(VARCHAR(8), d, 112)), 1, 4) AS INT)) AS h
          FROM j)
    INSERT INTO @Mvt (DateMouvement, Description, Reference, Montant)
    -- Dépôt du terminal de paiement, jours ouvrables
    SELECT d, 'DEPOT TPV MONERIS - LOT ' + RIGHT('0000' + CAST(h % 10000 AS VARCHAR(4)), 4),
           'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-TPV', -CAST(180 + (h % 72000) / 100.0 AS DECIMAL(15, 2))
    FROM k WHERE dow < 5
    UNION ALL  -- Virements Interac reçus, environ deux jours sur cinq
    SELECT d, 'VIREMENT INTERAC RECU', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-INT',
           -CAST(85 + (h / 7 % 26000) / 100.0 AS DECIMAL(15, 2))
    FROM k WHERE dow < 5 AND h % 5 IN (1, 3)
    UNION ALL  -- Loyer, le 1er
    SELECT d, 'PAIEMENT PREAUTORISE - GESTION IMMOBILIERE LAURIER', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-LOY', 2400.00
    FROM k WHERE jour = 1
    UNION ALL  -- Hydro-Québec, le 6
    SELECT d, 'HYDRO-QUEBEC - PAIEMENT FACTURE', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-HYD',
           CAST(118 + (h % 11000) / 100.0 AS DECIMAL(15, 2))
    FROM k WHERE jour = 6
    UNION ALL  -- Téléphone et Internet, le 12
    SELECT d, 'BELL CANADA - PAIEMENT PREAUTORISE', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-TEL', 96.58
    FROM k WHERE jour = 12
    UNION ALL  -- Paie, le 15 et le dernier jour du mois
    SELECT d, 'DEPOT DIRECT PAIE - EMPLOYES', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-PAI',
           CAST(3850 + (h % 80000) / 100.0 AS DECIMAL(15, 2))
    FROM k WHERE jour = 15 OR jour = dernier
    UNION ALL  -- Remises à la source, le 15
    SELECT d, 'REVENU QUEBEC - RETENUES A LA SOURCE', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-DAS',
           CAST(1420 + (h % 30000) / 100.0 AS DECIMAL(15, 2))
    FROM k WHERE jour = 15
    UNION ALL  -- Fournitures, le mercredi
    SELECT d, CASE h % 3 WHEN 0 THEN 'COSTCO WHOLESALE #0541' WHEN 1 THEN 'BUREAU EN GROS #112' ELSE 'PHARMAPRIX #0233' END,
           'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-FOU', CAST(42 + (h % 28000) / 100.0 AS DECIMAL(15, 2))
    FROM k WHERE dow = 2
    UNION ALL  -- Frais bancaires, le dernier jour du mois
    SELECT d, 'FRAIS MENSUELS - FORFAIT ENTREPRISE', 'SIM-J' + CONVERT(VARCHAR(8), d, 112) + '-FRA', 19.95
    FROM k WHERE jour = dernier;

    -- Les règlements réels (encaissements → entrées, paiements → sorties)
    INSERT INTO @Mvt (DateMouvement, Description, Reference, Montant)
    SELECT r.DateReglement,
           LEFT(CASE WHEN r.Sens = 'ENCAISSEMENT' THEN 'DEPOT - ' ELSE 'PAIEMENT - ' END
                + UPPER(ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, '')))
                + ISNULL(' ' + NULLIF(r.Reference, ''), ''), 500),
           'SIM-R' + CAST(r.Id AS VARCHAR(20)),
           CASE WHEN r.Sens = 'ENCAISSEMENT' THEN -r.Montant ELSE r.Montant END
    FROM dbo.T140Reglement r
    LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
    WHERE r.CompanyGUID = @CompanyGUID
      AND r.Statut <> 'ANNULE'
      AND r.DateReglement >= DATEADD(DAY, -ABS(@Jours), @Auj)
      -- pas deux fois : la facture déjà déposée en Interac simulé
      AND NOT EXISTS (SELECT 1 FROM dbo.T141ReglementDocument rd
                      JOIN dbo.T142ReleveBancaire x
                        ON x.CompanyGUID = @CompanyGUID AND x.Reference = 'SIM-F' + CAST(rd.DocumentId AS VARCHAR(20))
                      WHERE rd.ReglementId = r.Id);

    -- Virements de clients pour des factures encore ouvertes (à apparier)
    INSERT INTO @Mvt (DateMouvement, Description, Reference, Montant)
    SELECT TOP (3)
           DATEADD(DAY, -(ABS(CHECKSUM(v.Id)) % 6), @Auj),
           LEFT('VIREMENT INTERAC - ' + UPPER(ISNULL(v.NameRaw, '')) + ' ' + ISNULL(v.DocumentNumber, ''), 500),
           'SIM-F' + CAST(v.Id AS VARCHAR(20)),
           -CAST(v.ResteAPayer AS DECIMAL(15, 2))
    FROM dbo.vwCustomersInvoices v
    WHERE v.CompanyGUID = @CompanyGUID
      AND v.ComptabilisationStatus = 'COMPTABILISE'
      AND ISNULL(v.ResteAPayer, 0) > 0.005
      AND NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire x
                      WHERE x.CompanyGUID = @CompanyGUID AND x.Reference LIKE 'SIM-F%')
    ORDER BY v.DueDate, v.Id;

    -- ── 3. Écriture (jamais deux fois la même référence) ───────────────────
    INSERT INTO dbo.T142ReleveBancaire
        (ReleveBancaireGUID, CompanyGUID, DateMouvement, Description, Reference, Montant, CompteBanque, Statut, Created)
    SELECT NEWID(), @CompanyGUID, m.DateMouvement, m.Description, m.Reference, m.Montant, @Compte, 'Importé', GETDATE()
    FROM @Mvt m
    WHERE NOT EXISTS (SELECT 1 FROM dbo.T142ReleveBancaire x
                      WHERE x.CompanyGUID = @CompanyGUID AND x.Reference = m.Reference);

    DECLARE @Ajoutes INT = @@ROWCOUNT;

    -- ── 4. Le solde du compte simulé ───────────────────────────────────────
    DECLARE @Solde DECIMAL(15, 2) = @SoldeOuverture - ISNULL((SELECT SUM(Montant) FROM dbo.T142ReleveBancaire
                                                              WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @Compte), 0);
    UPDATE dbo.T143PlaidAccount
    SET BalanceCurrent = @Solde, BalanceAvailable = @Solde, BalanceUpdated = GETDATE()
    WHERE CompanyGUID = @CompanyGUID AND AccountId = @Compte;

    SELECT @Ajoutes AS MouvementsAjoutes,
           (SELECT COUNT(*) FROM dbo.T142ReleveBancaire WHERE CompanyGUID = @CompanyGUID AND CompteBanque = @Compte) AS MouvementsTotal,
           @Solde AS Solde;
END
GO
