-- =============================================================================
-- T251 — Les acomptes et règlements partiels, pour l'écran
--
-- Le poste « Acomptes et règlements partiels » de l'écran d'import. Les
-- mouvements d'argent eux-mêmes sont déjà repris depuis un moment —
-- staging.PaiementImport et sa table d'affectations, alimentées par
-- s0806ChargerPaiementsImport. Ce qui manquait, c'est de POUVOIR LES REGARDER :
-- s0807 existait sans que personne ne l'appelle.
--
-- CE QUE L'ÉCRAN DOIT DISTINGUER, ET QUE LES DONNÉES BRUTES NE DISENT PAS.
--
--   Un ACOMPTE est un mouvement dont une part ne règle RIEN : MontantNonImpute
--   est positif. L'argent est entré, mais il ne s'applique encore à aucune
--   facture. C'est le cas qui fait diverger la balance âgée du solde des
--   factures, et c'est pour ça qu'on veut le voir.
--
--   Un RÈGLEMENT PARTIEL est une imputation plus petite que le document
--   qu'elle vise. On ne peut PAS le déduire du paiement seul : il faut aller
--   chercher le total du document. D'où la jointure sur staging.DocumentImport
--   dans le troisième jeu — l'écran reçoit le montant imputé ET ce que le
--   document vaut, et n'a plus à deviner.
--
-- LA JOINTURE SE FAIT PAR L'IDENTIFIANT DE LA SOURCE, avec le numéro comme
-- second recours. Le nom n'entre jamais en jeu : deux factures d'un même client
-- peuvent porter le même montant et le même libellé, jamais le même identifiant.
-- Un document qui n'est pas en préparation ressort avec un total NUL plutôt que
-- d'être écarté : une imputation vers un document qu'on n'a pas repris est
-- justement ce qu'il faut voir.
--
-- Procédure : s0826 (lire). Rien ne charge ici — s0806 s'en occupe déjà.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0826GetReglementsImport]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Sens        VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Le récapitulatif, par sens : il sert aux onglets ET au bandeau.
    SELECT [Sens],
           COUNT(*)                          AS [NbMouvements],
           SUM(ISNULL([Montant], 0))          AS [Total],
           SUM(ISNULL([MontantNonImpute], 0)) AS [TotalAcomptes],
           SUM(CASE WHEN ISNULL([MontantNonImpute], 0) > 0.01 THEN 1 ELSE 0 END) AS [NbAcomptes],
           SUM([NbAffectations])              AS [NbImputations],
           SUM(CASE WHEN [Statut] <> 'OK' THEN 1 ELSE 0 END) AS [NbAnomalies],
           MAX([Created])                     AS [Depose]
      FROM staging.PaiementImport
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [Sens];

    -- 2) Les mouvements. Ce qui cloche remonte en premier.
    SELECT [Id], [Sens], [Rang], [ExterneId], [Reference], [DatePaiement],
           [TiersExterneId], [TiersNom], [Devise], [Montant], [MontantNonImpute],
           [ModePaiementNom], [CompteNom], [StatutSource], [NbAffectations],
           [Statut], [Anomalie]
      FROM staging.PaiementImport
     WHERE [CompanyGUID] = @CompanyGUID
       AND (@Sens IS NULL OR @Sens = '' OR [Sens] = @Sens)
     ORDER BY [Sens],
              CASE WHEN [Statut] <> 'OK' THEN 0 ELSE 1 END,
              [DatePaiement] DESC, [Id];

    -- 3) Les imputations, avec ce que vaut le document visé.
    --
    --    OUTER APPLY et pas JOIN : une imputation vers un document absent de la
    --    préparation doit RESTER VISIBLE, avec un total nul. C'est le signe
    --    qu'il manque une facture, et l'écarter cacherait le problème.
    SELECT a.[PaiementId], a.[Rang], a.[DocumentExterneId], a.[DocumentNumero],
           a.[DocumentType], a.[Montant],
           d.[Total]  AS [DocumentTotal],
           d.[Solde]  AS [DocumentSolde],
           d.[Numero] AS [DocumentNumeroRepris]
      FROM staging.PaiementImportAffectation a
      JOIN staging.PaiementImport p ON p.[Id] = a.[PaiementId]
      OUTER APPLY (
          SELECT TOP 1 x.[Total], x.[Solde], x.[Numero]
            FROM staging.DocumentImport x
           WHERE x.[CompanyGUID] = p.[CompanyGUID]
             AND (   (NULLIF(a.[DocumentExterneId], '') IS NOT NULL
                      AND x.[ExterneId] = a.[DocumentExterneId])
                  OR (NULLIF(a.[DocumentExterneId], '') IS NULL
                      AND NULLIF(a.[DocumentNumero], '') IS NOT NULL
                      AND x.[Numero] = a.[DocumentNumero]))
           -- L'identifiant d'abord, le numéro ensuite : un même numéro peut
           -- exister des deux côtés (client et fournisseur), pas un identifiant.
           ORDER BY CASE WHEN x.[ExterneId] = a.[DocumentExterneId] THEN 0 ELSE 1 END, x.[Id]
      ) AS d
     WHERE p.[CompanyGUID] = @CompanyGUID
       AND (@Sens IS NULL OR @Sens = '' OR p.[Sens] = @Sens)
     ORDER BY a.[PaiementId], a.[Rang];
END
GO
