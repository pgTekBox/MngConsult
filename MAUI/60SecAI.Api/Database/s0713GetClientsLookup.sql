/*
    Liste des clients (pour le sélecteur de « Nouvelle facture »).
    Renvoie Id, PartyGUID et le nom d'affichage. Lecture seule.
    Utilisé par l'API mobile 60SecAI. À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0713GetClientsLookup]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[Id],
        p.[PartyGUID],
        COALESCE(NULLIF(p.[DisplayName], ''), p.[Name]) AS DisplayName
    FROM [dbo].[T050Party] p
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND ISNULL(p.[isDeleted], 0) = 0
      AND p.[Type] IN (1, 3)     -- clients
    ORDER BY COALESCE(NULLIF(p.[DisplayName], ''), p.[Name]);
END
GO
