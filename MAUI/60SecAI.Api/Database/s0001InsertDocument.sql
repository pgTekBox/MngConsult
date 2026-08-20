/*
    Insère un reçu scanné (photo) dans dbo.T0001Receipt et renvoie le VRAI identifiant de la ligne.

    Correction : l'ancienne version faisait « select newid() », un GUID aléatoire sans aucun
    lien avec la ligne insérée. On renvoie désormais, via OUTPUT, l'imageGUID réel de la ligne
    (colonne imageGUID, défaut newid()) ET son Id identité.

    Colonne 0 = imageGUID (uniqueidentifier) — conserve le contrat existant côté serveur
    (ReceiptRepository lit Rows[0][0] comme un Guid).
    Colonne 1 = Id (int) — la vraie clé primaire, pour relire le reçu plus tard.

    ReceiptTypeId = 1 = client, 2 = fournisseur (les scans sont typés fournisseur).
    À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0001InsertDocument]
    @AccountId        UNIQUEIDENTIFIER,
    @UserId           UNIQUEIDENTIFIER,
    @SourceFileName   VARCHAR(300),
    @SourceContentType VARCHAR(300),
    @SourceSizeBytes  INT,
    @SourceSha256     VARBINARY(MAX),
    @SourceBlob       VARBINARY(MAX),
    @ProcessingStatus INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @out TABLE (ImageGUID UNIQUEIDENTIFIER, Id INT);

    INSERT INTO [dbo].[T0001Receipt]
        ( CompanyGUID, [ImageSource], [ContentType], [FileName], SourceSizeBytes, ProcessingStatus, ReceiptTypeId, Source )
    OUTPUT inserted.[imageGUID], inserted.[Id] INTO @out (ImageGUID, Id)
    VALUES
        ( '87893D29-6D64-40C8-8E45-A3492B4FBB91', @SourceBlob, @SourceContentType, @SourceFileName, @SourceSizeBytes, 1, 2, 1 );

    SELECT ImageGUID, Id FROM @out;
END
GO
