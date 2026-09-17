Imports System.Web.Security

Public Class SiteMaster
    Inherits System.Web.UI.MasterPage

    Private Sub Page_Init(sender As Object, e As EventArgs) Handles Me.Init
        ' Protection CSRF : lie le ViewState à l'utilisateur connecté.
        Page.ViewStateUserKey = Contexte.Utilisateur
    End Sub

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        lnkCompte.Text = Server.HtmlEncode(Contexte.Utilisateur)
        If Contexte.CompagnieId > 0 Then
            lblCompagnie.Text = Server.HtmlEncode(Convert.ToString(
                Db.Scalaire("SELECT Nom FROM dbo.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))))
        End If

        Dim chemin = Request.AppRelativeCurrentExecutionFilePath.ToLowerInvariant()
        Activer(lnkTableau, chemin = "~/default.aspx")
        Activer(lnkPaie, chemin = "~/paie/calculer.aspx")
        Activer(lnkHistorique, chemin.StartsWith("~/paie/") AndAlso chemin <> "~/paie/calculer.aspx")
        Activer(lnkRemises, chemin.StartsWith("~/remises/"))
        Activer(lnkEmployes, chemin.StartsWith("~/employes/"))
        Activer(lnkConfig, chemin.StartsWith("~/config/"))
    End Sub

    Private Shared Sub Activer(lien As HtmlControls.HtmlAnchor, actif As Boolean)
        If actif Then lien.Attributes("class") = "actif"
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim flash = TryCast(Session("flash"), String)
        If flash IsNot Nothing AndAlso Not pnlMessage.Visible Then
            Session.Remove("flash")
            Afficher(flash, False)
        End If
    End Sub

    Public Sub Afficher(message As String, estErreur As Boolean)
        pnlMessage.Visible = True
        pnlMessage.CssClass = If(estErreur, "message erreur", "message succes")
        litMessage.Text = Server.HtmlEncode(message)
    End Sub

    Private Sub lnkDeconnexion_Click(sender As Object, e As EventArgs) Handles lnkDeconnexion.Click
        FormsAuthentication.SignOut()
        Session.Abandon()
        Response.Redirect("~/Login.aspx", True)
    End Sub

End Class
