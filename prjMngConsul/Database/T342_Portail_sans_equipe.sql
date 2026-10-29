-- =============================================================================
-- T342_Portail_sans_equipe.sql — Portail comptable
-- Retrait de la notion d'ÉQUIPE : on démote les responsables en employés, on
-- détache tout lien d'équipe (membres et dossiers) et on désactive les équipes.
-- Les branches « équipe » des procs (fCabinetDossiers, s0920) deviennent alors
-- inertes (plus aucun responsable, plus aucun EquipeId) ; l'UI d'équipe est
-- retirée côté application. Les tables T333Equipe / colonnes EquipeId restent en
-- place (dormantes) pour ne pas risquer de DROP.
-- =============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Plus de rôle « responsable » (il n'existait que pour diriger une équipe).
UPDATE dbo.T332CabinetMembre SET Role = 'employe' WHERE Role = 'responsable';

-- Détacher les membres et les dossiers de toute équipe.
UPDATE dbo.T332CabinetMembre SET EquipeId = NULL WHERE EquipeId IS NOT NULL;
UPDATE dbo.T334CabinetDossier SET EquipeId = NULL WHERE EquipeId IS NOT NULL;

-- Désactiver toutes les équipes.
UPDATE dbo.T333Equipe SET IsActive = 0 WHERE IsActive = 1;
GO
