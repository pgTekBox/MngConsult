Public Class _Default
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("wbfLogin.aspx")

        End If
    End Sub
End Class