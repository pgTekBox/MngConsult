-- =============================================================================
-- fn_StringToDateTime — lecture de la date écrite sur un reçu
-- -----------------------------------------------------------------------------
-- La fonction se contentait de TRY_CONVERT(DATETIME, @DateString), donc de
-- l'interprétation par défaut du serveur (us_english = mm/jj/aaaa). Une date de
-- reçu québécois comme « 26/06/2026 10:27 » ne passait pas : le mois 26 n'existe
-- pas, la fonction rendait NULL, et le document sortait sans date.
--
-- Ordre d'essai, du moins ambigu au plus ambigu :
--   1. ISO (aaaa-MM-jj), qui ne peut pas être lu autrement ;
--   2. jj/mm/aaaa (style 103), la forme imprimée sur les reçus d'ici ;
--   3. mm/jj/aaaa (style 101), pour les reçus de chaînes américaines ;
--   4. l'interprétation par défaut du serveur, en dernier recours.
--
-- ATTENTION — changement de comportement voulu : une date ambiguë comme
-- « 03/04/2026 » était lue 4 mars (américain) et sera désormais lue 3 avril
-- (québécois). C'est la bonne lecture pour les reçus traités ici ; la fonction
-- n'est utilisée que par s0009SaveDocument et s0034SaveCustomerDocument, donc
-- uniquement sur des dates extraites de reçus par l'IA.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_StringToDateTime
(
    @DateString NVARCHAR(50)
)
RETURNS DATETIME
AS
BEGIN
    IF @DateString IS NULL RETURN NULL;

    DECLARE @s NVARCHAR(50) = LTRIM(RTRIM(@DateString));
    IF @s = '' RETURN NULL;

    DECLARE @d DATETIME;

    -- 1) ISO : aaaa-MM-jj, éventuellement suivi de l'heure.
    IF @s LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]%'
    BEGIN
        SET @d = TRY_CONVERT(DATETIME, @s, 120);
        IF @d IS NULL SET @d = TRY_CONVERT(DATETIME, @s, 126);
        IF @d IS NOT NULL RETURN @d;
    END

    -- 2) jj/mm/aaaa (ou jj-mm-aaaa)
    SET @d = TRY_CONVERT(DATETIME, @s, 103);
    IF @d IS NOT NULL RETURN @d;

    -- 3) mm/jj/aaaa
    SET @d = TRY_CONVERT(DATETIME, @s, 101);
    IF @d IS NOT NULL RETURN @d;

    -- 4) Tout le reste (« 8 février 2026 », « 2026/02/08 »…)
    RETURN TRY_CONVERT(DATETIME, @s);
END
GO

PRINT N'fn_StringToDateTime.sql : termine.';
GO
