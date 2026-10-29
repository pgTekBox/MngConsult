Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Fiche d'un dossier (compagnie cliente) du Portail comptable : en-tête,
''' affectation (membre/équipe), répartition « Qui fait quoi » (tuiles Client /
''' Cabinet / Partagé), et actions (Entrer, Gérer la répartition). Lisible par
''' tout membre du périmètre (s0937 renvoie vide si hors périmètre).
''' </summary>
Public Class wbfCabFiche
    Inherits clsData

    Protected WithEvents litInit As System.Web.UI.WebControls.Literal
    Protected WithEvents litNom As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litAssign As System.Web.UI.WebControls.Literal
    Protected WithEvents litActions As System.Web.UI.WebControls.Literal
    Protected WithEvents litQfqT As System.Web.UI.WebControls.Literal
    Protected WithEvents litQfq As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        Dim g As Guid
        If Not Guid.TryParse(If(Request.QueryString("company"), ""), g) Then
            Response.Redirect("~/wbfCabDossiers.aspx") : Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", g))
        Dim ds As DataSet = ExecuteSQLds("s0937GetDossierDetail", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ' Hors périmètre ou inexistant
            Response.Redirect("~/wbfCabDossiers.aspx") : Return
        End If

        Rendre(ds.Tables(0).Rows(0), g)
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function EstGestionnaire() As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0919GetUserCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim role As String = Convert.ToString(ds.Tables(0).Rows(0)("Role")).Trim().ToLowerInvariant()
                Return role = "admin" OrElse role = "solo" OrElse role = "responsable"
            End If
        Catch
        End Try
        Return False
    End Function

    Private Sub Rendre(r As DataRow, g As Guid)
        Dim nom As String = Convert.ToString(r("Name"))
        Dim code As String = Convert.ToString(r("CompanyCode"))
        Dim legal As String = If(IsDBNull(r("LegalName")), "", Convert.ToString(r("LegalName")))

        litInit.Text = Server.HtmlEncode(Initiales(nom))
        litNom.Text = Server.HtmlEncode(nom)
        Dim sous As String = code
        If legal <> "" AndAlso Not String.Equals(legal, nom, StringComparison.OrdinalIgnoreCase) Then sous = code & " · " & legal
        litSous.Text = Server.HtmlEncode(sous)

        ' Affectation
        Dim sb As New StringBuilder()
        Dim membre As String = If(IsDBNull(r("MembreNom")), "", Convert.ToString(r("MembreNom")))
        Dim equipe As String = If(IsDBNull(r("EquipeNom")), "", Convert.ToString(r("EquipeNom")))
        If membre <> "" Then
            sb.Append("<span class=""tag m"">").Append(Server.HtmlEncode(T("Suivi par ", "Handled by ", "A cargo de ") & membre)).Append("</span>")
        Else
            sb.Append("<span class=""tag none"">").Append(Server.HtmlEncode(T("Non confié", "Unassigned", "Sin asignar"))).Append("</span>")
        End If
        If equipe <> "" Then sb.Append("<span class=""tag t"">").Append(Server.HtmlEncode(equipe)).Append("</span>")
        litAssign.Text = sb.ToString()

        ' Actions
        Dim acts As New StringBuilder()
        acts.Append("<a class=""btn p"" href=""").Append(ResolveUrl("~/wbfCabDossiers.aspx?enter=" & Server.UrlEncode(g.ToString()))).Append(""">")
        acts.Append(Server.HtmlEncode(T("Entrer dans le dossier", "Enter the file", "Entrar en el expediente")))
        acts.Append(" <svg aria-hidden=""true"" width=""16"" height=""16"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.4"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M5 12h14M13 6l6 6-6 6""/></svg></a>")
        acts.Append("<a class=""btn s"" href=""").Append(ResolveUrl("~/wbfCabActivites.aspx?company=" & Server.UrlEncode(g.ToString()))).Append(""">")
        acts.Append(Server.HtmlEncode(T("Gérer la répartition", "Manage the split", "Gestionar el reparto"))).Append("</a>")
        If Not EstGestionnaire() Then
            ' (membre employé sans droit de gestion : la répartition reste consultable)
        End If
        litActions.Text = acts.ToString()

        ' Répartition QFQ
        litQfqT.Text = Server.HtmlEncode(T("Qui fait quoi", "Who does what", "Quién hace qué"))
        Dim nbCli As Integer = IntOf(r, "NbClient")
        Dim nbCab As Integer = IntOf(r, "NbCabinet")
        Dim nbPar As Integer = IntOf(r, "NbPartage")
        Dim q As New StringBuilder()
        q.Append(Tuile("cli", nbCli, T("Le client", "The client", "El cliente")))
        q.Append(Tuile("cab", nbCab, T("Le cabinet", "The firm", "El despacho")))
        q.Append(Tuile("par", nbPar, T("Partagé", "Shared", "Compartido")))
        litQfq.Text = q.ToString()
    End Sub

    Private Function Tuile(cls As String, n As Integer, lbl As String) As String
        Return "<div class=""k " & cls & """><div class=""n"">" & n.ToString() & "</div><div class=""l"">" & Server.HtmlEncode(lbl) & "</div></div>"
    End Function

    Private Shared Function IntOf(r As DataRow, col As String) As Integer
        If IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
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
