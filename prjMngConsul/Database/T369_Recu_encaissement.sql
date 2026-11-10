-- =============================================================================
-- T369 — Imprimer un encaissement avec son détail (reçu de paiement PDF)
--
-- Ventes › Encaissements : chaque paiement reçu a un bouton « Imprimer » qui
-- ouvre le reçu PDF (EncaissementPdf.ashx, QuestPDF) : la compagnie, le client,
-- la date, le mode et la référence, le compte de banque, et le détail des
-- factures payées (total, montant appliqué, solde restant).
--
-- s0988GetEncaissementPdf : 0 = l'en-tête (règlement, compagnie, client,
--                           compte, ligne du relevé reliée) ; 1 = les factures.
-- s0905GetEncaissements   : « Rapproché avec la banque » vient désormais du
--                           lien posé par le rapprochement du relevé
--                           (T208ReleveLien, scripts T367 et T370) ;
--                           l'ancienne colonne de T140 n'a jamais été remplie.
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0988GetEncaissementPdf
    @CompanyGUID UNIQUEIDENTIFIER,
    @ReglementId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T140Reglement WHERE Id = @ReglementId AND CompanyGUID = @CompanyGUID)
        THROW 51060, 'Encaissement introuvable.', 1;

    -- 0. L'en-tête
    SELECT r.Id, r.DateReglement, r.Montant, ISNULL(r.Reference, '') AS Reference,
           ISNULL(r.TypeReglement, '') AS TypeReglement, r.Sens, ISNULL(r.Statut, '') AS Statut,
           ISNULL(r.CompteBanque, '') AS CompteBanque, ISNULL(gl.Nom, '') AS NomCompteBanque,
           r.Created,
           -- Client
           ISNULL(NULLIF(p.DisplayName, ''), ISNULL(p.Name, '')) AS ClientNom,
           ISNULL(a.Address1, '') AS ClientAddr1, ISNULL(a.Address2, '') AS ClientAddr2,
           ISNULL(a.City, '') AS ClientCity, ISNULL(a.PostalCode, '') AS ClientPostal,
           ISNULL(NULLIF(a.Email, ''), '') AS ClientEmail, ISNULL(NULLIF(a.Phone, ''), ISNULL(p.AltPhone, '')) AS ClientPhone,
           -- Compagnie (mêmes paramètres que la facture, s0115)
           dbo.fCompanyName(r.CompanyGUID)               AS CoName,
           dbo.fParamS(r.CompanyGUID, 'TRADE_NAME')      AS CoTradeName,
           dbo.fParamS(r.CompanyGUID, 'ADDR1')           AS CoAddr1,
           dbo.fParamS(r.CompanyGUID, 'ADDR2')           AS CoAddr2,
           dbo.fParamS(r.CompanyGUID, 'CITY')            AS CoCity,
           dbo.fParamS(r.CompanyGUID, 'PROVINCE')        AS CoProvince,
           dbo.fParamS(r.CompanyGUID, 'POSTAL')          AS CoPostal,
           dbo.fParamS(r.CompanyGUID, 'PHONE')           AS CoPhone,
           dbo.fParamS(r.CompanyGUID, 'MAIL_FROM_EMAIL') AS CoEmail,
           (SELECT TOP 1 c.Logo FROM dbo.T010Company c WHERE c.CompanyGUID = r.CompanyGUID) AS CoLogo,
           -- La ligne du relevé bancaire reliée (rapprochement, T367)
           rb.DateMouvement AS ReleveDate, rb.Description AS ReleveDescription
    FROM dbo.T140Reglement r
    LEFT JOIN dbo.T050Party p ON p.Id = r.PartyId
    OUTER APPLY (SELECT TOP 1 x.Address1, x.Address2, x.City, x.PostalCode, x.Email, x.Phone
                 FROM dbo.T054PartyAddress x WHERE x.PartyId = r.PartyId
                 ORDER BY x.AddressTypeId) a
    OUTER APPLY (SELECT TOP 1 c.Nom FROM dbo.T121PlanComptable c
                 WHERE c.CompanyGUID = r.CompanyGUID AND c.compte = r.CompteBanque) gl
    OUTER APPLY (SELECT TOP 1 t.DateMouvement, t.Description FROM dbo.T208ReleveLien l JOIN dbo.T142ReleveBancaire t ON t.Id = l.ReleveId
                 WHERE l.ReglementId = r.Id) rb
    WHERE r.Id = @ReglementId AND r.CompanyGUID = @CompanyGUID;

    -- 1. Les factures payées par ce règlement
    SELECT d.Id AS DocumentId, ISNULL(d.DocumentNumber, '') AS DocumentNumber, d.DocumentDate, d.DueDate,
           CAST(ISNULL(d.Total, 0) AS DECIMAL(15, 2)) AS Total,
           CAST(rd.MontantImpute AS DECIMAL(15, 2)) AS MontantImpute,
           CAST(ISNULL(d.Total, 0) - ISNULL((
                SELECT SUM(x.MontantImpute) FROM dbo.T141ReglementDocument x
                JOIN dbo.T140Reglement rx ON rx.Id = x.ReglementId
                WHERE x.DocumentId = d.Id AND rx.Statut <> 'ANNULE'), 0) AS DECIMAL(15, 2)) AS SoldeActuel
    FROM dbo.T141ReglementDocument rd
    JOIN dbo.T060Document d ON d.Id = rd.DocumentId
    WHERE rd.ReglementId = @ReglementId AND d.CompanyGUID = @CompanyGUID
    ORDER BY d.DocumentNumber;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0905GetEncaissements]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = ISNULL(LTRIM(RTRIM(@Search)), N'');

    SELECT r.[Id], r.[DateReglement], r.[Montant], ISNULL(r.[Reference], '') AS [Reference],
           ISNULL(r.[TypeReglement], '') AS [TypeReglement], ISNULL(r.[Statut], '') AS [Statut],
           ISNULL(r.[CompteBanque], '') AS [CompteBanque],
           CASE WHEN EXISTS (SELECT 1 FROM dbo.T208ReleveLien t
                             WHERE t.ReglementId = r.Id) THEN 1 ELSE 0 END AS [Rapproche],
           r.[PartyId], ISNULL(p.[Name], '') AS [PartyName],
           ISNULL(f.[Factures], '') AS [Factures],
           r.[Created]
      FROM dbo.T140Reglement r
      LEFT JOIN dbo.T050Party p ON p.[Id] = r.[PartyId]
      OUTER APPLY (
          SELECT STRING_AGG(d.[DocumentNumber], ', ') WITHIN GROUP (ORDER BY d.[DocumentNumber]) AS [Factures]
            FROM dbo.T141ReglementDocument rd
            JOIN dbo.T060Document d ON d.[Id] = rd.[DocumentId]
           WHERE rd.[ReglementId] = r.[Id]
      ) f
     WHERE r.[CompanyGUID] = @CompanyGUID
       AND r.[Sens] = 'ENCAISSEMENT'
       AND (@Search = N''
            OR ISNULL(p.[Name], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(r.[Reference], '') LIKE N'%' + @Search + N'%'
            OR ISNULL(f.[Factures], '') LIKE N'%' + @Search + N'%')
     ORDER BY r.[DateReglement] DESC, r.[Id] DESC;
END
GO
