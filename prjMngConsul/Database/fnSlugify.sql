-- Transforme un nom en "slug" pour adresse courriel : minuscules, accents retires,
-- seuls [a-z0-9] gardes, le reste -> '-', pas de tiret en tete/fin (max 40 car.).
USE [MngConsul];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER FUNCTION dbo.fnSlugify(@s NVARCHAR(200))
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @t NVARCHAR(200) = LOWER(LTRIM(RTRIM(ISNULL(@s, N''))));
    -- accents francais/latins -> ASCII
    SET @t = TRANSLATE(@t,
        N'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ',
        N'aaaaaaceeeeiiiinooooouuuuyy');
    DECLARE @out VARCHAR(100) = '', @i INT = 1, @c NCHAR(1), @prevDash BIT = 1;
    WHILE @i <= LEN(@t) AND LEN(@out) < 40
    BEGIN
        SET @c = SUBSTRING(@t, @i, 1);
        IF @c LIKE '[a-z0-9]'
        BEGIN
            SET @out = @out + CAST(@c AS VARCHAR(1));
            SET @prevDash = 0;
        END
        ELSE IF @prevDash = 0
        BEGIN
            SET @out = @out + '-';
            SET @prevDash = 1;
        END
        SET @i = @i + 1;
    END
    WHILE LEN(@out) > 0 AND RIGHT(@out, 1) = '-' SET @out = LEFT(@out, LEN(@out) - 1);
    IF @out = '' SET @out = 'abonne';
    RETURN @out;
END
GO
