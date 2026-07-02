Public Class LeftMenu
    Inherits System.Web.UI.UserControl

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Affiche le courriel de l'administrateur connecté (session posée par wbfLogin).
        Dim email As String = TryCast(Session("AdminEmail"), String)
        If String.IsNullOrEmpty(email) AndAlso Context.User IsNot Nothing AndAlso Context.User.Identity.IsAuthenticated Then
            email = Context.User.Identity.Name
        End If
        litAdminEmail.Text = Server.HtmlEncode(If(email, ""))
    End Sub

End Class
