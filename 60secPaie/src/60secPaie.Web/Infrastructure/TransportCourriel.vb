Imports System.Configuration
Imports System.Data.SqlClient
Imports System.IO
Imports System.Net.Mail
Imports System.Text

''' <summary>Un courriel prêt à partir, sans rien savoir de la façon dont il partira.</summary>
Public Class CourrielSortant
    Public Property Destinataire As String = ""
    Public Property NomDestinataire As String = ""
    Public Property Expediteur As String = ""
    Public Property NomExpediteur As String = ""
    Public Property RepondreA As String = ""
    Public Property Sujet As String = ""
    Public Property CorpsHtml As String = ""
    Public Property PiecesJointes As New List(Of PieceJointeCourriel)()
End Class

Public Class PieceJointeCourriel
    Public Property Nom As String = ""
    Public Property Contenu As Byte()
    Public Property TypeMime As String = "application/octet-stream"
End Class

''' <summary>Par où sort un courriel. Deux chemins, un seul contrat.</summary>
Public Interface ITransportCourriel
    Sub Envoyer(courriel As CourrielSortant)
    ReadOnly Property Description As String
End Interface

''' <summary>
''' Le chemin de production : le courriel est DÉPOSÉ dans la base MailService, et
''' le service Windows SrvAI le remet lui-même aux serveurs de destination.
'''
''' C'est le même service que celui de l'ERP, et c'est délibéré : un seul point
''' d'envoi pour la plateforme veut dire un seul domaine à faire autoriser (SPF,
''' DKIM), un seul journal à consulter quand un courriel n'arrive pas, et une
''' seule file à reprendre après une panne. 60secPaie ne parle à aucun serveur
''' SMTP et ne détient aucun mot de passe de messagerie.
'''
''' Déposer n'est pas envoyer : la procédure rend la main dès l'insertion, et la
''' remise a lieu au cycle suivant de SrvAI, dans la minute. Un échec de remise
''' se lit dans MailService, pas ici.
''' </summary>
Public Class TransportServiceMail
    Implements ITransportCourriel

    Public ReadOnly Property Description As String Implements ITransportCourriel.Description
        Get
            Return "service d'envoi de la plateforme (MailService)"
        End Get
    End Property

    Public Sub Envoyer(courriel As CourrielSortant) Implements ITransportCourriel.Envoyer
        ' Le service lit l'expéditeur réel dans Sender ; From le suit pour que les
        ' deux disent la même chose.
        Dim id = DbMail.Procedure("s0610InsertOutboundMail",
            Db.P("@To", courriel.Destinataire),
            Db.P("@Subject", courriel.Sujet),
            Db.P("@HTMLBody", courriel.CorpsHtml),
            Db.P("@Sender", courriel.Expediteur),
            Db.P("@From", courriel.Expediteur),
            Db.P("@ReplyTo", If(courriel.RepondreA.Length > 0, courriel.RepondreA, Nothing)))

        If id Is Nothing Then
            Throw New SaisieInvalideException("Le service d'envoi n'a pas retourné d'identifiant de courriel.")
        End If

        Dim mailId = Convert.ToInt32(id)
        For Each piece In courriel.PiecesJointes
            DbMail.Procedure("s1579InsertAttachemnt_A",
                Db.P("@FileName", piece.Nom),
                Db.P("@content", piece.Contenu),
                Db.P("@MailId", mailId),
                Db.P("@ContentType", piece.TypeMime),
                Db.P("@ContentId", ""))
        Next
    End Sub

End Class

''' <summary>
''' Le chemin de développement : un client SMTP ordinaire, qui en pratique écrit
''' des fichiers .eml dans un dossier plutôt que d'envoyer quoi que ce soit. Il
''' sert à regarder ce qui partirait, sans rien envoyer à personne.
''' </summary>
Public Class TransportSmtp
    Implements ITransportCourriel

    Private ReadOnly fabrique As Func(Of SmtpClient)

    Public Sub New(fabrique As Func(Of SmtpClient))
        Me.fabrique = fabrique
    End Sub

    Public ReadOnly Property Description As String Implements ITransportCourriel.Description
        Get
            Return "SMTP"
        End Get
    End Property

    Public Sub Envoyer(courriel As CourrielSortant) Implements ITransportCourriel.Envoyer
        Using client = fabrique(), message As New MailMessage()
            message.From = New MailAddress(courriel.Expediteur, courriel.NomExpediteur)
            If courriel.RepondreA.Length > 0 Then message.ReplyToList.Add(New MailAddress(courriel.RepondreA, courriel.NomExpediteur))
            message.To.Add(New MailAddress(courriel.Destinataire, courriel.NomDestinataire))
            message.Subject = courriel.Sujet
            message.SubjectEncoding = Encoding.UTF8
            message.BodyEncoding = Encoding.UTF8
            message.IsBodyHtml = True
            message.Body = courriel.CorpsHtml
            For Each piece In courriel.PiecesJointes
                message.Attachments.Add(New Attachment(New MemoryStream(piece.Contenu), piece.Nom, piece.TypeMime))
            Next
            client.Send(message)
        End Using
    End Sub

End Class
