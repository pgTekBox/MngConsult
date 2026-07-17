-- =============================================================================
-- T102ParamI18n : traductions des libellés de paramètres (indexé par ShortName).
-- Table unique (indépendante de la compagnie) lue par s0150GetParamsForCompany
-- via COALESCE selon @Lang. Repli : langue demandée → FR → T100.Name.
-- MERGE = idempotent (ré-exécutable pour mettre à jour les libellés).
-- =============================================================================

IF OBJECT_ID('dbo.T102ParamI18n', 'U') IS NULL
    CREATE TABLE dbo.T102ParamI18n (
        ShortName VARCHAR(50)   NOT NULL PRIMARY KEY,
        NameFr    NVARCHAR(200) NULL,
        NameEn    NVARCHAR(200) NULL,
        NameEs    NVARCHAR(200) NULL
    );
GO

;WITH src (ShortName, NameFr, NameEn, NameEs) AS (
    SELECT * FROM (VALUES
        -- BANCAIRE
        ('COMPTE_BANQUE',       N'Compte bancaire par défaut',              N'Default bank account',              N'Cuenta bancaria predeterminada'),
        -- COMPTABILITÉ
        ('VP',                  N'Vente de produit',                        N'Product sale',                      N'Venta de producto'),
        ('AP',                  N'Achat produits',                          N'Product purchase',                  N'Compra de productos'),
        ('CC',                  N'Crédit client',                           N'Customer credit',                   N'Crédito de cliente'),
        ('CF',                  N'Crédit fournisseur',                      N'Supplier credit',                   N'Crédito de proveedor'),
        ('DP',                  N'Dépense payée perso',                     N'Personally-paid expense',           N'Gasto pagado personalmente'),
        ('BNR',                 N'Compte Bénéfices non répartis',           N'Retained earnings account',         N'Cuenta de resultados acumulados'),
        ('BNE',                 N'Compte Bénéfice net de l''exercice',      N'Net income for the year account',   N'Cuenta de resultado neto del ejercicio'),
        ('JOURNAL_OD',          N'Code du journal d''opérations diverses',  N'Miscellaneous journal code',        N'Código del diario de operaciones varias'),
        -- COMPTABLE
        ('COMPTABLE',           N'Clé comptable',                           N'Accountant key',                    N'Clave del contador'),
        -- EMAIL
        -- SMTP par compagnie retire (MAIL_FROM_NAME/SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASS) :
        -- envoi centralise via T400Mails + SrvAI. Cf. Database/remove_SMTP_params.sql.
        ('MAIL_FROM_EMAIL',     N'Courriel d''expéditeur',                  N'From email',                        N'Correo del remitente'),
        ('MAIL_SIGNATURE',      N'Signature courriel',                      N'Email signature',                   N'Firma de correo'),
        -- ENTREPRISE
        ('LEGAL_NAME',          N'Nom légal',                               N'Legal name',                        N'Razón social'),
        ('TRADE_NAME',          N'Nom commercial',                          N'Trade name',                        N'Nombre comercial'),
        ('NEQ',                 N'NEQ',                                      N'NEQ',                               N'NEQ'),
        ('PHONE',               N'Téléphone',                               N'Phone',                             N'Teléfono'),
        ('ADDR1',               N'Adresse (ligne 1)',                       N'Address (line 1)',                  N'Dirección (línea 1)'),
        ('ADDR2',               N'Adresse (ligne 2)',                       N'Address (line 2)',                  N'Dirección (línea 2)'),
        ('CITY',                N'Ville',                                   N'City',                              N'Ciudad'),
        ('PROVINCE',            N'Province',                                N'Province',                          N'Provincia'),
        ('POSTAL',              N'Code postal',                             N'Postal code',                       N'Código postal'),
        ('COUNTRY',             N'Pays',                                    N'Country',                           N'País'),
        ('FISCAL_YEAR_END',     N'Date de fin d''année fiscale',            N'Fiscal year-end date',              N'Fecha de cierre del ejercicio fiscal'),
        -- PDF
        ('PDF_TEMPLATE',        N'Nom du modèle PDF',                       N'PDF template name',                 N'Nombre de la plantilla PDF'),
        ('PDF_LOGO_PATH',       N'Logo (URL/chemin)',                       N'Logo (URL/path)',                   N'Logo (URL/ruta)'),
        ('PDF_PAYMENT_TERMS',   N'Conditions de paiement',                  N'Payment terms',                     N'Condiciones de pago'),
        ('PDF_NOTES',           N'Mentions / Notes',                        N'Disclaimers / Notes',               N'Menciones / Notas'),
        ('PDF_PAID_STAMP',      N'Afficher tampon « PAYÉ »',                N'Show "PAID" stamp',                 N'Mostrar sello «PAGADO»'),
        ('PDF_EMAIL_AFTER_PAY', N'Envoyer le PDF par courriel après paiement', N'Email PDF after payment',        N'Enviar el PDF por correo tras el pago'),
        -- TAXES
        ('TAX_FREQ',            N'Fréquence de remise des taxes (TPS/TVQ)', N'Tax remittance frequency (GST/QST)', N'Frecuencia de remesa de impuestos (GST/QST)'),
        ('TAX_PAY_BANK',        N'Compte banque pour la remise de taxes',   N'Bank account for tax remittance',   N'Cuenta bancaria para la remesa de impuestos'),
        ('GST_NO',              N'No TPS (GST)',                            N'GST number',                        N'Número GST'),
        ('QST_NO',              N'No TVQ (QST)',                            N'QST number',                        N'Número QST'),
        ('GST_RATE',            N'Taux TPS (%)',                            N'GST rate (%)',                      N'Tasa GST (%)'),
        ('QST_RATE',            N'Taux TVQ (%)',                            N'QST rate (%)',                      N'Tasa QST (%)'),
        ('TAX_ROUNDING',        N'Arrondi des taxes',                       N'Tax rounding',                      N'Redondeo de impuestos'),
        ('TAX_MODE',            N'Mode de taxes',                           N'Tax mode',                          N'Modo de impuestos')
    ) v(ShortName, NameFr, NameEn, NameEs)
)
MERGE dbo.T102ParamI18n AS t
USING src AS s ON t.ShortName = s.ShortName
WHEN MATCHED THEN
    UPDATE SET NameFr = s.NameFr, NameEn = s.NameEn, NameEs = s.NameEs
WHEN NOT MATCHED THEN
    INSERT (ShortName, NameFr, NameEn, NameEs)
    VALUES (s.ShortName, s.NameFr, s.NameEn, s.NameEs);
GO
