/* =====================================================================
   PortailMaster/ABN - Script 24 : indicateur « prêt EFT » dans les listes
   ---------------------------------------------------------------------
   Ajoute une colonne calculee HasBankCoords (1 si institution+transit+
   compte tous renseignes) aux procs de liste clients/fournisseurs, pour
   afficher dans le portail des abonnes lesquels peuvent figurer dans un
   fichier CPA-005. Ajout en fin de SELECT = retro-compatible (webAPI et
   pages existantes lisent les colonnes par nom).

   A executer APRES 16 et 23. Aucune nouvelle proc sNNNN.
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
            CourrielContact, Telephone, Ville, Province, Statut, CreatedUtc,
            CAST(CASE WHEN BankInstitution IS NOT NULL AND BankTransit IS NOT NULL
                       AND BankAccount IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS HasBankCoords
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
            CourrielContact, Telephone, Ville, Province, Statut, CreatedUtc,
            CAST(CASE WHEN BankInstitution IS NOT NULL AND BankTransit IS NOT NULL
                       AND BankAccount IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS HasBankCoords
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

PRINT N'24_bank_coords_list.sql : termine.';
GO
