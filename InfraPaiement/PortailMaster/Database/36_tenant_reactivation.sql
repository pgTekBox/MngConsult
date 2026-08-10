/* =====================================================================
   PortailMaster - Script 36 : réactivation d'un compte abonné clôturé
   ---------------------------------------------------------------------
   Inverse de la clôture (s0088OffboardAbonne). Ramène un abonné FERMÉ à
   l'état ACTIF et restaure l'accès de ses utilisateurs.

   ⚠️ IMPOSSIBLE si l'abonné a été ANONYMISÉ (s0089) : les données
   personnelles ont été détruites — l'anonymisation est irréversible.

   Ce que fait la réactivation :
     - T010Abonne : Statut=Actif, efface ClosedUtc/ClosedByAdminId.
     - T011AbonneUser : réactive TOUS les comptes (IsActive=1) + remet à zéro
       compteur d'échecs / verrouillage — nécessaire pour restaurer l'accès
       (le staff n'a pas d'écran de gestion par-utilisateur ; c'est l'abonné
       qui, une fois reconnecté, ré-ajuste ses utilisateurs).
   Ce qu'elle NE fait PAS (à ré-habiliter délibérément, par sécurité) :
     - Clés d'API : restent RÉVOQUÉES (en ré-émettre de nouvelles).
     - Webhook : reste INACTIF (le réactiver manuellement).
     - Clients/Fournisseurs : restent GELÉS (Inactif) ; l'abonné réactive
       ceux qu'il veut depuis ses écrans (Statut modifiable).

   ⚠️ Réactive TOUS les utilisateurs : si certains avaient été désactivés
   individuellement AVANT la clôture, les ré-désactiver au besoin.

   s0090ReactivateAbonne.
   A executer APRES 35. Procs numerotees s0090+.
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0090ReactivateAbonne
    @AbonneId INT,
    @AdminId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId)
    BEGIN RAISERROR(N'Abonné introuvable.', 16, 1); RETURN; END

    IF EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId AND AnonymizedUtc IS NOT NULL)
    BEGIN
        RAISERROR(N'Réactivation impossible : les données de cet abonné ont été anonymisées (action irréversible).', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.T010Abonne WHERE Id = @AbonneId AND Statut = N'Ferme')
    BEGIN
        RAISERROR(N'Réactivation impossible : seul un compte clôturé (Fermé) peut être réactivé.', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        UPDATE dbo.T010Abonne
        SET Statut            = N'Actif',
            ClosedUtc         = NULL,
            ClosedByAdminId   = NULL,
            ModifiedUtc       = SYSUTCDATETIME(),
            ModifiedByAdminId = @AdminId
        WHERE Id = @AbonneId;

        UPDATE dbo.T011AbonneUser
        SET IsActive        = 1,
            FailedAttempts  = 0,
            LockoutUntilUtc = NULL,
            ModifiedUtc     = SYSUTCDATETIME()
        WHERE AbonneId = @AbonneId;
    COMMIT;

    SELECT 1 AS Reactivated;
END
GO

/* Rappel du GRANT (inutile si MngConsul est db_owner). */
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'MngConsul')
    GRANT EXECUTE ON SCHEMA::dbo TO [MngConsul];
GO

PRINT N'36_tenant_reactivation.sql : termine.';
GO
