-- =============================================================================
-- s0151UpdateParamValue
-- Met à jour la valeur d'un paramètre de compagnie (T101ParamValues) par son Id.
-- sVal reste la valeur « chaîne » canonique (lue par les procs existantes) ;
-- dVal/fVal sont les miroirs typés (date / float) alimentés par wbfSetting.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[s0151UpdateParamValue]
    @ParamId INT,
    @sVal    VARCHAR(8000) = NULL,
    @iVal    INT           = NULL,
    @dVal    DATETIME      = NULL,
    @fVal    DECIMAL(18,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[T101ParamValues]
       SET [sVal] = @sVal,
           [iVal] = @iVal,
           [dVal] = @dVal,
           [fVal] = @fVal
     WHERE [Id] = @ParamId;
END
GO
