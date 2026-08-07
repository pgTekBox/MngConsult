-- Reception limitee a UNE adresse locale (@60sec.ca) - base MailService.
USE [MailService];
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE dbo.s0616ListInboxForAddress
    @Addr NVARCHAR(320),
    @Top  INT = 300
AS
BEGIN
    SET NOCOUNT ON;
    IF @Addr IS NULL OR @Addr = '' RETURN;
    SELECT TOP (@Top)
        Id, MailFrom, CAST(RcptTo AS NVARCHAR(1000)) AS RcptTo,
        SubjectHeader, ReceivedAtUtc, ProcessingStatus, MimeStatus, MessageSizeBytes
    FROM dbo.T990SmtpInboundMessage
    WHERE CAST(RcptTo AS NVARCHAR(1000)) LIKE '%' + @Addr + '%'
    ORDER BY Id DESC;
END
GO
