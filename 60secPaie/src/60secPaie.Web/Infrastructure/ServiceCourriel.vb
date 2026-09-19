Imports System.Configuration
Imports System.IO
Imports System.Net.Mail
Imports System.Text

''' <summary>
''' Envoi des talons de paie par courriel aux employés qui l'ont demandé (case « Envoyer le talon de paie par courriel » de leur fiche).
''' Configuration dans Web.config :
'''   - production : section system.net/mailSettings (serveur SMTP, TLS) et la clé Courriel:Expediteur ;
'''   - développement : la clé Courriel:DossierTest écrit les courriels en fichiers .eml dans un dossier au lieu de les envoyer.
''' Un talon contient des renseignements personnels : n'utiliser qu'un serveur SMTP avec chiffrement TLS.
''' </summary>
Public NotInheritable Class ServiceCourriel

    Private Sub New()
    End Sub

    ''' <summary>Le domaine d'où part tout courriel de 60secPaie, et l'adresse utilisée à défaut de configuration.</summary>
    Private Const DomaineAutorise As String = "60sec.ca"
    Private Const ExpediteurParDefaut As String = "paie@60sec.ca"

    Public Class Bilan
        Public Property Envoyes As Integer
        Public Property DejaEnvoyes As Integer
        Public Property Erreurs As New List(Of String)()
    End Class

    ''' <summary>Remplaçable dans les tests.</summary>
    Public Shared Property FabriqueClient As Func(Of SmtpClient) = AddressOf ClientParDefaut

    Private Shared Function ClientParDefaut() As SmtpClient
        Dim client As New SmtpClient()
        Dim dossierTest = ConfigurationManager.AppSettings("Courriel:DossierTest")
        If Not String.IsNullOrWhiteSpace(dossierTest) Then
            Dim chemin = If(dossierTest.StartsWith("~"), HttpContext.Current.Server.MapPath(dossierTest), dossierTest)
            Directory.CreateDirectory(chemin)
            client.DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory
            client.PickupDirectoryLocation = chemin
        ElseIf String.IsNullOrEmpty(client.Host) Then
            Throw New SaisieInvalideException("Le serveur de courriel n'est pas configuré (section mailSettings de Web.config).")
        End If
        Return client
    End Function

    Public Shared ReadOnly Property ModeTest As Boolean
        Get
            Return Not String.IsNullOrWhiteSpace(ConfigurationManager.AppSettings("Courriel:DossierTest"))
        End Get
    End Property

    ''' <summary>Employés du lot qui reçoivent leur talon par courriel.</summary>
    Public Shared Function Destinataires(lotId As Integer) As DataTable
        Return Db.Table(
            "SELECT p.Id AS PaieId, p.TalonEnvoyeLe, e.Prenom, e.Nom, e.Courriel, e.Langue FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
            "JOIN paie.Employe e ON e.Id = p.EmployeId WHERE l.Id = @l AND l.CompagnieId = @c AND l.Statut = 'C' AND p.Inclus = 1 AND e.TalonParCourriel = 1 " &
            "ORDER BY e.Nom, e.Prenom", Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
    End Function

    ''' <summary>Envoie les talons du lot. Par défaut, ceux déjà envoyés ne sont pas renvoyés.</summary>
    Public Shared Function EnvoyerTalons(lotId As Integer, renvoyer As Boolean) As Bilan
        Dim lot = Db.Ligne("SELECT l.*, c.Nom AS CompagnieNom, c.Courriel AS CompagnieCourriel FROM paie.LotPaie l JOIN paie.Compagnie c ON c.Id = l.CompagnieId " &
                           "WHERE l.Id = @l AND l.CompagnieId = @c AND l.Statut = 'C'", Db.P("@l", lotId), Db.P("@c", Contexte.CompagnieId))
        If lot Is Nothing Then Throw New SaisieInvalideException("Les talons s'envoient à partir d'une paie confirmée.")

        Dim destinataires = ServiceCourriel.Destinataires(lotId)
        If destinataires.Rows.Count = 0 Then
            Throw New SaisieInvalideException("Aucun employé de cette paie n'a demandé son talon par courriel (case à cocher dans la fiche de l'employé).")
        End If

        Dim adresseEnvoi = Expediteur()
        Dim repondreA = lot.Txt("CompagnieCourriel")

        Dim bilan As New Bilan()
        Using client = FabriqueClient()()
            For Each d As DataRow In destinataires.Rows
                Dim nom = d.Txt("Prenom") & " " & d.Txt("Nom")
                If Not d.IsNull("TalonEnvoyeLe") AndAlso Not renvoyer Then
                    bilan.DejaEnvoyes += 1
                    Continue For
                End If
                If d.Txt("Courriel").Length = 0 Then
                    bilan.Erreurs.Add(nom & " : " & Tr("aucun courriel dans la fiche."))
                    Continue For
                End If

                ' Le talon part dans la langue de l'employé, pas dans celle de la personne qui fait la paie.
                Dim langue = d.Txt("Langue").ToLowerInvariant()
                If Not I18n.Valide(langue) Then langue = "fr"
                Dim paieId = d.Ent("PaieId")
                Dim compagnie = lot.Txt("CompagnieNom")
                Try
                    Using message As New MailMessage()
                        ' Le courriel part TOUJOURS de 60sec.ca, au nom de l'employeur.
                        ' Écrire l'adresse de la compagnie dans le From ferait échouer
                        ' les vérifications SPF et DMARC de son domaine : le talon
                        ' n'arriverait pas, et sans que personne ne le sache.
                        message.From = New MailAddress(adresseEnvoi, lot.Txt("CompagnieNom"))
                        If repondreA.Length > 0 Then message.ReplyToList.Add(New MailAddress(repondreA, lot.Txt("CompagnieNom")))
                        message.To.Add(New MailAddress(d.Txt("Courriel"), nom))
                        message.Subject = I18n.Traduire("Talon de paie du " & TexteDate(lot("DatePaie")), langue)
                        message.SubjectEncoding = Encoding.UTF8
                        message.BodyEncoding = Encoding.UTF8
                        message.IsBodyHtml = True
                        message.Body = I18n.DansLaLangue(langue, Function() I18n.TraduireHtml(CorpsHtml(paieId, nom, compagnie, langue)))
                        Joindre(message, paieId, langue)
                        client.Send(message)
                    End Using
                    Db.Exec("UPDATE paie.Paie SET TalonEnvoyeLe = sysdatetime() WHERE Id = @p", Db.P("@p", d.Ent("PaieId")))
                    bilan.Envoyes += 1
                Catch ex As FormatException
                    bilan.Erreurs.Add(nom & " : " & Tr("adresse de courriel invalide."))
                Catch ex As SmtpException
                    bilan.Erreurs.Add(nom & " : " & ex.Message)
                End Try
            Next
        End Using

        If bilan.Envoyes > 0 Then
            Contexte.Journaliser(bilan.Envoyes.ToString() & " talon(s) de la paie du " & TexteDate(lot("DatePaie")) & " envoyé(s) par courriel.",
                                 "~/Paie/Detail.aspx?lot=" & lotId.ToString())
        End If
        Return bilan
    End Function

    ''' <summary>
    ''' L'adresse d'envoi. Tous les courriels de 60secPaie partent de 60sec.ca.
    '''
    ''' Mettre l'adresse de l'employeur dans le From reviendrait à écrire en son
    ''' nom depuis un serveur que son domaine n'autorise pas : SPF et DMARC font
    ''' alors rejeter le message, ou le classent en indésirable. Un talon de paie
    ''' qui n'arrive pas est pire qu'un talon en retard, parce que personne ne
    ''' s'en aperçoit. L'employeur est nommé — il apparaît comme expéditeur et
    ''' reçoit les réponses par le Reply-To —, mais l'envoi, lui, vient d'ici.
    '''
    ''' Une clé Courriel:Expediteur hors de 60sec.ca est refusée : une erreur de
    ''' configuration ne doit pas pouvoir contourner la règle en silence.
    ''' </summary>
    Public Shared Function Expediteur() As String
        Dim adresse = ConfigurationManager.AppSettings("Courriel:Expediteur")
        If String.IsNullOrWhiteSpace(adresse) Then Return ExpediteurParDefaut
        adresse = adresse.Trim()
        If Not adresse.EndsWith("@" & DomaineAutorise, StringComparison.OrdinalIgnoreCase) AndAlso
           Not adresse.EndsWith("." & DomaineAutorise, StringComparison.OrdinalIgnoreCase) Then
            Throw New SaisieInvalideException(
                "L'expéditeur configuré (" & adresse & ") n'appartient pas au domaine " & DomaineAutorise &
                " : les courriels de 60secPaie ne peuvent partir d'ailleurs.")
        End If
        Return adresse
    End Function

    ''' <summary>
    ''' Joint le talon en PDF. Le corps du message reste lisible tel quel — on
    ''' consulte son talon sans rien ouvrir —, et le PDF est ce qui s'imprime,
    ''' se classe et s'envoie à un tiers sans traîner la mise en page d'un
    ''' courriel derrière lui.
    ''' </summary>
    Private Shared Sub Joindre(message As MailMessage, paieId As Integer, langue As String)
        Dim d = RenduPaie.Lire(paieId)
        If Not d.Trouve Then Return

        Dim contenu As Byte() = Nothing
        Dim nomFichier As String = "talon.pdf"
        I18n.DansLaLangue(langue, Function()
                                      contenu = TalonPdf.Produire(d)
                                      nomFichier = TalonPdf.NomFichier(d)
                                      Return ""
                                  End Function)
        If contenu Is Nothing Then Return
        message.Attachments.Add(New Attachment(New MemoryStream(contenu), nomFichier, "application/pdf"))
    End Sub

    ''' <summary>Courriel autonome : les styles sont dans le message, car la feuille de style du site n'est pas accessible au destinataire.</summary>
    Private Shared Function CorpsHtml(paieId As Integer, nomEmploye As String, compagnie As String, langue As String) As String
        Dim sb As New StringBuilder()
        sb.Append("<!DOCTYPE html><html lang=""").Append(langue).Append("""><head><meta charset=""utf-8""/><style>")
        sb.Append("body{font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1d2733}")
        sb.Append("table{border-collapse:collapse;width:100%;margin-bottom:12px}th{text-align:left;border-bottom:1px solid #1d2733;padding:4px 6px;font-size:12px}")
        sb.Append("td{padding:4px 6px;border-bottom:1px solid #e3e7eb}.num{text-align:right}.note{color:#5b6877;font-size:12px}")
        sb.Append(".talon-entete{border-bottom:2px solid #1d2733;padding-bottom:8px;margin-bottom:12px}.talon-entete div{margin-bottom:8px}")
        sb.Append(".talon-net{background:#eef6fa;padding:10px 14px;font-size:17px;font-weight:bold}.talon-net span{margin-right:24px}")
        sb.Append(".avertissement,.message{display:none}</style></head><body>")
        sb.Append("<p>Bonjour ").Append(HttpUtility.HtmlEncode(nomEmploye)).Append(",</p><p>Voici votre talon de paie.</p>")
        sb.Append(RenduPaie.Talon(paieId))
        sb.Append("<p class=""note"">Ce message contient des renseignements personnels et confidentiels. Si vous l'avez reçu par erreur, ")
        ' « …aviser Boulangerie Lévesque inc. » : le nom porte déjà son point.
        sb.Append("veuillez le supprimer et en aviser ").Append(HttpUtility.HtmlEncode(SansPointFinal(compagnie))).Append(".</p></body></html>")
        Return sb.ToString()
    End Function

End Class
