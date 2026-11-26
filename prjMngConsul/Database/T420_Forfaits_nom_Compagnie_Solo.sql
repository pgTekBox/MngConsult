-- =============================================================================
-- T420 : « Compagnie Solo » → « Société sans employé » dans les textes des forfaits
-- Ancien nom (français) du forfait CIE 0, resté dans la 1re fonction de CIE 1-50
-- (« Tout du plan Compagnie Solo ») et dans les cartes mises en forme
-- (DescriptionLong, non affichées aujourd'hui) de CIE 0 et CIE 1-50.
-- L'anglais (Solo Corporation) et l'espagnol (Empresa Individual) sont déjà justes.
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

UPDATE dbo.T021Plan
   SET Features        = REPLACE(Features, N'Compagnie Solo', N'Société sans employé'),
       DescriptionLong = REPLACE(CAST(DescriptionLong AS NVARCHAR(MAX)), N'Compagnie Solo', N'Soci&eacute;t&eacute; sans employ&eacute;'),
       ModifiedOn      = GETDATE(),
       ModifiedBy      = N'T420'
 WHERE IsDeleted = 0
   AND (Features LIKE N'%Compagnie Solo%' OR CAST(DescriptionLong AS NVARCHAR(MAX)) LIKE N'%Compagnie Solo%');
GO
