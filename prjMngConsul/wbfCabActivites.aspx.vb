Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Activités à attribuer (répartition « Qui fait quoi ») pour un dossier donné du
''' Portail comptable. Réutilise les paramètres de compagnie QUIFAITQUOI : lecture
''' s0150GetParamsForCompany, écriture s0151UpdateParamValue. Accès borné au
''' périmètre du cabinet (s0937GetDossierDetail renvoie vide sinon). Écriture
''' réservée admin/solo/responsable.
''' </summary>
Public Class wbfCabActivites
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litLegCli As System.Web.UI.WebControls.Literal
    Protected WithEvents litLegCab As System.Web.UI.WebControls.Literal
    Protected WithEvents litLegPar As System.Web.UI.WebControls.Literal
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents rptActs As System.Web.UI.WebControls.Repeater
    Protected WithEvents btnSave As System.Web.UI.WebControls.Button
    Protected WithEvents btnSaveTop As System.Web.UI.WebControls.Button

    Private Property CompanyId As Guid
        Get
            Dim g As Guid
            If Guid.TryParse(CStr(If(ViewState("cg"), "")), g) Then Return g
            Return Guid.Empty
        End Get
        Set(value As Guid)
            ViewState("cg") = value.ToString()
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then
            Dim g As Guid
            If Not Guid.TryParse(If(Request.QueryString("company"), ""), g) Then
                Response.Redirect("~/wbfCabDossiers.aspx") : Return
            End If

            ' Garde d'accès + en-tête via s0937 (vide si hors périmètre)
            Dim nom As String = DossierNom(g)
            If nom Is Nothing Then
                Response.Redirect("~/wbfCabDossiers.aspx") : Return
            End If
            CompanyId = g
            Textes(nom)
            BindActs()
        End If
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>Nom du dossier si accessible (s0937), sinon Nothing.</summary>
    Private Function DossierNom(g As Guid) As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            p.Add(New SqlParameter("@CompanyGUID", g))
            Dim ds As DataSet = ExecuteSQLds("s0937GetDossierDetail", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Convert.ToString(ds.Tables(0).Rows(0)("Name"))
            End If
        Catch
        End Try
        Return Nothing
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

    Private Sub Textes(nom As String)
        litTitre.Text = Server.HtmlEncode(T("Activités à attribuer", "Activities to assign", "Actividades por asignar"))
        litSous.Text = Server.HtmlEncode(T("Pour ", "For ", "Para ") & nom & T(" — qui fait chaque activité : le client, le cabinet, ou les deux.",
                                                                               " — who does each activity: the client, the firm, or both.",
                                                                               " — quién hace cada actividad: el cliente, el despacho, o ambos."))
        litLegCli.Text = Server.HtmlEncode(T("Le client", "The client", "El cliente"))
        litLegCab.Text = Server.HtmlEncode(T("Le cabinet", "The firm", "El despacho"))
        litLegPar.Text = Server.HtmlEncode(T("Partagé", "Shared", "Compartido"))
        btnSave.Text = T("Enregistrer", "Save", "Guardar")
        btnSaveTop.Text = btnSave.Text
        Dim lecteur As Boolean = Not EstGestionnaire()
        btnSave.Visible = Not lecteur
        btnSaveTop.Visible = Not lecteur
    End Sub

    Private Sub BindActs()
        rptActs.DataSource = LireParams()
        rptActs.DataBind()
    End Sub

    Private Function LireParams() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", CompanyId))
        p.Add(New SqlParameter("@Categorie", "QUIFAITQUOI"))
        Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return New DataTable()
        ' Trier par Ordre si présent
        Dim dt As DataTable = ds.Tables(0)
        If dt.Columns.Contains("Ordre") Then
            Dim dv As New DataView(dt)
            dv.Sort = "Ordre ASC"
            Return dv.ToTable()
        End If
        Return dt
    End Function

    Protected Sub rptActs_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return
        Dim row As DataRowView = CType(e.Item.DataItem, DataRowView)
        Dim rbl As RadioButtonList = CType(e.Item.FindControl("rblChoix"), RadioButtonList)
        rbl.Items.Clear()
        rbl.Items.Add(New ListItem(T("Client", "Client", "Cliente"), "moi"))
        rbl.Items.Add(New ListItem(T("Cabinet", "Firm", "Despacho"), "cabinet"))
        rbl.Items.Add(New ListItem(T("Partagé", "Shared", "Compartido"), "moi+cabinet"))
        Dim cur As String = If(IsDBNull(row("sVal")), "moi", Convert.ToString(row("sVal")))
        Dim it As ListItem = rbl.Items.FindByValue(cur)
        If it IsNot Nothing Then it.Selected = True Else rbl.Items(0).Selected = True
        If Not EstGestionnaire() Then rbl.Enabled = False
    End Sub

    Private Sub Enregistrer()
        If Not EstGestionnaire() Then Return

        ' Valeurs actuelles en base pour n'écrire que les changements
        Dim actuel As New Dictionary(Of Integer, String)
        For Each r As DataRow In LireParams().Rows
            actuel(Convert.ToInt32(r("ParamId"))) = If(IsDBNull(r("sVal")), "moi", Convert.ToString(r("sVal")))
        Next

        Dim nb As Integer = 0
        For Each item As RepeaterItem In rptActs.Items
            Dim hf As HiddenField = CType(item.FindControl("hfParamId"), HiddenField)
            Dim rbl As RadioButtonList = CType(item.FindControl("rblChoix"), RadioButtonList)
            If hf Is Nothing OrElse rbl Is Nothing Then Continue For
            Dim pid As Integer
            If Not Integer.TryParse(hf.Value, pid) Then Continue For
            Dim val As String = rbl.SelectedValue
            If val = "" Then Continue For
            If actuel.ContainsKey(pid) AndAlso actuel(pid) = val Then Continue For

            Dim p As New Collection
            p.Add(New SqlParameter("@ParamId", pid))
            p.Add(New SqlParameter("@sVal", val))
            ExecuteSQL("s0151UpdateParamValue", p)
            nb += 1
        Next

        litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(
            If(nb = 0, T("Aucun changement.", "No change.", "Sin cambios."),
               T("Répartition enregistrée (", "Split saved (", "Reparto guardado (") & nb & T(" modification(s)).", " change(s)).", " cambio(s))."))) & "</div>"
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click, btnSaveTop.Click
        Enregistrer()
    End Sub

End Class
