-- ============================================================================
-- Procédures : s0727GetInvoicePhotos / s0728GetInvoicePhotoContent
-- Description :
--   Lecture des photos de facture (T063DocumentPhoto) depuis l'ERP web.
--
--   Les procédures existantes s0720GetInvoicePhotos / s0721GetInvoicePhotoContent
--   servent l'API mobile (60SecAI.Api), qui a déjà validé le locataire dans son
--   jeton : elles prennent un DocumentId nu, sans filtre de compagnie.
--   Le web, lui, expose un handler HTTP (InvoicePhoto.ashx) où le DocumentId et
--   le PhotoId viennent de la query string : sans filtre, un utilisateur connecté
--   pourrait lire les photos d'une autre compagnie en devinant un identifiant.
--   D'où ces deux variantes scopées par @CompanyGUID.
--
--   Le filtre s'appuie sur T060Document.CompanyGUID (la facture parente fait
--   autorité) et non sur T063DocumentPhoto.CompanyGUID, qui est nullable.
-- ============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Deux jeux de résultats :
--   0) l'en-tête du document (numéro + géolocalisation), pour le titre et le lien
--      carte de la visionneuse — évite une seconde requête juste pour ça ;
--   1) la liste des photos (métadonnées, sans le blob).
-- Created = date de prise EXIF si connue, sinon l'horodatage d'upload.
-- Les deux jeux sont vides si la facture n'appartient pas à @CompanyGUID.
CREATE OR ALTER PROCEDURE [dbo].[s0727GetInvoicePhotos]
    @CompanyGUID UNIQUEIDENTIFIER,
    @DocumentId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT d.[DocumentNumber],
           d.[Latitude],
           d.[Longitude],
           d.[GeoCapturedAt]
      FROM dbo.T060Document d
     WHERE d.[Id] = @DocumentId
       AND d.[CompanyGUID] = @CompanyGUID;

    SELECT ph.[Id],
           ph.[PhotoGUID],
           ph.[FileName],
           ph.[ContentType],
           ph.[SizeBytes],
           COALESCE(ph.[CapturedAt], ph.[Created]) AS [Created]
      FROM dbo.T063DocumentPhoto ph
      JOIN dbo.T060Document d ON d.[Id] = ph.[DocumentId]
     WHERE ph.[DocumentId] = @DocumentId
       AND d.[CompanyGUID] = @CompanyGUID
     ORDER BY COALESCE(ph.[CapturedAt], ph.[Created]), ph.[Id];
END
GO

-- Contenu binaire d'une photo précise, scopé à la compagnie.
-- Ne renvoie aucune ligne si la facture n'appartient pas à @CompanyGUID :
-- l'appelant doit répondre 404 dans ce cas.
CREATE OR ALTER PROCEDURE [dbo].[s0728GetInvoicePhotoContent]
    @CompanyGUID UNIQUEIDENTIFIER,
    @DocumentId  INT,
    @PhotoId     INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 ph.[ContentType],
                 ph.[ImageSource],
                 ph.[FileName]
      FROM dbo.T063DocumentPhoto ph
      JOIN dbo.T060Document d ON d.[Id] = ph.[DocumentId]
     WHERE ph.[DocumentId] = @DocumentId
       AND ph.[Id] = @PhotoId
       AND d.[CompanyGUID] = @CompanyGUID;
END
GO
