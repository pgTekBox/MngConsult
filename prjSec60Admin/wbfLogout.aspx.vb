Imports System.Web.Security

Public Class wbfLogout
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        FormsAuthentication.SignOut()
        Session.Clear()
        Session.Abandon()
        Response.Redirect("~/wbfLogin.aspx")
    End Sub

End Class
