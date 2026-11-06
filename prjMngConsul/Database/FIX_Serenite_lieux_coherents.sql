-- =============================================================================
-- FIX — Massothérapie Sérénité : un lieu cohérent avec la base pour chaque RDV
--
-- Le champ Location des RDV contenait des valeurs libres (Téléphone, Visio,
-- « À votre place », « Bureau Montréal », NULL…) qui ne correspondent pas aux
-- lieux définis de la compagnie (T331Lieu). On remappe chaque RDV dont le lieu
-- n'est PAS déjà un T331Lieu valide vers le lieu existant le plus proche, par
-- catégorie de sens : à distance / chez le client / à la place d'affaires.
-- Les lieux cibles sont résolus depuis T331Lieu (donc toujours cohérents) ;
-- repli sur le 1er lieu de la compagnie si une catégorie manque.
-- Portée : compagnie D2D2D2D2-…-002 (Massothérapie Sérénité).
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DECLARE @g UNIQUEIDENTIFIER = 'D2D2D2D2-0000-4000-8000-000000000002';

-- Lieu par défaut (repli) et lieux cibles par catégorie, lus depuis T331Lieu
DECLARE @LieuDefaut NVARCHAR(200) =
    (SELECT TOP 1 Nom FROM dbo.T331Lieu WHERE CompanyGUID = @g ORDER BY Id);

IF @LieuDefaut IS NULL
BEGIN
    PRINT 'Aucun lieu défini (T331Lieu) pour cette compagnie — rien à faire.';
    RETURN;
END

DECLARE @LieuDistance NVARCHAR(200) =
    (SELECT TOP 1 Nom FROM dbo.T331Lieu WHERE CompanyGUID = @g
      AND (Nom LIKE N'%distance%' OR Nom LIKE N'%visio%' OR Nom LIKE N'%télé%'
           OR Nom LIKE N'%phone%' OR Nom LIKE N'%ligne%') ORDER BY Id);
DECLARE @LieuClient NVARCHAR(200) =
    (SELECT TOP 1 Nom FROM dbo.T331Lieu WHERE CompanyGUID = @g
      AND (Nom LIKE N'%client%' OR Nom LIKE N'%domicile%') ORDER BY Id);
DECLARE @LieuPlace NVARCHAR(200) =
    (SELECT TOP 1 Nom FROM dbo.T331Lieu WHERE CompanyGUID = @g
      AND (Nom LIKE N'%place%' OR Nom LIKE N'%affaires%' OR Nom LIKE N'%bureau%'
           OR Nom LIKE N'%clinique%' OR Nom LIKE N'%salon%') ORDER BY Id);

SET @LieuDistance = ISNULL(@LieuDistance, @LieuDefaut);
SET @LieuClient   = ISNULL(@LieuClient,   @LieuDefaut);
SET @LieuPlace    = ISNULL(@LieuPlace,    @LieuDefaut);

-- Remap des RDV dont le lieu n'est pas déjà un T331Lieu valide
UPDATE a
SET a.Location =
    CASE
        WHEN x.loc LIKE N'%visio%' OR x.loc LIKE N'%télé%' OR x.loc LIKE N'%phone%'
          OR x.loc LIKE N'%zoom%'  OR x.loc LIKE N'%teams%' OR x.loc LIKE N'%meet%'
          OR x.loc LIKE N'%distance%' OR x.loc LIKE N'%ligne%' OR x.loc LIKE N'%appel%'
            THEN @LieuDistance
        WHEN x.loc LIKE N'%client%' OR x.loc LIKE N'%domicile%' OR x.loc LIKE N'%site%'
            THEN @LieuClient
        ELSE @LieuPlace   -- bureau, place, salle, conférence, inconnu, vide/NULL
    END
FROM dbo.Appointments a
CROSS APPLY (SELECT LOWER(LTRIM(RTRIM(ISNULL(a.Location, N'')))) AS loc) x
WHERE a.CompanyGUID = @g AND a.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM dbo.T331Lieu l
                  WHERE l.CompanyGUID = @g AND l.Nom = a.Location);

PRINT CONCAT('RDV dont le lieu a été rendu cohérent : ', @@ROWCOUNT, '.');
GO

-- Contrôle : répartition des lieux + reste d'incohérents
DECLARE @g2 UNIQUEIDENTIFIER = 'D2D2D2D2-0000-4000-8000-000000000002';
SELECT ISNULL(a.Location, N'(null)') AS LieuRDV, COUNT(*) AS n,
       CASE WHEN EXISTS (SELECT 1 FROM dbo.T331Lieu l WHERE l.CompanyGUID = @g2 AND l.Nom = a.Location)
            THEN 'OK' ELSE 'INCOHERENT' END AS coherent
FROM dbo.Appointments a
WHERE a.CompanyGUID = @g2 AND a.IsDeleted = 0
GROUP BY a.Location
ORDER BY n DESC;
GO
