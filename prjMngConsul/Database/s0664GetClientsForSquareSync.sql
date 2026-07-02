-- =============================================================================
-- s0664GetClientsForSquareSync
-- Retourne les clients d'une compagnie a exporter vers Square (Customers API),
-- avec leurs coordonnees (1re adresse) et leurs identifiants Square existants
-- (colonnes sur T050Party) pour permettre une MISE A JOUR plutot qu'une creation.
--
-- Clients = T050Party.Type IN (1, 3)  (CLIENT, CLIENT_FOURNISSEUR), non supprimes.
-- L'adresse retenue : adresse principale (AddressTypeId = 1) sinon la 1re par Id.
-- =============================================================================

USE [MngConsul];
GO

-- Coherence avec les autres procs : QUOTED_IDENTIFIER/ANSI_NULLS ON a la creation.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.s0664GetClientsForSquareSync', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0664GetClientsForSquareSync;
GO

CREATE PROCEDURE dbo.s0664GetClientsForSquareSync
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[Id],
        p.[Name],
        p.[DisplayName],
        p.[Note],
        a.[Email],
        a.[Phone],
        a.[Address1],
        a.[Address2],
        a.[City],
        a.[PostalCode],
        p.[SquareCustomerId],
        p.[SquareCustomerVersion]
    FROM dbo.T050Party p
    OUTER APPLY (
        SELECT TOP 1
            a2.[Email], a2.[Phone], a2.[Address1], a2.[Address2], a2.[City], a2.[PostalCode]
        FROM dbo.T054PartyAddress a2
        WHERE a2.PartyId = p.[Id]
        ORDER BY CASE WHEN a2.AddressTypeId = 1 THEN 0 ELSE 1 END, a2.[Id]
    ) a
    WHERE p.[CompanyGUID] = @CompanyGUID
      AND ISNULL(p.[isDeleted], 0) = 0
      AND p.[Type] IN (1, 3)
      AND p.[Name] IS NOT NULL
      AND LEN(LTRIM(RTRIM(p.[Name]))) > 0
    ORDER BY p.[Name];
END
GO
