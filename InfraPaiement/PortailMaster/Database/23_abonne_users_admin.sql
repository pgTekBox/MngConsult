/* =====================================================================
   PortailABN - Script 23 : Gestion multi-utilisateurs par l'abonne
   ---------------------------------------------------------------------
   Permet a un utilisateur ADMINISTRATEUR d'un abonne (T011AbonneUser.IsAdmin)
   de gerer les autres utilisateurs de SON organisation : liste, fiche,
   creation/edition. Toutes les operations sont scopees a l'AbonneId cote
   application ; ces procs ajoutent une garde d'isolation en base.

   L'upsert reutilise s0070SaveAbonneUser (script 22). Ici : liste + fiche.

   A executer APRES 22. Procs numerotees s0071+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   s0071ListAbonneUsers : utilisateurs d'un abonne (filtrables).
   @AbonneId OBLIGATOIRE (scoping locataire). @Search optionnel.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0071ListAbonneUsers
    @AbonneId INT,
    @Search   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id, AbonneId, Email, FirstName, LastName,
            IsAdmin, IsActive, LastLoginUtc, CreatedUtc
    FROM    dbo.T011AbonneUser
    WHERE   AbonneId = @AbonneId
      AND   (@Search IS NULL OR @Search = N''
             OR Email     LIKE N'%' + @Search + N'%'
             OR FirstName LIKE N'%' + @Search + N'%'
             OR LastName  LIKE N'%' + @Search + N'%')
    ORDER BY IsActive DESC, LastName, FirstName, Email;
END
GO

/* ---------------------------------------------------------------------
   s0072GetAbonneUser : fiche d'un utilisateur (inclut AbonneId pour que
   l'application verifie l'appartenance au locataire avant edition).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.s0072GetAbonneUser
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id, AbonneId, Email, FirstName, LastName,
            IsAdmin, IsActive, FailedAttempts, LockoutUntilUtc,
            LastLoginUtc, CreatedUtc, ModifiedUtc
    FROM    dbo.T011AbonneUser
    WHERE   Id = @Id;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'23_abonne_users_admin.sql : termine.';
GO
