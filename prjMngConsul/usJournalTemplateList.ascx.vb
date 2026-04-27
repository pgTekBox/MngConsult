


Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class usJournalTemplateList
    Inherits clsDataUC

    ' =========================================================
    '  PAGE LOAD
    ' =========================================================

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            LoadJournauxFilter()
            BindList()
        End If
    End Sub

    ' =========================================================
    '  CHARGEMENT FILTRE JOURNAL
    ' =========================================================

    Sub LoadJournauxFilter()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0114Get_Journaux", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        For Each row As DataRow In ds.Tables(0).Rows
            cbJournalFilter.Items.Add(New RadComboBoxItem(
                row("DisplayName").ToString(),
                row("Id").ToString()))
        Next
    End Sub

    ' =========================================================
    '  CHARGEMENT DE LA LISTE
    ' =========================================================

    ''' <summary>
    ''' Charge la liste des templates depuis la BD selon les filtres.
    ''' Procédure : s0120SearchTemplates
    ''' Retourne : Id, Code, Libelle, Description, JournauxId, JournalCode,
    '''            JournalLibelle, MontantsPreRemplis, Actif, NbLignes, search
    ''' </summary>
    Sub BindList()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search",
            If(String.IsNullOrEmpty(txtSearch.Text), CType(DBNull.Value, Object), txtSearch.Text.Trim())))
        p.Add(New SqlParameter("@OnlyActive", If(chkOnlyActive.Checked, 1, 0)))
        p.Add(New SqlParameter("@JournauxId",
            If(String.IsNullOrEmpty(cbJournalFilter.SelectedValue),
               CType(DBNull.Value, Object), CInt(cbJournalFilter.SelectedValue))))

        Dim ds As DataSet = ExecuteSQLds("s0120SearchTemplates", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            rpTemplates.DataSource = Nothing
            rpTemplates.DataBind()
            pnlEmpty.Visible = True
            lblCount.Text = "0"
            Return
        End If

        pnlEmpty.Visible = False
        rpTemplates.DataSource = ds.Tables(0)
        rpTemplates.DataBind()
        lblCount.Text = ds.Tables(0).Rows.Count.ToString()
    End Sub

    ' =========================================================
    '  ACTIONS
    ' =========================================================

    Private Sub btnFilter_Click(sender As Object, e As EventArgs) Handles btnFilter.Click
        BindList()
    End Sub

    Private Sub rpTemplates_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rpTemplates.ItemCommand
        If e.CommandName = "DeleteTemplate" Then
            Dim id As Integer = Convert.ToInt32(e.CommandArgument)
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@TemplateId", id))
                ExecuteSQL("s0124DeleteTemplate", p)
            Catch ex As Exception
                Dim safe As String = ex.Message.Replace("'", "\'").Replace(Chr(13), " ").Replace(Chr(10), " ")
                ScriptManager.RegisterStartupScript(Page, Page.GetType(),
                    "alert_" & Guid.NewGuid().ToString("N"),
                    "alert('Erreur : " & safe & "');", True)
                Return
            End Try
            BindList()
        End If
    End Sub



End Class