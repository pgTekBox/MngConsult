Imports System.Web.Security

Public Class SiteMaster
    Inherits System.Web.UI.MasterPage

    Private Sub Page_Init(sender As Object, e As EventArgs) Handles Me.Init
        ' Protection CSRF : lie le ViewState à l'utilisateur connecté.
        Page.ViewStateUserKey = Contexte.Utilisateur
    End Sub

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' La feuille de style porte la date de sa dernière modification : un navigateur qui
        ' l'avait en cache la recharge dès qu'elle change (sinon l'assistant flottant, par
        ' exemple, apparaîtrait sans ses styles jusqu'à expiration du cache).
        lnkCss.Href = ResolveUrl("~/Content/site.css") & "?v=" & IO.File.GetLastWriteTimeUtc(Server.MapPath("~/Content/site.css")).Ticks.ToString()
        Dim compte = Contexte.Compte
        If compte IsNot Nothing Then
            lblUtilisateur.Text = Server.HtmlEncode(If(compte.Txt("NomComplet").Length > 0, compte.Txt("NomComplet"), compte.Txt("Courriel")))
            lblUtilisateur.ToolTip = compte.Txt("Courriel")
        End If
        litLangues.Text = I18n.SelecteurLangues(Request)
        lnkAideHaut.HRef = I18n.CheminAide()
        lnkAidePied.HRef = I18n.CheminAide()

        If Not IsPostBack Then RemplirCompagnies()

        ' Le nom et l'adresse de la compagnie viennent de MngConsul : on les recopie une fois par session et par compagnie.
        Dim courante = Contexte.CompanyGuid
        If Not courante.Equals(Session("CompagnieSynchronisee")) Then
            Contexte.SynchroniserCompagnie()
            Session("CompagnieSynchronisee") = courante
        End If

        Dim chemin = Request.AppRelativeCurrentExecutionFilePath.ToLowerInvariant()
        Activer(lnkTableau, chemin = "~/default.aspx")
        Activer(lnkPaie, chemin = "~/paie/calculer.aspx")
        Activer(lnkHistorique, chemin.StartsWith("~/paie/") AndAlso chemin <> "~/paie/calculer.aspx")
        Activer(lnkRemises, chemin.StartsWith("~/remises/"))
        Activer(lnkRapports, chemin.StartsWith("~/rapports/"))
        Activer(lnkEmployes, chemin.StartsWith("~/employes/"))
        Activer(lnkConfig, chemin.StartsWith("~/config/"))
        Activer(lnkAssistant, chemin = "~/assistant.aspx")
    End Sub

    ''' <summary>Une compagnie : son nom. Plusieurs (utilisateur comptable dans MngConsul) : liste déroulante.</summary>
    Private Sub RemplirCompagnies()
        Dim compagnies = Contexte.Compagnies
        If compagnies.Rows.Count > 1 Then
            ddlCompagnie.Visible = True
            lblCompagnie.Visible = False
            ddlCompagnie.Items.Clear()
            For Each c As DataRow In compagnies.Rows
                ddlCompagnie.Items.Add(New ListItem(c.Txt("Name"), DirectCast(c("CompanyGUID"), Guid).ToString()))
            Next
            Dim courante = ddlCompagnie.Items.FindByValue(Contexte.CompanyGuid.ToString())
            If courante IsNot Nothing Then ddlCompagnie.SelectedValue = courante.Value
        Else
            lblCompagnie.Text = Server.HtmlEncode(Contexte.NomCompagnie)
        End If
    End Sub

    Private Sub ddlCompagnie_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlCompagnie.SelectedIndexChanged
        Dim nouvelle As Guid
        ' L'accès est revalidé côté serveur : la valeur de la liste ne suffit pas.
        If Guid.TryParse(ddlCompagnie.SelectedValue, nouvelle) AndAlso Contexte.ChangerCompagnie(nouvelle) Then
            Contexte.SynchroniserCompagnie()
        End If
        ' On repart du tableau de bord : la page courante peut pointer vers une donnée de l'autre compagnie.
        Response.Redirect("~/Default.aspx", True)
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
