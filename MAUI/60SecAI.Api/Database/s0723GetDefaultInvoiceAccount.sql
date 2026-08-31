/*
    Compte comptable par defaut d'une ligne de facture client = compte de ventes
    « VP » (dbo.fGetAccount(@CompanyGUID,'VP')), avec son nom depuis T121PlanComptable.
    Sert a associer un compte aux lignes libres. A executer sur MngConsul.
*/
USE MngConsul;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0723GetDefaultInvoiceAccount]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @no VARCHAR(20) = dbo.fGetAccount(@CompanyGUID, 'VP');

    SELECT @no AS NoCompte,
           ISNULL((SELECT TOP 1 c.[Nom]
                   FROM dbo.T121PlanComptable c
                   WHERE c.compte = @no
                     AND c.CompanyGUID = @CompanyGUID
                     AND c.[Actif] = 1), '') AS Name;
END
GO
