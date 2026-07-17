-- =============================================================================
-- T010Company_AddMailVerification
-- Colonnes de suivi de la verification par courriel de l'adresse d'entreprise.
--
-- La VALEUR du courriel reste dans T101ParamValues (parametre MAIL_FROM_EMAIL,
-- categorie EMAIL) : T010Company ne contient aucun champ metier, uniquement
-- l'identite et les metadonnees techniques (cf. Square*, Logo*).
--
-- MailVerifiedAddress = l'adresse effectivement confirmee. On la compare a la
-- valeur courante de MAIL_FROM_EMAIL : si l'utilisateur change le courriel,
-- la verification tombe automatiquement (plus de correspondance).
-- =============================================================================

IF COL_LENGTH('dbo.T010Company', 'MailVerifiedAddress') IS NULL
BEGIN
    ALTER TABLE dbo.T010Company ADD
        MailVerifiedAddress     VARCHAR(300)      NULL,   -- adresse confirmee
        MailVerifiedOn          DATETIME          NULL,   -- date de confirmation
        MailVerifySentTo        VARCHAR(300)      NULL,   -- adresse du lien en attente
        MailVerifyToken         UNIQUEIDENTIFIER  NULL,   -- token du lien en attente
        MailVerifyTokenExpires  DATETIME          NULL;   -- expiration du lien (24 h)
END
GO

-- Pas d'index sur MailVerifyToken : T010Company compte une ligne par abonne,
-- le scan est negligeable. Un index FILTRE imposerait SET QUOTED_IDENTIFIER ON
-- a toute ecriture sur T010Company (cf. le piege deja connu sur
-- T100ParamComptable avec sqlcmd), pour aucun gain.
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_T010Company_MailVerifyToken')
    DROP INDEX IX_T010Company_MailVerifyToken ON dbo.T010Company;
GO
