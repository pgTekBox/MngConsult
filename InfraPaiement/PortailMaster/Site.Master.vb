''' <summary>
''' Page maître de la zone authentifiée du portail.
''' Centralise l'entête (marque, navigation, utilisateur, déconnexion) et
''' la garde d'authentification : toute page de contenu qui utilise ce
''' master est automatiquement protégée.
''' </summary>
Public Class SiteMaster
    Inherits System.Web.UI.MasterPage

    ''' <summary>Accès aux propriétés de session/BD via la page de contenu (qui hérite de clsData).</summary>
    Private ReadOnly Property Data() As clsData
        Get
            Return TryCast(Me.Page, clsData)
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Garde d'authentification pour toute la zone protégée.
        If Data Is Nothing OrElse Not Data.IsAuthenticated Then
            Dim ret As String = Request.RawUrl
            Response.Redirect("~/wbfLogin.aspx?ReturnUrl=" & Server.UrlEncode(ret))
            Return
        End If

        If Not IsPostBack Then
            litUser.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(Data.AdminName), Data.AdminEmail, Data.AdminName))
            navPartenaires.Visible = Data.AdminIsSuperAdmin
            navUsers.Visible = Data.AdminIsSuperAdmin
            navAudit.Visible = Data.AdminIsSuperAdmin
            HighlightNav()
        End If
    End Sub

    ''' <summary>Marque l'onglet de navigation correspondant à la page courante.</summary>
    Private Sub HighlightNav()
        Dim page As String = System.IO.Path.GetFileName(Request.Path).ToLowerInvariant()
        Select Case page
            Case "default.aspx"
                navDash.Attributes("class") = "active"
            Case "wbfsupervision.aspx"
                navSup.Attributes("class") = "active"
            Case "wbfabonnes.aspx", "wbfabonne.aspx"
                navAbonnes.Attributes("class") = "active"
            Case "wbfeftbatches.aspx"
                navEft.Attributes("class") = "active"
            Case "wbfrapprochement.aspx"
                navRec.Attributes("class") = "active"
            Case "wbfpartenaires.aspx"
                navPartenaires.Attributes("class") = "active"
            Case "wbfutilisateurs.aspx", "wbfutilisateur.aspx"
                navUsers.Attributes("class") = "active"
            Case "wbfaudit.aspx"
                navAudit.Attributes("class") = "active"
        End Select
    End Sub

    Protected Sub btnLogout_Click(sender As Object, e As EventArgs)
        If Data IsNot Nothing Then
            If Data.AdminId > 0 Then
                clsAudit.Write(Data.AdminId, Data.AdminEmail, "Logout", "PortalAdmin", Data.AdminId, Data.AdminEmail, Nothing, Request.UserHostAddress)
            End If
            Data.SignOut()
        End If
        Response.Redirect("~/wbfLogin.aspx")
    End Sub

End Class
