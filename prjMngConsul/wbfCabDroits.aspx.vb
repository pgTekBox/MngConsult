Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Droits par activité, par domaine (Portail comptable, admin/solo) : matrice
''' membres × domaines. Déclaratif (qui prend en charge quels domaines). Procs
''' s0947GetDroits / s0948SetDroit. Domaines = liste fixe calquée sur les blocs QFQ.
''' </summary>
Public Class wbfCabDroits
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents rptMembres As System.Web.UI.WebControls.Repeater
    Protected WithEvents litVide As System.Web.UI.WebControls.Literal
    Protected WithEvents btnSave As System.Web.UI.WebControls.Button
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal

    Private Shared ReadOnly Domaines As String() = {"agenda", "ventes", "depenses", "argent", "taxes", "impots", "societe", "employes", "metier"}
    Private _droits As HashSet(Of String)   ' "userguid|domaine" accordés

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        Dim role As String = RoleCabinet()
        If role <> "admin" AndAlso role <> "solo" Then
            Response.Redirect("~/wbfCabTableauBord.aspx") : Return
        End If

        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        ChargerDroits()
        Textes()
        If Not IsPostBack Then BindMembres()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function RoleCabinet() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0919GetUserCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Convert.ToString(ds.Tables(0).Rows(0)("Role")).Trim().ToLowerInvariant()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Sub Textes()
        litTitre.Text = Server.HtmlEncode(T("Droits par activité", "Activity rights", "Derechos por actividad"))
        litSous.Text = Server.HtmlEncode(T("Qui, dans votre cabinet, prend en charge quels domaines d'activités.",
                                           "Who, in your firm, handles which activity domains.",
                                           "Quién, en su despacho, se encarga de qué dominios de actividad."))
        btnSave.Text = T("Enregistrer", "Save", "Guardar")
    End Sub

    Private Function DomaineLabel(code As String) As String
        Select Case code
            Case "agenda" : Return T("Agenda", "Agenda", "Agenda")
            Case "ventes" : Return T("Ventes", "Sales", "Ventas")
            Case "depenses" : Return T("Dépenses", "Expenses", "Gastos")
            Case "argent" : Return T("Argent", "Money", "Dinero")
            Case "taxes" : Return T("Taxes", "Sales taxes", "Impuestos de venta")
            Case "impots" : Return T("Impôts", "Income tax", "Renta")
            Case "societe" : Return T("Société", "Corporation", "Sociedad")
            Case "employes" : Return T("Employés", "Employees", "Empleados")
            Case "metier" : Return T("Métier", "Trade", "Oficio")
            Case Else : Return code
        End Select
    End Function

    Private Sub ChargerDroits()
        _droits = New HashSet(Of String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0947GetDroits", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    _droits.Add(Convert.ToString(r("UserGUID")).ToLowerInvariant() & "|" & Convert.ToString(r("Domaine")))
                Next
            End If
        Catch
        End Try
    End Sub

    Private Sub BindMembres()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptMembres.DataSource = dt
        rptMembres.DataBind()
        litVide.Text = If(dt.Rows.Count = 0, "<div class=""vide"">" & Server.HtmlEncode(T("Aucun membre.", "No member.", "Ningún miembro.")) & "</div>", "")
    End Sub

    Protected Sub rptMembres_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return
        Dim row As DataRowView = CType(e.Item.DataItem, DataRowView)
        Dim uid As String = Convert.ToString(row("UserGUID")).ToLowerInvariant()
        Dim cbl As CheckBoxList = CType(e.Item.FindControl("cblDom"), CheckBoxList)
        cbl.Items.Clear()
        For Each code As String In Domaines
            Dim it As New ListItem(DomaineLabel(code), code)
            it.Selected = _droits.Contains(uid & "|" & code)
            cbl.Items.Add(it)
        Next
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        ChargerDroits()   ' état courant en base, pour n'écrire que les différences
        Dim nb As Integer = 0
        For Each item As RepeaterItem In rptMembres.Items
            Dim hf As HiddenField = CType(item.FindControl("hfUser"), HiddenField)
            Dim cbl As CheckBoxList = CType(item.FindControl("cblDom"), CheckBoxList)
            If hf Is Nothing OrElse cbl Is Nothing Then Continue For
            Dim uid As String = If(hf.Value, "").ToLowerInvariant()
            For Each it As ListItem In cbl.Items
                Dim present As Boolean = _droits.Contains(uid & "|" & it.Value)
                If it.Selected = present Then Continue For
                Dim p As New Collection
                p.Add(New SqlParameter("@UserId", UserEmail))
                p.Add(New SqlParameter("@MembreUserGUID", New Guid(hf.Value)))
                p.Add(New SqlParameter("@Domaine", it.Value))
                p.Add(New SqlParameter("@Accorde", it.Selected))
                Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                p.Add(outErr)
                ExecuteSQL("s0948SetDroit", p)
                nb += 1
            Next
        Next
        litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(
            If(nb = 0, T("Aucun changement.", "No change.", "Sin cambios."),
               T("Droits enregistrés.", "Rights saved.", "Derechos guardados."))) & "</div>"
    End Sub

    Protected Function NomMembre(first As Object, last As Object, email As Object) As String
        Dim nom As String = (Convert.ToString(first) & " " & Convert.ToString(last)).Trim()
        If nom = "" Then nom = Convert.ToString(email)
        Return Server.HtmlEncode(nom)
    End Function

End Class
