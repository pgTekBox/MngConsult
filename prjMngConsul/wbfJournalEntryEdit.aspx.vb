Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfJournalEntryEdit
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS VIEWSTATE
    ' =========================================================

    Property EcritureId() As Integer
        Get
            Try
                If ViewState("EcritureId") Is Nothing Then ViewState("EcritureId") = 0
                Return CInt(ViewState("EcritureId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            ViewState("EcritureId") = value
        End Set
    End Property

    Property Statut() As String
        Get
            Try
                If ViewState("Statut") Is Nothing Then ViewState("Statut") = "BROUILLON"
                Return ViewState("Statut").ToString()
            Catch
                Return "BROUILLON"
            End Try
        End Get
        Set(value As String)
            ViewState("Statut") = value
        End Set
    End Property

    ' =========================================================
    '  HELPER PUBLIC POUR L'ASPX
    ' =========================================================

    Public Function IsReadOnly() As Boolean
        Return Statut = "VALIDEE" OrElse Statut = "EXTOURNEE"
    End Function

    ' =========================================================
    '  PAGE LOAD
    ' =========================================================

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If


            EcritureId = CInt(Val(Request.QueryString("Id")))
            CreateLinesTable()

            ' Charger les combos avant tout le reste (pour pouvoir les pré-sélectionner)
            LoadJournauxCombo()
            LoadPeriodesCombo()

            If EcritureId > 0 Then
                LoadEcritureFromBD()
                LoadLinesFromBD()
            Else
                ' Nouvelle écriture : valeurs par défaut
                dpDateEcriture.SelectedDate = Date.Today
                ' Ajouter 2 lignes vides pour démarrer
                AddEmptyLine()
                AddEmptyLine()
            End If

            BindLineGrid()
        End If

        ApplyLocalization()
        ApplyReadOnlyMode()
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    ''' <remarks>Appelée à chaque chargement (y compris AJAX) pour re-localiser les panneaux mis à jour.</remarks>
    Private Sub ApplyLocalization()
        ' Badges de statut
        lblValideeBadge.Text = L("badgeValidee")
        lblExtourneeBadge.Text = L("badgeExtournee")
        lblBalanceBadge.Text = L("badgeBalanced")

        ' Boutons / actions
        btnLoadTemplate.Text = L("loadTemplate")
        btnAddLine.ToolTip = L("addLineTooltip")
        radSave.Text = L("save")

        ' Combos / placeholders en-tête
        cbJournal.EmptyMessage = L("phSelect")
        cbPeriode.EmptyMessage = L("phSelect")
        txtNumeroPiece.EmptyMessage = L("phNumeroPiece")
        txtLibelle.EmptyMessage = L("phLibelle")

        ' Libellés statiques (Literal — pas de <%= %> à cause du RadAjaxManager)
        SetLiteral(Me, "litLblJournal", L("journal"))
        SetLiteral(Me, "litLblPeriode", L("periode"))
        SetLiteral(Me, "litLblDate", L("dateEcriture"))
        SetLiteral(Me, "litLblValider", L("validerEcriture"))
        SetLiteral(Me, "litLblNoPiece", L("noPiece"))
        SetLiteral(Me, "litLblLibelle", L("libelleEcriture"))
        SetLiteral(Me, "litLignesEcriture", L("lignesEcriture"))

        ' En-têtes de colonnes des lignes
        SetLiteral(Me, "litColCompte", L("colCompte"))
        SetLiteral(Me, "litColLibelle", L("colLibelleLigne"))
        SetLiteral(Me, "litColDebit", L("colDebit"))
        SetLiteral(Me, "litColCredit", L("colCredit"))

        ' Totaux (footer)
        SetLiteral(Me, "litTotalDebit", L("totalDebit"))
        SetLiteral(Me, "litTotalCredit", L("totalCredit"))
        SetLiteral(Me, "litEcart", L("ecart"))
    End Sub

    ' =========================================================
    '  COMBOS DE RÉFÉRENCE
    ' =========================================================

    Sub LoadJournauxCombo()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0114Get_Journaux", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        cbJournal.DataSource = ds.Tables(0)
        cbJournal.DataBind()
    End Sub

    Sub LoadPeriodesCombo()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0115Get_PeriodesOuvertes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        cbPeriode.DataSource = ds.Tables(0)
        cbPeriode.DataBind()
    End Sub

    ' =========================================================
    '  TABLE EN MÉMOIRE DES LIGNES — VERSION UI (12 colonnes)
    '  Contient en plus les 3 colonnes d'affichage (AccountNumero,
    '  AccountName, AccountDisplay) qui ne sont PAS dans le TVP.
    ' =========================================================

    Public Sub CreateLinesTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("PlanComptableId", GetType(Integer))
        dt.Columns.Add("AccountNumero", GetType(String))      ' UI seulement
        dt.Columns.Add("AccountName", GetType(String))         ' UI seulement
        dt.Columns.Add("AccountDisplay", GetType(String))      ' UI seulement
        dt.Columns.Add("PartyId", GetType(Integer))
        dt.Columns.Add("Libelle", GetType(String))
        dt.Columns.Add("MontantDebit", GetType(Double))
        dt.Columns.Add("MontantCredit", GetType(Double))
        dt.Columns.Add("Dirty", GetType(Integer))
        dt.Columns.Add("Deleted", GetType(Integer))
        dt.Columns.Add("Ordre", GetType(Integer))
        ViewState("LinesTable") = dt
    End Sub

    Sub AddEmptyLine()
        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim dr As DataRow = dt.NewRow()
        dr("Id") = -(dt.Rows.Count + 1)   ' Id négatif temporaire
        dr("PlanComptableId") = 0
        dr("AccountNumero") = ""
        dr("AccountName") = ""
        dr("AccountDisplay") = L("accountSelectorDefault")
        dr("PartyId") = 0
        dr("Libelle") = ""
        dr("MontantDebit") = 0
        dr("MontantCredit") = 0
        dr("Dirty") = 1
        dr("Deleted") = 0
        dr("Ordre") = dt.Rows.Count + 1
        dt.Rows.Add(dr)
        ViewState("LinesTable") = dt
    End Sub

    ''' <summary>
    ''' Projette le DataTable UI (12 colonnes) vers une structure compatible
    ''' avec le TVP dbo.TVP_LigneEcriture (9 colonnes).
    '''
    ''' L'ORDRE DES COLONNES EST CRITIQUE : SQL Server mappe les TVP par
    ''' position et non par nom. L'ordre doit correspondre exactement à :
    '''   Id, PlanComptableId, PartyId, Libelle, MontantDebit, MontantCredit,
    '''   Ordre, Dirty, Deleted
    ''' </summary>
    Private Function ProjectLinesForTVP(source As DataTable) As DataTable
        Dim tvp As New DataTable()
        tvp.Columns.Add("Id", GetType(Integer))
        tvp.Columns.Add("PlanComptableId", GetType(Integer))
        tvp.Columns.Add("PartyId", GetType(Integer))
        tvp.Columns.Add("Libelle", GetType(String))
        tvp.Columns.Add("MontantDebit", GetType(Decimal))
        tvp.Columns.Add("MontantCredit", GetType(Decimal))
        tvp.Columns.Add("Ordre", GetType(Integer))
        tvp.Columns.Add("Dirty", GetType(Integer))
        tvp.Columns.Add("Deleted", GetType(Integer))

        For Each row As DataRow In source.Rows
            Dim newRow As DataRow = tvp.NewRow()
            newRow("Id") = row("Id")
            newRow("PlanComptableId") = row("PlanComptableId")

            ' PartyId : NULL si 0 ou DBNull
            If IsDBNull(row("PartyId")) OrElse Convert.ToInt32(row("PartyId")) = 0 Then
                newRow("PartyId") = DBNull.Value
            Else
                newRow("PartyId") = row("PartyId")
            End If

            newRow("Libelle") = If(IsDBNull(row("Libelle")), "", row("Libelle"))
            newRow("MontantDebit") = Convert.ToDecimal(row("MontantDebit"))
            newRow("MontantCredit") = Convert.ToDecimal(row("MontantCredit"))
            newRow("Ordre") = row("Ordre")
            newRow("Dirty") = row("Dirty")
            newRow("Deleted") = row("Deleted")
            tvp.Rows.Add(newRow)
        Next

        Return tvp
    End Function

    ''' <summary>
    ''' Charge l'en-tête de l'écriture depuis la BD.
    ''' </summary>
    Sub LoadEcritureFromBD()
        Dim p As New Collection
        p.Add(New SqlParameter("@EcritureId", EcritureId))

        Dim ds As DataSet = ExecuteSQLds("s0110GetEcritureById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim orow As DataRow = ds.Tables(0).Rows(0)

        cbJournal.SelectedValue = orow("JournauxId").ToString()
        cbPeriode.SelectedValue = orow("PeriodeId").ToString()
        dpDateEcriture.SelectedDate = Convert.ToDateTime(orow("DateEcriture"))
        txtNumeroPiece.Text = If(IsDBNull(orow("NumeroPiece")), "", orow("NumeroPiece").ToString())
        txtLibelle.Text = If(IsDBNull(orow("Libelle")), "", orow("Libelle").ToString())

        Statut = If(IsDBNull(orow("Statut")), "BROUILLON", orow("Statut").ToString())
        chkValider.Checked = (Statut = "VALIDEE")
    End Sub

    ''' <summary>
    ''' Charge les lignes de l'écriture (T136LignesEcriture).
    ''' </summary>
    Sub LoadLinesFromBD()
        Dim p As New Collection
        p.Add(New SqlParameter("@EcritureId", EcritureId))

        Dim ds As DataSet = ExecuteSQLds("s0111GetEcritureLignes", p)
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
            dr("PartyId") = If(IsDBNull(orow("PartyId")), 0, Convert.ToInt32(orow("PartyId")))
            dr("Libelle") = If(IsDBNull(orow("Libelle")), "", orow("Libelle").ToString())
            dr("MontantDebit") = If(IsDBNull(orow("MontantDebit")), 0D, Convert.ToDouble(orow("MontantDebit")))
            dr("MontantCredit") = If(IsDBNull(orow("MontantCredit")), 0D, Convert.ToDouble(orow("MontantCredit")))
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

    ''' <summary>
    ''' Met à jour la table en mémoire avec les valeurs saisies.
    ''' </summary>
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

            Dim txtLibelle As RadTextBox = TryCast(item.FindControl("txtLineLibelle"), RadTextBox)
            Dim numDebit As RadTextBox = TryCast(item.FindControl("numMontantDebit"), RadTextBox)
            Dim numCredit As RadTextBox = TryCast(item.FindControl("numMontantCredit"), RadTextBox)
            Dim hidPC As HiddenField = TryCast(item.FindControl("hidPlanComptableId"), HiddenField)

            Dim planComptableId As Integer = If(hidPC Is Nothing OrElse String.IsNullOrWhiteSpace(hidPC.Value),
                                                0, Convert.ToInt32(hidPC.Value))
            Dim libelle As String = If(txtLibelle Is Nothing, "", txtLibelle.Text.Trim())
            Dim montantDebit As Double = If(numDebit Is Nothing, 0, ToDoubleAnyCulture(numDebit.Text))
            Dim montantCredit As Double = If(numCredit Is Nothing, 0, ToDoubleAnyCulture(numCredit.Text))

            Dim rows() As DataRow = dt.Select("Id=" & id.ToString())
            If rows Is Nothing OrElse rows.Length = 0 Then Continue For

            Dim dr As DataRow = rows(0)
            If Convert.ToInt32(dr("Deleted")) = 1 Then Continue For

            dr("PlanComptableId") = planComptableId
            dr("Libelle") = libelle
            dr("MontantDebit") = montantDebit
            dr("MontantCredit") = montantCredit
            dr("Ordre") = ordreCounter
            dr("Dirty") = 1
        Next

        ViewState("LinesTable") = dt
    End Sub

    ' =========================================================
    '  READ-ONLY MODE
    ' =========================================================

    Private Sub ApplyReadOnlyMode()
        lblValideeBadge.Visible = (Statut = "VALIDEE")
        lblExtourneeBadge.Visible = (Statut = "EXTOURNEE")

        If IsReadOnly() Then
            chkValider.Enabled = False
            pnlMain.CssClass &= " readonly"
            cbJournal.Enabled = False
            cbPeriode.Enabled = False
            dpDateEcriture.Enabled = False
            txtNumeroPiece.Enabled = False
            txtLibelle.Enabled = False
            btnAddLine.Visible = False
            btnLoadTemplate.Visible = False
            radSave.Enabled = False

            For Each item As RepeaterItem In rpLines.Items
                Dim txtLib = CType(item.FindControl("txtLineLibelle"), RadTextBox)
                Dim numD = CType(item.FindControl("numMontantDebit"), RadTextBox)
                Dim numC = CType(item.FindControl("numMontantCredit"), RadTextBox)
                Dim btnDel = CType(item.FindControl("btnDeleteLine"), RadImageButton)
                Dim lblAccount = TryCast(item.FindControl("lblAccount"), Label)

                If txtLib IsNot Nothing Then txtLib.Enabled = False
                If numD IsNot Nothing Then numD.Enabled = False
                If numC IsNot Nothing Then numC.Enabled = False
                If btnDel IsNot Nothing Then btnDel.Visible = False
                If lblAccount IsNot Nothing Then lblAccount.CssClass &= " readonly-blocked"
            Next
        End If
    End Sub

    ' =========================================================
    '  AJOUT / SUPPRESSION DE LIGNES
    ' =========================================================

    Private Sub btnAddLine_Click(sender As Object, e As EventArgs) Handles btnAddLine.Click
        If IsReadOnly() Then Return
        UpdateAllLinesInViewstate()
        AddEmptyLine()
        BindLineGrid()
    End Sub

    Private Sub rpLines_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rpLines.ItemCommand
        If IsReadOnly() Then Return

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
        If lblAccount IsNot Nothing Then
            Dim planComptableId As Object = DataBinder.Eval(e.Item.DataItem, "PlanComptableId")
            If planComptableId IsNot Nothing AndAlso CInt(planComptableId) > 0 Then
                lblAccount.Text = DataBinder.Eval(e.Item.DataItem, "AccountDisplay").ToString()
            Else
                lblAccount.Text = L("accountSelectorDefault")
            End If
        End If

        ' Placeholder localisé du libellé de ligne
        Dim txtLine As RadTextBox = TryCast(e.Item.FindControl("txtLineLibelle"), RadTextBox)
        If txtLine IsNot Nothing Then txtLine.EmptyMessage = L("phLineLibelle")
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        If IsReadOnly() Then Return
        UpdateAllLinesInViewstate()

        ' --- Validations en-tête ---
        If String.IsNullOrEmpty(cbJournal.SelectedValue) Then
            RegisterAlert(L("alertJournal"))
            Return
        End If
        If String.IsNullOrEmpty(cbPeriode.SelectedValue) Then
            RegisterAlert(L("alertPeriode"))
            Return
        End If
        If Not dpDateEcriture.SelectedDate.HasValue Then
            RegisterAlert(L("alertDate"))
            Return
        End If
        If String.IsNullOrWhiteSpace(txtLibelle.Text) Then
            RegisterAlert(L("alertLibelle"))
            Return
        End If

        ' --- Validations lignes ---
        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim activeLines = dt.AsEnumerable().Where(Function(r) Convert.ToInt32(r("Deleted")) = 0).ToList()

        If activeLines.Count < 2 Then
            RegisterAlert(L("alertMin2Lines"))
            Return
        End If

        For Each row In activeLines
            If Convert.ToInt32(row("PlanComptableId")) <= 0 Then
                RegisterAlert(L("alertAccountRequired"))
                Return
            End If
            Dim d As Double = Convert.ToDouble(row("MontantDebit"))
            Dim c As Double = Convert.ToDouble(row("MontantCredit"))
            If d <= 0 AndAlso c <= 0 Then
                RegisterAlert(L("alertAmountRequired"))
                Return
            End If
            If d > 0 AndAlso c > 0 Then
                RegisterAlert(L("alertBothSides"))
                Return
            End If
        Next

        Dim totDebit As Double = activeLines.Sum(Function(r) Convert.ToDouble(r("MontantDebit")))
        Dim totCredit As Double = activeLines.Sum(Function(r) Convert.ToDouble(r("MontantCredit")))
        If Math.Abs(totDebit - totCredit) > 0.005 Then
            RegisterAlert(String.Format(L("alertUnbalanced"), totDebit.ToString("N2"), totCredit.ToString("N2")))
            Return
        End If
        If totDebit <= 0 Then
            RegisterAlert(L("alertTotalPositive"))
            Return
        End If

        ' --- Sauvegarde via TVP : sp_SaveEcriture ---
        Dim DRconn As New SqlConnection(ConnectionString)
        Dim oCom As New SqlCommand("sp_SaveEcriture", DRconn)
        oCom.CommandType = CommandType.StoredProcedure

        oCom.Parameters.Add(New SqlParameter("@EcritureId", SqlDbType.Int) With {.Value = EcritureId})
        oCom.Parameters.Add(New SqlParameter("@CompanyGUID", SqlDbType.UniqueIdentifier) With {.Value = Company})
        oCom.Parameters.Add(New SqlParameter("@JournauxId", SqlDbType.Int) With {.Value = CInt(cbJournal.SelectedValue)})
        oCom.Parameters.Add(New SqlParameter("@PeriodeId", SqlDbType.Int) With {.Value = CInt(cbPeriode.SelectedValue)})
        oCom.Parameters.Add(New SqlParameter("@PartyId", SqlDbType.Int) With {.Value = DBNull.Value})
        oCom.Parameters.Add(New SqlParameter("@DateEcriture", SqlDbType.Date) With {.Value = dpDateEcriture.SelectedDate.Value})
        oCom.Parameters.Add(New SqlParameter("@NumeroPiece", SqlDbType.VarChar, 50) With {.Value = If(String.IsNullOrEmpty(txtNumeroPiece.Text), CType(DBNull.Value, Object), txtNumeroPiece.Text.Trim())})
        oCom.Parameters.Add(New SqlParameter("@Libelle", SqlDbType.VarChar, 250) With {.Value = txtLibelle.Text.Trim()})
        oCom.Parameters.Add(New SqlParameter("@ToValider", SqlDbType.Bit) With {.Value = If(chkValider.Checked, 1, 0)})
        oCom.Parameters.Add(New SqlParameter("@UserId", SqlDbType.Int) With {.Value = GetCurrentUserId()})

        ' >>> CORRECTION : projeter le DataTable UI vers la structure du TVP <<<
        Dim tvpLignes As DataTable = ProjectLinesForTVP(dt)

        Dim ParamLignes As New SqlParameter("@Lignes", SqlDbType.Structured)
        ParamLignes.Value = tvpLignes
        ParamLignes.TypeName = "dbo.TVP_LigneEcriture"
        oCom.Parameters.Add(ParamLignes)

        Try
            oCom.Connection.Open()
            oCom.ExecuteNonQuery()
        Catch ex As Exception
            RegisterAlert(String.Format(L("alertSaveError"), ex.Message))
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
    '  PICKER COMPTES (T121PlanComptable)
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

    ''' <summary>Libellé de l'EmptyDataTemplate du picker de comptes (langue courante).</summary>
    Private Sub rlvAccounts_PreRender(sender As Object, e As EventArgs) Handles rlvAccounts.PreRender
        SetLiteral(rlvAccounts, "litNoAccount", L("noAccount"))
    End Sub

    ' =========================================================
    '  PICKER TEMPLATES
    ' =========================================================

    Private Function GetTemplatesTable() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        p.Add(New SqlParameter("@OnlyActive", 1))
        p.Add(New SqlParameter("@JournauxId", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0120SearchTemplates", p)
        Return ds.Tables(0)
    End Function

    Private Sub rlvTemplates_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvTemplates.NeedDataSource
        rlvTemplates.DataSource = GetTemplatesTable()
    End Sub

    ''' <summary>Libellé de l'EmptyDataTemplate du picker de templates (langue courante).</summary>
    Private Sub rlvTemplates_PreRender(sender As Object, e As EventArgs) Handles rlvTemplates.PreRender
        SetLiteral(rlvTemplates, "litNoTemplate", L("noTemplate"))
    End Sub

    ' =========================================================
    '  AJAX REQUEST
    ' =========================================================

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If IsReadOnly() Then Return

        Dim AllParam As String() = e.Argument.Split("|"c)
        If AllParam.Length < 2 Then Return

        Dim CommandName As String = AllParam(0)

        Select Case CommandName

            Case "ACCOUNT"
                If AllParam.Length < 3 Then Return
                Dim lineId As Integer = 0
                Dim accountId As Integer = 0
                If Integer.TryParse(AllParam(1), lineId) AndAlso Integer.TryParse(AllParam(2), accountId) Then
                    UpdateAllLinesInViewstate()
                    UpdateLineAccount(lineId, accountId)
                    BindLineGrid()
                End If

            Case "TEMPLATE"
                Dim templateId As Integer = 0
                If Integer.TryParse(AllParam(1), templateId) Then
                    ApplyTemplate(templateId)
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

    ''' <summary>
    ''' Charge un template et remplace les lignes courantes.
    ''' </summary>
    Sub ApplyTemplate(templateId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@TemplateId", templateId))
        Dim ds As DataSet = ExecuteSQLds("s0123ApplyTemplateToEcriture", p)

        If ds Is Nothing OrElse ds.Tables.Count < 2 Then Return

        ' --- En-tête : pré-remplir Journal et Libelle si vides ---
        If ds.Tables(0).Rows.Count > 0 Then
            Dim hdr As DataRow = ds.Tables(0).Rows(0)
            Dim journauxId As Integer = If(IsDBNull(hdr("JournauxId")), 0, CInt(hdr("JournauxId")))
            Dim libelleDefaut As String = If(IsDBNull(hdr("LibelleDefaut")), "", hdr("LibelleDefaut").ToString())

            If journauxId > 0 Then
                cbJournal.SelectedValue = journauxId.ToString()
            End If
            If String.IsNullOrWhiteSpace(txtLibelle.Text) AndAlso Not String.IsNullOrEmpty(libelleDefaut) Then
                txtLibelle.Text = libelleDefaut
            End If
        End If

        ' --- Lignes : remplacer toutes les lignes courantes ---
        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        dt.Rows.Clear()

        Dim ordre As Integer = 0
        For Each tplRow As DataRow In ds.Tables(1).Rows
            ordre += 1
            Dim dr As DataRow = dt.NewRow()
            dr("Id") = -ordre
            dr("PlanComptableId") = If(IsDBNull(tplRow("PlanComptableId")), 0, CInt(tplRow("PlanComptableId")))
            dr("AccountNumero") = If(IsDBNull(tplRow("AccountNumero")), "", tplRow("AccountNumero").ToString())
            dr("AccountName") = If(IsDBNull(tplRow("AccountName")), "", tplRow("AccountName").ToString())
            dr("AccountDisplay") = dr("AccountNumero").ToString() & " - " & dr("AccountName").ToString()
            dr("PartyId") = 0
            dr("Libelle") = If(IsDBNull(tplRow("Libelle")), "", tplRow("Libelle").ToString())
            dr("MontantDebit") = If(IsDBNull(tplRow("MontantDebit")), 0D, Convert.ToDouble(tplRow("MontantDebit")))
            dr("MontantCredit") = If(IsDBNull(tplRow("MontantCredit")), 0D, Convert.ToDouble(tplRow("MontantCredit")))
            dr("Dirty") = 1
            dr("Deleted") = 0
            dr("Ordre") = ordre
            dt.Rows.Add(dr)
        Next

        ViewState("LinesTable") = dt
    End Sub

    ' =========================================================
    '  HELPERS
    ' =========================================================

    Private Function GetCurrentUserId() As Integer
        ' TODO : adapter selon votre mécanisme d'authentification
        Return 1
    End Function

    ' =========================================================
    '  LOCALISATION (fr / en / es)
    ' =========================================================

    ''' <summary>Traductions de l'écran d'édition d'une écriture de journal (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Écriture comptable — Édition", "Journal entry — Edit", "Asiento contable — Edición")

            ' Badges de statut
            Case "badgeValidee" : Return Choose3(lang, "Validée 🔒", "Validated 🔒", "Validado 🔒")
            Case "badgeExtournee" : Return Choose3(lang, "Extournée", "Reversed", "Reversado")
            Case "badgeBalanced" : Return Choose3(lang, "Équilibré ✓", "Balanced ✓", "Cuadrado ✓")
            Case "badgeUnbalanced" : Return Choose3(lang, "Déséquilibré ✗", "Unbalanced ✗", "Descuadrado ✗")
            Case "badgeEmpty" : Return Choose3(lang, "Vide", "Empty", "Vacío")

            ' Boutons / actions
            Case "loadTemplate" : Return Choose3(lang, "📋 Charger un template", "📋 Load a template", "📋 Cargar una plantilla")
            Case "addLineTooltip" : Return Choose3(lang, "Ajouter une ligne", "Add a line", "Agregar una línea")
            Case "save" : Return Choose3(lang, "Enregistrer l'écriture", "Save entry", "Guardar asiento")

            ' Libellés en-tête
            Case "journal" : Return Choose3(lang, "Journal", "Journal", "Diario")
            Case "periode" : Return Choose3(lang, "Période", "Period", "Período")
            Case "dateEcriture" : Return Choose3(lang, "Date écriture", "Entry date", "Fecha de asiento")
            Case "validerEcriture" : Return Choose3(lang, "Valider l'écriture", "Validate the entry", "Validar el asiento")
            Case "noPiece" : Return Choose3(lang, "No pièce", "Voucher no.", "N.º de comprobante")
            Case "libelleEcriture" : Return Choose3(lang, "Libellé de l'écriture", "Entry description", "Descripción del asiento")
            Case "lignesEcriture" : Return Choose3(lang, "Lignes d'écriture", "Entry lines", "Líneas del asiento")

            ' En-têtes de colonnes des lignes
            Case "colCompte" : Return Choose3(lang, "Compte", "Account", "Cuenta")
            Case "colLibelleLigne" : Return Choose3(lang, "Libellé ligne", "Line description", "Descripción de línea")
            Case "colDebit" : Return Choose3(lang, "Débit", "Debit", "Débito")
            Case "colCredit" : Return Choose3(lang, "Crédit", "Credit", "Crédito")

            ' Totaux (footer)
            Case "totalDebit" : Return Choose3(lang, "Total Débit", "Total Debit", "Total Débito")
            Case "totalCredit" : Return Choose3(lang, "Total Crédit", "Total Credit", "Total Crédito")
            Case "ecart" : Return Choose3(lang, "Écart (D − C)", "Difference (D − C)", "Diferencia (D − C)")

            ' Placeholders / valeurs par défaut
            Case "phSelect" : Return Choose3(lang, "Sélectionner...", "Select...", "Seleccionar...")
            Case "phNumeroPiece" : Return Choose3(lang, "(auto si laissé vide)", "(auto if left blank)", "(automático si se deja vacío)")
            Case "phLibelle" : Return Choose3(lang, "Description / mémo...", "Description / memo...", "Descripción / nota...")
            Case "phLineLibelle" : Return Choose3(lang, "Description ligne...", "Line description...", "Descripción de línea...")
            Case "accountSelectorDefault" : Return Choose3(lang, "Sélectionner un compte ▾", "Select an account ▾", "Seleccionar una cuenta ▾")

            ' Pickers comptes / templates
            Case "searchAccount" : Return Choose3(lang, "Rechercher un compte...", "Search for an account...", "Buscar una cuenta...")
            Case "searchTemplate" : Return Choose3(lang, "Rechercher un template...", "Search for a template...", "Buscar una plantilla...")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "noAccount" : Return Choose3(lang, "Aucun compte trouvé.", "No account found.", "No se encontró ninguna cuenta.")
            Case "noTemplate" : Return Choose3(lang, "Aucun template défini.", "No template defined.", "Ninguna plantilla definida.")
            Case "prefilled" : Return Choose3(lang, "💰 pré-rempli", "💰 pre-filled", "💰 pre-rellenado")

            ' Confirmations JS
            Case "jsConfirmTemplate" : Return Choose3(lang, "Charger ce template écrasera les lignes actuelles. Continuer ?", "Loading this template will overwrite the current lines. Continue?", "Cargar esta plantilla sobrescribirá las líneas actuales. ¿Continuar?")
            Case "jsConfirmDelete" : Return Choose3(lang, "Supprimer cette ligne ?", "Delete this line?", "¿Eliminar esta línea?")

            ' Alertes de validation / erreur
            Case "alertJournal" : Return Choose3(lang, "Veuillez sélectionner un journal.", "Please select a journal.", "Seleccione un diario.")
            Case "alertPeriode" : Return Choose3(lang, "Veuillez sélectionner une période.", "Please select a period.", "Seleccione un período.")
            Case "alertDate" : Return Choose3(lang, "Veuillez saisir une date.", "Please enter a date.", "Ingrese una fecha.")
            Case "alertLibelle" : Return Choose3(lang, "Le libellé de l'écriture est obligatoire.", "The entry description is required.", "La descripción del asiento es obligatoria.")
            Case "alertMin2Lines" : Return Choose3(lang, "Une écriture doit comporter au moins 2 lignes.", "An entry must have at least 2 lines.", "Un asiento debe tener al menos 2 líneas.")
            Case "alertAccountRequired" : Return Choose3(lang, "Toutes les lignes doivent avoir un compte sélectionné.", "All lines must have an account selected.", "Todas las líneas deben tener una cuenta seleccionada.")
            Case "alertAmountRequired" : Return Choose3(lang, "Toutes les lignes doivent avoir un montant Débit ou Crédit.", "All lines must have a Debit or Credit amount.", "Todas las líneas deben tener un importe en Débito o Crédito.")
            Case "alertBothSides" : Return Choose3(lang, "Une ligne ne peut avoir un montant à la fois en Débit et en Crédit.", "A line cannot have an amount in both Debit and Credit.", "Una línea no puede tener un importe en Débito y Crédito a la vez.")
            Case "alertUnbalanced" : Return Choose3(lang, "L'écriture n'est pas équilibrée. Débit = {0} / Crédit = {1}", "The entry is not balanced. Debit = {0} / Credit = {1}", "El asiento no está cuadrado. Débito = {0} / Crédito = {1}")
            Case "alertTotalPositive" : Return Choose3(lang, "Le total de l'écriture doit être supérieur à 0.", "The entry total must be greater than 0.", "El total del asiento debe ser mayor que 0.")
            Case "alertSaveError" : Return Choose3(lang, "Erreur lors de l'enregistrement : {0}", "Error while saving: {0}", "Error al guardar: {0}")

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
