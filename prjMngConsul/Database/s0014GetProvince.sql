SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- s0014GetProvince : liste des provinces / états.
-- @Lang (fr|en|es) choisit la langue du libellé. es = en (demande client).
-- @CountryId : 0 = tous ; sinon filtre par pays (1 = Canada, 2 = USA).
-- Rétrocompatible : sans paramètre => français, tous pays.
-- =============================================================
CREATE OR ALTER PROCEDURE [dbo].[s0014GetProvince]
    @Lang      varchar(2) = 'fr',
    @CountryId int = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Id] AS value,
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(NameEn, [Name])
            WHEN 'es' THEN COALESCE(NameEs, NameEn, [Name])
            ELSE            COALESCE(NameFr, [Name])
        END AS [Name],
        [CountryId],
        [Created]
    FROM [dbo].[T053State]
    WHERE (@CountryId = 0 OR [CountryId] = @CountryId)
    ORDER BY
        [CountryId],
        CASE LOWER(@Lang)
            WHEN 'en' THEN COALESCE(NameEn, [Name])
            WHEN 'es' THEN COALESCE(NameEs, NameEn, [Name])
            ELSE            COALESCE(NameFr, [Name])
        END;
END
GO
