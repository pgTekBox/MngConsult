-- Un message entrant, SEULEMENT s'il appartient a @Addr (securite) - MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0617GetInboxForAddress
    @Id   BIGINT,
    @Addr NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, MailFrom, CAST(RcptTo AS NVARCHAR(1000)) AS RcptTo,
           SubjectHeader, DateHeader, ReceivedAtUtc, ProcessingStatus, MimeStatus, RawMessage
    FROM dbo.T990SmtpInboundMessage
    WHERE Id = @Id
      AND CAST(RcptTo AS NVARCHAR(1000)) LIKE '%' + @Addr + '%';
END
GO
