-- Un courriel entrant (avec MIME brut a parser cote application) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0612GetInboundMail
    @Id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, MailFrom,
           CAST(RcptTo AS NVARCHAR(1000)) AS RcptTo,
           SubjectHeader, DateHeader, ReceivedAtUtc,
           ProcessingStatus, MimeStatus, RawMessage
    FROM dbo.T990SmtpInboundMessage
    WHERE Id = @Id;
END
GO
