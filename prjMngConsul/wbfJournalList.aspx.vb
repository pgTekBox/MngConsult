Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfJournalList
    Inherits clsData

    ' =========================================================
    '  PAGE LOAD
    ' =========================================================

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Période par défaut : mois en cours
            dpDateFrom.SelectedDate = New Date(Date.Today.Year, Date.Today.Month, 1)
            dpDateTo.SelectedDate = Date.Today
            cbStatusFilter.SelectedValue = ""

            LoadJournauxFilter()
            BindList()
        End If
    End Sub

    ' =========================================================
    '  CHARGEMENT DU FILTRE JOURNAL (T130Journaux)
    ' =========================================================

    ''' <summary>
    ''' Charge la liste des journaux dans le combo de filtre.
    ''' L'item "(Tous)" reste défini en ASPX et n'est pas écrasé.
    ''' </summary>
    Sub LoadJournauxFilter()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", GetCompanyGUID()))

        Dim ds As DataSet = ExecuteSQLds("s0114Get_Journaux", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        For Each row As DataRow In ds.Tables(0).Rows
            cbJournalFilter.Items.Add(New RadComboBoxItem(
                row("DisplayName").ToString(),
                row("Id").ToString()))
        Next
    End Sub

    ' =========================================================
    '  CHARGEMENT DE LA LISTE DES ÉCRITURES
    ' =========================================================

    ''' <summary>
    ''' Charge les écritures depuis la BD selon les filtres.
    ''' Procédure : s0112SearchEcritures
    ''' Retourne : Id, NumeroPiece, DateEcriture, JournauxId, JournalCode, JournalLibelle,
    '''            Libelle, Statut, SourceType, TotalDebit, TotalCredit, Created
    ''' </summary>
    Sub BindList()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", GetCompanyGUID()))
        p.Add(New SqlParameter("@DateFrom",
            If(dpDateFrom.SelectedDate.HasValue,
               CType(dpDateFrom.SelectedDate.Value, Object), DBNull.Value)))
        p.Add(New SqlParameter("@DateTo",
            If(dpDateTo.SelectedDate.HasValue,
               CType(dpDateTo.SelectedDate.Value, Object), DBNull.Value)))
        p.Add(New SqlParameter("@JournauxId",
            If(String.IsNullOrEmpty(cbJournalFilter.SelectedValue),
               CType(DBNull.Value, Object), CInt(cbJournalFilter.SelectedValue))))
        p.Add(New SqlParameter("@Statut",
            If(String.IsNullOrEmpty(cbStatusFilter.SelectedValue),
               CType(DBNull.Value, Object), cbStatusFilter.SelectedValue)))
        p.Add(New SqlParameter("@Search",
            If(String.IsNullOrEmpty(txtSearch.Text),
               CType(DBNull.Value, Object), txtSearch.Text.Trim())))

        Dim ds As DataSet = ExecuteSQLds("s0112SearchEcritures", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            rpEcritures.DataSource = Nothing
            rpEcritures.DataBind()
            pnlEmpty.Visible = True
            lblCount.Text = "0"
            lblTotalDebit.Text = "0.00"
            lblTotalCredit.Text = "0.00"
            Return
        End If

        pnlEmpty.Visible = False
        rpEcritures.DataSource = ds.Tables(0)
        rpEcritures.DataBind()

        ' Totaux pied de page
        Dim totD As Double = ds.Tables(0).AsEnumerable().Sum(
            Function(r) If(IsDBNull(r("TotalDebit")), 0D, Convert.ToDouble(r("TotalDebit"))))
        Dim totC As Double = ds.Tables(0).AsEnumerable().Sum(
            Function(r) If(IsDBNull(r("TotalCredit")), 0D, Convert.ToDouble(r("TotalCredit"))))

        lblCount.Text = ds.Tables(0).Rows.Count.ToString()
        lblTotalDebit.Text = totD.ToString("N2")
        lblTotalCredit.Text = totC.ToString("N2")
    End Sub

    ' =========================================================
    '  FILTRER / SUPPRIMER
    ' =========================================================

    Private Sub btnFilter_Click(sender As Object, e As EventArgs) Handles btnFilter.Click
        BindList()
    End Sub

    Private Sub rpEcritures_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rpEcritures.ItemCommand
        If e.CommandName = "DeleteEcriture" Then
            Dim id As Integer = Convert.ToInt32(e.CommandArgument)

            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@EcritureId", id))
                ExecuteSQL("s0113DeleteEcriture", p)
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

    ' =========================================================
    '  HELPERS POUR LE BINDING (appelés depuis l'ASPX)
    ' =========================================================

    ''' <summary>
    ''' Retourne le label affiché pour un statut.
    ''' </summary>
    Public Function GetStatutLabel(statut As Object) As String
        Dim s As String = If(IsDBNull(statut) OrElse statut Is Nothing, "BROUILLON", statut.ToString())
        Select Case s
            Case "VALIDEE" : Return "Validée"
            Case "EXTOURNEE" : Return "Extournée"
            Case Else : Return "Brouillon"
        End Select
    End Function

    ''' <summary>
    ''' Retourne la classe CSS du badge selon le statut.
    ''' </summary>
    Public Function GetStatutCssClass(statut As Object) As String
        Dim s As String = If(IsDBNull(statut) OrElse statut Is Nothing, "BROUILLON", statut.ToString())
        Select Case s
            Case "VALIDEE" : Return "badge-validee"
            Case "EXTOURNEE" : Return "badge-extournee"
            Case Else : Return "badge-brouillon"
        End Select
    End Function

    ''' <summary>
    ''' Indique si l'écriture peut être supprimée.
    ''' Seules les écritures BROUILLON manuelles peuvent être supprimées.
    ''' </summary>
    Public Function CanDelete(statut As Object) As Boolean
        Dim s As String = If(IsDBNull(statut) OrElse statut Is Nothing, "BROUILLON", statut.ToString())
        Return (s = "BROUILLON")
    End Function

    ''' <summary>
    ''' Affiche un petit badge à côté du libellé pour indiquer la source
    ''' (FACTURE_CLIENT, FACTURE_FOURN, REGLEMENT, MANUEL).
    ''' </summary>
    Public Function RenderSourceBadge(sourceType As Object) As String
        If IsDBNull(sourceType) OrElse sourceType Is Nothing Then Return ""
        Dim s As String = sourceType.ToString()

        Select Case s
            Case "FACTURE_CLIENT" : Return "<span class='badge-source'>Fact. client</span>"
            Case "FACTURE_FOURN" : Return "<span class='badge-source'>Fact. fourn.</span>"
            Case "REGLEMENT" : Return "<span class='badge-source'>Règlement</span>"
            Case "MANUEL" : Return ""   ' pas de badge pour les écritures manuelles (cas par défaut)
            Case Else : Return ""
        End Select
    End Function

    ' =========================================================
    '  UTILITAIRES
    ' =========================================================

    Private Function GetCompanyGUID() As Guid
        ' TODO : adapter selon votre mécanisme de session
        ' Exemple : Return CType(Session("CompanyGUID"), Guid)
        Return Guid.Empty
    End Function

End Class
