-- =============================================================================
-- T280 — Les reçus appartiennent à une compagnie
--
-- Constat : la liste des reçus (Achats › Reçus, s0001GetReceipts) montrait TOUS
-- les reçus, de toutes les compagnies, et les reçus arrivés par courriel
-- (Source = 3, T990MailId renseigné) étaient créés SANS CompanyGUID. La remise
-- à zéro (s0863) ne les touchait donc pas, et ils restaient visibles.
--
--   s0864AttribuerRecusCourriel : donne sa compagnie à chaque reçu venu par courriel
--       d'après le destinataire du message (MailService.dbo.T990SmtpInboundMessage.RcptTo)
--       = boîte @60sec.ca de la compagnie (T010Company.Sec60Email) ou d'un de ses
--       employés (T300Employees.Sec60Email). Rejouable ; ignore ce qui ne se résout pas.
--   s0001GetReceipts @CompanyGUID : filtre par compagnie (NULL = tout, compatibilité),
--       après avoir attribué les reçus courriel encore sans compagnie.
--   s0863ResetCompanyAccounting : attribue puis efface, pour que les reçus courriel
--       de la compagnie partent avec le reste.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0864AttribuerRecusCourriel
    @CompanyGUID uniqueidentifier = NULL   -- NULL : toutes les compagnies
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.T0001Receipt WHERE CompanyGUID IS NULL AND T990MailId IS NOT NULL) RETURN;

    BEGIN TRY
        -- Boîtes connues : celle de la compagnie, puis celles de ses employés.
        DECLARE @boites TABLE (CompanyGUID uniqueidentifier, Email nvarchar(320));
        INSERT INTO @boites (CompanyGUID, Email)
        SELECT CompanyGUID, LOWER(Sec60Email) FROM dbo.T010Company WHERE Sec60Email IS NOT NULL AND Sec60Email <> ''
          AND (@CompanyGUID IS NULL OR CompanyGUID = @CompanyGUID)
        UNION
        SELECT CompanyGUID, LOWER(Sec60Email) FROM dbo.T300Employees WHERE Sec60Email IS NOT NULL AND Sec60Email <> ''
          AND (@CompanyGUID IS NULL OR CompanyGUID = @CompanyGUID);

        UPDATE r
           SET r.CompanyGUID = b.CompanyGUID
          FROM dbo.T0001Receipt r
          JOIN MailService.dbo.T990SmtpInboundMessage m ON m.Id = r.T990MailId
          CROSS APPLY (SELECT TOP 1 b.CompanyGUID
                         FROM @boites b
                        WHERE LOWER(CAST(m.RcptTo AS nvarchar(1000))) LIKE '%' + b.Email + '%') b
         WHERE r.CompanyGUID IS NULL;
    END TRY
    BEGIN CATCH
        -- Base MailService absente ou inaccessible : on n'attribue pas, la liste reste utilisable.
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [dbo].[s0001GetReceipts]
    @CompanyGUID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.s0864AttribuerRecusCourriel @CompanyGUID;

SELECT [Id] ReceiptId
      ,[Created]  Created
      ,[ImageSource]
	   ,case
	           when len(coalesce(AI_JSON,'')) = 0 then '' else '<div title="Receipt number">#' + dbo.fn_GetJSONvalue( AI_JSON, '$.receipt_number')  + '</div><div>'  + dbo.fn_GetJSONvalue( AI_JSON, '$.merchant_name')  + '</div><div>'  + coalesce( dbo.fn_GetJSONvalue( AI_JSON, '$.merchant_street'),'') + '</div>'   end  SupplierInfo
	  ,'<div>
	         <a style="color:blue; text-decoration:underline; " onclick = openImageViewer(''Voirlerecu_' + convert(varchar(200),[imageGUID])  +  '.jpeg'') >
			 <span style="cursor:pointer;">'+ coalesce([FileName],'LeRecu') + '</span></a> <span style="color: #b1a7a7;    font-size: 12px;    font-family: monospace;"> Original</span><span  style="padding-left: 30px;">' +  dbo.FormatMilliersEN( coalesce(SourceSizeBytes,0) )  + ' bytes ' +
			 '<div> ' + dbo.fn_FormatDateFR_Safe ( [Created]  ) + '</div></div>'
           SourceFileNameOLD
		  ,case when ContentType = 'application/pdf' then
	   '<div>
	         <a rel="noopener"  style="color:blue; text-decoration:underline; " href=''Facture_' + convert(varchar(200),[imageGUID])  +  '.pdf'' target=''_blank'' ><div style="cursor:pointer;">'+ coalesce([FileName],'LaFacture') + '</div></a>
			 <div> ' + dbo.fn_FormatDateFR_Safe (Created)  +'</div>
       </div>'
	  else
	 '<div>
	         <a style="color:blue; text-decoration:underline; " onclick = openImageViewer(''Voirlerecu_' + convert(varchar(200),[imageGUID])  +  '.jpeg'') >
			 <span style="cursor:pointer;">'+ coalesce([FileName],'LeRecu') + '</span></a> <span style="color: #b1a7a7;    font-size: 12px;    font-family: monospace;"> Original</span><span  style="padding-left: 30px;">' +  dbo.FormatMilliersEN( coalesce(SourceSizeBytes,0) )  + ' bytes ' +
			 '<div> ' + dbo.fn_FormatDateFR_Safe ( [Created]  ) + '</div></div>'  end   SourceFileName
	  ,case when len(coalesce(AI_JSON,'')) > 0 then '<div>
	          <a style="color:blue; text-decoration:underline; " onclick = openImageViewer(''Optimized_' + convert(varchar(200),[imageGUID])  +  '.jpeg'') >
			  <span   style="cursor:pointer;">'+ coalesce([FileName],'LeRecu') + '</span></a><span style="color: #b1a7a7;    font-size: 12px;    font-family: monospace;"> Optimized</span> <span  style="padding-left: 30px;"> ' +  dbo.FormatMilliersEN( coalesce([ImageForAISizeBytes] ,0) )  + ' bytes</span>
			  <div></div>
			  </div>'else '' end  Optimized
      ,[ContentType]  SourceContentType
      ,[imageGUID]
      ,[SourceSizeBytes]  SourceSizeBytes
	  ,  ProcessingStatus
	  ,  case when len(coalesce(AI_JSON,'')) = 0 then  0 else 1 end CanViewJSON
	   , case when len(coalesce(AI_JSON,'')) = 0 then  1 else 0 end CanProcessAI
  FROM [dbo].[T0001Receipt]
  where receipttypeid = 2
    and (@CompanyGUID IS NULL OR CompanyGUID = @CompanyGUID)
  order by Created desc
END
GO

PRINT N'T280_Recus_par_compagnie.sql : terminé.';
