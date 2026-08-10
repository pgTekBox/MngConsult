/* =====================================================================
   PortailMaster - Script 43 : liste des utilisateurs d'un partenaire
   ---------------------------------------------------------------------
   Complement du script 42 (Modele B). Utilise par la page staff
   wbfPartenaires pour afficher les utilisateurs du portail partenaire.

   A executer APRES 42. Proc s0119.
   ===================================================================== */

USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0119ListPartnerUsers
    @PartenaireId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Email, FirstName, LastName, IsAdmin, IsActive, LastLoginUtc, CreatedUtc
    FROM   dbo.T046PartenaireUser
    WHERE  PartenaireId = @PartenaireId
    ORDER BY IsActive DESC, Email;
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'43_partenaire_users_list.sql : termine.';
GO
