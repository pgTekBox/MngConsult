-- =====================================================================
-- T400 — Importation 2 : données déjà en préparation
--
-- Une extraction par connecteur (Apideck) laisse ses enregistrements dans
-- staging.ConnecteurDonnee jusqu'à ce que la préparation soit vidée.
-- Importation2.aspx les signale aux étapes 1 et 2 et permet de continuer
-- avec elles, sans relier la source une nouvelle fois.
--
--   s1024GetPreparationConnecteur — ce qui attend en préparation pour une compagnie
-- =====================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1024GetPreparationConnecteur]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Une ligne, même vide : NbEnregistrements = 0 veut dire « rien en préparation ».
    SELECT COUNT(*)                    AS [NbEnregistrements],
           COUNT(DISTINCT d.[Ressource]) AS [NbRessources],
           MAX(d.[Created])            AS [Derniere],
           -- Le logiciel de la plus récente extraction encore présente.
           (SELECT TOP 1 r.[Service]
              FROM staging.ConnecteurRun r
             WHERE r.[CompanyGUID] = @CompanyGUID
               AND EXISTS (SELECT 1 FROM staging.ConnecteurDonnee x WHERE x.[RunId] = r.[Id])
             ORDER BY r.[Id] DESC)     AS [Service]
      FROM staging.ConnecteurDonnee d
     WHERE d.[CompanyGUID] = @CompanyGUID;
END
GO
