/* =====================================================================
   PortailMaster / webAPI - Script 15 : Moindre privilège (accès BD)
   ---------------------------------------------------------------------
   Contexte : en dev, le login applicatif [MngConsul] a été mis db_owner
   sur 60secPaiement. En PRODUCTION, l'app n'a besoin que d'EXECUTE sur les
   procédures stockées (tout l'accès aux tables passe par elles, via le
   chaînage de propriétaire). Ce script prépare un rôle EXECUTE-seul.

   PARTIE A (sûre, additive) : crée le rôle db_apiexec + GRANT EXECUTE +
     y ajoute [MngConsul]. Aucun changement de comportement (MngConsul a
     déjà tout via db_owner).
   PARTIE B (À FAIRE MANUELLEMENT en prod, après tests) : retirer
     [MngConsul] de db_owner pour ne garder qu'EXECUTE. Laissée en
     commentaire — l'exécuter bascule réellement au moindre privilège.
   ===================================================================== */
USE [60secPaiement];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---- PARTIE A : rôle EXECUTE-seul (additif) ---- */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_apiexec' AND type = 'R')
    CREATE ROLE db_apiexec;
GO

GRANT EXECUTE ON SCHEMA::dbo TO db_apiexec;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
   AND NOT EXISTS (
        SELECT 1 FROM sys.database_role_members rm
        JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id AND r.name = N'db_apiexec'
        JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id AND m.name = N'MngConsul')
    ALTER ROLE db_apiexec ADD MEMBER [MngConsul];
GO

PRINT N'PARTIE A terminée : rôle db_apiexec (EXECUTE sur dbo) prêt, [MngConsul] ajouté.';
GO

/* ---- PARTIE B : bascule au moindre privilège (À EXÉCUTER MANUELLEMENT) ----

   1) Vérifier au préalable que l'application fonctionne (toute la BD est
      accédée par procédures stockées sNNNN — aucun SQL direct).
   2) Retirer [MngConsul] de db_owner :

        USE [60secPaiement];
        ALTER ROLE db_owner DROP MEMBER [MngConsul];

   3) (Optionnel, meilleure séparation) créer un login DÉDIÉ aux apps de
      paiement plutôt que réutiliser [MngConsul] (nécessite sysadmin) :

        CREATE LOGIN [SixtySecApp] WITH PASSWORD = '<fort-et-aléatoire>';
        USE [60secPaiement];
        CREATE USER [SixtySecApp] FOR LOGIN [SixtySecApp];
        ALTER ROLE db_apiexec ADD MEMBER [SixtySecApp];
      puis pointer les ConnectionString (Web.config) sur [SixtySecApp].

   Rollback si besoin : ALTER ROLE db_owner ADD MEMBER [MngConsul];
   --------------------------------------------------------------------- */

PRINT N'15_least_privilege.sql : PARTIE A appliquée. PARTIE B = manuelle (voir commentaires).';
GO
