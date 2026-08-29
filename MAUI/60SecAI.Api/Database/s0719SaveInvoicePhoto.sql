/*
    Photos liées à une facture (T060Document) — plusieurs par facture.
    Crée la table dbo.T063DocumentPhoto + les procédures d'enregistrement et de
    liste. À exécuter sur la base MngConsul.
*/
USE MngConsul;
GO

IF OBJECT_ID('dbo.T063DocumentPhoto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.T063DocumentPhoto
    (
        Id           INT IDENTITY(1,1)  NOT NULL CONSTRAINT PK_T063DocumentPhoto PRIMARY KEY,
        DocumentId   INT                NOT NULL,
        CompanyGUID  UNIQUEIDENTIFIER   NULL,
        PhotoGUID    UNIQUEIDENTIFIER   NOT NULL CONSTRAINT DF_T063DocumentPhoto_PhotoGUID DEFAULT NEWID(),
        FileName     VARCHAR(300)       NULL,
        ContentType  VARCHAR(300)       NULL,
        SizeBytes    INT                NULL,
        ImageSource  VARBINARY(MAX)     NULL,
        Created      DATETIME           NOT NULL CONSTRAINT DF_T063DocumentPhoto_Created DEFAULT GETDATE()
    );
    CREATE INDEX IX_T063DocumentPhoto_DocumentId ON dbo.T063DocumentPhoto(DocumentId);
END
GO

/* CapturedAt = vraie date de prise (EXIF), extraite à l'upload. NULL si absente. */
IF COL_LENGTH('dbo.T063DocumentPhoto', 'CapturedAt') IS NULL
BEGIN
    ALTER TABLE dbo.T063DocumentPhoto ADD CapturedAt DATETIME NULL;
END
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* Enregistre une photo pour une facture. Renvoie Id + PhotoGUID. */
CREATE OR ALTER PROCEDURE [dbo].[s0719SaveInvoicePhoto]
    @DocumentId   INT,
    @CompanyGUID  UNIQUEIDENTIFIER,
    @FileName     VARCHAR(300),
    @ContentType  VARCHAR(300),
    @SizeBytes    INT,
    @ImageSource  VARBINARY(MAX),
    @CapturedAt   DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @out TABLE (Id INT, PhotoGUID UNIQUEIDENTIFIER);

    INSERT INTO dbo.T063DocumentPhoto (DocumentId, CompanyGUID, FileName, ContentType, SizeBytes, ImageSource, CapturedAt)
    OUTPUT inserted.Id, inserted.PhotoGUID INTO @out (Id, PhotoGUID)
    VALUES (@DocumentId, @CompanyGUID, @FileName, @ContentType, @SizeBytes, @ImageSource, @CapturedAt);

    SELECT Id, PhotoGUID FROM @out;
END
GO

/* Liste des photos (métadonnées, sans le blob) d'une facture. */
CREATE OR ALTER PROCEDURE [dbo].[s0720GetInvoicePhotos]
    @DocumentId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Created renvoyé = date de prise EXIF si connue, sinon l'horodatage d'upload.
    SELECT Id, PhotoGUID, FileName, ContentType, SizeBytes,
           COALESCE(CapturedAt, Created) AS Created
    FROM dbo.T063DocumentPhoto
    WHERE DocumentId = @DocumentId
    ORDER BY COALESCE(CapturedAt, Created), Id;
END
GO

/* Contenu binaire d'une photo précise d'une facture. */
CREATE OR ALTER PROCEDURE [dbo].[s0721GetInvoicePhotoContent]
    @DocumentId INT,
    @PhotoId    INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 ContentType, ImageSource
    FROM dbo.T063DocumentPhoto
    WHERE DocumentId = @DocumentId AND Id = @PhotoId;
END
GO
