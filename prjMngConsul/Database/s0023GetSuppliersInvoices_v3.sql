-- =============================================================================
-- s0023GetSuppliersInvoices (v3)
-- Ajout colonnes pour le bouton "Programmer auto-paiement" :
--   AutoPay                  : flag T060 (1 = facture programmee)
--   AutoPayStatus            : PLANIFIE / EN_COURS / PAYE / ECHEC / REQUIRES_3DS / ANNULE
--   AutoPayDate              : date prevue du debit
--   HasActiveAuthorization   : 1 si T144 active existe pour ce fournisseur
--                              (permet d'afficher le bouton Programmer)
--
-- Conserve toutes les colonnes V2 (DejaPaye, ResteAPayer, StatutPaiement,
-- LastPaymentMethod, StripeAccountId).
-- =============================================================================

USE [MngConsul];
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0023GetSuppliersInvoices', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0023GetSuppliersInvoices;
GO

-- @Etats / @StatutsPaiement : listes separees par des virgules, pour les filtres
--   a selection multiple de la grille. Vide ou NULL = aucun filtre.
--     @Etats           'Brouillon', 'Comptabilise'
--     @StatutsPaiement 'OUVERTE', 'PARTIELLE', 'PAYEE'
--   Valeurs par defaut : les appelants existants ne changent pas.
CREATE PROCEDURE [dbo].[s0023GetSuppliersInvoices]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search VARCHAR(100),
    @Etats VARCHAR(200) = NULL,
    @StatutsPaiement VARCHAR(200) = NULL
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
    ),
    -- Compte les autorisations actives par fournisseur (pour bouton Programmer)
    AuthByParty AS (
        SELECT PartyId, COUNT(*) AS ActiveAuthCount
        FROM dbo.T144AuthorizationAutoPay
        WHERE CompanyGUID = @CompanyGUID
          AND RevokedDate IS NULL
        GROUP BY PartyId
    ),
    -- Le statut de paiement est CALCULÉ ci-dessous : on passe par une CTE pour
    -- pouvoir filtrer dessus (impossible dans un WHERE sur un alias du SELECT).
    Src AS (
    SELECT
        T060.[Id],

        '<div>' + T060.[Name] + ' '
            + COALESCE(T060.Address1, '')
            + COALESCE(T060.Address2, '')
            + ' '
            + COALESCE(T060.[City], '')
            + '</div>'                                                    AS Name,

        T060.Total,

        -- Numero de la facture. Sans image de recu (facture saisie a la main),
        -- imageGUID est NULL : la concatenation rendait TOUTE la colonne NULL et
        -- la premiere colonne de la grille restait vide. On n'habille donc le
        -- numero d'un lien vers la visionneuse que s'il y a une image.
        CASE WHEN T060.[imageGUID] IS NOT NULL THEN
            '<div>
            <a style="color:blue; text-decoration:underline; " title="'
                + COALESCE(T060.[DocumentNumber], '')
                + '" onclick = openImageViewer(''Voirlerecu_'
                + CONVERT(VARCHAR(200), T060.imageGUID)
                + '.jpeg'') >
                <span style="cursor:pointer;">'
                + dbo.fn_Truncate(COALESCE(T060.[DocumentNumber], 'LeRecu'), 10)
                + '</span>
            </a>
         </div>'
        ELSE
            '<div title="' + COALESCE(T060.[DocumentNumber], '') + '">'
                + dbo.fn_Truncate(COALESCE(T060.[DocumentNumber], ''), 10)
                + '</div>'
        END                                                               AS DocumentNumber,
        T050.Id                                                           AS PartyId,
        T060.Created,
        T001.[imageGUID],
        T060.[PartyGUID],
        T066.[Name]                                                       AS Statusold,
        CASE WHEN [ComptabilisationStatus] = 'COMPTABILISE'
             THEN N'Comptabilisé' ELSE 'Brouillon' END                    AS Status,
        T060.[ComptabilisationStatus],
        T060.DocumentDate,
        T060.DueDate,

        -- Colonnes BRUTES pour le tri : les colonnes affichées plus haut
        -- contiennent du HTML, on ne peut pas trier dessus.
        T060.[Name]                                                       AS NameSort,
        T060.[DocumentNumber]                                             AS NumeroSort,

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
        T050.StripeAccountId,

        -- AutoPay (V3)
        ISNULL(T060.AutoPay, 0)                                           AS AutoPay,
        T060.AutoPayStatus                                                AS AutoPayStatus,
        T060.AutoPayDate                                                  AS AutoPayDate,
        CAST(CASE WHEN ISNULL(ap.ActiveAuthCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) AS HasActiveAuthorization

    FROM [dbo].[T060Document] T060
    LEFT JOIN [dbo].[T050Party] T050
        ON T050.PartyGUID = T060.[PartyGUID]
    INNER JOIN [dbo].[T066DocumentStatus] T066
        ON T066.Id = T060.[StatusId]
    LEFT JOIN [dbo].[T0001Receipt] T001
        ON T001.[imageGUID] = T060.[imageGUID]
    LEFT JOIN PaiementsCumules pc
        ON pc.DocumentId = T060.[Id]
    LEFT JOIN AuthByParty ap
        ON ap.PartyId = T050.Id
    WHERE T060.[CompanyGUID] = @CompanyGUID
      AND T060.[DocumentTypeId] IN (2, 5)
      AND (T060.[Name] LIKE '%' + @Search + '%')
    )
    SELECT *
    FROM Src
    -- Filtres a selection multiple de la grille (vide = pas de filtre)
    WHERE (@Etats IS NULL OR LTRIM(RTRIM(@Etats)) = ''
           OR Src.[Status] IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Etats, ',')))
      AND (@StatutsPaiement IS NULL OR LTRIM(RTRIM(@StatutsPaiement)) = ''
           OR Src.[StatutPaiement] IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@StatutsPaiement, ',')))
    -- Ordre par defaut de la grille : de la plus recente a la plus vieille.
    -- Un brouillon n'a pas de date de document : on retombe sur sa date de
    -- creation pour qu'il se classe quand meme au bon endroit. L'Id departage
    -- les documents de meme date et rend l'ordre deterministe.
    ORDER BY COALESCE(Src.[DocumentDate], Src.[Created]) DESC, Src.[Id] DESC;
END;
GO
