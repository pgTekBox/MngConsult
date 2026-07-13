-- =============================================================================
-- s0160GetParamValue
-- Lit un paramètre (par ShortName) pour une compagnie donnée.
-- Expose les 4 colonnes de valeur : sVal (chaîne), iVal (INT), dVal (DATE),
-- fVal (DECIMAL). Filtre p.CompanyGUID = @CompanyGUID : chaque compagnie a ses
-- propres définitions T100 (voir s0500/s0150), donc le filtre est indispensable
-- pour ne pas ramener plusieurs lignes homonymes.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[s0160GetParamValue]
    @CompanyGUID UNIQUEIDENTIFIER,
    @ShortName   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[ShortName],
        p.[Name],
        p.[ParamType],
        p.[Categorie],
        v.[sVal],
        v.[iVal],
        v.[dVal],
        v.[fVal]
    FROM [dbo].[T100ParamComptable] p
    LEFT JOIN [dbo].[T101ParamValues] v
           ON v.[T100Id]      = p.[Id]
          AND v.[CompanyGUID] = @CompanyGUID
    WHERE p.[ShortName]   = @ShortName
      AND p.[CompanyGUID] = @CompanyGUID;
END
GO
