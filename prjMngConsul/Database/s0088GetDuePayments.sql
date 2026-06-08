-- =============================================================================
-- s0088GetDuePayments
-- Retourne les factures dues a debiter aujourd'hui, lockees pour le scheduler.
--
-- Logique du lock : on passe le Status de PLANIFIE -> EN_COURS dans la meme
-- transaction (UPDATE + OUTPUT), donc deux executions concurrentes du
-- scheduler ne peuvent pas traiter la meme facture en double.
--
-- Critere de selection :
--   - AutoPay = 1
--   - AutoPayStatus = 'PLANIFIE'
--   - AutoPayDate <= aujourd'hui
--   - AutoPayAttempts < @MaxAttempts (defaut 3)
--   - Autorisation toujours active (T144.RevokedDate IS NULL)
--   - Si carte : preavis 24h envoye (AutoPayPreavisSentDate IS NOT NULL)
--   - Si ACSS : preavis PAD 3 jours envoye (AutoPayPadPreavisSentDate IS NOT NULL)
--
-- Joint T144 pour ramener tout ce que le scheduler doit savoir pour appeler Stripe.
-- =============================================================================

USE [MngConsul];
GO

IF OBJECT_ID('dbo.s0088GetDuePayments', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0088GetDuePayments;
GO

CREATE PROCEDURE dbo.s0088GetDuePayments
    @MaxAttempts        INT = 3,
    @BatchSize          INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    -- Lock atomique : UPDATE des factures eligibles -> EN_COURS, OUTPUT la liste.
    -- L'index IX_T060_AutoPayScheduler (filtre WHERE AutoPay=1) couvre la requete.

    DECLARE @Locked TABLE (
        DocumentId INT,
        CompanyGUID UNIQUEIDENTIFIER,
        PartyGUID UNIQUEIDENTIFIER,
        Total DECIMAL(15,2),
        AutoPayDate DATE,
        AutoPayAttempts INT,
        AutoPayAuthorizationId INT
    );

    UPDATE TOP (@BatchSize) D
        SET AutoPayStatus = 'EN_COURS'
        OUTPUT inserted.Id,
               inserted.CompanyGUID,
               inserted.PartyGUID,
               inserted.Total,
               inserted.AutoPayDate,
               inserted.AutoPayAttempts,
               inserted.AutoPayAuthorizationId
        INTO @Locked
    FROM dbo.T060Document D
        INNER JOIN dbo.T144AuthorizationAutoPay A
            ON A.Id = D.AutoPayAuthorizationId
            AND A.RevokedDate IS NULL
    WHERE D.AutoPay = 1
      AND D.AutoPayStatus = 'PLANIFIE'
      AND D.AutoPayDate <= @Today
      AND D.AutoPayAttempts < @MaxAttempts
      AND (
            -- Carte : preavis 24h envoye
            (A.PaymentMethodType = 'card' AND D.AutoPayPreavisSentDate IS NOT NULL)
            OR
            -- ACSS : preavis PAD envoye
            (A.PaymentMethodType = 'acss_debit' AND D.AutoPayPadPreavisSentDate IS NOT NULL)
          );

    -- Retourner les details necessaires au scheduler
    SELECT
        L.DocumentId,
        L.CompanyGUID,
        L.PartyGUID,
        P.Id AS PartyId,
        P.DisplayName AS PartyName,
        D.DocumentNumber,
        D.DocumentDate,
        D.DueDate,
        L.Total,
        L.AutoPayDate,
        L.AutoPayAttempts,
        L.AutoPayAuthorizationId,

        A.StripeAccountId,
        A.StripeCustomerId,
        A.StripePaymentMethodId,
        A.PaymentMethodType,
        A.MaxAmountPerCharge,
        A.MaxAmountPerMonth,
        A.AuthorizedByUserGUID,

        -- Reste a payer (au cas ou paiement partiel deja effectue)
        L.Total - ISNULL((
            SELECT SUM(RD.MontantImpute)
            FROM dbo.T141ReglementDocument RD
                INNER JOIN dbo.T140Reglement R ON R.Id = RD.ReglementId
            WHERE RD.DocumentId = L.DocumentId
              AND R.Statut IN ('COMPTABILISE','RAPPROCHE')
        ), 0) AS RestantAPayer
    FROM @Locked L
        INNER JOIN dbo.T060Document D ON D.Id = L.DocumentId
        INNER JOIN dbo.T050Party P ON P.PartyGUID = L.PartyGUID AND P.CompanyGUID = L.CompanyGUID
        INNER JOIN dbo.T144AuthorizationAutoPay A ON A.Id = L.AutoPayAuthorizationId;
END
GO
