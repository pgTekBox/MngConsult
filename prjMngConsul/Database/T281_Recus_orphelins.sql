-- =============================================================================
-- T281 — Reçus orphelins (Sec60Admin › Gestion des démos)
--
-- Un reçu arrivé par courriel dont le destinataire n'est la boîte @60sec.ca
-- d'aucune compagnie ni d'aucun employé reste sans CompanyGUID : il n'apparaît
-- dans aucune liste et aucune remise à zéro ne l'efface. La console d'admin
-- les montre, les rattache à une compagnie ou les supprime.
--   s0865GetOrphanReceipts     : la liste (avec destinataire, expéditeur et objet du courriel).
--   s0866AssignOrphanReceipts  : rattache les Ids donnés (CSV) à une compagnie.
--   s0867DeleteOrphanReceipts  : supprime les Ids donnés (CSV) — seulement s'ils sont encore orphelins.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE dbo.s0865GetOrphanReceipts
AS
BEGIN
    SET NOCOUNT ON;
    -- On rattache d'abord ce qui peut l'être : ne restent que les vrais orphelins.
    EXEC dbo.s0864AttribuerRecusCourriel;

    SELECT r.Id, r.Created, r.FileName, r.ContentType, r.SourceSizeBytes, r.Source, r.T990MailId,
           CASE WHEN LEN(ISNULL(r.AI_JSON, '')) > 0 THEN 1 ELSE 0 END AS Analyse,
           CAST(m.RcptTo AS nvarchar(320)) AS Destinataire,
           CAST(m.MailFrom AS nvarchar(320)) AS Expediteur,
           CAST(m.SubjectHeader AS nvarchar(400)) AS Objet,
           m.ReceivedAtUtc
      FROM dbo.T0001Receipt r
      LEFT JOIN MailService.dbo.T990SmtpInboundMessage m ON m.Id = r.T990MailId
     WHERE r.CompanyGUID IS NULL
     ORDER BY r.Created DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0866AssignOrphanReceipts
    @Ids         nvarchar(max),          -- « 12,15,18 »
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    IF @CompanyGUID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.T010Company WHERE CompanyGUID = @CompanyGUID)
    BEGIN
        RAISERROR('Compagnie introuvable.', 16, 1);
        RETURN;
    END
    UPDATE r SET r.CompanyGUID = @CompanyGUID
      FROM dbo.T0001Receipt r
      JOIN STRING_SPLIT(@Ids, ',') s ON TRY_CAST(s.value AS int) = r.Id
     WHERE r.CompanyGUID IS NULL;
    SELECT @@ROWCOUNT AS Nb;
END
GO

CREATE OR ALTER PROCEDURE dbo.s0867DeleteOrphanReceipts
    @Ids nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @cibles TABLE (Id int PRIMARY KEY);
    INSERT INTO @cibles (Id)
    SELECT DISTINCT r.Id
      FROM dbo.T0001Receipt r
      JOIN STRING_SPLIT(@Ids, ',') s ON TRY_CAST(s.value AS int) = r.Id
     WHERE r.CompanyGUID IS NULL;

    BEGIN TRAN;
    DELETE FROM dbo.T0002ReceiptProcessLog WHERE ReceiptId IN (SELECT Id FROM @cibles);
    DELETE FROM dbo.T0001Receipt WHERE Id IN (SELECT Id FROM @cibles);
    DECLARE @nb int = @@ROWCOUNT;
    COMMIT;
    SELECT @nb AS Nb;
END
GO

PRINT N'T281_Recus_orphelins.sql : terminé.';
