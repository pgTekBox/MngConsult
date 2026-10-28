Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' « Mes dossiers » du Portail comptable : la liste des compagnies clientes du
''' cabinet, scopée par le rôle du comptable connecté (s0920). Recherche côté
''' client. Le bouton « Entrer » (lien ?enter=GUID) valide l'accès (s0211), quitte
''' le portail et pointe la compagnie, puis renvoie au tableau de bord ERP normal.
''' Réservé aux comptables ; sinon redirection vers Default.aspx.
''' </summary>
Public Class wbfCabDossiers
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litOutils As System.Web.UI.WebControls.Literal
    Protected WithEvents litListe As System.Web.UI.WebControls.Literal
    Protected WithEvents litVide As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Action « Entrer » : rejoindre une compagnie et quitter le portail.
        Dim enter As String = Request.QueryString("enter")
        If Not String.IsNullOrEmpty(enter) Then
            EntrerDansDossier(enter)
            Return
        End If

        ' Sinon on reste dans l'espace du cabinet.
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then Charger()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>Valide l'accès (s0211) puis bascule sur la compagnie et sort du portail.</summary>
    Private Sub EntrerDansDossier(guidStr As String)
        Dim g As Guid
        If Not Guid.TryParse(guidStr, g) Then
            Response.Redirect("~/wbfCabDossiers.aspx")
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", g))
        Dim outAccess As New SqlParameter("@HasAccess", SqlDbType.Bit)
        outAccess.Direction = ParameterDirection.Output
        p.Add(outAccess)
        ExecuteSQL("s0211ValidateCompanyAccess", p)

        Dim hasAccess As Boolean = False
        If outAccess.Value IsNot Nothing AndAlso Not IsDBNull(outAccess.Value) Then hasAccess = CBool(outAccess.Value)

        If Not hasAccess Then
            ' Accès refusé : rester dans le portail.
            Response.Redirect("~/wbfCabDossiers.aspx")
            Return
        End If

        EnPortailComptable = False
        Company = g
        Response.Redirect("~/Default.aspx")
    End Sub

    Private Sub Charger()
        litTitre.Text = Server.HtmlEncode(T("Mes dossiers", "My files", "Mis expedientes"))
        litSous.Text = Server.HtmlEncode(T("Les compagnies dont vous vous occupez. Entrez dans un dossier pour y travailler.",
                                           "The companies you handle. Enter a file to work in it.",
                                           "Las empresas de las que se ocupa. Entre en un expediente para trabajar en él."))

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))

        Dim sb As New StringBuilder()
        Dim total As Integer = 0
        Try
            Dim ds As DataSet = ExecuteSQLds("s0920ListCabinetDossiers", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    sb.Append(Carte(r))
                    total += 1
                Next
            End If
        Catch ex As Exception
            sb.Append("<div class=""doss-vide"">" & Server.HtmlEncode(T("La liste n'a pas pu être lue : ", "The list could not be read: ", "No se pudo leer la lista: ") & ex.Message) & "</div>")
        End Try

        litListe.Text = sb.ToString()
        litVide.Text = Server.HtmlEncode(T("Aucun dossier ne correspond à votre recherche.", "No file matches your search.", "Ningún expediente coincide con su búsqueda."))

        ' Barre d'outils : recherche + décompte
        litOutils.Text = "<div class=""cab-outils"">" &
            "<label class=""cab-recherche""><svg aria-hidden=""true"" width=""18"" height=""18"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.2"" stroke-linecap=""round"" stroke-linejoin=""round""><circle cx=""11"" cy=""11"" r=""7""/><path d=""M21 21l-4.3-4.3""/></svg>" &
            "<input type=""search"" id=""dossRecherche"" autocomplete=""off"" placeholder=""" &
            Server.HtmlEncode(T("Rechercher un dossier…", "Search a file…", "Buscar un expediente…")) & """ /></label>" &
            "<span class=""cab-compte"" id=""dossCompte"" data-un=""" & Server.HtmlEncode(T("{0} dossier", "{0} file", "{0} expediente")) &
            """ data-plusieurs=""" & Server.HtmlEncode(T("{0} dossiers", "{0} files", "{0} expedientes")) & """></span></div>"
    End Sub

    Private Function Carte(r As DataRow) As String
        Dim guid As String = Convert.ToString(r("CompanyGUID"))
        Dim nom As String = Convert.ToString(r("Name"))
        Dim code As String = Convert.ToString(r("CompanyCode"))
        Dim equipe As String = ""
        If Not IsDBNull(r("EquipeNom")) Then equipe = Convert.ToString(r("EquipeNom"))

        Dim sous As String = code
        If equipe <> "" Then sous = code & " · " & equipe

        Dim txt As String = nom & " " & code & " " & equipe
        Dim href As String = ResolveUrl("~/wbfCabDossiers.aspx?enter=" & Server.UrlEncode(guid))

        Dim sb As New StringBuilder()
        sb.Append("<article class=""doss-carte"" data-txt=""").Append(Server.HtmlEncode(txt)).Append(""">")
        sb.Append("<div class=""doss-top""><span class=""doss-av"">").Append(Server.HtmlEncode(Initiales(nom))).Append("</span><div>")
        sb.Append("<h2>").Append(Server.HtmlEncode(nom)).Append("</h2>")
        sb.Append("<div class=""doss-sous"">").Append(Server.HtmlEncode(sous)).Append("</div></div></div>")
        sb.Append("<div class=""doss-actions""><a class=""doss-entrer"" href=""").Append(href).Append(""">")
        sb.Append(Server.HtmlEncode(T("Entrer", "Enter", "Entrar")))
        sb.Append(" <svg aria-hidden=""true"" width=""16"" height=""16"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.4"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M5 12h14M13 6l6 6-6 6""/></svg></a></div>")
        sb.Append("</article>")
        Return sb.ToString()
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return sb.ToString()
    End Function

End Class
