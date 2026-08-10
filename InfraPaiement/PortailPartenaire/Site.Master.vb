''' <summary>
''' Page maître de la zone authentifiée du portail des partenaires.
''' Centralise l'entête (marque, navigation, partenaire/utilisateur,
''' deconnexion) et la garde d'authentification : toute page de contenu qui
''' utilise ce master est automatiquement protégée et scopée au partenaire
''' connecté.
''' </summary>
Public Class SiteMaster
    Inherits System.Web.UI.MasterPage

    Protected WithEvents navDash As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navAbonnes As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navApi As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents litPartenaire As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litUser As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents btnLogout As Global.System.Web.UI.WebControls.LinkButton

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
            litPartenaire.Text = Server.HtmlEncode(Data.PartenaireName)
            litUser.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(Data.UserName), Data.UserEmail, Data.UserName))
            ' Gestion des cles d'API reservee aux administrateurs du partenaire.
            navApi.Visible = Data.IsPartnerAdmin
            HighlightNav()
        End If
    End Sub

    ''' <summary>Marque l'onglet de navigation correspondant à la page courante.</summary>
    Private Sub HighlightNav()
        Dim page As String = System.IO.Path.GetFileName(Request.Path).ToLowerInvariant()
        Select Case page
            Case "default.aspx" : navDash.Attributes("class") = "active"
            Case "wbfabonnes.aspx", "wbfabonne.aspx" : navAbonnes.Attributes("class") = "active"
            Case "wbfapikeys.aspx" : navApi.Attributes("class") = "active"
        End Select
    End Sub

    Protected Sub btnLogout_Click(sender As Object, e As EventArgs)
        If Data IsNot Nothing Then Data.SignOut()
        Response.Redirect("~/wbfLogin.aspx")
    End Sub

End Class
