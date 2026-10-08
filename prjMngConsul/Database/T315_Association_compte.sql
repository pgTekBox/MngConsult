-- =============================================================================
-- T315 — Associer un compte, un par un : « Demander à mon cabinet certifié »
--
-- Le nouvel écran AssocierCompte.aspx présente les comptes « à décider » un à
-- la fois. « Demander à mon cabinet certifié » n'est pas une décision : la
-- ligne reste à décider et la question part par courriel aux utilisateurs
-- comptables de la compagnie (T015User.isAccountant), au nom de la compagnie.
--
-- s0897GetComptablesCompagnie rend ces destinataires : les utilisateurs actifs
-- de la compagnie marqués comptables, avec un courriel.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0897GetComptablesCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.[Id], u.[Email], u.[FirstName], u.[LastName]
      FROM dbo.T015User u
     WHERE u.[CompanyGUID] = @CompanyGUID
       AND ISNULL(u.[isAccountant], 0) = 1
       AND ISNULL(u.[IsActive], 1) = 1
       AND ISNULL(u.[IsDeleted], 0) = 0
       AND NULLIF(LTRIM(RTRIM(u.[Email])), '') IS NOT NULL
     ORDER BY u.[LastName], u.[FirstName];
END
GO
