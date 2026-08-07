-- Liste la boite de reception (courriel entrant @60sec.ca) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0611ListInboundMail
    @Rcpt NVARCHAR(320) = NULL,
    @Top  INT = 300
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        Id, MailFrom,
        CAST(RcptTo AS NVARCHAR(1000)) AS RcptTo,
        SubjectHeader, ReceivedAtUtc, ProcessingStatus, MimeStatus, MessageSizeBytes
    FROM dbo.T990SmtpInboundMessage
    WHERE (@Rcpt IS NULL OR CAST(RcptTo AS NVARCHAR(1000)) LIKE '%' + @Rcpt + '%')
    ORDER BY Id DESC;
END
GO
