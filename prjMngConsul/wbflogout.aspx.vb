Public Class wbflogout
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Révoquer le jeton « Se souvenir de moi » (cookie + base) avant de fermer la session.
        clsRememberMe.Clear(Context)
        Session.Clear()
        Session.Abandon()
        Response.Redirect("~/wbfLogin.aspx")

    End Sub

End Class