''' <summary>
''' Page maître de la zone authentifiée du portail des abonnes.
''' Centralise l'entête (marque, navigation, abonne/utilisateur, deconnexion)
''' et la garde d'authentification : toute page de contenu qui utilise ce
''' master est automatiquement protégée et scopée a l'abonne connecte.
''' </summary>
Public Class SiteMaster
    Inherits System.Web.UI.MasterPage

    Protected WithEvents navDash As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navClients As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navFourn As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navEnc As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navDec As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navReleve As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navApi As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navHooks As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents navUsers As Global.System.Web.UI.HtmlControls.HtmlAnchor
    Protected WithEvents litAbonne As Global.System.Web.UI.WebControls.Literal
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
            litAbonne.Text = Server.HtmlEncode(Data.AbonneName)
            litUser.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(Data.UserName), Data.UserEmail, Data.UserName))
            ' Gestion API/Webhooks/Utilisateurs reservee aux administrateurs de l'abonne.
            navApi.Visible = Data.IsAbonneAdmin
            navHooks.Visible = Data.IsAbonneAdmin
            navUsers.Visible = Data.IsAbonneAdmin
            HighlightNav()
        End If
    End Sub

    ''' <summary>Marque l'onglet de navigation correspondant à la page courante.</summary>
    Private Sub HighlightNav()
        Dim page As String = System.IO.Path.GetFileName(Request.Path).ToLowerInvariant()
        Select Case page
            Case "default.aspx" : navDash.Attributes("class") = "active"
            Case "wbfclients.aspx" : navClients.Attributes("class") = "active"
            Case "wbffournisseurs.aspx" : navFourn.Attributes("class") = "active"
            Case "wbfencaissements.aspx" : navEnc.Attributes("class") = "active"
            Case "wbfdecaissements.aspx" : navDec.Attributes("class") = "active"
            Case "wbfreleve.aspx" : navReleve.Attributes("class") = "active"
            Case "wbfapikeys.aspx" : navApi.Attributes("class") = "active"
            Case "wbfwebhooks.aspx" : navHooks.Attributes("class") = "active"
            Case "wbfutilisateurs.aspx", "wbfutilisateur.aspx" : navUsers.Attributes("class") = "active"
        End Select
    End Sub

    Protected Sub btnLogout_Click(sender As Object, e As EventArgs)
        If Data IsNot Nothing Then Data.SignOut()
        Response.Redirect("~/wbfLogin.aspx")
    End Sub

End Class
