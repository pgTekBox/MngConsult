/*
    Résumé TPS/TVQ pour une période (calcul direct depuis les factures).
    Utilisé par l'API mobile 60SecAI (Rapports financiers → Taxes).
    Lecture seule — ne remplace pas sp_GenererRapportTaxe (qui, elle, écrit).
    Perçues  = factures clients      (DocumentTypeId = 1)
    Payées   = factures fournisseurs (DocumentTypeId IN (2,5))
    À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0711GetTaxesResume]
    @CompanyGUID UNIQUEIDENTIFIER,
    @DateDebut   DATE,
    @DateFin     DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SUM(CASE WHEN d.DocumentTypeId = 1        THEN ISNULL(d.TPS, 0) ELSE 0 END) AS TpsPercue,
        SUM(CASE WHEN d.DocumentTypeId = 1        THEN ISNULL(d.TVQ, 0) ELSE 0 END) AS TvqPercue,
        SUM(CASE WHEN d.DocumentTypeId IN (2, 5)  THEN ISNULL(d.TPS, 0) ELSE 0 END) AS TpsPayee,
        SUM(CASE WHEN d.DocumentTypeId IN (2, 5)  THEN ISNULL(d.TVQ, 0) ELSE 0 END) AS TvqPayee
    FROM [dbo].[T060Document] d
    WHERE d.CompanyGUID = @CompanyGUID
      AND d.DocumentDate >= @DateDebut
      AND d.DocumentDate <= @DateFin
      AND ISNULL(d.ComptabilisationStatus, '') = 'COMPTABILISE';
END
GO
