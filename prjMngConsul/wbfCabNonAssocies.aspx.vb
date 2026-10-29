Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Clients non associés (Portail comptable, admin/solo) : les dossiers du cabinet
''' pas encore confiés à un membre (s0920 filtré AssignedUserGUID NULL), avec
''' « Confier à… » (s0930AssignDossier). Membres via s0922.
''' </summary>
Public Class wbfCabNonAssocies
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents rptDossiers As System.Web.UI.WebControls.Repeater
    Protected WithEvents litVide As System.Web.UI.WebControls.Literal

    Private _membres As DataTable

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

        ChargerMembres()
        Textes()
        If Not IsPostBack Then BindDossiers()
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
        litTitre.Text = Server.HtmlEncode(T("Clients non associés", "Unassigned clients", "Clientes sin asignar"))
        litSous.Text = Server.HtmlEncode(T("Vos dossiers pas encore confiés à un membre. Confiez chacun à quelqu'un.",
                                           "Your files not yet assigned to a member. Assign each to someone.",
                                           "Sus expedientes aún sin asignar. Asigne cada uno a alguien."))
    End Sub

    Private Sub ChargerMembres()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
        _membres = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
    End Sub

    Private Sub BindDossiers()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0920ListCabinetDossiers", p)

        Dim dt As New DataTable()
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            dt = ds.Tables(0).Clone()
            For Each r As DataRow In ds.Tables(0).Rows
                If IsDBNull(r("AssignedUserGUID")) Then dt.ImportRow(r)
            Next
        End If

        rptDossiers.DataSource = dt
        rptDossiers.DataBind()
        litVide.Text = If(dt.Rows.Count = 0, "<div class=""vide"">" & Server.HtmlEncode(T("Tous vos dossiers sont confiés.", "All your files are assigned.", "Todos sus expedientes están asignados.")) & "</div>", "")
    End Sub

    Protected Sub rptDossiers_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return
        Dim ddl As DropDownList = CType(e.Item.FindControl("ddlMembre"), DropDownList)
        ddl.Items.Clear()
        ddl.Items.Add(New ListItem(T("Choisir un membre…", "Choose a member…", "Elegir un miembro…"), ""))
        If _membres IsNot Nothing Then
            For Each m As DataRow In _membres.Rows
                Dim nom As String = (Convert.ToString(m("FirstName")) & " " & Convert.ToString(m("LastName"))).Trim()
                If nom = "" Then nom = Convert.ToString(m("Email"))
                ddl.Items.Add(New ListItem(nom, Convert.ToString(m("UserGUID"))))
            Next
        End If
    End Sub

    Protected Sub rptDossiers_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "confier" Then Return
        Dim g As Guid
        If Not Guid.TryParse(Convert.ToString(e.CommandArgument), g) Then Return

        Dim ddl As DropDownList = CType(e.Item.FindControl("ddlMembre"), DropDownList)
        If String.IsNullOrEmpty(ddl.SelectedValue) Then
            litMsg.Text = "<div class=""msg"" style=""background:#FDECEA;color:#A3261C"">" & Server.HtmlEncode(T("Choisissez d'abord un membre.", "Choose a member first.", "Elija primero un miembro.")) & "</div>"
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", g))
        p.Add(New SqlParameter("@AssignedUserGUID", New Guid(ddl.SelectedValue)))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0930AssignDossier", p)

        BindDossiers()
        litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(T("Dossier confié.", "File assigned.", "Expediente asignado.")) & "</div>"
    End Sub

    Protected ReadOnly Property LblConfier As String
        Get
            Return T("Confier", "Assign", "Asignar")
        End Get
    End Property

End Class
