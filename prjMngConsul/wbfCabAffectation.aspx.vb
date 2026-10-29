Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Affectation des dossiers (Portail comptable, admin/solo) : pour chaque dossier
''' (compagnie cliente du cabinet), choisir le membre et/ou l'équipe qui le suit.
''' Dossiers via s0920 (vue admin), membres via s0922, équipes via s0928,
''' enregistrement via s0930AssignDossier.
''' </summary>
Public Class wbfCabAffectation
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents litHDoss As System.Web.UI.WebControls.Literal
    Protected WithEvents litHMembre As System.Web.UI.WebControls.Literal
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

        ChargerListes()   ' membres + équipes (à chaque cycle, pour le bind des dropdowns)
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
        litTitre.Text = Server.HtmlEncode(T("Affectation des dossiers", "File assignment", "Asignación de expedientes"))
        litSous.Text = Server.HtmlEncode(T("Confiez chaque dossier à un membre.",
                                           "Assign each file to a member.",
                                           "Asigne cada expediente a un miembro."))
        litHDoss.Text = Server.HtmlEncode(T("Dossier", "File", "Expediente"))
        litHMembre.Text = Server.HtmlEncode(T("Membre", "Member", "Miembro"))
    End Sub

    Private Sub ChargerListes()
        Dim pm As New Collection
        pm.Add(New SqlParameter("@UserId", UserEmail))
        Dim dsm As DataSet = ExecuteSQLds("s0922ListCabinetMembres", pm)
        _membres = If(dsm IsNot Nothing AndAlso dsm.Tables.Count > 0, dsm.Tables(0), New DataTable())
    End Sub

    Private Sub BindDossiers()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0920ListCabinetDossiers", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptDossiers.DataSource = dt
        rptDossiers.DataBind()
        litVide.Text = If(dt.Rows.Count = 0, "<div style=""color:#44536E;font-size:14px"">" & Server.HtmlEncode(T("Aucun dossier.", "No file.", "Ningún expediente.")) & "</div>", "")
    End Sub

    Protected Sub rptDossiers_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return
        Dim row As DataRowView = CType(e.Item.DataItem, DataRowView)
        Dim ddlMembre As DropDownList = CType(e.Item.FindControl("ddlMembre"), DropDownList)

        ddlMembre.Items.Clear()
        ddlMembre.Items.Add(New ListItem(T("— Non assigné —", "— Unassigned —", "— Sin asignar —"), ""))
        If _membres IsNot Nothing Then
            For Each m As DataRow In _membres.Rows
                Dim nom As String = (Convert.ToString(m("FirstName")) & " " & Convert.ToString(m("LastName"))).Trim()
                If nom = "" Then nom = Convert.ToString(m("Email"))
                ddlMembre.Items.Add(New ListItem(nom, Convert.ToString(m("UserGUID"))))
            Next
        End If
        Dim assigned As String = If(IsDBNull(row("AssignedUserGUID")), "", Convert.ToString(row("AssignedUserGUID")))
        SelectValue(ddlMembre, assigned)
    End Sub

    Private Shared Sub SelectValue(ddl As DropDownList, value As String)
        ddl.ClearSelection()
        Dim it As ListItem = ddl.Items.FindByValue(If(value, ""))
        If it IsNot Nothing Then it.Selected = True
    End Sub

    Protected Sub rptDossiers_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "save" Then Return
        Dim g As Guid
        If Not Guid.TryParse(Convert.ToString(e.CommandArgument), g) Then Return

        Dim ddlMembre As DropDownList = CType(e.Item.FindControl("ddlMembre"), DropDownList)

        Dim membre As Object = DBNull.Value
        If Not String.IsNullOrEmpty(ddlMembre.SelectedValue) Then membre = New Guid(ddlMembre.SelectedValue)

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@CompanyGUID", g))
        p.Add(New SqlParameter("@AssignedUserGUID", membre))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0930AssignDossier", p)

        BindDossiers()
        litMsg.Text = "<div class=""msg ok"">" & Server.HtmlEncode(T("Affectation enregistrée.", "Assignment saved.", "Asignación guardada.")) & "</div>"
    End Sub

    Protected ReadOnly Property LblEnregistrer As String
        Get
            Return T("Enregistrer", "Save", "Guardar")
        End Get
    End Property

End Class
