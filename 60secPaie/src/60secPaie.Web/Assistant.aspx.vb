Imports System.Text
Imports System.Text.RegularExpressions

''' <summary>
''' L'assistant IA d'une compagnie. La conversation vit en session (elle
''' recommence à la connexion suivante) ; chaque échange est journalisé par
''' AssistantIA. Le profil et ses particularités s'entretiennent dans la
''' colonne de droite.
''' </summary>
Public Class PageAssistant
    Inherits PageBase

    Private Const CleSession As String = "AssistantIA"

    Private ReadOnly Property Historique As List(Of TourIA)
        Get
            Dim h = TryCast(Session(CleSession), List(Of TourIA))
            If h Is Nothing Then
                h = New List(Of TourIA)()
                Session(CleSession) = h
            End If
            Return h
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then txtParticularites.Text = ServiceProfilIA.Particularites()
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        AfficherConversation()
        AfficherProfil()
    End Sub

    Private Sub AfficherConversation()
        Dim h = Historique
        pnlVide.Visible = h.Count = 0
        Dim sb As New StringBuilder()
        For Each t In h
            sb.Append("<div class='ia-tour ").Append(If(t.Role = "user", "user", "assistant")).Append("'><div><div class='ia-bulle'>")
            sb.Append(EnHtml(t.Texte)).Append("</div><div class='ia-quand'>").Append(t.Quand.ToString("HH:mm")).Append("</div></div></div>")
        Next
        litMessages.Text = sb.ToString()
        litCout.Text = Server.HtmlEncode(Tr("Coût des questions ce mois-ci : {0} US$", AssistantIA.CoutDuMois().ToString("N4")))
    End Sub

    Private Sub AfficherProfil()
        Dim quand = ServiceProfilIA.GenereLe()
        litProfilInfo.Text = Server.HtmlEncode(If(quand.HasValue, Tr("Profil généré le {0}.", quand.Value.ToString("yyyy-MM-dd HH:mm")), Tr("Le profil sera généré à la première question.")))

        Dim sb As New StringBuilder()
        For Each l In ServiceProfilIA.Legende()
            sb.Append("<div><b>").Append(l.Code).Append("</b> ").Append(Server.HtmlEncode(l.Nom)).Append(If(l.Actif, "", " <span class='note'>(" & Server.HtmlEncode(Tr("inactif")) & ")</span>")).Append("</div>")
        Next
        litLegende.Text = If(sb.Length = 0, Server.HtmlEncode(Tr("Aucun employé.")), sb.ToString())

        Dim profil = Convert.ToString(Db.Scalaire("SELECT ProfilGenere FROM paie.ProfilIA WHERE CompagnieId = @c", Db.P("@c", Contexte.CompagnieId)))
        litProfil.Text = If(profil.Length = 0, Server.HtmlEncode(Tr("Pas encore généré.")), Server.HtmlEncode(profil))
    End Sub

    ''' <summary>La réponse en HTML sûr : texte encodé, gras **…**, retours de ligne conservés par la feuille de style.</summary>
    Private Function EnHtml(texte As String) As String
        Dim s = Server.HtmlEncode(If(texte, ""))
        s = Regex.Replace(s, "\*\*(.+?)\*\*", "<b>$1</b>")
        Return s
    End Function

    Private Async Sub btnEnvoyer_Click(sender As Object, e As EventArgs) Handles btnEnvoyer.Click
        Dim question = txtQuestion.Text.Trim()
        If question.Length = 0 Then
            Erreur(Tr("Écrivez une question."))
            Return
        End If
        Try
            Dim r = Await AssistantIA.DemanderAsync(question, Historique, I18n.Langue)
            Historique.Add(New TourIA With {.Role = "user", .Texte = question, .Quand = Date.Now})
            Historique.Add(New TourIA With {.Role = "assistant", .Texte = r.Texte, .Quand = Date.Now})
            txtQuestion.Text = ""
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        Catch ex As Exception
            Erreur(Tr("L'assistant n'a pas pu répondre : {0}", ex.Message))
        End Try
    End Sub

    Private Sub btnNouvelle_Click(sender As Object, e As EventArgs) Handles btnNouvelle.Click
        Session.Remove(CleSession)
        txtQuestion.Text = ""
    End Sub

    Private Sub btnParticularites_Click(sender As Object, e As EventArgs) Handles btnParticularites.Click
        ServiceProfilIA.EnregistrerParticularites(txtParticularites.Text.Trim())
        Succes(Tr("Particularités enregistrées : l'assistant en tiendra compte dès la prochaine question."))
    End Sub

    Private Sub btnActualiser_Click(sender As Object, e As EventArgs) Handles btnActualiser.Click
        ServiceProfilIA.Obtenir(forcer:=True)
        Succes(Tr("Profil actualisé."))
    End Sub

End Class
