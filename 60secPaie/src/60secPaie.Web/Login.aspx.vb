Imports System.Web.Security

''' <summary>Connexion avec les comptes de MngConsul (dbo.T015User).</summary>
Public Class PageConnexion
    Inherits System.Web.UI.Page

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        litLangues.Text = I18n.SelecteurLangues(Request)
    End Sub

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        I18n.RendreTraduit(writer, Sub(w) MyBase.Render(w))
    End Sub

    Private Sub Afficher(message As String)
        pnlErreur.Visible = True
        litErreur.Text = Server.HtmlEncode(message)
    End Sub

    Private Sub btnConnexion_Click(sender As Object, e As EventArgs) Handles btnConnexion.Click
        Dim courriel = txtCourriel.Text.Trim().ToLowerInvariant()

        Select Case ServiceConnexion.Authentifier(courriel, txtMotDePasse.Text)
            Case ServiceConnexion.Issue.Verrouillee
                Afficher("Trop de tentatives. Réessayez dans quelques minutes.")
            Case ServiceConnexion.Issue.AucuneCompagnie
                Afficher("Votre compte n'est associé à aucune compagnie dans MngConsul.")
            Case ServiceConnexion.Issue.Refusee
                Afficher("Courriel ou mot de passe invalide.")
            Case Else
                Dim langue = I18n.Langue
                Session.Clear()
                I18n.Langue = langue
                FormsAuthentication.RedirectFromLoginPage(courriel, False)
        End Select
    End Sub

End Class
