-- ===========================================================================
-- T343 — « Ma journée » du Portail comptable : branchement sur les tâches
-- réelles (T339DossierTache de la Phase 4) + données réelles de démonstration.
--
--  1) Ajoute 3 employés réels au cabinet de démo (comptes comptables actifs),
--     pour que la vue « par employé » soit riche avec de vraies données.
--  2) Proc s0956GetJourneeTaches : toutes les tâches du périmètre du cabinet
--     (scopées par rôle via fCabinetDossiers), avec dossier + employé assigné.
--  3) Seed d'un jeu de tâches variées (échéances passées/présentes/futures,
--     statuts afaire/encours/bloque/fait) réparties sur les 5 employés et les
--     5 dossiers du cabinet de démo.
--
-- Idempotent : les membres sont ajoutés s'ils n'existent pas ; les tâches de
-- seed sont marquées par CreatedBy sentinelle et ré-insérées à chaque passage.
-- Rejouable sans dommage (n'écrase aucune donnée hors seed).
-- ===========================================================================
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DECLARE @cab   int = 1;                                              -- Cabinet 60sec (démo)
DECLARE @home  uniqueidentifier = 'D2D2D2D2-0000-4000-8000-000000000002'; -- compagnie maison (celle de l'admin)
DECLARE @hash  nvarchar(500) = '$2a$11$UivG96fK3TnS4EZ8KucBuOc1U4MtKTh3Osq3BSQ.m6y9G7sq6OjTW'; -- BCrypt de « 123 »

-- ---- 1) Employés réels de démonstration -----------------------------------
;WITH demo(Email, FirstName, LastName) AS (
    SELECT N'marie.tremblay@60sec.ca', N'Marie',  N'Tremblay' UNION ALL
    SELECT N'luc.bouchard@60sec.ca',   N'Luc',    N'Bouchard' UNION ALL
    SELECT N'sophie.gagnon@60sec.ca',  N'Sophie', N'Gagnon'
)
INSERT INTO dbo.T015User
    (CompanyGUID, Email, PasswordHash, FirstName, LastName,
     IsAdmin, IsAccountant, IsActive, IsEmailVerified, CreatedBy)
SELECT @home, d.Email, @hash, d.FirstName, d.LastName,
       0, 1, 1, 1, N'seed-journee'
FROM demo d
WHERE NOT EXISTS (SELECT 1 FROM dbo.T015User u WHERE u.Email = d.Email AND u.IsDeleted = 0);

INSERT INTO dbo.T332CabinetMembre (CabinetId, UserGUID, Role)
SELECT @cab, u.UserGUID, 'employe'
FROM dbo.T015User u
WHERE u.Email IN (N'marie.tremblay@60sec.ca', N'luc.bouchard@60sec.ca', N'sophie.gagnon@60sec.ca')
  AND u.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM dbo.T332CabinetMembre m WHERE m.CabinetId = @cab AND m.UserGUID = u.UserGUID);
GO

-- ---- 2) Proc : toutes les tâches du périmètre du cabinet ------------------
CREATE OR ALTER PROCEDURE dbo.s0956GetJourneeTaches
    @UserId varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid uniqueidentifier;
    SELECT TOP 1 @uid = u.UserGUID
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;
    IF @uid IS NULL RETURN;

    SELECT
        t.Id,
        t.Titre,
        t.Description,
        CONVERT(varchar(40), t.CompanyGUID)       AS CompanyGUID,
        dbo.fCompanyName(t.CompanyGUID)            AS DossierNom,
        CONVERT(varchar(40), t.AssignedUserGUID)  AS AssignedUserGUID,
        LTRIM(RTRIM(ISNULL(au.FirstName, N'') + N' ' + ISNULL(au.LastName, N''))) AS AssignedNom,
        DATEDIFF(DAY, CAST(GETDATE() AS date), t.Echeance) AS Jours,
        t.Statut
    FROM dbo.T339DossierTache t
    JOIN dbo.fCabinetDossiers(@uid) f ON f.CompanyGUID = t.CompanyGUID
    LEFT JOIN dbo.T015User au ON au.UserGUID = t.AssignedUserGUID
    ORDER BY ISNULL(t.Echeance, '9999-12-31'), t.Id;
END
GO

-- ---- 3) Seed des tâches ----------------------------------------------------
DECLARE @cab   int = 1;                                                   -- Cabinet 60sec (démo)
DECLARE @seed  uniqueidentifier = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';  -- sentinelle « tâche de démo »
DECLARE @today date = CAST(GETDATE() AS date);

DELETE FROM dbo.T339DossierTache WHERE CreatedBy = @seed;

DECLARE @admin  uniqueidentifier = (SELECT UserGUID FROM dbo.T015User WHERE Email = 'comptable@60sec.ca'      AND IsDeleted = 0);
DECLARE @lea    uniqueidentifier = (SELECT UserGUID FROM dbo.T015User WHERE Email = 'employe1@60sec.ca'       AND IsDeleted = 0);
DECLARE @marie  uniqueidentifier = (SELECT UserGUID FROM dbo.T015User WHERE Email = 'marie.tremblay@60sec.ca' AND IsDeleted = 0);
DECLARE @luc    uniqueidentifier = (SELECT UserGUID FROM dbo.T015User WHERE Email = 'luc.bouchard@60sec.ca'   AND IsDeleted = 0);
DECLARE @sophie uniqueidentifier = (SELECT UserGUID FROM dbo.T015User WHERE Email = 'sophie.gagnon@60sec.ca'  AND IsDeleted = 0);

DECLARE @boutique  uniqueidentifier = 'D2D2D2D2-0000-4000-8000-000000000002';
DECLARE @clinique  uniqueidentifier = 'D4D4D4D4-0000-4000-8000-000000000004';
DECLARE @info      uniqueidentifier = 'D89EB638-6B05-443D-B1C9-01A6316443BF';
DECLARE @plomberie uniqueidentifier = 'D5D5D5D5-0000-4000-8000-000000000005';
DECLARE @nordik    uniqueidentifier = 'D3D3D3D3-0000-4000-8000-000000000003';

INSERT INTO dbo.T339DossierTache
    (CabinetId, CompanyGUID, Titre, Description, AssignedUserGUID, Echeance, Statut, CreatedBy)
VALUES
    (@cab, @nordik,    N'Concilier le relevé bancaire d''octobre',  N'Importez le relevé : j''apparie la plupart des lignes, vous validez le reste.', @admin,  DATEADD(DAY, -2, @today), 'afaire',  @seed),
    (@cab, @nordik,    N'Transmettre un relevé d''emploi',          N'Je pré-remplis le relevé à partir de la dernière paie.',                       @lea,    DATEADD(DAY, -3, @today), 'afaire',  @seed),
    (@cab, @nordik,    N'Obtenir les pièces manquantes du client',  N'J''ai envoyé au client la liste des pièces manquantes.',                       @admin,  DATEADD(DAY,  5, @today), 'encours', @seed),
    (@cab, @nordik,    N'Vérifier les dépenses par carte',          N'Les dépenses sans pièce justificative sont surlignées pour suivi.',            @luc,    DATEADD(DAY,  7, @today), 'afaire',  @seed),
    (@cab, @plomberie, N'Produire la déclaration TPS/TVQ',          N'Vérifiez les taxes extraites avant de transmettre à Revenu Québec.',           @admin,  DATEADD(DAY,  0, @today), 'afaire',  @seed),
    (@cab, @plomberie, N'Classer les factures d''achat',            N'Glissez les PDF : j''extrais le fournisseur, la date et les taxes.',           @marie,  DATEADD(DAY,  1, @today), 'afaire',  @seed),
    (@cab, @plomberie, N'Relancer une facture client impayée',      N'Un rappel courtois part en un clic ; je relance encore dans 7 jours.',         @luc,    DATEADD(DAY,  0, @today), 'afaire',  @seed),
    (@cab, @plomberie, N'Réviser la paie du mois',                  N'Contrôlez les heures et les retenues avant l''émission.',                      @marie,  DATEADD(DAY,  6, @today), 'encours', @seed),
    (@cab, @clinique,  N'Produire la déclaration TPS/TVQ',          N'En attente d''une autorisation du client pour transmettre.',                   @lea,    DATEADD(DAY, -1, @today), 'bloque',  @seed),
    (@cab, @clinique,  N'Préparer les états financiers',            N'Bilan et résultats seront prêts dès la clôture du mois.',                      @lea,    DATEADD(DAY,  9, @today), 'afaire',  @seed),
    (@cab, @clinique,  N'Classer les factures d''achat',            N'',                                                                             @luc,    DATEADD(DAY, 21, @today), 'afaire',  @seed),
    (@cab, @clinique,  N'Approuver la conciliation mensuelle',      N'Un coup d''œil, puis j''inscris l''approbation au journal.',                   @lea,    DATEADD(DAY, -5, @today), 'fait',    @seed),
    (@cab, @boutique,  N'Réviser la paie du mois',                  N'Contrôlez les heures et les retenues avant l''émission.',                      @sophie, DATEADD(DAY,  2, @today), 'afaire',  @seed),
    (@cab, @boutique,  N'Fermer le mois comptable',                 N'Je bloque les écritures une fois la conciliation approuvée.',                  @sophie, DATEADD(DAY,  4, @today), 'afaire',  @seed),
    (@cab, @boutique,  N'Approuver la conciliation mensuelle',      N'',                                                                             @lea,    DATEADD(DAY,  3, @today), 'encours', @seed),
    (@cab, @boutique,  N'Préparer les acomptes provisionnels',      N'Je calcule l''acompte à partir des résultats courants.',                       @admin,  DATEADD(DAY, 14, @today), 'afaire',  @seed),
    (@cab, @info,      N'Produire la déclaration TPS/TVQ',          N'',                                                                             @marie,  DATEADD(DAY, 14, @today), 'afaire',  @seed),
    (@cab, @info,      N'Relancer une facture client impayée',      N'Je relance encore dans 7 jours si le client ne répond pas.',                   @admin,  DATEADD(DAY,  4, @today), 'afaire',  @seed),
    (@cab, @info,      N'Obtenir les pièces manquantes du client',  N'',                                                                             @sophie, DATEADD(DAY,  1, @today), 'bloque',  @seed),
    (@cab, @info,      N'Classer les factures d''achat',            N'',                                                                             @marie,  DATEADD(DAY, -1, @today), 'fait',    @seed);
GO
