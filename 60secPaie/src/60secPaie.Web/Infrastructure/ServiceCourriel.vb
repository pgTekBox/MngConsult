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
            "SELECT p.Id AS PaieId, p.TalonEnvoyeLe, e.Prenom, e.Nom, e.Courriel FROM paie.Paie p JOIN paie.LotPaie l ON l.Id = p.LotPaieId " &
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

        Dim expediteur = ConfigurationManager.AppSettings("Courriel:Expediteur")
        If String.IsNullOrWhiteSpace(expediteur) Then expediteur = lot.Txt("CompagnieCourriel")
        If String.IsNullOrWhiteSpace(expediteur) Then
            Throw New SaisieInvalideException("Aucune adresse d'expéditeur : inscrivez le courriel de la compagnie ou la clé Courriel:Expediteur de Web.config.")
        End If

        Dim bilan As New Bilan()
        Using client = FabriqueClient()()
            For Each d As DataRow In destinataires.Rows
                Dim nom = d.Txt("Prenom") & " " & d.Txt("Nom")
                If Not d.IsNull("TalonEnvoyeLe") AndAlso Not renvoyer Then
                    bilan.DejaEnvoyes += 1
                    Continue For
                End If
                If d.Txt("Courriel").Length = 0 Then
                    bilan.Erreurs.Add(nom & " : aucun courriel dans la fiche.")
                    Continue For
                End If

                Try
                    Using message As New MailMessage()
                        message.From = New MailAddress(expediteur, lot.Txt("CompagnieNom"))
                        message.To.Add(New MailAddress(d.Txt("Courriel"), nom))
                        message.Subject = "Talon de paie du " & TexteDate(lot("DatePaie"))
                        message.SubjectEncoding = Encoding.UTF8
                        message.BodyEncoding = Encoding.UTF8
                        message.IsBodyHtml = True
                        message.Body = CorpsHtml(d.Ent("PaieId"), nom, lot.Txt("CompagnieNom"))
                        client.Send(message)
                    End Using
                    Db.Exec("UPDATE paie.Paie SET TalonEnvoyeLe = sysdatetime() WHERE Id = @p", Db.P("@p", d.Ent("PaieId")))
                    bilan.Envoyes += 1
                Catch ex As FormatException
                    bilan.Erreurs.Add(nom & " : adresse de courriel invalide.")
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

    ''' <summary>Courriel autonome : les styles sont dans le message, car la feuille de style du site n'est pas accessible au destinataire.</summary>
    Private Shared Function CorpsHtml(paieId As Integer, nomEmploye As String, compagnie As String) As String
        Dim sb As New StringBuilder()
        sb.Append("<!DOCTYPE html><html lang=""fr""><head><meta charset=""utf-8""/><style>")
        sb.Append("body{font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1d2733}")
        sb.Append("table{border-collapse:collapse;width:100%;margin-bottom:12px}th{text-align:left;border-bottom:1px solid #1d2733;padding:4px 6px;font-size:12px}")
        sb.Append("td{padding:4px 6px;border-bottom:1px solid #e3e7eb}.num{text-align:right}.note{color:#5b6877;font-size:12px}")
        sb.Append(".talon-entete{border-bottom:2px solid #1d2733;padding-bottom:8px;margin-bottom:12px}.talon-entete div{margin-bottom:8px}")
        sb.Append(".talon-net{background:#eef6fa;padding:10px 14px;font-size:17px;font-weight:bold}.talon-net span{margin-right:24px}")
        sb.Append(".avertissement,.message{display:none}</style></head><body>")
        sb.Append("<p>Bonjour ").Append(HttpUtility.HtmlEncode(nomEmploye)).Append(",</p><p>Voici votre talon de paie.</p>")
        sb.Append(RenduPaie.Talon(paieId))
        sb.Append("<p class=""note"">Ce message contient des renseignements personnels et confidentiels. Si vous l'avez reçu par erreur, ")
        sb.Append("veuillez le supprimer et en aviser ").Append(HttpUtility.HtmlEncode(compagnie)).Append(".</p></body></html>")
        Return sb.ToString()
    End Function

End Class
