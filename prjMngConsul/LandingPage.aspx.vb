Imports System
Imports System.Web.UI

Partial Public Class LandingPage
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Aucun traitement requis au chargement
    End Sub



    Protected Sub lnkConnexion_Click(sender As Object, e As EventArgs) Handles lnkConnexion.Click
        ' Redirection vers la page de connexion
        Response.Redirect("wbfLogin.aspx")
    End Sub

    Protected Sub btnDemarrer_Click(sender As Object, e As EventArgs) Handles btnDemarrer.Click
        ' Redirection vers l'inscription depuis le CTA
        Response.Redirect("Inscription.aspx")
    End Sub

End Class