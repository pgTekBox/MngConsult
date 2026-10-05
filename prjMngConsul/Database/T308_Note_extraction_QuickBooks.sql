-- =============================================================================
-- T308 — La note de « QuickBooks, en direct » suit les extractions réussies
--
-- Sur l'écran des importations, la carte du connecteur portait une note fixe,
-- écrite dans le code. Elle doit dire ce qui s'est réellement passé : la part
-- des ressources rapatriées à la dernière extraction. Tout rapatrié : 10/10 ;
-- une ressource sur quatre en échec : 8/10 ; aucune extraction : 0/10.
--
-- Pour cela, l'extraction garde deux décomptes qu'elle ne gardait pas :
-- combien de ressources ont été demandées, combien n'ont pas répondu. Le
-- NbRessources existant compte celles qui ont déposé au moins un
-- enregistrement, ce qui n'est ni l'un ni l'autre — une ressource vide chez
-- la source a réussi sans rien déposer.
--
--   staging.ConnecteurRun   + NbDemandees, NbEchecs
--   s0778FermerConnecteurRun  reçoit les deux décomptes (facultatifs)
--   s0892GetDerniereExtraction  la dernière extraction de la compagnie
-- =============================================================================

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('staging.ConnecteurRun', 'NbDemandees') IS NULL
    ALTER TABLE staging.ConnecteurRun ADD [NbDemandees] INT NULL;
GO
IF COL_LENGTH('staging.ConnecteurRun', 'NbEchecs') IS NULL
    ALTER TABLE staging.ConnecteurRun ADD [NbEchecs] INT NULL;
GO

-- -----------------------------------------------------------------------------
-- s0778FermerConnecteurRun — ferme l'extraction, avec ses deux décomptes.
-- Les anciens appels sans décomptes restent valides : les colonnes restent NULL.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0778FermerConnecteurRun]
    @RunId       INT,
    @CompanyGUID UNIQUEIDENTIFIER,
    @Statut      VARCHAR(20),
    @Note        NVARCHAR(2000) = NULL,
    @NbDemandees INT = NULL,
    @NbEchecs    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE staging.ConnecteurRun
       SET [Statut]      = @Statut,
           [Fin]         = GETDATE(),
           [Note]        = @Note,
           [NbDemandees] = @NbDemandees,
           [NbEchecs]    = @NbEchecs
     WHERE [Id] = @RunId AND [CompanyGUID] = @CompanyGUID;
END
GO

-- -----------------------------------------------------------------------------
-- s0892GetDerniereExtraction — la dernière extraction fermée de la compagnie.
-- Une extraction encore EN_COURS n'est pas un résultat : on l'ignore, sinon
-- la note tomberait à zéro le temps qu'elle tourne.
-- Rien ne revient quand la compagnie n'a jamais extrait.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0892GetDerniereExtraction]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
           r.[Id], r.[Service], r.[Statut], r.[Debut], r.[Fin],
           r.[NbRessources], r.[NbEnregistrements],
           r.[NbDemandees], r.[NbEchecs], r.[Note]
      FROM staging.ConnecteurRun r
     WHERE r.[CompanyGUID] = @CompanyGUID
       AND r.[Statut] <> 'EN_COURS'
     ORDER BY r.[Debut] DESC;
END
GO
