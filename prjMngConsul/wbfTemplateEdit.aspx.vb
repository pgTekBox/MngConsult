Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfTemplateEdit
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉ VIEWSTATE
    ' =========================================================

    Property TemplateId() As Integer
        Get
            Try
                If ViewState("TemplateId") Is Nothing Then ViewState("TemplateId") = 0
                Return CInt(ViewState("TemplateId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            ViewState("TemplateId") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LOAD
    ' =========================================================

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            TemplateId = CInt(Val(Request.QueryString("Id")))
            CreateLinesTable()

            ' Charger combo Journal
            LoadJournauxCombo()

            If TemplateId > 0 Then
                LoadTemplateFromBD()
                LoadLinesFromBD()
            Else
                AddEmptyLine()
                AddEmptyLine()
            End If

            BindLineGrid()
        End If

        UpdateModeInfo()
    End Sub

    Sub UpdateModeInfo()
        If chkPreRempli.Checked Then
            lblModeInfo.Text = "Mode <strong>pré-rempli</strong> : les montants enregistrés ici seront automatiquement utilisés à chaque application du template."
        Else
            lblModeInfo.Text = "Mode <strong>structure</strong> : seuls les comptes et leur sens (Débit/Crédit) sont mémorisés. Les montants seront à saisir à chaque utilisation."
        End If
    End Sub

    ' =========================================================
    '  COMBO JOURNAUX
    ' =========================================================

    Sub LoadJournauxCombo()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0114Get_Journaux", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        cbJournal.DataSource = ds.Tables(0)
        cbJournal.DataBind()
    End Sub

    ' =========================================================
    '  TABLE EN MÉMOIRE DES LIGNES — VERSION UI (11 colonnes)
    '  Contient en plus 3 colonnes d'affichage (AccountNumero,
    '  AccountName, AccountDisplay) qui ne sont PAS dans le TVP.
    ' =========================================================

    Public Sub CreateLinesTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("PlanComptableId", GetType(Integer))
        dt.Columns.Add("AccountNumero", GetType(String))     ' UI seulement
        dt.Columns.Add("AccountName", GetType(String))        ' UI seulement
        dt.Columns.Add("AccountDisplay", GetType(String))     ' UI seulement
        dt.Columns.Add("Libelle", GetType(String))
        dt.Columns.Add("Sens", GetType(String))
        dt.Columns.Add("Montant", GetType(Double))
        dt.Columns.Add("Dirty", GetType(Integer))
        dt.Columns.Add("Deleted", GetType(Integer))
        dt.Columns.Add("Ordre", GetType(Integer))
        ViewState("LinesTable") = dt
    End Sub

    Sub AddEmptyLine()
        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim dr As DataRow = dt.NewRow()
        dr("Id") = -(dt.Rows.Count + 1)
        dr("PlanComptableId") = 0
        dr("AccountNumero") = ""
        dr("AccountName") = ""
        dr("AccountDisplay") = "Sélectionner un compte ▾"
        dr("Libelle") = ""
        dr("Sens") = "DEBIT"
        dr("Montant") = 0
        dr("Dirty") = 1
        dr("Deleted") = 0
        dr("Ordre") = dt.Rows.Count + 1
        dt.Rows.Add(dr)
        ViewState("LinesTable") = dt
    End Sub

    ''' <summary>
    ''' Projette le DataTable UI (11 colonnes) vers une structure compatible
    ''' avec le TVP dbo.TVP_TemplateLigne (8 colonnes).
    '''
    ''' L'ORDRE DES COLONNES EST CRITIQUE : SQL Server mappe les TVP par
    ''' position, pas par nom. L'ordre doit correspondre exactement à :
    '''   Id, PlanComptableId, Libelle, Sens, Montant, Ordre, Dirty, Deleted
    ''' </summary>
    Private Function ProjectLinesForTVP(source As DataTable) As DataTable
        Dim tvp As New DataTable()
        tvp.Columns.Add("Id", GetType(Integer))
        tvp.Columns.Add("PlanComptableId", GetType(Integer))
        tvp.Columns.Add("Libelle", GetType(String))
        tvp.Columns.Add("Sens", GetType(String))
        tvp.Columns.Add("Montant", GetType(Decimal))
        tvp.Columns.Add("Ordre", GetType(Integer))
        tvp.Columns.Add("Dirty", GetType(Integer))
        tvp.Columns.Add("Deleted", GetType(Integer))

        For Each row As DataRow In source.Rows
            Dim newRow As DataRow = tvp.NewRow()
            newRow("Id") = row("Id")
            newRow("PlanComptableId") = row("PlanComptableId")
            newRow("Libelle") = If(IsDBNull(row("Libelle")), "", row("Libelle"))
            newRow("Sens") = If(IsDBNull(row("Sens")), "DEBIT", row("Sens"))
            newRow("Montant") = Convert.ToDecimal(row("Montant"))
            newRow("Ordre") = row("Ordre")
            newRow("Dirty") = row("Dirty")
            newRow("Deleted") = row("Deleted")
            tvp.Rows.Add(newRow)
        Next

        Return tvp
    End Function

    ''' <summary>
    ''' Charge l'en-tête du template.
    ''' </summary>
    Sub LoadTemplateFromBD()
        Dim p As New Collection
        p.Add(New SqlParameter("@TemplateId", TemplateId))

        Dim ds As DataSet = ExecuteSQLds("s0121GetTemplateById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim orow As DataRow = ds.Tables(0).Rows(0)
        txtCode.Text = orow("Code").ToString()
        txtLibelle.Text = orow("Libelle").ToString()
        txtDescription.Text = If(IsDBNull(orow("Description")), "", orow("Description").ToString())
        cbJournal.SelectedValue = orow("JournauxId").ToString()
        chkPreRempli.Checked = CBool(orow("MontantsPreRemplis"))
        chkActif.Checked = CBool(orow("Actif"))
    End Sub

    ''' <summary>
    ''' Charge les lignes du template.
    ''' </summary>
    Sub LoadLinesFromBD()
        Dim p As New Collection
        p.Add(New SqlParameter("@TemplateId", TemplateId))

        Dim ds As DataSet = ExecuteSQLds("s0122GetTemplateLignes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        dt.Rows.Clear()

        For Each orow As DataRow In ds.Tables(0).Rows
            Dim dr As DataRow = dt.NewRow()
            dr("Id") = orow("Id")
            dr("PlanComptableId") = If(IsDBNull(orow("PlanComptableId")), 0, Convert.ToInt32(orow("PlanComptableId")))
            dr("AccountNumero") = If(IsDBNull(orow("AccountNumero")), "", orow("AccountNumero").ToString())
            dr("AccountName") = If(IsDBNull(orow("AccountName")), "", orow("AccountName").ToString())
            dr("AccountDisplay") = dr("AccountNumero").ToString() & " - " & dr("AccountName").ToString()
            dr("Libelle") = If(IsDBNull(orow("Libelle")), "", orow("Libelle").ToString())
            dr("Sens") = If(IsDBNull(orow("Sens")), "DEBIT", orow("Sens").ToString())
            dr("Montant") = If(IsDBNull(orow("Montant")), 0D, Convert.ToDouble(orow("Montant")))
            dr("Dirty") = 0
            dr("Deleted") = 0
            dr("Ordre") = If(IsDBNull(orow("Ordre")), 0, Convert.ToInt32(orow("Ordre")))
            dt.Rows.Add(dr)
        Next

        ViewState("LinesTable") = dt
    End Sub

    Public Sub BindLineGrid()
        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim dv As New DataView(dt)
        dv.Sort = "Ordre"
        dv.RowFilter = "Deleted = 0"
        rpLines.DataSource = dv
        rpLines.DataBind()
    End Sub

    Sub UpdateAllLinesInViewstate()
        Dim dt As DataTable = TryCast(ViewState("LinesTable"), DataTable)
        If dt Is Nothing Then Exit Sub

        Dim ordreCounter As Integer = 0

        For Each item As RepeaterItem In rpLines.Items
            ordreCounter += 1
            If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then Continue For

            Dim hid As HiddenField = TryCast(item.FindControl("hidId"), HiddenField)
            If hid Is Nothing OrElse String.IsNullOrWhiteSpace(hid.Value) Then Continue For

            Dim id As Integer
            If Not Integer.TryParse(hid.Value, id) Then Continue For

            Dim txtLineLib = TryCast(item.FindControl("txtLineLibelle"), RadTextBox)
            Dim numMontant = TryCast(item.FindControl("numMontant"), RadTextBox)
            Dim cbSens = TryCast(item.FindControl("cbSens"), RadComboBox)
            Dim hidPC = TryCast(item.FindControl("hidPlanComptableId"), HiddenField)

            Dim planComptableId As Integer = If(hidPC Is Nothing OrElse String.IsNullOrWhiteSpace(hidPC.Value),
                                                0, Convert.ToInt32(hidPC.Value))
            Dim libelle As String = If(txtLineLib Is Nothing, "", txtLineLib.Text.Trim())
            Dim montant As Double = If(numMontant Is Nothing, 0, ToDoubleAnyCulture(numMontant.Text))
            Dim sens As String = If(cbSens IsNot Nothing AndAlso Not String.IsNullOrEmpty(cbSens.SelectedValue),
                                    cbSens.SelectedValue, "DEBIT")

            Dim rows() As DataRow = dt.Select("Id=" & id.ToString())
            If rows Is Nothing OrElse rows.Length = 0 Then Continue For

            Dim dr As DataRow = rows(0)
            If Convert.ToInt32(dr("Deleted")) = 1 Then Continue For

            dr("PlanComptableId") = planComptableId
            dr("Libelle") = libelle
            dr("Sens") = sens
            dr("Montant") = montant
            dr("Ordre") = ordreCounter
            dr("Dirty") = 1
        Next

        ViewState("LinesTable") = dt
    End Sub

    ' =========================================================
    '  AJOUT / SUPPRESSION
    ' =========================================================

    Private Sub btnAddLine_Click(sender As Object, e As EventArgs) Handles btnAddLine.Click
        UpdateAllLinesInViewstate()
        AddEmptyLine()
        BindLineGrid()
    End Sub

    Private Sub rpLines_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rpLines.ItemCommand
        If e.CommandName = "DeleteLine" Then
            UpdateAllLinesInViewstate()
            Dim id As Integer = Convert.ToInt32(e.CommandArgument)
            Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
            For Each dr As DataRow In dt.Rows
                If Convert.ToInt32(dr("Id")) = id Then
                    dr("Deleted") = 1
                    dr("Dirty") = 1
                    Exit For
                End If
            Next
            BindLineGrid()
        End If
    End Sub

    Private Sub rpLines_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rpLines.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim lblAccount As Label = TryCast(e.Item.FindControl("lblAccount"), Label)
        Dim cbSens As RadComboBox = TryCast(e.Item.FindControl("cbSens"), RadComboBox)

        If lblAccount IsNot Nothing Then
            Dim planComptableId As Object = DataBinder.Eval(e.Item.DataItem, "PlanComptableId")
            If planComptableId IsNot Nothing AndAlso CInt(planComptableId) > 0 Then
                lblAccount.Text = DataBinder.Eval(e.Item.DataItem, "AccountDisplay").ToString()
            Else
                lblAccount.Text = "Sélectionner un compte ▾"
            End If
        End If

        ' Pré-sélectionner le sens
        If cbSens IsNot Nothing Then
            Dim sens As String = If(IsDBNull(DataBinder.Eval(e.Item.DataItem, "Sens")), "DEBIT",
                                    DataBinder.Eval(e.Item.DataItem, "Sens").ToString())
            cbSens.SelectedValue = sens
        End If
    End Sub

    Private Sub chkPreRempli_CheckedChanged(sender As Object, e As EventArgs) Handles chkPreRempli.CheckedChanged
        UpdateAllLinesInViewstate()
        UpdateModeInfo()
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        UpdateAllLinesInViewstate()

        ' --- Validations ---
        If String.IsNullOrWhiteSpace(txtCode.Text) Then
            RegisterAlert("Le code du template est obligatoire.")
            Return
        End If
        If String.IsNullOrWhiteSpace(txtLibelle.Text) Then
            RegisterAlert("Le libellé du template est obligatoire.")
            Return
        End If
        If String.IsNullOrEmpty(cbJournal.SelectedValue) Then
            RegisterAlert("Veuillez sélectionner un journal.")
            Return
        End If

        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim activeLines = dt.AsEnumerable().Where(Function(r) Convert.ToInt32(r("Deleted")) = 0).ToList()

        If activeLines.Count < 2 Then
            RegisterAlert("Un template doit comporter au moins 2 lignes.")
            Return
        End If

        For Each row In activeLines
            If Convert.ToInt32(row("PlanComptableId")) <= 0 Then
                RegisterAlert("Toutes les lignes doivent avoir un compte sélectionné.")
                Return
            End If
        Next

        ' Si pré-rempli : valider que ça balance
        If chkPreRempli.Checked Then
            Dim totDebit As Double = activeLines.Where(Function(r) r("Sens").ToString() = "DEBIT").
                                                 Sum(Function(r) Convert.ToDouble(r("Montant")))
            Dim totCredit As Double = activeLines.Where(Function(r) r("Sens").ToString() = "CREDIT").
                                                  Sum(Function(r) Convert.ToDouble(r("Montant")))
            If Math.Abs(totDebit - totCredit) > 0.005 Then
                RegisterAlert("Le template pré-rempli n'est pas équilibré. Débit = " &
                              totDebit.ToString("N2") & " / Crédit = " & totCredit.ToString("N2"))
                Return
            End If
            If totDebit <= 0 Then
                RegisterAlert("Les montants pré-remplis doivent être > 0.")
                Return
            End If
        End If

        ' --- Sauvegarde via TVP ---
        Dim DRconn As New SqlConnection(ConnectionString)
        Dim oCom As New SqlCommand("sp_SaveTemplate", DRconn)
        oCom.CommandType = CommandType.StoredProcedure

        oCom.Parameters.Add(New SqlParameter("@TemplateId", SqlDbType.Int) With {.Value = TemplateId})
        oCom.Parameters.Add(New SqlParameter("@CompanyGUID", SqlDbType.UniqueIdentifier) With {.Value = Company})
        oCom.Parameters.Add(New SqlParameter("@Code", SqlDbType.VarChar, 50) With {.Value = txtCode.Text.Trim()})
        oCom.Parameters.Add(New SqlParameter("@Libelle", SqlDbType.VarChar, 250) With {.Value = txtLibelle.Text.Trim()})
        oCom.Parameters.Add(New SqlParameter("@Description", SqlDbType.VarChar, 500) With {.Value = txtDescription.Text.Trim()})
        oCom.Parameters.Add(New SqlParameter("@JournauxId", SqlDbType.Int) With {.Value = CInt(cbJournal.SelectedValue)})
        oCom.Parameters.Add(New SqlParameter("@MontantsPreRemplis", SqlDbType.Bit) With {.Value = If(chkPreRempli.Checked, 1, 0)})
        oCom.Parameters.Add(New SqlParameter("@Actif", SqlDbType.Bit) With {.Value = If(chkActif.Checked, 1, 0)})
        oCom.Parameters.Add(New SqlParameter("@UserId", SqlDbType.Int) With {.Value = GetCurrentUserId()})

        ' >>> CORRECTION : projeter le DataTable UI (11 col) vers le TVP (8 col) <<<
        Dim tvpLignes As DataTable = ProjectLinesForTVP(dt)

        Dim ParamLignes As New SqlParameter("@Lignes", SqlDbType.Structured)
        ParamLignes.Value = tvpLignes
        ParamLignes.TypeName = "dbo.TVP_TemplateLigne"
        oCom.Parameters.Add(ParamLignes)

        Try
            oCom.Connection.Open()
            oCom.ExecuteNonQuery()
        Catch ex As Exception
            RegisterAlert("Erreur lors de l'enregistrement : " & ex.Message)
            Return
        Finally
            If oCom.Connection.State = ConnectionState.Open Then oCom.Connection.Close()
        End Try

        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    Private Sub RegisterAlert(msg As String)
        Dim safe As String = msg.Replace("'", "\'").Replace(Chr(13), " ").Replace(Chr(10), " ")
        ScriptManager.RegisterStartupScript(Page, Page.GetType(),
            "alert_" & Guid.NewGuid().ToString("N"),
            "alert('" & safe & "');", True)
    End Sub

    ' =========================================================
    '  PICKER COMPTES
    ' =========================================================

    Private Function GetAccountsTable() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0093Get_PlanComptable_All", p)
        Return ds.Tables(0)
    End Function

    Private Sub rlvAccounts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAccounts.NeedDataSource
        rlvAccounts.DataSource = GetAccountsTable()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        Dim AllParam As String() = e.Argument.Split("|"c)
        If AllParam.Length < 3 Then Return

        Select Case AllParam(0)
            Case "ACCOUNT"
                Dim lineId As Integer = 0
                Dim accountId As Integer = 0
                If Integer.TryParse(AllParam(1), lineId) AndAlso Integer.TryParse(AllParam(2), accountId) Then
                    UpdateAllLinesInViewstate()
                    UpdateLineAccount(lineId, accountId)
                    BindLineGrid()
                End If
        End Select
    End Sub

    Sub UpdateLineAccount(lineId As Integer, accountId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@AccountId", accountId))
        Dim ds As DataSet = ExecuteSQLds("s0083Get_GLAccountById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim acctRow As DataRow = ds.Tables(0).Rows(0)
        Dim noCompte As String = acctRow("NoCompte").ToString()
        Dim name As String = acctRow("Name").ToString()

        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim dr As DataRow = dt.AsEnumerable().FirstOrDefault(Function(r) Convert.ToInt32(r("Id")) = lineId)
        If dr Is Nothing Then Return

        dr("PlanComptableId") = accountId
        dr("AccountNumero") = noCompte
        dr("AccountName") = name
        dr("AccountDisplay") = noCompte & " - " & name
        dr("Dirty") = 1

        ViewState("LinesTable") = dt
    End Sub

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function GetCurrentUserId() As Integer
        ' TODO : adapter
        Return 1
    End Function

End Class
