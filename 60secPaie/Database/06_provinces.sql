-- =============================================================================
-- 06 — Paie des autres provinces et territoires du Canada
--
-- Après le Québec (01) et l'Ontario (05) : Alberta, Colombie-Britannique, Île-du-Prince-Édouard,
-- Manitoba, Nouveau-Brunswick, Nouvelle-Écosse, Nunavut, Saskatchewan, Terre-Neuve-et-Labrador,
-- Territoires du Nord-Ouest et Yukon.
--
-- Rien ne change dans les tables de paie : comme pour l'Ontario, les colonnes gardent leur nom
-- québécois et leur contenu suit la province de la paie (paie.Paie.Province) :
--
--     ImpotQuebec                   impôt de la province ou du territoire
--     RRQ, RRQ2, GainsRRQ           RPC
--     EmployeurFSS, GainsFSS        cotisation santé de l'employeur, là où il y en a une (C.-B., Manitoba, T.-N.-L.)
--     EmployeurCNESST, GainsCNESST  commission des accidents du travail de la province
--     RQAP, GainsRQAP               Territoires du Nord-Ouest et Nunavut : impôt de 2 % sur la paie retenu à
--                                   l'employé et remis au territoire ; 0 partout ailleurs hors Québec
--     EmployeurRQAP, EmployeurCNT   toujours 0
--
-- Les taux de ces provinces vivent dans une table à part, paie.ParametresProvince : une ligne par
-- province et par DATE D'ENTRÉE EN VIGUEUR, parce qu'une province peut changer ses taux en cours
-- d'année (au 1er juillet 2026 : Colombie-Britannique, Terre-Neuve-et-Labrador, Île-du-Prince-Édouard).
-- Une paie prend la ligne la plus récente en vigueur à sa date. L'Ontario reste dans paie.ParametresAnnee.
-- L'état (brouillon ou validée) est celui de l'année, dans paie.ParametresAnnee.
--
-- Rejouable sans danger : chaque étape vérifie avant d'agir.
-- =============================================================================
SET NOCOUNT ON;
GO

-- ── La province d'une paie peut être n'importe laquelle des treize ───────────
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Paie_Province' AND parent_object_id = OBJECT_ID(N'paie.Paie')
           AND [definition] NOT LIKE N'%YT%')
    ALTER TABLE paie.Paie DROP CONSTRAINT CK_Paie_Province;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Paie_Province' AND parent_object_id = OBJECT_ID(N'paie.Paie'))
    ALTER TABLE paie.Paie ADD CONSTRAINT CK_Paie_Province
        CHECK (Province IN (N'QC', N'ON', N'AB', N'BC', N'MB', N'NB', N'NL', N'NS', N'NT', N'NU', N'PE', N'SK', N'YT'));
GO

-- ── Taux des provinces ────────────────────────────────────────────────────────
IF OBJECT_ID(N'paie.ParametresProvince') IS NULL
CREATE TABLE paie.ParametresProvince (
    Annee                 int            NOT NULL,
    Province              nchar(2)       NOT NULL,
    EnVigueurLe           date           NOT NULL,
    -- « seuil|taux|constante;… » : revenu imposable annuel jusqu'où la tranche s'applique (« * » = sans plafond),
    -- taux V et constante KP du tableau 8.1 du guide T4127.
    Tranches              nvarchar(600)  NOT NULL,
    MontantPersonnelBase  decimal(12,2)  NOT NULL,
    TauxCredits           decimal(8,5)   NOT NULL,   -- taux des crédits K1P et K2P (celui de la première tranche)
    -- « clé=valeur;… » : ce qui n'existe que dans certaines provinces (voir ParametresProvince.vb).
    Particularites        nvarchar(1000) NULL,
    AccidentsMaxAssurable decimal(12,2)  NULL,       -- plafond annuel de la commission des accidents du travail
    ModifieLe             datetime2(0)   NULL,
    ModifiePar            nvarchar(256)  NULL,
    CONSTRAINT PK_ParametresProvince PRIMARY KEY (Annee, Province, EnVigueurLe),
    CONSTRAINT FK_ParametresProvince_Annee FOREIGN KEY (Annee) REFERENCES paie.ParametresAnnee (Annee) ON DELETE CASCADE,
    CONSTRAINT CK_ParametresProvince_Province CHECK (Province IN (N'AB', N'BC', N'MB', N'NB', N'NL', N'NS', N'NT', N'NU', N'PE', N'SK', N'YT')),
    CONSTRAINT CK_ParametresProvince_Date CHECK (YEAR(EnVigueurLe) = Annee)
);
GO

-- ── 2026 : T4127, 122e édition (1er janvier) et 123e édition (1er juillet) ────
-- Plafonds des accidents du travail : À VALIDER auprès de chaque commission.
-- Seules les provinces absentes sont ajoutées : une valeur corrigée dans Sec60Admin n'est jamais écrasée.
IF EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = 2026)
    INSERT INTO paie.ParametresProvince (Annee, Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable)
    SELECT 2026, v.Province, v.EnVigueurLe, v.Tranches, v.MontantPersonnelBase, v.TauxCredits, v.Particularites, v.AccidentsMaxAssurable
      FROM (VALUES
    (N'AB', '2026-01-01', N'61200|0.08|0;154259|0.1|1224;185111|0.12|4309;246813|0.13|6160;370220|0.14|8628;*|0.15|12331', 22769, 0.08, N'creditSupplSeuil=4896;creditSupplTaux=0.25', 110900),
    (N'BC', '2026-01-01', N'50363|0.0506|0;100728|0.077|1330;115648|0.105|4150;140430|0.1229|6220;190405|0.147|9604;265545|0.168|13603;*|0.205|23428', 13216, 0.0506, N'reductionMontant=575;reductionSeuil=25570;reductionTaux=0.0356;reductionFin=41722', 127500),
    (N'BC', '2026-07-01', N'50363|0.0614|0;100728|0.077|786;115648|0.105|3606;140430|0.1229|5676;190405|0.147|9061;265545|0.168|13059;*|0.205|22884', 13216, 0.0614, N'reductionMontant=805;reductionSeuil=25570;reductionTaux=0.0356;reductionFin=44952', 127500),
    (N'MB', '2026-01-01', N'47000|0.108|0;100000|0.1275|917;*|0.174|5567', 15780, 0.108, N'baseReduiteDe=200000;baseNulleA=400000', 171500),
    (N'NB', '2026-01-01', N'52333|0.094|0;104666|0.14|2407;193861|0.16|4501;*|0.195|11286', 13664, 0.094, NULL, 85800),
    (N'NL', '2026-01-01', N'44678|0.087|0;89354|0.145|2591;159528|0.158|3753;223340|0.178|6943;285319|0.198|11410;570638|0.208|14263;1141275|0.213|17117;*|0.218|22823', 11188, 0.087, NULL, 80935),
    (N'NL', '2026-07-01', N'44678|0.087|0;89354|0.145|2591;159528|0.158|3753;223340|0.178|6943;285319|0.198|11410;570638|0.208|14263;1141275|0.213|17117;*|0.218|22823', 15000, 0.087, NULL, 80935),
    (N'NS', '2026-01-01', N'30995|0.0879|0;61991|0.1495|1909;97417|0.1667|2976;157124|0.175|3784;*|0.21|9283', 11932, 0.0879, NULL, 79900),
    (N'NT', '2026-01-01', N'53003|0.059|0;106009|0.086|1431;172346|0.122|5247;*|0.1405|8436', 18198, 0.059, N'taxePaie=0.02', 116000),
    (N'NU', '2026-01-01', N'55801|0.04|0;111602|0.07|1674;181439|0.09|3906;*|0.115|8442', 19659, 0.04, N'taxePaie=0.02', 117300),
    (N'PE', '2026-01-01', N'33928|0.095|0;65820|0.1347|1347;106890|0.166|3407;142520|0.1762|4497;*|0.19|6464', 15000, 0.095, NULL, 89300),
    (N'PE', '2026-07-01', N'33928|0.095|0;65820|0.1347|1347;106890|0.166|3407;142520|0.1762|4497;200000|0.19|6464;*|0.21|10464', 15000, 0.095, NULL, 89300),
    (N'SK', '2026-01-01', N'54532|0.105|0;155805|0.125|1091;*|0.145|4207', 20381, 0.105, NULL, 108223),
    (N'YT', '2026-01-01', N'58523|0.064|0;117045|0.09|1522;181440|0.109|3745;500000|0.128|7193;*|0.15|18193', 16452, 0.064, N'creditEmploi=1', 107599)
      ) AS v (Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable)
     WHERE NOT EXISTS (SELECT 1 FROM paie.ParametresProvince p WHERE p.Annee = 2026 AND p.Province = v.Province);
GO

-- ── Une nouvelle année reprend les provinces de la précédente ────────────────
-- paie.spParametresAnnee_Copier crée l'année en brouillon ; ce déclencheur lui donne les provinces de
-- l'année la plus récente qui en a, chacune avec ses dernières valeurs, en vigueur au 1er janvier.
CREATE OR ALTER TRIGGER paie.trParametresAnnee_Provinces ON paie.ParametresAnnee
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO paie.ParametresProvince (Annee, Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable)
    SELECT i.Annee, s.Province, DATEFROMPARTS(i.Annee, 1, 1), s.Tranches, s.MontantPersonnelBase, s.TauxCredits, s.Particularites, s.AccidentsMaxAssurable
      FROM inserted i
      CROSS APPLY (SELECT MAX(p.Annee) AS Annee FROM paie.ParametresProvince p WHERE p.Annee < i.Annee) AS src
      JOIN paie.ParametresProvince s ON s.Annee = src.Annee
     WHERE s.EnVigueurLe = (SELECT MAX(x.EnVigueurLe) FROM paie.ParametresProvince x WHERE x.Annee = s.Annee AND x.Province = s.Province)
       AND NOT EXISTS (SELECT 1 FROM paie.ParametresProvince d WHERE d.Annee = i.Annee);
END
GO

-- Les brouillons des années suivantes créés avant ce script n'ont pas de provinces : même reprise.
INSERT INTO paie.ParametresProvince (Annee, Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable)
SELECT a.Annee, s.Province, DATEFROMPARTS(a.Annee, 1, 1), s.Tranches, s.MontantPersonnelBase, s.TauxCredits, s.Particularites, s.AccidentsMaxAssurable
  FROM paie.ParametresAnnee a
  JOIN paie.ParametresProvince s ON s.Annee = 2026
 WHERE a.Statut = 'B' AND a.Annee > 2026
   AND s.EnVigueurLe = (SELECT MAX(x.EnVigueurLe) FROM paie.ParametresProvince x WHERE x.Annee = 2026 AND x.Province = s.Province)
   AND NOT EXISTS (SELECT 1 FROM paie.ParametresProvince d WHERE d.Annee = a.Annee);
GO

-- ── Procédures de la console Sec60Admin ───────────────────────────────────────
CREATE OR ALTER PROCEDURE paie.spParametresProvince_Liste
    @Annee int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Annee, Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable, ModifieLe, ModifiePar
      FROM paie.ParametresProvince
     WHERE Annee = @Annee
     ORDER BY Province, EnVigueurLe;
END
GO

-- Ajoute ou remplace les valeurs d'une province à une date d'entrée en vigueur.
CREATE OR ALTER PROCEDURE paie.spParametresProvince_Save
    @Annee int, @Province nchar(2), @EnVigueurLe date,
    @Tranches nvarchar(600), @MontantPersonnelBase decimal(12,2), @TauxCredits decimal(8,5),
    @Particularites nvarchar(1000) = NULL, @AccidentsMaxAssurable decimal(12,2) = NULL,
    @Par nvarchar(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM paie.ParametresAnnee WHERE Annee = @Annee)
        THROW 51010, 'Cette année n''existe pas.', 1;
    IF YEAR(@EnVigueurLe) <> @Annee
        THROW 51011, 'La date d''entrée en vigueur doit être dans l''année.', 1;

    UPDATE paie.ParametresProvince
       SET Tranches = @Tranches, MontantPersonnelBase = @MontantPersonnelBase, TauxCredits = @TauxCredits,
           Particularites = NULLIF(LTRIM(RTRIM(@Particularites)), N''), AccidentsMaxAssurable = @AccidentsMaxAssurable,
           ModifieLe = SYSDATETIME(), ModifiePar = @Par
     WHERE Annee = @Annee AND Province = @Province AND EnVigueurLe = @EnVigueurLe;

    IF @@ROWCOUNT = 0
        INSERT INTO paie.ParametresProvince (Annee, Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits,
                                             Particularites, AccidentsMaxAssurable, ModifieLe, ModifiePar)
        VALUES (@Annee, @Province, @EnVigueurLe, @Tranches, @MontantPersonnelBase, @TauxCredits,
                NULLIF(LTRIM(RTRIM(@Particularites)), N''), @AccidentsMaxAssurable, SYSDATETIME(), @Par);
END
GO

CREATE OR ALTER PROCEDURE paie.spParametresProvince_Supprimer
    @Annee int, @Province nchar(2), @EnVigueurLe date
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM paie.ParametresProvince WHERE Annee = @Annee AND Province = @Province AND EnVigueurLe = @EnVigueurLe;
END
GO

-- ── La compagnie : taux saisi de la cotisation santé de l'employeur ───────────
-- Le FSS (Québec) et l'ISE de l'Ontario se calculent d'après la masse salariale. En Colombie-Britannique,
-- au Manitoba et à Terre-Neuve-et-Labrador, l'employeur inscrit lui-même son taux effectif, en pourcentage
-- de la rémunération : il dépend de sa masse salariale et de l'exemption de la province. Le montant calculé
-- va dans EmployeurFSS, comme le FSS et l'ISE. La colonne ne sert pas dans les autres provinces.
IF COL_LENGTH('paie.Compagnie', 'TauxSanteEmployeur') IS NULL
    ALTER TABLE paie.Compagnie ADD TauxSanteEmployeur decimal(7,4) NOT NULL CONSTRAINT DF_Compagnie_TauxSante DEFAULT (0);
GO

PRINT N'06_provinces.sql : terminé.';
GO
