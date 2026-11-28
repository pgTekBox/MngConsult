Imports System.Web.Security

Public Class wbfLogout
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        FormsAuthentication.SignOut()
        clsAdminRememberMe.Clear(Context)   ' oublie aussi « Se souvenir de moi »
        Session.Clear()
        Session.Abandon()
        Response.Redirect("~/wbfLogin.aspx")
    End Sub

End Class
