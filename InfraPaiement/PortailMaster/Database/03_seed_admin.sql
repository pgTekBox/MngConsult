/* =====================================================================
   PortailMaster - Script 03 : Administrateur de depart (seed)
   ---------------------------------------------------------------------
   Cree un premier administrateur pour se connecter au portail.

        Courriel     : admin@60secpaiement.ca
        Mot de passe : Admin@2026

   >>> CHANGEZ ce mot de passe des la premiere connexion (fonction a
       venir) ou en regenerant un hash BCrypt. <<<

   Le hash ci-dessous est un BCrypt ($2a$11$...) genere pour "Admin@2026".
   ===================================================================== */

USE [60secPaiement];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.T001PortalAdmin WHERE Email = N'admin@60secpaiement.ca')
BEGIN
    INSERT INTO dbo.T001PortalAdmin (Email, PasswordHash, FirstName, LastName, IsActive, IsSuperAdmin)
    VALUES (N'admin@60secpaiement.ca',
            N'$2a$11$SA4wZ4hDPoCu70tpR2Llfe.Vrd6kddvZDQr1ntYfMBLmKsfa9dKUS',
            N'Admin',
            N'60secPaiement',
            1,
            1);

    PRINT N'Administrateur de depart cree : admin@60secpaiement.ca / Admin@2026';
END
ELSE
BEGIN
    PRINT N'Administrateur admin@60secpaiement.ca deja present : aucun changement.';
END
GO
