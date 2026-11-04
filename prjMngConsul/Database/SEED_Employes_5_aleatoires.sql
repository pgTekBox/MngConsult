-- =============================================================================
-- SEED — 5 employés aléatoires par entreprise qui n'en a aucun
--
-- Pour chaque compagnie de T010Company SANS employé (T300Employees), on insère
-- 5 employés fictifs (noms québécois au hasard, couleur d'agenda, poste, date
-- d'embauche). La compagnie modèle (…0001) est exclue.
--
-- Idempotent : ne touche que les compagnies à 0 employé → rejouable sans doublon.
-- =============================================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @g uniqueidentifier, @n int = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT co.CompanyGUID
    FROM dbo.T010Company co
    WHERE co.CompanyGUID <> '00000000-0000-0000-0000-000000000001'
      AND NOT EXISTS (SELECT 1 FROM dbo.T300Employees e WHERE e.CompanyGUID = co.CompanyGUID);

OPEN cur;
FETCH NEXT FROM cur INTO @g;
WHILE @@FETCH_STATUS = 0
BEGIN
    ;WITH Pick AS (
        SELECT TOP 5 fn.v AS fn, ln.v AS ln
        FROM (VALUES
            (N'Émilie'),(N'Marc'),(N'Sophie'),(N'Julien'),(N'Nadia'),(N'Olivier'),
            (N'Catherine'),(N'Samuel'),(N'Léa'),(N'Antoine'),(N'Chloé'),(N'Maxime'),
            (N'Camille'),(N'Félix'),(N'Gabrielle'),(N'Hugo'),(N'Isabelle'),(N'Jérôme'),
            (N'Karine'),(N'Louis')) fn(v)
        CROSS JOIN (VALUES
            (N'Tremblay'),(N'Gagnon'),(N'Roy'),(N'Côté'),(N'Bouchard'),(N'Gauthier'),
            (N'Morin'),(N'Lavoie'),(N'Fortin'),(N'Gagné'),(N'Ouellet'),(N'Pelletier'),
            (N'Bélanger'),(N'Lévesque'),(N'Bergeron'),(N'Leblanc'),(N'Paquette'),(N'Girard'),
            (N'Simard'),(N'Boucher')) ln(v)
        ORDER BY NEWID()
    ),
    Noms AS (
        SELECT fn, ln, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS k FROM Pick
    )
    INSERT INTO dbo.T300Employees
        (EmployeeGUID, CompanyGUID, FirstName, LastName, DisplayName,
         JobTitle, EmploymentStatus, EmploymentType, Active, ColorHex, HireDate, Created)
    SELECT NEWID(), @g, n.fn, n.ln, n.fn + ' ' + n.ln,
           pal.title, N'Actif', N'Temps plein', 1, pal.hex,
           DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 2000 + 30), CAST(GETDATE() AS date)),
           GETDATE()
    FROM Noms n
    JOIN (VALUES
        (1, '#1B4F9C', N'Conseiller'),
        (2, '#0A827C', N'Technicienne'),
        (3, '#A84DBF', N'Coordonnateur'),
        (4, '#C77D11', N'Adjointe'),
        (5, '#2E7D32', N'Spécialiste')) pal(k, hex, title) ON pal.k = n.k;

    SET @n = @n + 1;
    FETCH NEXT FROM cur INTO @g;
END
CLOSE cur;
DEALLOCATE cur;

PRINT CONCAT('Compagnies garnies : ', @n, ' (5 employés chacune).');
GO
