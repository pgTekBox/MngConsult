-- =============================================================================
-- s0695GenerateInvoiceNumber
--   Génère le prochain numéro officiel de facture pour une compagnie, à partir
--   des paramètres de numérotation (T101 : INV_NUM_*) et du compteur
--   T062DocumentNumberCounter (incrément atomique, dans la transaction appelante).
--
--   Jetons de format : {PREFIXE} {AAAA} {MM} {NUMERO}
--   Appelée par sp_ComptabiliserDocument uniquement à la comptabilisation.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE dbo.s0695GenerateInvoiceNumber
    @CompanyGUID    UNIQUEIDENTIFIER,
    @DocumentTypeId INT,
    @RefDate        DATE,
    @Number         VARCHAR(120) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start  INT, @digits INT, @reset INT,
            @prefix VARCHAR(50), @format VARCHAR(120);

    SELECT @start  = v.iVal FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id
        WHERE t.CompanyGUID = @CompanyGUID AND t.ShortName = 'INV_NUM_START';
    SELECT @digits = v.iVal FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id
        WHERE t.CompanyGUID = @CompanyGUID AND t.ShortName = 'INV_NUM_DIGITS';
    SELECT @reset  = v.iVal FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id
        WHERE t.CompanyGUID = @CompanyGUID AND t.ShortName = 'INV_NUM_RESET_YEARLY';
    SELECT @prefix = v.sVal FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id
        WHERE t.CompanyGUID = @CompanyGUID AND t.ShortName = 'INV_NUM_PREFIX';
    SELECT @format = v.sVal FROM dbo.T101ParamValues v JOIN dbo.T100ParamComptable t ON t.Id = v.T100Id
        WHERE t.CompanyGUID = @CompanyGUID AND t.ShortName = 'INV_NUM_FORMAT';

    -- Valeurs par défaut si le paramètre n'est pas (encore) renseigné
    SET @start  = ISNULL(@start, 1);
    SET @digits = ISNULL(NULLIF(@digits, 0), 4);
    SET @reset  = ISNULL(@reset, 0);
    SET @prefix = ISNULL(@prefix, '');
    SET @format = ISNULL(NULLIF(LTRIM(RTRIM(@format)), ''), '{PREFIXE}-{AAAA}-{NUMERO}');

    DECLARE @year        INT = YEAR(@RefDate);
    DECLARE @counterYear INT = CASE WHEN @reset = 1 THEN @year ELSE 0 END;

    -- Incrément atomique (jamais en dessous du numéro de départ)
    DECLARE @next INT;
    UPDATE dbo.T062DocumentNumberCounter WITH (UPDLOCK, HOLDLOCK)
       SET @next = DernierNumero =
           CASE WHEN DernierNumero + 1 < @start THEN @start ELSE DernierNumero + 1 END
     WHERE CompanyGUID = @CompanyGUID
       AND DocumentTypeId = @DocumentTypeId
       AND Annee = @counterYear;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @next = @start;
        INSERT INTO dbo.T062DocumentNumberCounter (CompanyGUID, DocumentTypeId, Annee, DernierNumero)
        VALUES (@CompanyGUID, @DocumentTypeId, @counterYear, @start);
    END

    -- Séquence avec zéros de tête (jamais tronquée si plus longue que @digits)
    DECLARE @numStr VARCHAR(30) = CAST(@next AS VARCHAR(30));
    IF LEN(@numStr) < @digits
        SET @numStr = RIGHT(REPLICATE('0', @digits) + @numStr, @digits);

    -- Sans préfixe : retirer le jeton {PREFIXE} et un séparateur superflu
    IF @prefix = ''
        SET @format = REPLACE(REPLACE(@format, '{PREFIXE}-', ''), '{PREFIXE} ', '');

    DECLARE @res VARCHAR(150) = @format;
    SET @res = REPLACE(@res, '{PREFIXE}', @prefix);
    SET @res = REPLACE(@res, '{AAAA}',   CAST(@year AS VARCHAR(4)));
    SET @res = REPLACE(@res, '{MM}',     RIGHT('0' + CAST(MONTH(@RefDate) AS VARCHAR(2)), 2));
    SET @res = REPLACE(@res, '{NUMERO}', @numStr);

    SET @Number = @res;
END
GO
