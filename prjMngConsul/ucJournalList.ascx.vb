
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class ucJournalList
    Inherits clsDataUC


    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Période par défaut : mois en cours
            dpDateFrom.SelectedDate = New Date(Date.Today.Year, Date.Today.Month, 1)
            dpDateTo.SelectedDate = Date.Today
            cbStatusFilter.SelectedValue = ""

            LoadJournauxFilter()
            BindList()
        End If

        ' Localisation (fr/en/es) à chaque chargement, y compris les postbacks AJAX.
        ApplyLocalization()
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de l'écran Journaux.</summary>
    Private Sub ApplyLocalization()
        ' Libellés des filtres
        SetLiteral(Me, "litLblDateFrom", L("lblDateFrom"))
        SetLiteral(Me, "litLblDateTo", L("lblDateTo"))
        SetLiteral(Me, "litLblJournal", L("lblJournal"))
        SetLiteral(Me, "litLblStatus", L("lblStatus"))
        SetLiteral(Me, "litLblSearch", L("lblSearch"))

        ' En-têtes de la grille
        SetLiteral(Me, "litColNoPiece", L("colNoPiece"))
        SetLiteral(Me, "litColDate", L("colDate"))
        SetLiteral(Me, "litColJournal", L("colJournal"))
        SetLiteral(Me, "litColLibelle", L("colLibelle"))
        SetLiteral(Me, "litColDebit", L("colDebit"))
        SetLiteral(Me, "litColCredit", L("colCredit"))
        SetLiteral(Me, "litColStatut", L("colStatut"))
        SetLiteral(Me, "litColActions", L("colActions"))

        ' Pied de page (totaux)
        SetLiteral(Me, "litFtEntries", L("ftEntries"))
        SetLiteral(Me, "litFtTotalDebit", L("ftTotalDebit"))
        SetLiteral(Me, "litFtTotalCredit", L("ftTotalCredit"))

        ' Message liste vide
        SetLiteral(Me, "litEmpty", L("empty"))

        ' Contrôles serveur
        btnFilter.Text = L("filter")
        txtSearch.EmptyMessage = L("searchPh")

        ' Items des combos
        Dim itAll = cbJournalFilter.Items.FindItemByValue("")
        If itAll IsNot Nothing Then itAll.Text = L("all")

        SetStatusItem("", L("all"))
        SetStatusItem("BROUILLON", L("draft"))
        SetStatusItem("VALIDEE", L("validated"))
        SetStatusItem("EXTOURNEE", L("reversed"))

        ' FAB « Nouvelle écriture »
        Dim fab As Control = FindDeep(Me, "fabNew")
        If TypeOf fab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(fab, System.Web.UI.HtmlControls.HtmlControl).Attributes("title") = L("newEntry")
        End If
        Dim imgFab As Control = FindDeep(Me, "imgFabNew")
        If TypeOf imgFab Is System.Web.UI.HtmlControls.HtmlControl Then
            CType(imgFab, System.Web.UI.HtmlControls.HtmlControl).Attributes("alt") = L("newEntry")
        End If
    End Sub

    Private Sub SetStatusItem(value As String, text As String)
        Dim it = cbStatusFilter.Items.FindItemByValue(value)
        If it IsNot Nothing Then it.Text = text
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
        p.Add(New SqlParameter("@CompanyGUID", Company()))

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
        p.Add(New SqlParameter("@CompanyGUID", Company()))
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
                    "alert('" & L("errorPrefix").Replace("'", "\'") & safe & "');", True)
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
            Case "VALIDEE" : Return L("validated")
            Case "EXTOURNEE" : Return L("reversed")
            Case Else : Return L("draft")
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
            Case "FACTURE_CLIENT" : Return "<span class='badge-source'>" & L("srcClient") & "</span>"
            Case "FACTURE_FOURN" : Return "<span class='badge-source'>" & L("srcFourn") & "</span>"
            Case "REGLEMENT" : Return "<span class='badge-source'>" & L("srcReglement") & "</span>"
            Case "MANUEL" : Return ""   ' pas de badge pour les écritures manuelles (cas par défaut)
            Case Else : Return ""
        End Select
    End Function

    ' =========================================================
    '  LOCALISATION (fr/en/es)
    ' =========================================================

    ''' <summary>Traductions de l'écran Journaux (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            ' Filtres
            Case "lblDateFrom" : Return Choose3(lang, "Date de", "Date from", "Fecha desde")
            Case "lblDateTo" : Return Choose3(lang, "Date à", "Date to", "Fecha hasta")
            Case "lblJournal" : Return Choose3(lang, "Journal", "Journal", "Diario")
            Case "lblStatus" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "lblSearch" : Return Choose3(lang, "Recherche (no pièce, libellé)", "Search (voucher no., description)", "Buscar (n.º comprobante, descripción)")
            Case "searchPh" : Return Choose3(lang, "Rechercher...", "Search...", "Buscar...")
            Case "filter" : Return Choose3(lang, "Filtrer", "Filter", "Filtrar")
            Case "all" : Return Choose3(lang, "(Tous)", "(All)", "(Todos)")
            ' Statuts
            Case "draft" : Return Choose3(lang, "Brouillon", "Draft", "Borrador")
            Case "validated" : Return Choose3(lang, "Validée", "Validated", "Validado")
            Case "reversed" : Return Choose3(lang, "Extournée", "Reversed", "Reversado")
            ' En-têtes de grille
            Case "colNoPiece" : Return Choose3(lang, "No pièce", "Voucher no.", "N.º comprobante")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colJournal" : Return Choose3(lang, "Journal", "Journal", "Diario")
            Case "colLibelle" : Return Choose3(lang, "Libellé", "Description", "Descripción")
            Case "colDebit" : Return Choose3(lang, "Débit", "Debit", "Débito")
            Case "colCredit" : Return Choose3(lang, "Crédit", "Credit", "Crédito")
            Case "colStatut" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "colActions" : Return Choose3(lang, "Actions", "Actions", "Acciones")
            ' Pied de page
            Case "ftEntries" : Return Choose3(lang, "écriture(s)", "entry(ies)", "asiento(s)")
            Case "ftTotalDebit" : Return Choose3(lang, "Total Débit :", "Total debit:", "Total débito:")
            Case "ftTotalCredit" : Return Choose3(lang, "Total Crédit :", "Total credit:", "Total crédito:")
            ' Liste vide
            Case "empty" : Return Choose3(lang, "Aucune écriture trouvée pour ces critères.", "No entry found for these criteria.", "No se encontró ningún asiento con estos criterios.")
            ' Actions / fenêtre
            Case "newEntry" : Return Choose3(lang, "Nouvelle écriture", "New entry", "Nuevo asiento")
            Case "editEntry" : Return Choose3(lang, "Modifier l'écriture", "Edit entry", "Editar asiento")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "confirmDelete" : Return Choose3(lang, "Supprimer cette écriture ?", "Delete this entry?", "¿Eliminar este asiento?")
            ' Badges source
            Case "srcClient" : Return Choose3(lang, "Fact. client", "Cust. inv.", "Fact. cliente")
            Case "srcFourn" : Return Choose3(lang, "Fact. fourn.", "Supp. inv.", "Fact. prov.")
            Case "srcReglement" : Return Choose3(lang, "Règlement", "Payment", "Pago")
            ' Messages
            Case "errorPrefix" : Return Choose3(lang, "Erreur : ", "Error: ", "Error: ")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
    End Sub

    Private Shared Function FindDeep(root As Control, id As String) As Control
        If root Is Nothing Then Return Nothing
        Dim direct As Control = root.FindControl(id)
        If direct IsNot Nothing Then Return direct
        For Each ch As Control In root.Controls
            Dim r As Control = FindDeep(ch, id)
            If r IsNot Nothing Then Return r
        Next
        Return Nothing
    End Function

End Class