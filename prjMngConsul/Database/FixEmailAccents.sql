-- =============================================================================
-- FixEmailAccents
-- Retire les accents de la colonne Email de T054PartyAddress (les courriels
-- ne doivent pas contenir d'accents). N'agit QUE sur les lignes dont l'email
-- contient au moins un caractere non-ASCII imprimable.
--
-- A lancer avec : sqlcmd ... -I -f 65001   (UTF-8, pour les accents)
-- =============================================================================

USE [MngConsul];
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;

-- NB : collation BINAIRE obligatoire pour detecter les non-ASCII par octet.
-- Sans elle, le pattern [^ -~] est evalue selon l'ordre de tri de la collation
-- par defaut et matche aussi des courriels propres (faux positifs).
DECLARE @before INT, @after INT;
SELECT @before = COUNT(*) FROM dbo.T054PartyAddress
WHERE Email COLLATE Latin1_General_BIN LIKE '%[^ -~]%';

UPDATE dbo.T054PartyAddress
SET Email =
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        Email,
        N'à',N'a'),N'â',N'a'),N'ä',N'a'),N'á',N'a'),
        N'è',N'e'),N'é',N'e'),N'ê',N'e'),N'ë',N'e'),
        N'ì',N'i'),N'î',N'i'),N'ï',N'i'),N'í',N'i'),
        N'ò',N'o'),N'ô',N'o'),N'ö',N'o'),N'ó',N'o'),
        N'ù',N'u'),N'û',N'u'),N'ü',N'u'),N'ú',N'u'),
        N'ç',N'c'),N'ÿ',N'y'),N'ñ',N'n'),
        N'À',N'A'),N'Â',N'A'),N'É',N'E'),N'È',N'E'),
        N'Ê',N'E'),N'Ô',N'O'),N'Ç',N'C'),N'Î',N'I')
WHERE Email COLLATE Latin1_General_BIN LIKE '%[^ -~]%';

SET @after = @@ROWCOUNT;
PRINT CAST(@after AS VARCHAR(10)) + ' courriel(s) normalise(s) (sur ' + CAST(@before AS VARCHAR(10)) + ' detecte(s) avec accents).';
GO
