-- ============================================================================
-- Procedure : s1570GetOneMail_A          *** BASE MailService, pas MngConsul ***
-- Distribue un courriel a envoyer au service SrvAI / TkbServiceMailTask.
--
-- BAIL DE VISIBILITE (ajoute) : avant, la procedure distribuait un courriel sans
-- le rendre inelligible. Ses filtres (ToSend=1, SendWithSuccess IS NULL,
-- destinataire T404 en attente avec SendAt <= GETDATE()) restaient tous vrais
-- apres la distribution ; seul CountResend etait incremente, et il n'entre dans
-- aucun filtre. Le courriel restait donc distribuable pendant TOUT l'envoi SMTP,
-- jusqu'a s1572SetSendWithSuccess. Deux expediteurs concurrents le prenaient tous
-- les deux et le destinataire recevait le courriel EN DOUBLE.
--
-- Signature du probleme en base : T400Mails.CountResend = 2, SendWithSuccess = 1,
-- AUCUNE ligne dans T403SendErrorMessage, T404.CountResend = 0. Aucune tentative
-- n'avait echoue : c'etait une course, pas une panne.
--
-- Correctif : a la distribution, on repousse SendAt des destinataires remis au
-- demandeur. Le courriel devient invisible aux autres pendant @LeaseMinutes.
--   - envoi reussi  -> s1572SetSendWithSuccess le sort de la file ;
--   - envoi echoue  -> s1575ErrorSendEmail repositionne SendAt a +30 min ;
--   - processus mort -> le bail expire et le courriel revient TOUT SEUL.
-- C'est ce 3e cas qu'un verrou permanent ne saurait pas traiter : le courriel y
-- resterait bloque pour toujours, personne ne venant liberer le verrou.
--
-- Duree du bail : elle doit depasser le plus long envoi plausible, sinon un
-- second expediteur repart pendant que le premier travaille encore et le doublon
-- revient. Les envois observes durent 1 a 5 s, mais ce n'est pas la bonne mesure :
-- dans SendMessageSMTP la boucle de connexion tolere jusqu'a 20 iterations d'une
-- minute, et SendAsync n'a aucune limite de temps. D'ou 30 minutes, aligne sur le
-- delai de reessai que s1575 utilise deja. Un bail trop long ne coute qu'une
-- attente supplementaire apres un plantage ; un bail trop court coute un doublon.
--
-- Portee : ceci reduit les doublons, il ne les supprime pas absolument. Si l'envoi
-- SMTP reussit mais que le marquage echoue juste apres (clsTaskMail.ExecuteSQL
-- avale ses exceptions), le courriel revient a l'expiration du bail et repart. La
-- garantie est « au moins une fois », jamais « exactement une fois ».
-- ============================================================================
-- ⚠️ OBLIGATOIRE. Le reglage est capture a la CREATION de la procedure et fige
-- pour toutes ses executions. sqlcmd a QUOTED_IDENTIFIER OFF par defaut (ADO.NET
-- l'a ON), et une procedure creee en OFF echoue a l'INSERT sur une table portant
-- un index filtre : « INSERT failed because the following SET options have
-- incorrect settings: 'QUOTED_IDENTIFIER' ». C'est exactement ce qui est arrive
-- lors du premier deploiement de ce script, la definition exportee depuis
-- sys.sql_modules ne portant aucun SET. Les procs voisines (s0610, s1572, s1575)
-- sont toutes en ON : verifier avec sys.sql_modules.uses_quoted_identifier.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s1570GetOneMail_A]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MailId INT;
    DECLARE @MaxRetry INT = 10;

    -- Duree du bail de visibilite (voir l'en-tete).
    DECLARE @LeaseMinutes INT = 30;

    BEGIN TRAN;

    -- Nettoyages historiques (conserves)
    UPDATE T400Mails SET ToSend = 0, [to] = '' WHERE [to] IS NULL AND ToSend = 1;
    UPDATE T400Mails SET ToSend = 0, [to] = '' WHERE [to] = ''   AND ToSend = 1;

    UPDATE T400Mails
       SET SendAt = GETDATE(), [to] = LTRIM(RTRIM([to]))
     WHERE SendAt IS NULL AND COALESCE(ToSend, 0) = 1;

    UPDATE T400Mails SET SendAt = NULL
     WHERE COALESCE(ToSend, 0) = 0 AND SendAt IS NOT NULL;

    UPDATE T400Mails SET CountResend = 0
     WHERE CountResend IS NULL AND COALESCE(ToSend, 0) = 1;

    UPDATE T400Mails SET CountResend = NULL
     WHERE COALESCE(ToSend, 0) = 0 AND CountResend IS NOT NULL;

    --UPDATE T400Mails SET Sender = 'giv4@sourcevolution.com'
    -- WHERE COALESCE(Sender, '') = ''
    --   AND COALESCE(ToSend, 0) = 1
    --   AND COALESCE(SendWithSuccess, 0) = 0;

    --UPDATE T400Mails SET MailPriority = 5
    -- WHERE Sender = 'facturation@sourcevolution.com';

    -- IMPORTANT : on ne tue PLUS le mail au niveau CountResend mail.
    -- La decision de fin de retry est maintenant PAR destinataire (T404).

    -- Init T404 pour les mails ToSend=1 qui n'ont pas encore de rangees
    -- (inclut [To], [CC] et [BCC] : chacun est livre via SMTP individuellement)
    ;WITH MailsSansT404 AS (
        SELECT m.Id,
               COALESCE(m.[To],  '') + ';' +
               COALESCE(m.[CC],  '') + ';' +
               COALESCE(m.[BCC], '') AS AllRecipients
          FROM T400Mails m
         WHERE COALESCE(m.ToSend, 0) = 1
           AND m.SendWithSuccess IS NULL
           AND (COALESCE(m.[To],'') <> '' OR COALESCE(m.[CC],'') <> '' OR COALESCE(m.[BCC],'') <> '')
           AND NOT EXISTS (
                SELECT 1 FROM T404MailRecipientStatus r WHERE r.MailId = m.Id
           )
    )
    INSERT INTO T404MailRecipientStatus (MailId, Email, SendAt)
    SELECT DISTINCT m.Id, e.Email, GETDATE()
      FROM MailsSansT404 m
     CROSS APPLY STRING_SPLIT(m.AllRecipients, ';') s
     CROSS APPLY (
        -- Si "Name <email@host>", extraire entre < et >, sinon prendre tel quel
        SELECT LOWER(LTRIM(RTRIM(
            CASE
                WHEN CHARINDEX('<', s.value) > 0
                 AND CHARINDEX('>', s.value) > CHARINDEX('<', s.value)
                THEN SUBSTRING(s.value,
                               CHARINDEX('<', s.value) + 1,
                               CHARINDEX('>', s.value) - CHARINDEX('<', s.value) - 1)
                ELSE s.value
            END
        ))) AS Email
     ) e
     WHERE e.Email <> ''
       AND CHARINDEX('@', e.Email) > 0;

    -- Marquer en echec definitif les destinataires qui ont depasse @MaxRetry
    UPDATE T404MailRecipientStatus
       SET SendWithSuccess = 0
     WHERE SendWithSuccess IS NULL
       AND CountResend >= @MaxRetry;

    -- Propager le statut au mail si TOUS les destinataires sont termines
    UPDATE m
       SET SendWithSuccess = CASE
                WHEN EXISTS (SELECT 1 FROM T404MailRecipientStatus r
                              WHERE r.MailId = m.Id AND r.SendWithSuccess = 1) THEN 1
                ELSE 0
            END
      FROM T400Mails m
     WHERE COALESCE(m.ToSend, 0) = 1
       AND m.SendWithSuccess IS NULL
       AND EXISTS (SELECT 1 FROM T404MailRecipientStatus r WHERE r.MailId = m.Id)
       AND NOT EXISTS (SELECT 1 FROM T404MailRecipientStatus r
                        WHERE r.MailId = m.Id AND r.SendWithSuccess IS NULL);

    -- Nettoyages cosmetiques (conserves)
    UPDATE [T400Mails]
       SET [recipientIDList] = COALESCE([recipientIDList], '00000000-0000-0000-0000-000000000000')
     WHERE COALESCE(ToSend, 0) = 1 AND SendWithSuccess IS NULL;

    UPDATE [T400Mails]
       SET [To] = REPLACE(COALESCE([To], ''), '; ;', ';')
     WHERE COALESCE(ToSend, 0) = 1 AND SendWithSuccess IS NULL;

    UPDATE [T400Mails]
       SET [To] = REPLACE(COALESCE([To], ''), ';;', ';')
     WHERE COALESCE(ToSend, 0) = 1 AND SendWithSuccess IS NULL;

    -- Choisir un mail qui a au moins un destinataire pending pret a (re)essayer
    SELECT TOP (1) @MailId = m.[Id]
      FROM T400Mails m
     WHERE COALESCE(m.ToSend, 0) = 1
       AND m.SendWithSuccess IS NULL
       AND EXISTS (
            SELECT 1 FROM T404MailRecipientStatus r
             WHERE r.MailId = m.Id
               AND r.SendWithSuccess IS NULL
               AND (r.SendAt IS NULL OR r.SendAt <= GETDATE())
               AND r.CountResend < @MaxRetry
       )
     ORDER BY m.MailPriority DESC, m.Id;

    -- Trim final du ';' a la fin du To
    IF @MailId IS NOT NULL
    BEGIN
        DECLARE @MyTo VARCHAR(600);
        SELECT @MyTo = RTRIM(LTRIM([To])) FROM [T400Mails] WHERE Id = @MailId;
        IF (RIGHT(@MyTo, 1) = ';')
        BEGIN
            SET @MyTo = LEFT(@MyTo, LEN(@MyTo) - 1);
            UPDATE [T400Mails] SET [To] = @MyTo WHERE Id = @MailId;
        END
    END

    ---------------------------------------------------------------------------
    -- Result set #1 : le mail (compat avec l'appelant existant)
    ---------------------------------------------------------------------------
    SELECT Id, [Mail], [RCPT], [Received], [Sended], [FolderId], [From],
           COALESCE([BCC], '')             AS BCC,
           COALESCE([CC], '')              AS CC,
           [ReplyTo], [ResentBCC], [ResentCC], [ResentFrom], [ResentReplyTo],
           [ResentSender], [ResentTo],
           COALESCE([Sender], '')          AS Sender,
           LOWER(COALESCE([To], ''))       AS [To],
           [InReplyTo], [Importance], [xPriority], [MessageId], [ResentMessageId],
           COALESCE([Subject], '')         AS [Subject],
           COALESCE([TextBody], '')        AS TextBody,
           COALESCE([HTMLBody], '')        AS HTMLBody,
           [ClientIP], [HasBeenRead], [RCPT_ORG], [HasBeenNotifie],
           [ToSend], CountResend, SendWithSuccess
      FROM [T400Mails]
     WHERE Id = @MailId;

    ---------------------------------------------------------------------------
    -- Result set #2 : destinataires pending pour ce mail
    ---------------------------------------------------------------------------
    SELECT LOWER(Email) AS Email
      FROM T404MailRecipientStatus
     WHERE MailId = @MailId
       AND SendWithSuccess IS NULL
       AND (SendAt IS NULL OR SendAt <= GETDATE())
       AND CountResend < @MaxRetry;

    ---------------------------------------------------------------------------
    -- BAIL DE VISIBILITE : rendre invisibles les destinataires qu'on vient de
    -- remettre au demandeur, pour qu'un second expediteur ne les reprenne pas
    -- pendant l'envoi SMTP.
    --
    -- Le predicat est IDENTIQUE a celui du result set #2 : on ne baille que ce
    -- qui a effectivement ete distribue. Les destinataires dont le SendAt est
    -- deja dans le futur (en attente d'un reessai) ne sont pas touches, sinon on
    -- repousserait leur echeance a chaque passage.
    --
    -- L'ordre compte : cet UPDATE doit rester APRES le result set #2, qui filtre
    -- sur SendAt <= GETDATE(). Le remonter au-dessus rendrait la liste des
    -- destinataires vide et le service n'aurait plus personne a qui envoyer.
    ---------------------------------------------------------------------------
    UPDATE T404MailRecipientStatus
       SET SendAt = DATEADD(MINUTE, @LeaseMinutes, GETDATE())
     WHERE MailId = @MailId
       AND SendWithSuccess IS NULL
       AND (SendAt IS NULL OR SendAt <= GETDATE())
       AND CountResend < @MaxRetry;

    -- Marquer la tentative au niveau mail (informatif)
    UPDATE [T400Mails]
       SET Sended = GETDATE(),
           SendWithSuccess = NULL,
           CountResend = COALESCE(CountResend, 0) + 1
     WHERE Id = @MailId;

    COMMIT TRAN;
END
