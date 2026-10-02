-- =============================================================================
-- T306 — Cloisonnement par compagnie : contrôle d'appartenance et procédures corrigées
--
-- Audit du 2026-10-02 : plusieurs écrans prenaient un identifiant venu du
-- navigateur (adresse, champ caché, argument AJAX) et lisaient ou modifiaient
-- l'enregistrement sans vérifier qu'il appartient à la compagnie de la session.
--
--   s0891AppartientCompagnie     — « cet enregistrement est-il à cette compagnie ? »
--                                  appelé par les pages avant toute lecture ou
--                                  écriture par identifiant (clsData.Appartient)
--   s0316DeleteParty             — ne supprime qu'un tiers de la compagnie
--   s0059GetComptesForDDL        — ne liste que les comptes de la compagnie
--   s0017UpdateParty             — ne modifie qu'un tiers de la compagnie
--   s0028GetDocScanned           — reçoit la compagnie et filtre dessus
--   s0601GetRecentImportFiles    — reçoit la compagnie et filtre dessus
--   s0211ValidateCompanyAccess   — un comptable n'accède qu'à sa compagnie et à
--                                  celles dont il est le comptable désigné
--                                  (la même règle que la liste s0210)
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0891AppartientCompagnie]
    @CompanyGUID UNIQUEIDENTIFIER,
    @Type        VARCHAR(20),               -- PARTY, ADRESSE, DOCUMENT, ECRITURE, TEMPLATE, PRODUIT, COMPTE, PARAM, IMPORT, RECU
    @Id          INT              = NULL,
    @Guid        UNIQUEIDENTIFIER = NULL    -- pour RECU (imageGUID)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Ok BIT = 0;

    -- Une compagnie absente ou vide ne possède rien.
    IF @CompanyGUID IS NOT NULL AND @CompanyGUID <> '00000000-0000-0000-0000-000000000000'
    BEGIN
        IF @Type = 'PARTY'    AND EXISTS (SELECT 1 FROM dbo.T050Party             WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'ADRESSE'  AND EXISTS (SELECT 1 FROM dbo.T054PartyAddress a
                                            JOIN dbo.T050Party p ON p.[Id] = a.[PartyId]
                                           WHERE a.[Id] = @Id AND p.[CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'DOCUMENT' AND EXISTS (SELECT 1 FROM dbo.T060Document          WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'ECRITURE' AND EXISTS (SELECT 1 FROM dbo.T135Ecritures         WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'TEMPLATE' AND EXISTS (SELECT 1 FROM dbo.T138EcrituresTemplate WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'PRODUIT'  AND EXISTS (SELECT 1 FROM dbo.T075Products          WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'COMPTE'   AND EXISTS (SELECT 1 FROM dbo.T121PlanComptable     WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'PARAM'    AND EXISTS (SELECT 1 FROM dbo.T101ParamValues       WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'IMPORT'   AND EXISTS (SELECT 1 FROM staging.ImportFiles       WHERE [Id] = @Id AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
        IF @Type = 'RECU'     AND EXISTS (SELECT 1 FROM dbo.T0001Receipt          WHERE [imageGUID] = @Guid AND [CompanyGUID] = @CompanyGUID) SET @Ok = 1;
    END

    SELECT @Ok AS Ok;
END
GO

-- ── Suppression d'un tiers : la compagnie était reçue mais jamais utilisée ──
CREATE OR ALTER PROCEDURE [dbo].[s0316DeleteParty]
    @CompanyGUID UNIQUEIDENTIFIER,
    @PartyId     INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T050Party WHERE [Id] = @PartyId AND [CompanyGUID] = @CompanyGUID)
        RETURN;

    DELETE dbo.T054PartyAddress WHERE [PartyId] = @PartyId;
    DELETE dbo.T050Party        WHERE [Id] = @PartyId AND [CompanyGUID] = @CompanyGUID;
END
GO

-- ── Comptes pour les listes des fiches produit et catégorie ─────────────────
CREATE OR ALTER PROCEDURE [dbo].[s0059GetComptesForDDL]
    @CompanyGUID        UNIQUEIDENTIFIER,
    @ClasseParentIds    VARCHAR(50) = ''   -- ex: '6' ou '7,8'
AS
BEGIN
    SET NOCOUNT ON;

    -- Les écrans passent les numéros de classes du plan modèle (6 = Revenus,
    -- 7 = Coût des ventes, 8 = Charges d'exploitation). Chaque compagnie a
    -- ses propres classes, avec d'autres numéros : on les retrouve par leur code.
    DECLARE @classes TABLE (Id INT PRIMARY KEY);
    INSERT INTO @classes (Id)
    SELECT DISTINCT mine.[Id]
      FROM STRING_SPLIT(@ClasseParentIds, ',') s
      JOIN dbo.T120PlanComptable_Classe ref  ON ref.[Id] = TRY_CAST(s.value AS INT)
      JOIN dbo.T120PlanComptable_Classe mine ON mine.[Code] = ref.[Code]
                                            AND mine.[CompanyGUID] = @CompanyGUID
     WHERE @ClasseParentIds <> '';

    SELECT c.[Id]                     AS [Value],
           c.compte + ' - ' + c.[Nom] AS [Name]
      FROM dbo.T121PlanComptable c
     WHERE c.[CompanyGUID] = @CompanyGUID
       AND c.[Actif] = 1
       AND (   @ClasseParentIds = ''
            OR c.[ClasseParentId] IN (SELECT Id FROM @classes))
     ORDER BY c.compte;
END
GO

-- ── Fichiers d'import récents : ceux de la compagnie seulement ──────────────
CREATE OR ALTER PROCEDURE [dbo].[s0601GetRecentImportFiles]
    @Top         INT = 10,
    @CompanyGUID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
           Id, TypeImport, OriginalName, FileExtension, FileSize, UploadDate,
           Status, InputTokens, OutputTokens, EstimatedCostUsd
      FROM staging.ImportFiles
     WHERE [CompanyGUID] = @CompanyGUID      -- NULL ne ramène rien : jamais « tout »
     ORDER BY Id DESC;
END
GO

-- ── Modification d'un tiers : seulement s'il est à la compagnie ─────────────

-- ------------------------------------------------------------ mise a jour ---
CREATE OR ALTER PROCEDURE [dbo].[s0017UpdateParty]
    @CompanyGUID uniqueidentifier, @DisplayName varchar(500), @Note varchar(max), @Type int,
    @Id int, @Name varchar(500), @TPS varchar(20), @TVQ varchar(20), @WebSite varchar(200),
    @PaymentTermDays int = 0
AS
UPDATE [dbo].[T050Party]
   SET Name            = @Name
      ,DisplayName     = @DisplayName
      ,TPS             = @TPS
      ,TVQ             = @TVQ
      ,WebSite         = @WebSite
      ,Note            = @Note
      ,Type            = @Type
      ,PaymentTermDays = CASE WHEN @PaymentTermDays < 0 THEN 0 ELSE @PaymentTermDays END
 WHERE Id = @Id
   AND CompanyGUID = @CompanyGUID
GO

-- ── PDF numérisés : ceux de la compagnie seulement ──────────────────────────





CREATE OR ALTER PROCEDURE [dbo].[s0028GetDocScanned]
    @CompanyGUID UNIQUEIDENTIFIER = NULL   -- NULL ne ramène rien : jamais « tout »
AS

--Facture_59315.pdf
SELECT [Id] ReceiptId
      ,dbo.fn_FormatDateFR_Safe (Created)  Created
      ,[ImageSource]

	  
	  ,case when ContentType = 'application/pdf' then
	   '<div>
	         <a rel="noopener"  style="color:blue; text-decoration:underline; " href=''Facture_' + convert(varchar(200),[imageGUID])  +  '.pdf'' target=''_blank'' ><div style="cursor:pointer;">'+ coalesce([FileName],'LaFacture') + '</div></a> 
			 <div> ' + dbo.fn_FormatDateFR_Safe (Created)  +'</div>
       </div>'
	  else
	  '<div>
	         <a  onclick = openImageViewer(''Voirlerecu_' + convert(varchar(200),[imageGUID])  +  '.jpeg'') ><div style="cursor:pointer;">'+ coalesce([FileName],'LeRecu') + '</div></a> 
			 <div> ' + dbo.fn_FormatDateFR_Safe (Created)  +'<span  style="padding-left: 30px;">' +  dbo.FormatMilliersEN( coalesce(SourceSizeBytes,0) )  + ' bytes</span> </div>
       </div>' end   SourceFileName


	  ,case when ContentType = 'application/pdf' then
	   '<div>
	         <a rel="noopener"  style="color:blue; text-decoration:underline; " href=''Facture_' + convert(varchar(200),[imageGUID])  +  '.pdf'' target=''_blank'' ><div style="cursor:pointer;">'+ coalesce([FileName],'LaFacture') + '</div></a> 
			 <div> ' + dbo.fn_FormatDateFR_Safe (Created)  +'<span  style="padding-left: 30px;">' +  dbo.FormatMilliersEN( coalesce(SourceSizeBytes,0) )  + ' bytes</span> </div>
       </div>'
	  else
	  '<div>
	         <a  onclick = openImageViewer(''Voirlerecu_' + convert(varchar(200),[imageGUID])  +  '.jpeg'') ><div style="cursor:pointer;">'+ coalesce([FileName],'LeRecu') + '</div></a> 
			 <div> ' + dbo.fn_FormatDateFR_Safe (Created)  +'<span  style="padding-left: 30px;">' +  dbo.FormatMilliersEN( coalesce(SourceSizeBytes,0) )  + ' bytes</span> </div>
       </div>' end   SourceFileName2



	  	   
	  ,'<div>
	          <a  onclick = openImageViewer(''Optimized_' + convert(varchar(200),[imageGUID])  +  '.jpeg'') ><div   style="cursor:pointer;">'+ coalesce([FileName],'LeRecu') + '</div></a>
			  <div> ' + convert(varchar(200),[Created]) +'<span  style="padding-left: 30px;">' +  dbo.FormatMilliersEN( coalesce([ImageForAISizeBytes] ,0) )  + ' bytes</span> </div>
			  </div>' Optimized
      ,[ContentType]  SourceContentType
      ,[imageGUID]
      ,[SourceSizeBytes]  SourceSizeBytes
	  ,  ProcessingStatus
	  ,  case when len(coalesce(AI_JSON,'')) = 0 then  0 else 1 end CanViewJSON 
	  , case when len(coalesce(AI_JSON,'')) = 0 then  1 else 0 end CanProcessAI


  FROM [dbo].[T0001Receipt] 
  where [ReceiptTypeId]  = 1
    and [CompanyGUID] = @CompanyGUID
  order by created desc
GO

-- ── Changement de compagnie : la même règle que la liste proposée ───────────
CREATE OR ALTER PROCEDURE [dbo].[s0211ValidateCompanyAccess]
    @UserId       varchar(200),
    @CompanyGUID  UNIQUEIDENTIFIER,
    @HasAccess    BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @HasAccess = 0;

    DECLARE @IsAccountant BIT = 0;
    DECLARE @UserCompanyGUID UNIQUEIDENTIFIER;
    DECLARE @UserGUID UNIQUEIDENTIFIER;

    SELECT
        @IsAccountant = IsAccountant,
        @UserCompanyGUID = CompanyGUID,
        @UserGUID = UserGUID
    FROM dbo.T015User
    WHERE email = @UserId
      AND IsDeleted = 0
      AND IsActive = 1;

    -- Comptable : sa compagnie, et celles dont il est le comptable désigné (T306, comme s0210)
    IF @IsAccountant = 1
    BEGIN
        IF @UserCompanyGUID = @CompanyGUID
           OR EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID AND ComptableGUID = @UserGUID)
            SET @HasAccess = 1;
    END
    ELSE
    BEGIN
        -- Utilisateur normal : sa compagnie seulement
        IF @UserCompanyGUID = @CompanyGUID
            SET @HasAccess = 1;
    END
END
GO

PRINT 'T306_Cloisonnement_par_compagnie.sql : terminé.';
