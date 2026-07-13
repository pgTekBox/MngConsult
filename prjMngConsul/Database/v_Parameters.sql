-- =============================================================================
-- v_Parameters : vue des valeurs de paramètres par compagnie.
-- Expose désormais aussi les colonnes typées dVal (DATE) et fVal (DECIMAL),
-- en plus de sVal/iVal.
-- =============================================================================
CREATE OR ALTER VIEW dbo.v_Parameters
AS
SELECT
    dbo.T101ParamValues.Id,
    dbo.T101ParamValues.iVal,
    dbo.T101ParamValues.sVal,
    dbo.T101ParamValues.dVal,
    dbo.T101ParamValues.fVal,
    dbo.T100ParamComptable.Name,
    dbo.T100ParamComptable.ParamType,
    dbo.T101ParamValues.CompanyGUID,
    dbo.T100ParamComptable.ShortName
FROM dbo.T101ParamValues
INNER JOIN dbo.T100ParamComptable
    ON dbo.T101ParamValues.T100Id = dbo.T100ParamComptable.Id;
GO
