-- Unicite des adresses locales acceptees par le MTA (SrvAI).
USE [MailService];
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_SmtpLocalRecipient_Email' AND object_id=OBJECT_ID('dbo.SmtpLocalRecipient'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_SmtpLocalRecipient_Email
        ON dbo.SmtpLocalRecipient(Email);
GO
