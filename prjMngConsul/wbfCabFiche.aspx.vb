Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Fiche d'un dossier (Portail comptable), en onglets : Vue (affectation +
''' répartition QFQ), Tâches (suivi d'avancement), Journal, Échanges, Préparer la
''' rencontre, Miroir. Accès borné au périmètre (s0937 renvoie vide sinon).
''' Tâches/journal : s0942/s0943/s0944/s0945.
''' </summary>
Public Class wbfCabFiche
    Inherits clsData

    Protected WithEvents litInit As System.Web.UI.WebControls.Literal
    Protected WithEvents litNom As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litAssign As System.Web.UI.WebControls.Literal
    Protected WithEvents litOnglets As System.Web.UI.WebControls.Literal
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents pnlVue As System.Web.UI.WebControls.Panel
    Protected WithEvents litQfqT As System.Web.UI.WebControls.Literal
    Protected WithEvents litQfq As System.Web.UI.WebControls.Literal
    Protected WithEvents litActions As System.Web.UI.WebControls.Literal
    Protected WithEvents pnlTaches As System.Web.UI.WebControls.Panel
    Protected WithEvents litLblTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblAssigne As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblEcheance As System.Web.UI.WebControls.Literal
    Protected WithEvents txtTitre As System.Web.UI.WebControls.TextBox
    Protected WithEvents ddlAssigne As System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtEcheance As System.Web.UI.WebControls.TextBox
    Protected WithEvents btnAddTache As System.Web.UI.WebControls.Button
    Protected WithEvents rptTaches As System.Web.UI.WebControls.Repeater
    Protected WithEvents litTachesVide As System.Web.UI.WebControls.Literal
    Protected WithEvents pnlJournal As System.Web.UI.WebControls.Panel
    Protected WithEvents litJournal As System.Web.UI.WebControls.Literal
    Protected WithEvents pnlAvenir As System.Web.UI.WebControls.Panel
    Protected WithEvents litAvenir As System.Web.UI.WebControls.Literal

    Private _g As Guid

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not Guid.TryParse(If(Request.QueryString("company"), ""), _g) Then
            Response.Redirect("~/wbfCabDossiers.aspx") : Return
        End If

        ' En-tête + garde d'accès (s0937 vide = hors périmètre)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", _g))
        Dim ds As DataSet = ExecuteSQLds("s0937GetDossierDetail", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Response.Redirect("~/wbfCabDossiers.aspx") : Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)
        RendreEntete(r)
        RendreOnglets()

        Dim tab As String = OngletActif()
        If Not IsPostBack Then
            Select Case tab
                Case "taches"
                    pnlTaches.Visible = True : Textes() : BindAssignes() : BindTaches()
                Case "journal"
                    pnlJournal.Visible = True : BindJournal()
                Case "echanges"
                    pnlAvenir.Visible = True : litAvenir.Text = Server.HtmlEncode(T("Échanges — à venir.", "Messages — coming soon.", "Intercambios — próximamente."))
                Case "preparer"
                    pnlAvenir.Visible = True : litAvenir.Text = Server.HtmlEncode(T("Préparer la rencontre — à venir.", "Meeting prep — coming soon.", "Preparar la reunión — próximamente."))
                Case "miroir"
                    pnlAvenir.Visible = True : litAvenir.Text = Server.HtmlEncode(T("Ce que voit le client — à venir.", "What the client sees — coming soon.", "Lo que ve el cliente — próximamente."))
                Case Else
                    pnlVue.Visible = True : RendreVue(r)
            End Select
        Else
            ' Postback : on est sur l'onglet Tâches (seul à poster) ; garder visible.
            pnlTaches.Visible = True : Textes()
        End If
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function OngletActif() As String
        Dim o As String = If(Request.QueryString("onglet"), "vue").ToLowerInvariant()
        Select Case o
            Case "taches", "journal", "echanges", "preparer", "miroir" : Return o
            Case Else : Return "vue"
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

    ' ---- En-tête + onglets ----
    Private Sub RendreEntete(r As DataRow)
        Dim nom As String = Convert.ToString(r("Name"))
        Dim code As String = Convert.ToString(r("CompanyCode"))
        Dim legal As String = If(IsDBNull(r("LegalName")), "", Convert.ToString(r("LegalName")))
        litInit.Text = Server.HtmlEncode(Initiales(nom))
        litNom.Text = Server.HtmlEncode(nom)
        Dim sous As String = code
        If legal <> "" AndAlso Not String.Equals(legal, nom, StringComparison.OrdinalIgnoreCase) Then sous = code & " · " & legal
        litSous.Text = Server.HtmlEncode(sous)

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
    End Sub

    Private Sub RendreOnglets()
        Dim tab As String = OngletActif()
        Dim items As (k As String, lbl As String)() = {
            ("vue", T("Vue", "Overview", "Vista")),
            ("taches", T("Tâches", "Tasks", "Tareas")),
            ("journal", T("Journal", "Log", "Registro")),
            ("echanges", T("Échanges", "Messages", "Intercambios")),
            ("preparer", T("Préparer la rencontre", "Meeting prep", "Preparar la reunión")),
            ("miroir", T("Ce que voit le client", "Client view", "Vista del cliente"))
        }
        Dim sb As New StringBuilder()
        Dim g As String = _g.ToString()
        For Each it In items
            Dim cls As String = If(it.k = tab, " class=""on""", "")
            Dim href As String = ResolveUrl("~/wbfCabFiche.aspx?company=" & Server.UrlEncode(g) & "&onglet=" & it.k)
            sb.Append("<a").Append(cls).Append(" href=""").Append(href).Append(""">").Append(Server.HtmlEncode(it.lbl)).Append("</a>")
        Next
        litOnglets.Text = sb.ToString()
    End Sub

    ' ---- Onglet Vue ----
    Private Sub RendreVue(r As DataRow)
        litQfqT.Text = Server.HtmlEncode(T("Qui fait quoi", "Who does what", "Quién hace qué"))
        Dim q As New StringBuilder()
        q.Append(Tuile("cli", IntOf(r, "NbClient"), T("Le client", "The client", "El cliente")))
        q.Append(Tuile("cab", IntOf(r, "NbCabinet"), T("Le cabinet", "The firm", "El despacho")))
        q.Append(Tuile("par", IntOf(r, "NbPartage"), T("Partagé", "Shared", "Compartido")))
        litQfq.Text = q.ToString()

        Dim g As String = _g.ToString()
        Dim a As New StringBuilder()
        a.Append("<a class=""btn p"" href=""").Append(ResolveUrl("~/wbfCabDossiers.aspx?enter=" & Server.UrlEncode(g))).Append(""">")
        a.Append(Server.HtmlEncode(T("Entrer dans le dossier", "Enter the file", "Entrar en el expediente")))
        a.Append(" <svg aria-hidden=""true"" width=""16"" height=""16"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.4"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M5 12h14M13 6l6 6-6 6""/></svg></a>")
        a.Append("<a class=""btn s"" href=""").Append(ResolveUrl("~/wbfCabActivites.aspx?company=" & Server.UrlEncode(g))).Append(""">")
        a.Append(Server.HtmlEncode(T("Gérer la répartition", "Manage the split", "Gestionar el reparto"))).Append("</a>")
        litActions.Text = a.ToString()
    End Sub

    ' ---- Onglet Tâches ----
    Private Sub Textes()
        litLblTitre.Text = Server.HtmlEncode(T("Nouvelle tâche", "New task", "Nueva tarea"))
        litLblAssigne.Text = Server.HtmlEncode(T("Assignée à", "Assigned to", "Asignada a"))
        litLblEcheance.Text = Server.HtmlEncode(T("Échéance", "Due date", "Vencimiento"))
        btnAddTache.Text = T("Ajouter", "Add", "Añadir")
    End Sub

    Private Sub BindAssignes()
        ddlAssigne.Items.Clear()
        ddlAssigne.Items.Add(New ListItem(T("— Personne —", "— Nobody —", "— Nadie —"), ""))
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each m As DataRow In ds.Tables(0).Rows
                    Dim nm As String = (Convert.ToString(m("FirstName")) & " " & Convert.ToString(m("LastName"))).Trim()
                    If nm = "" Then nm = Convert.ToString(m("Email"))
                    ddlAssigne.Items.Add(New ListItem(nm, Convert.ToString(m("UserGUID"))))
                Next
            End If
        Catch
        End Try
    End Sub

    Private Sub BindTaches()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", _g))
        Dim ds As DataSet = ExecuteSQLds("s0942ListTaches", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptTaches.DataSource = dt
        rptTaches.DataBind()
        litTachesVide.Text = If(dt.Rows.Count = 0, "<div class=""vide"">" & Server.HtmlEncode(T("Aucune tâche.", "No task.", "Ninguna tarea.")) & "</div>", "")
    End Sub

    Protected Sub btnAddTache_Click(sender As Object, e As EventArgs) Handles btnAddTache.Click
        Dim titre As String = txtTitre.Text.Trim()
        If titre = "" Then
            litMsg.Text = "<div class=""msg"" style=""background:#FDECEA;color:#A3261C"">" & Server.HtmlEncode(T("Donnez un titre à la tâche.", "Give the task a title.", "Dé un título a la tarea.")) & "</div>"
            BindTaches() : Return
        End If
        Dim assigne As Object = DBNull.Value
        If Not String.IsNullOrEmpty(ddlAssigne.SelectedValue) Then assigne = New Guid(ddlAssigne.SelectedValue)
        Dim ech As Object = DBNull.Value
        Dim d As Date
        If Date.TryParse(txtEcheance.Text, d) Then ech = d.Date

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Id", 0))
        p.Add(New SqlParameter("@CompanyGUID", _g))
        p.Add(New SqlParameter("@Titre", titre))
        p.Add(New SqlParameter("@Description", DBNull.Value))
        p.Add(New SqlParameter("@AssignedUserGUID", assigne))
        p.Add(New SqlParameter("@Echeance", ech))
        p.Add(New SqlParameter("@Statut", "afaire"))
        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outNew) : p.Add(outErr)
        ExecuteSQL("s0943SaveTache", p)

        txtTitre.Text = "" : txtEcheance.Text = "" : ddlAssigne.SelectedIndex = 0
        BindTaches()
        litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(T("Tâche ajoutée.", "Task added.", "Tarea añadida.")) & "</div>"
    End Sub

    Protected Sub rptTaches_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptTaches.ItemCommand
        If e.CommandName <> "st" Then Return
        Dim parts As String() = Convert.ToString(e.CommandArgument).Split("|"c)
        If parts.Length <> 2 Then Return
        Dim id As Integer
        If Not Integer.TryParse(parts(0), id) Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@Statut", parts(1)))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0944SetStatutTache", p)
        BindTaches()
    End Sub

    ' ---- Onglet Journal ----
    Private Sub BindJournal()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", _g))
        Dim ds As DataSet = ExecuteSQLds("s0945ListJournal", p)
        Dim sb As New StringBuilder()
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                Dim quand As String = Convert.ToDateTime(r("Utc")).ToLocalTime().ToString("yyyy-MM-dd HH:mm")
                Dim par As String = If(IsDBNull(r("ParNom")), "", Convert.ToString(r("ParNom"))).Trim()
                sb.Append("<div class=""jrow""><div class=""jd"">").Append(Server.HtmlEncode(quand)).Append("</div><div class=""jt"">")
                sb.Append(Server.HtmlEncode(Convert.ToString(r("Texte"))))
                If par <> "" Then sb.Append(" <span class=""jp"">— ").Append(Server.HtmlEncode(par)).Append("</span>")
                sb.Append("</div></div>")
            Next
        Else
            sb.Append("<div class=""vide"">").Append(Server.HtmlEncode(T("Rien au journal pour l'instant.", "Nothing in the log yet.", "Nada en el registro aún."))).Append("</div>")
        End If
        litJournal.Text = sb.ToString()
    End Sub

    ' ---- Helpers ----
    Private Function Tuile(cls As String, n As Integer, lbl As String) As String
        Return "<div class=""k " & cls & """><div class=""n"">" & n.ToString() & "</div><div class=""l"">" & Server.HtmlEncode(lbl) & "</div></div>"
    End Function

    Protected Function MetaTache(assigne As Object, ech As Object) As String
        Dim parts As New List(Of String)
        Dim a As String = If(assigne Is Nothing OrElse IsDBNull(assigne), "", Convert.ToString(assigne)).Trim()
        If a <> "" Then parts.Add(T("Assignée à ", "Assigned to ", "Asignada a ") & a)
        If ech IsNot Nothing AndAlso Not IsDBNull(ech) Then parts.Add(T("échéance ", "due ", "vence ") & Convert.ToDateTime(ech).ToString("yyyy-MM-dd"))
        If parts.Count = 0 Then Return Server.HtmlEncode(T("Non assignée", "Unassigned", "Sin asignar"))
        Return Server.HtmlEncode(String.Join(" · ", parts))
    End Function

    Protected Function StatutLabel(s As Object) As String
        Select Case Convert.ToString(s)
            Case "encours" : Return Server.HtmlEncode(T("En cours", "In progress", "En curso"))
            Case "fait" : Return Server.HtmlEncode(T("Fait", "Done", "Hecho"))
            Case "bloque" : Return Server.HtmlEncode(T("Bloqué", "Blocked", "Bloqueado"))
            Case Else : Return Server.HtmlEncode(T("À faire", "To do", "Por hacer"))
        End Select
    End Function

    Protected ReadOnly Property LblEnCours As String
        Get
            Return T("En cours", "In progress", "En curso")
        End Get
    End Property
    Protected ReadOnly Property LblFait As String
        Get
            Return T("Fait", "Done", "Hecho")
        End Get
    End Property
    Protected ReadOnly Property LblBloque As String
        Get
            Return T("Bloqué", "Blocked", "Bloqueado")
        End Get
    End Property

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
