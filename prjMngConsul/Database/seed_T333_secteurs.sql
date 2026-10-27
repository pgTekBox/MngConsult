-- =============================================================================
-- seed_T333 — Première liste de secteurs d'activité, et un secteur par métier
--
-- À exécuter après T333_Secteurs_activite.sql. Crée les secteurs absents, puis
-- donne un secteur aux métiers qui n'en ont pas encore (un secteur choisi dans
-- l'admin n'est jamais écrasé) : le secteur de leur famille, sauf les exceptions
-- par métier ci-dessous.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;
GO

-- <mapping>
DECLARE @ParFamille TABLE (Famille NVARCHAR(100) PRIMARY KEY, Secteur NVARCHAR(100) NOT NULL);
INSERT INTO @ParFamille (Famille, Secteur) VALUES
    (N'Agriculture et production',           N'Agriculture et agroalimentaire'),
    (N'Arts, culture et création',           N'Arts, culture et loisirs'),
    (N'Commerce de détail et en ligne',      N'Commerce de détail et de gros'),
    (N'Construction et métiers spécialisés', N'Construction'),
    (N'Courtage et services financiers',     N'Finance et assurances'),
    (N'Entretien et services à domicile',    N'Services aux bâtiments et à domicile'),
    (N'Garde d''enfants et éducation',       N'Éducation'),
    (N'Hébergement touristique',             N'Hébergement et restauration'),
    (N'Professions de la santé à ordre',     N'Santé et services sociaux'),
    (N'Professions libérales à ordre',       N'Services professionnels'),
    (N'Restauration et alimentation',        N'Hébergement et restauration'),
    (N'Services professionnels par projet',  N'Services professionnels'),
    (N'Services sur rendez-vous',            N'Services personnels'),
    (N'Transport et livraison',              N'Transport et livraison');

DECLARE @ParMetier TABLE (Metier NVARCHAR(150) PRIMARY KEY, Secteur NVARCHAR(100) NOT NULL);
INSERT INTO @ParMetier (Metier, Secteur) VALUES
    -- Courtage et services financiers
    (N'Courtier immobilier',                                    N'Immobilier'),
    -- Entretien et services à domicile
    (N'Aide à domicile et soins aux aînés',                     N'Santé et services sociaux'),
    (N'Gardiennage et promenade d''animaux',                    N'Services personnels'),
    -- Garde d'enfants et éducation
    (N'Studio de yoga ou de mise en forme',                     N'Arts, culture et loisirs'),
    -- Professions de la santé à ordre
    (N'Conseillère ou conseiller d''orientation',               N'Éducation'),
    -- Professions libérales à ordre
    (N'Avocat',                                                 N'Services juridiques'),
    (N'Notaire',                                                N'Services juridiques'),
    (N'Huissier de justice',                                    N'Services juridiques'),
    (N'Évaluateur agréé',                                       N'Immobilier'),
    (N'Agronome',                                               N'Agriculture et agroalimentaire'),
    (N'Ingénieur forestier',                                    N'Agriculture et agroalimentaire'),
    (N'Conseiller d''orientation',                              N'Éducation'),
    -- Restauration et alimentation
    (N'Épicerie fine',                                          N'Commerce de détail et de gros'),
    (N'Producteur artisan de boissons alcoolisées (cidre, vin, hydromel, microbrasserie)', N'Agriculture et agroalimentaire'),
    (N'Producteur artisanal transformateur (confitures, charcuteries, mets préparés)',     N'Agriculture et agroalimentaire'),
    -- Services professionnels par projet
    (N'Consultant en TI',                                       N'Technologies de l''information'),
    (N'Développeur ou programmeur',                             N'Technologies de l''information'),
    (N'Designer web ou UX',                                     N'Technologies de l''information'),
    (N'Animateur 3D ou concepteur multimédia',                  N'Technologies de l''information'),
    (N'Formateur',                                              N'Éducation'),
    (N'Organisateur d''événements',                             N'Arts, culture et loisirs'),
    -- Services sur rendez-vous
    (N'Coach (vie, carrière, affaires)',                        N'Services professionnels'),
    (N'Doula',                                                  N'Santé et services sociaux'),
    (N'Kinésiologue',                                           N'Santé et services sociaux'),
    (N'Massothérapeute',                                        N'Santé et services sociaux'),
    (N'Naturopathe',                                            N'Santé et services sociaux'),
    (N'Orthothérapeute',                                        N'Santé et services sociaux'),
    (N'Ostéopathe',                                             N'Santé et services sociaux'),
    (N'Entraîneuse ou entraîneur personnel',                    N'Arts, culture et loisirs'),
    (N'Professeure ou professeur de musique (cours privés)',    N'Éducation'),
    -- Transport et livraison
    (N'École de conduite',                                      N'Éducation');
-- </mapping>

BEGIN TRANSACTION;

INSERT INTO dbo.T333SecteurActivite (Nom)
SELECT DISTINCT x.Secteur
FROM (SELECT Secteur FROM @ParFamille UNION SELECT Secteur FROM @ParMetier) x
WHERE NOT EXISTS (SELECT 1 FROM dbo.T333SecteurActivite s WHERE s.Nom = x.Secteur);

UPDATE m SET m.SecteurId = s.Id, m.ModifiedOn = GETDATE()
FROM dbo.T330Metier m
LEFT JOIN @ParMetier pm ON pm.Metier = m.Nom
LEFT JOIN @ParFamille pf ON pf.Famille = m.Famille
JOIN dbo.T333SecteurActivite s ON s.Nom = COALESCE(pm.Secteur, pf.Secteur)
WHERE m.SecteurId IS NULL;

COMMIT;

SELECT (SELECT COUNT(*) FROM dbo.T333SecteurActivite) AS NbSecteurs,
       (SELECT COUNT(*) FROM dbo.T330Metier WHERE SecteurId IS NOT NULL) AS MetiersAvecSecteur,
       (SELECT COUNT(*) FROM dbo.T330Metier WHERE SecteurId IS NULL) AS MetiersSansSecteur;
GO
