/*
    Création d'un client (T050Party, Type=1) depuis l'app mobile 60SecAI.
    Renvoie Id + PartyGUID + DisplayName pour pouvoir le sélectionner aussitôt
    dans une nouvelle facture. À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0715InsertClient]
    @CompanyGUID  UNIQUEIDENTIFIER,
    @Name         VARCHAR(500),
    @DisplayName  VARCHAR(500) = NULL,
    @TPS          VARCHAR(20)  = NULL,
    @TVQ          VARCHAR(20)  = NULL,
    @Note         VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Account VARCHAR(20)  = [dbo].[fGetAccount](@CompanyGUID, 'AR');
    DECLARE @Display VARCHAR(500) = ISNULL(NULLIF(LTRIM(RTRIM(@DisplayName)), ''), @Name);

    DECLARE @out TABLE (Id INT, PartyGUID UNIQUEIDENTIFIER, DisplayName VARCHAR(500));

    INSERT INTO [dbo].[T050Party]
        ( CompanyGUID, CompteAuxClient, Name, DisplayName, TPS, TVQ, Note, Type, Origin, isDeleted )
    OUTPUT inserted.[Id], inserted.[PartyGUID], inserted.[DisplayName] INTO @out (Id, PartyGUID, DisplayName)
    VALUES
        ( @CompanyGUID, @Account, @Name, @Display, @TPS, @TVQ, @Note, 1, 1, 0 );

    SELECT Id, PartyGUID, DisplayName FROM @out;
END
GO
