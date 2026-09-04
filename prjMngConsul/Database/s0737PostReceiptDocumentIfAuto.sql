-- =============================================================================
-- Comptabilisation automatique des reçus
-- -----------------------------------------------------------------------------
-- Branche le paramètre RECEIPT_AUTO_POST (onglet « Traitement » des paramètres)
-- sur le service de traitement des reçus : une fois le document créé par
-- s0009SaveDocument / s0034SaveCustomerDocument, il est comptabilisé tout de
-- suite si la compagnie a demandé « Reçu comptabilisé automatiquement ».
--
-- Deux objets :
--   fParamI                       lecture d'un paramètre entier (iVal), pendant
--                                 de fParamS / fParamD qui n'existaient que pour
--                                 les chaînes et les dates
--   s0737PostReceiptDocumentIfAuto  décide, et comptabilise le cas échéant
-- =============================================================================
USE [MngConsul];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- fParamI — valeur entière d'un paramètre de compagnie.
--
-- Repli sur la compagnie modèle quand la compagnie n'a pas encore sa copie du
-- paramètre : le catalogue n'est cloné qu'à l'ouverture de la page Paramètres
-- (s0150GetParamsForCompany). Sans ce repli, un paramètre récemment ajouté
-- resterait invisible pour toute compagnie dont personne n'a ouvert la page.
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fParamI(@CompanyGUID UNIQUEIDENTIFIER, @ShortName VARCHAR(50))
RETURNS INT
AS
BEGIN
    DECLARE @v INT;

    SELECT @v = v.iVal
      FROM dbo.T101ParamValues v
     INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
     WHERE p.CompanyGUID = @CompanyGUID AND p.ShortName = @ShortName;

    IF @v IS NULL
        SELECT @v = v.iVal
          FROM dbo.T101ParamValues v
         INNER JOIN dbo.T100ParamComptable p ON p.Id = v.T100Id
         WHERE p.CompanyGUID = '00000000-0000-0000-0000-000000000001'
           AND p.ShortName = @ShortName;

    RETURN @v;
END
GO

-- -----------------------------------------------------------------------------
-- s0737PostReceiptDocumentIfAuto
--
-- Renvoie toujours une ligne décrivant ce qui a été fait, pour que le service
-- puisse la journaliser :
--   AutoPost      1 = la compagnie demande la comptabilisation automatique
--   DocumentId    le document créé pour ce reçu (NULL s'il n'y en a pas)
--   Comptabilise  1 = le document est comptabilisé au sortir de la procédure
--
-- sp_ComptabiliserDocument annule sa transaction et relance l'erreur quand elle
-- refuse (période fermée, compte manquant, total à zéro…). L'exception remonte
-- donc au service, qui la journalise sans perdre le document : celui-ci reste
-- en brouillon et peut être comptabilisé à la main.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[s0737PostReceiptDocumentIfAuto]
    @imageGUID UNIQUEIDENTIFIER,
    @UserId    INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyGUID    UNIQUEIDENTIFIER;
    DECLARE @DocumentId     INT;
    DECLARE @DocumentNumber VARCHAR(200);
    DECLARE @Statut         VARCHAR(50);
    DECLARE @Auto           INT;

    SELECT TOP 1 @CompanyGUID = [CompanyGUID]
      FROM dbo.T0001Receipt WHERE [imageGUID] = @imageGUID;

    SELECT TOP 1 @DocumentId = [Id], @DocumentNumber = [DocumentNumber], @Statut = [ComptabilisationStatus]
      FROM dbo.T060Document WHERE [imageGUID] = @imageGUID;

    SET @Auto = ISNULL(dbo.fParamI(@CompanyGUID, 'RECEIPT_AUTO_POST'), 0);

    IF @Auto = 1 AND @DocumentId IS NOT NULL AND ISNULL(@Statut, '') <> 'COMPTABILISE'
    BEGIN
        EXEC dbo.sp_ComptabiliserDocument @DocumentId = @DocumentId, @UserId = @UserId;

        SELECT @DocumentNumber = [DocumentNumber], @Statut = [ComptabilisationStatus]
          FROM dbo.T060Document WHERE [Id] = @DocumentId;
    END

    SELECT
        CAST(CASE WHEN @Auto = 1 THEN 1 ELSE 0 END AS BIT)                            AS AutoPost,
        @DocumentId                                                                   AS DocumentId,
        @DocumentNumber                                                               AS DocumentNumber,
        CAST(CASE WHEN ISNULL(@Statut, '') = 'COMPTABILISE' THEN 1 ELSE 0 END AS BIT)  AS Comptabilise;
END
GO

PRINT N's0737PostReceiptDocumentIfAuto.sql : termine.';
GO
