/*
    Solde bancaire (compte configuré COMPTE_BANQUE / BANCAIRE) pour une entreprise.
    Utilisé par l'API mobile 60SecAI (Rapports financiers → Trésorerie).
    Lecture seule. Reproduit la logique inline de wbfAISale.ChargerSoldeBancaire.
    À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0710GetSoldeBancaire]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        pa.[BalanceCurrent]
    FROM [dbo].[T101ParamValues] pv
    INNER JOIN [dbo].[T100ParamComptable] pc ON pc.[Id]  = pv.[T100Id]
    INNER JOIN [dbo].[T143PlaidAccount]   pa ON pa.[Id]  = pv.[iVal]
    WHERE pv.[CompanyGUID] = @CompanyGUID
      AND pc.[ShortName]   = 'COMPTE_BANQUE'
      AND pc.[Categorie]   = 'BANCAIRE'
      AND pa.[Active]      = 1;
END
GO
