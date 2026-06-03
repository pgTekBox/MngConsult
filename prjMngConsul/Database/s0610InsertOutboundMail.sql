-- =============================================================================
-- s0610InsertOutboundMail
-- Insère un courriel sortant dans T400Mails de la BD MailService.
-- Le service Windows SrvAI poll régulièrement cette table et envoie via SMTP
-- les rows avec ToSend = 1 et SendWithSuccess IS NULL.
--
-- BASE DE DONNÉES CIBLE : MailService (PAS MngConsul)
--
-- Retourne l'Id du mail créé pour permettre au caller de suivre l'envoi.
--
-- Utilisé par : wbfRegister.aspx.vb (envoi du courriel d'activation)
--               Toute autre page qui doit envoyer un mail système.
--
-- ATTENTION : à déployer SEULEMENT si check_existing_outbound_mail_proc.sql
-- confirme qu'aucune proc équivalente n'existe déjà.
-- =============================================================================

USE [MailService];
GO

IF OBJECT_ID('dbo.s0610InsertOutboundMail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.s0610InsertOutboundMail;
GO

CREATE PROCEDURE dbo.s0610InsertOutboundMail
    @To             NVARCHAR(500),                              -- Destinataire(s) séparés par ;
    @Subject        NVARCHAR(500),
    @HTMLBody       NVARCHAR(MAX),
    @TextBody       NVARCHAR(MAX)   = NULL,
    @Sender         NVARCHAR(200)   = 'noreply@mngconsul.com',  -- Adresse d'envoi
    @From           NVARCHAR(200)   = 'noreply@mngconsul.com',
    @ReplyTo        NVARCHAR(200)   = NULL,
    @CC             NVARCHAR(500)   = NULL,
    @BCC            NVARCHAR(500)   = NULL,
    @Importance     VARCHAR(20)     = 'normal',
    @SendAt         DATETIME        = NULL                      -- NULL = envoi immédiat (1 min)
AS
BEGIN
    SET NOCOUNT ON;

    -- Default sendAt = maintenant moins 1 minute (sera ramassé au prochain cycle SrvAI)
    IF @SendAt IS NULL
        SET @SendAt = DATEADD(MINUTE, -1, GETDATE());

    INSERT INTO dbo.T400Mails (
        [To],
        [Subject],
        HTMLBody,
        TextBody,
        Sender,
        [From],
        ReplyTo,
        CC,
        BCC,
        Importance,
        Created,
        SendAt,
        ToSend,
        SMTPMail,
        CountResend,
        recipientIDList,
        HasBeenNotifie
    )
    OUTPUT INSERTED.Id
    VALUES (
        @To,
        @Subject,
        @HTMLBody,
        @TextBody,
        @Sender,
        @From,
        @ReplyTo,
        @CC,
        @BCC,
        @Importance,
        GETDATE(),
        @SendAt,
        1,                                                      -- ToSend = 1 (sortant)
        0,                                                      -- SMTPMail = 0 (pas reçu via SMTP)
        0,                                                      -- CountResend initial
        '00000000-0000-0000-0000-000000000000',                 -- Empty GUID par défaut
        0                                                       -- HasBeenNotifie
    );
END
GO

-- Accorder EXECUTE au user MngConsulMail (créé par setup_MailService_user.sql)
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'MngConsulMail')
BEGIN
    GRANT EXECUTE ON dbo.s0610InsertOutboundMail TO [MngConsulMail];
    PRINT 'GRANT EXECUTE sur s0610InsertOutboundMail accordé à MngConsulMail.';
END
GO
