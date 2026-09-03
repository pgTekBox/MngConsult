-- =============================================================================
-- s0023GetSuppliersInvoices (v2)
-- Mise a jour : ajout de 2 colonnes pour le bouton "Payer" :
--   LastPaymentMethod : derniere methode utilisee pour ce fournisseur
--                       (Interac / ACSS / Carte) - pre-selectionne dans le modal
--   StripeAccountId   : acct_xxx Stripe Connect du fournisseur (NULL si pas onboard)
--
-- Conserve toutes les colonnes existantes (DejaPaye, ResteAPayer, StatutPaiement).
-- =============================================================================

USE [MngConsul];
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0023GetSuppliersInvoices', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0023GetSuppliersInvoices;
GO

CREATE PROCEDURE [dbo].[s0023GetSuppliersInvoices]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PaiementsCumules AS (
        SELECT
            rd.[DocumentId],
            SUM(rd.[MontantImpute]) AS DejaPaye
        FROM [dbo].[T141ReglementDocument] rd
        INNER JOIN [dbo].[T140Reglement] r ON r.[Id] = rd.[ReglementId]
        WHERE r.[Statut] <> 'ANNULE'
          AND r.[Sens]    = 'DECAISSEMENT'
        GROUP BY rd.[DocumentId]
    )
    SELECT
        T060.[Id],

        '<div>' + T060.[Name] + ' '
            + COALESCE(T060.Address1, '')
            + COALESCE(T060.Address2, '')
            + ' '
            + COALESCE(T060.[City], '')
            + '</div>'                                                    AS Name,

        T060.Total,

        '<div>
            <a style="color:blue; text-decoration:underline; " onclick = openImageViewer(''Voirlerecu_'
                + CONVERT(VARCHAR(200), T060.imageGUID)
                + '.jpeg'') >
                <span style="cursor:pointer;">'
                + dbo.fn_Truncate(COALESCE(T060.[DocumentNumber], 'LeRecu'), 10)
                + '</span>
            </a>
         </div>'                                                          AS DocumentNumber,
        T050.Id                                                           AS PartyId,
        T060.Created,
        T001.[imageGUID],
        T060.[PartyGUID],
        T066.[Name]                                                       AS Statusold,
        CASE WHEN [ComptabilisationStatus] = 'COMPTABILISE'
             THEN N'Comptabilisé' ELSE 'Brouillon' END                    AS Status,
        T060.[ComptabilisationStatus],
        T060.DocumentDate,

        -- Colonnes paiement
        ISNULL(pc.DejaPaye, 0)                                            AS DejaPaye,
        CAST(ISNULL(T060.[Total], 0) - ISNULL(pc.DejaPaye, 0) AS DECIMAL(15,2)) AS ResteAPayer,
        CASE
            WHEN ISNULL(T060.[Total], 0) - ISNULL(pc.DejaPaye, 0) <= 0.005 THEN 'PAYEE'
            WHEN ISNULL(pc.DejaPaye, 0) > 0.005                            THEN 'PARTIELLE'
            ELSE                                                                 'OUVERTE'
        END                                                               AS StatutPaiement,

        -- Stripe Connect (V2)
        T050.LastPaymentMethod,
        T050.StripeAccountId

    FROM [dbo].[T060Document] T060
    LEFT JOIN [dbo].[T050Party] T050
        ON T050.PartyGUID = T060.[PartyGUID]
    INNER JOIN [dbo].[T066DocumentStatus] T066
        ON T066.Id = T060.[StatusId]
    LEFT JOIN [dbo].[T0001Receipt] T001
        ON T001.[imageGUID] = T060.[imageGUID]
    LEFT JOIN PaiementsCumules pc
        ON pc.DocumentId = T060.[Id]
    WHERE T060.[CompanyGUID] = @CompanyGUID
      AND T060.[DocumentTypeId] IN (2, 5)
      AND (T060.[Name] LIKE '%' + @Search + '%')
    -- Ordre par defaut de la grille : de la plus recente a la plus vieille.
    -- L'Id departage les factures de meme date (les plus recemment saisies
    -- d'abord) et rend l'ordre deterministe.
    ORDER BY T060.[DocumentDate] DESC, T060.[Id] DESC;
END;
GO
