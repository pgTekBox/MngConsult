/* =====================================================================
   PortailMaster / webAPI - Script 13 : Pagination des procs de liste
   ---------------------------------------------------------------------
   Ajoute @Limit / @Offset (OFFSET ... FETCH) a s0011ListClients,
   s0035ListFournisseurs et s0023ListPayments. Retro-compatible :
   @Limit NULL (defaut) => toutes les lignes (comportement d'origine),
   donc les pages PortailMaster restent inchangees.
   A executer APRES 11-12.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0011ListClients
    @AbonneId INT,
    @Search   NVARCHAR(200) = NULL,
    @Statut   NVARCHAR(20)  = NULL,
    @Limit    INT           = NULL,
    @Offset   INT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, ClientGUID, AbonneId, TypeClient, Nom, ReferenceExterne,
            CourrielContact, Telephone, Ville, Province, Statut, CreatedUtc
    FROM    dbo.T020Client
    WHERE   AbonneId = @AbonneId
      AND   (@Search IS NULL OR @Search = N''
             OR Nom LIKE N'%' + @Search + N'%'
             OR CourrielContact LIKE N'%' + @Search + N'%'
             OR ReferenceExterne LIKE N'%' + @Search + N'%')
      AND   (@Statut IS NULL OR @Statut = N'' OR Statut = @Statut)
    ORDER BY Nom
    OFFSET ISNULL(@Offset, 0) ROWS
    FETCH NEXT COALESCE(@Limit, 2147483647) ROWS ONLY;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0035ListFournisseurs
    @AbonneId INT,
    @Search   NVARCHAR(200) = NULL,
    @Statut   NVARCHAR(20)  = NULL,
    @Limit    INT           = NULL,
    @Offset   INT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  Id, FournisseurGUID, AbonneId, TypeFournisseur, Nom, ReferenceExterne,
            CourrielContact, Telephone, Ville, Province, Statut, CreatedUtc
    FROM    dbo.T021Fournisseur
    WHERE   AbonneId = @AbonneId
      AND   (@Search IS NULL OR @Search = N''
             OR Nom LIKE N'%' + @Search + N'%'
             OR CourrielContact LIKE N'%' + @Search + N'%'
             OR ReferenceExterne LIKE N'%' + @Search + N'%')
      AND   (@Statut IS NULL OR @Statut = N'' OR Statut = @Statut)
    ORDER BY Nom
    OFFSET ISNULL(@Offset, 0) ROWS
    FETCH NEXT COALESCE(@Limit, 2147483647) ROWS ONLY;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0023ListPayments
    @AbonneId  INT,
    @Status    NVARCHAR(20)  = NULL,
    @Search    NVARCHAR(200) = NULL,
    @Direction NVARCHAR(10)  = NULL,
    @Limit     INT           = NULL,
    @Offset    INT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  p.Id, p.PaymentGUID, p.ClientId, c.Nom AS ClientNom,
            p.FournisseurId, f.Nom AS FournisseurNom,
            p.Direction, p.Method, p.AmountCents, p.FeeCents, p.NetCents,
            p.Status, p.Description, p.Reference, p.ExpectedSettlementDate,
            p.InitiatedUtc, p.SettledUtc, p.ReturnedUtc, p.ReturnReason
    FROM    dbo.T030Payment p
    LEFT JOIN dbo.T020Client c      ON c.Id = p.ClientId
    LEFT JOIN dbo.T021Fournisseur f ON f.Id = p.FournisseurId
    WHERE   p.AbonneId = @AbonneId
      AND   (@Status IS NULL OR @Status = N'' OR p.Status = @Status)
      AND   (@Direction IS NULL OR @Direction = N'' OR p.Direction = @Direction)
      AND   (@Search IS NULL OR @Search = N''
             OR c.Nom LIKE N'%' + @Search + N'%'
             OR f.Nom LIKE N'%' + @Search + N'%'
             OR p.Reference LIKE N'%' + @Search + N'%'
             OR p.Description LIKE N'%' + @Search + N'%')
    ORDER BY p.Id DESC
    OFFSET ISNULL(@Offset, 0) ROWS
    FETCH NEXT COALESCE(@Limit, 2147483647) ROWS ONLY;
END
GO

PRINT N'13_pagination.sql : termine.';
GO
