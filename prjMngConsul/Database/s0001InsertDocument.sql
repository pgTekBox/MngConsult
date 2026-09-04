-- =============================================================================
-- Dépôt d'un reçu : la compagnie est celle de l'utilisateur qui le dépose
-- -----------------------------------------------------------------------------
-- Les deux procédures d'insertion dans T0001Receipt écrivaient
-- CompanyGUID = '87893D29-6D64-40C8-8E45-A3492B4FBB91' EN DUR. Tout reçu
-- atterrissait donc dans cette compagnie, quel que soit l'utilisateur qui le
-- déposait. Conséquences constatées :
--   - les reçus n'apparaissent pas dans la compagnie de celui qui les envoie ;
--   - le paramètre « Reçu comptabilisé automatiquement » est lu sur une
--     compagnie que personne ne paramètre ;
--   - la comptabilisation échoue, cette compagnie n'ayant aucun plan comptable.
--
-- La compagnie est maintenant résolue, et l'insertion est REFUSÉE si elle ne
-- peut pas l'être : classer un reçu dans une compagnie arbitraire est
-- exactement le défaut qu'on corrige, mieux vaut une erreur lisible.
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- s0001InsertDocument — dépôt par l'API (WebApi/UploadController)
--
-- Ordre de résolution :
--   1. @UserId, rapproché de T015User.UserGUID : c'est la source la plus sûre,
--      elle désigne la personne qui dépose ;
--   2. @AccountId, s'il désigne bien une compagnie existante ;
--   3. sinon, erreur.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0001InsertDocument]
    @AccountId         UNIQUEIDENTIFIER,
    @UserId            UNIQUEIDENTIFIER,
    @SourceFileName    VARCHAR(300),
    @SourceContentType VARCHAR(300),
    @SourceSizeBytes   INT,
    @SourceSha256      VARBINARY(MAX),
    @SourceBlob        VARBINARY(MAX),
    @ProcessingStatus  INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyGUID UNIQUEIDENTIFIER;

    IF @UserId IS NOT NULL
        SELECT TOP 1 @CompanyGUID = u.[CompanyGUID]
          FROM [dbo].[T015User] u
         WHERE u.[UserGUID] = @UserId;

    IF @CompanyGUID IS NULL AND @AccountId IS NOT NULL
       AND EXISTS (SELECT 1 FROM [dbo].[T010Company] WHERE [CompanyGUID] = @AccountId)
        SET @CompanyGUID = @AccountId;

    IF @CompanyGUID IS NULL
        THROW 50101, 'Compagnie introuvable pour ce reçu : @UserId ne correspond à aucun T015User.UserGUID et @AccountId ne désigne aucune compagnie.', 1;

    DECLARE @out TABLE (ImageGUID UNIQUEIDENTIFIER, Id INT);

    INSERT INTO [dbo].[T0001Receipt]
        ( CompanyGUID, [ImageSource], [ContentType], [FileName], SourceSizeBytes, ProcessingStatus, ReceiptTypeId, Source )
    OUTPUT inserted.[imageGUID], inserted.[Id] INTO @out (ImageGUID, Id)
    VALUES
        ( @CompanyGUID, @SourceBlob, @SourceContentType, @SourceFileName, @SourceSizeBytes, 1, 2, 1 );

    SELECT ImageGUID, Id FROM @out;
END
GO

-- -----------------------------------------------------------------------------
-- s0027InsertDocumentClient — dépôt d'une facture client scannée (wbfScannedPDF)
--
-- La page connaît la compagnie de la session : elle la transmet désormais.
-- Le paramètre est optionnel dans la signature pour ne pas casser un appelant
-- oublié, mais son absence lève une erreur : c'est le même raisonnement que
-- ci-dessus.
--
-- Le « select newid() » de fin est conservé tel quel (l'appelant ignore la
-- valeur retournée), mais il ne renvoie PAS l'imageGUID de la ligne insérée :
-- à ne pas utiliser tant qu'il n'est pas corrigé.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0027InsertDocumentClient]
    @SourceFileName    VARCHAR(300),
    @SourceContentType VARCHAR(300),
    @SourceSizeBytes   INT,
    @SourceBlob        VARBINARY(MAX),
    @CompanyGUID       UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CompanyGUID IS NULL
       OR NOT EXISTS (SELECT 1 FROM [dbo].[T010Company] WHERE [CompanyGUID] = @CompanyGUID)
        THROW 50102, 'Compagnie introuvable pour ce document : @CompanyGUID est vide ou ne désigne aucune compagnie.', 1;

    INSERT INTO [dbo].[T0001Receipt]
        ( CompanyGUID, [ImageSource], [ContentType], [FileName], SourceSizeBytes, ProcessingStatus, [ReceiptTypeId] )
    VALUES
        ( @CompanyGUID, @SourceBlob, @SourceContentType, @SourceFileName, @SourceSizeBytes, 1, 1 );

    SELECT NEWID() ImageGUID;
END
GO

PRINT N's0001InsertDocument.sql : termine.';
GO
