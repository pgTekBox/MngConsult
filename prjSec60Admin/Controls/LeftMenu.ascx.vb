Public Class LeftMenu
    Inherits System.Web.UI.UserControl

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Affiche le courriel de l'administrateur connecté (session posée par wbfLogin).
        Dim email As String = TryCast(Session("AdminEmail"), String)
        If String.IsNullOrEmpty(email) AndAlso Context.User IsNot Nothing AndAlso Context.User.Identity.IsAuthenticated Then
            email = Context.User.Identity.Name
        End If
        litAdminEmail.Text = Server.HtmlEncode(If(email, ""))
        litAdminEmailHaut.Text = litAdminEmail.Text
        litVersion.Text = Server.HtmlEncode(TexteVersion())
    End Sub

    ''' <summary>
    ''' « v1.0.9463.13950 · compilée le 28 nov. 2026 à 07 h 45 » : la version de
    ''' l'assembly (AssemblyInfo « 1.0.* » : build = jours depuis le 1er janvier 2000,
    ''' révision = secondes depuis minuit ÷ 2), et la date de compilation qu'elle code.
    ''' </summary>
    Private Shared Function TexteVersion() As String
        Dim v As Version = GetType(LeftMenu).Assembly.GetName().Version
        Dim texte As String = "v" & v.ToString()
        If v.Build > 0 Then
            Dim compilee As DateTime = New DateTime(2000, 1, 1).AddDays(v.Build).AddSeconds(v.Revision * 2)
            texte &= " · compilée le " & compilee.ToString("d MMM yyyy 'à' HH 'h' mm", New Globalization.CultureInfo("fr-CA"))
        End If
        Return texte
    End Function

End Class
