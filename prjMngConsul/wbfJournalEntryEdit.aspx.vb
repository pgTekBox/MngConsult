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

        ApplyReadOnlyMode()
    End Sub

    ' =========================================================
    '  COMBOS DE RÉFÉRENCE
    ' =========================================================

    Sub LoadJournauxCombo()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", GetCompanyGUID()))
        Dim ds As DataSet = ExecuteSQLds("s0114Get_Journaux", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        cbJournal.DataSource = ds.Tables(0)
        cbJournal.DataBind()
    End Sub

    Sub LoadPeriodesCombo()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", GetCompanyGUID()))
        Dim ds As DataSet = ExecuteSQLds("s0115Get_PeriodesOuvertes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        cbPeriode.DataSource = ds.Tables(0)
        cbPeriode.DataBind()
    End Sub

    ' =========================================================
    '  TABLE EN MÉMOIRE DES LIGNES (T136LignesEcriture)
    ' =========================================================

    Public Sub CreateLinesTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("PlanComptableId", GetType(Integer))
        dt.Columns.Add("AccountNumero", GetType(String))
        dt.Columns.Add("AccountName", GetType(String))
        dt.Columns.Add("AccountDisplay", GetType(String))
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
        dr("AccountDisplay") = "Sélectionner un compte ▾"
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
    ''' Charge l'en-tête de l'écriture depuis la BD.
    ''' Procédure : s0110GetEcritureById
    ''' Retourne : Id, JournauxId, PeriodeId, PartyId, DateEcriture,
    '''            NumeroPiece, Libelle, Statut, SourceType, ...
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
    ''' Procédure : s0111GetEcritureLignes
    ''' Retourne : Id, PlanComptableId, AccountNumero, AccountName, PartyId,
    '''            Libelle, MontantDebit, MontantCredit, Ordre
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
    ''' À appeler avant toute action serveur.
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
    '  READ-ONLY MODE (écritures VALIDEE ou EXTOURNEE)
    ' =========================================================

    Private Sub ApplyReadOnlyMode()
        ' Badges de statut
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
            ' L'attribut onclick est ajouté côté JS via wireAccountSelectors
            ' (mais on peut aussi l'attacher ici si on veut un clic direct sans JS)

            Dim planComptableId As Object = DataBinder.Eval(e.Item.DataItem, "PlanComptableId")
            If planComptableId IsNot Nothing AndAlso CInt(planComptableId) > 0 Then
                lblAccount.Text = DataBinder.Eval(e.Item.DataItem, "AccountDisplay").ToString()
            Else
                lblAccount.Text = "Sélectionner un compte ▾"
            End If
        End If
    End Sub

    ' =========================================================
    '  SAUVEGARDE
    ' =========================================================

    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        If IsReadOnly() Then Return
        UpdateAllLinesInViewstate()

        ' --- Validations en-tête ---
        If String.IsNullOrEmpty(cbJournal.SelectedValue) Then
            RegisterAlert("Veuillez sélectionner un journal.")
            Return
        End If
        If String.IsNullOrEmpty(cbPeriode.SelectedValue) Then
            RegisterAlert("Veuillez sélectionner une période.")
            Return
        End If
        If Not dpDateEcriture.SelectedDate.HasValue Then
            RegisterAlert("Veuillez saisir une date.")
            Return
        End If
        If String.IsNullOrWhiteSpace(txtLibelle.Text) Then
            RegisterAlert("Le libellé de l'écriture est obligatoire.")
            Return
        End If

        ' --- Validations lignes ---
        Dim dt As DataTable = CType(ViewState("LinesTable"), DataTable)
        Dim activeLines = dt.AsEnumerable().Where(Function(r) Convert.ToInt32(r("Deleted")) = 0).ToList()

        If activeLines.Count < 2 Then
            RegisterAlert("Une écriture doit comporter au moins 2 lignes.")
            Return
        End If

        For Each row In activeLines
            If Convert.ToInt32(row("PlanComptableId")) <= 0 Then
                RegisterAlert("Toutes les lignes doivent avoir un compte sélectionné.")
                Return
            End If
            Dim d As Double = Convert.ToDouble(row("MontantDebit"))
            Dim c As Double = Convert.ToDouble(row("MontantCredit"))
            ' La contrainte chk_T136_UnSeulCote exige Débit XOR Crédit
            If d <= 0 AndAlso c <= 0 Then
                RegisterAlert("Toutes les lignes doivent avoir un montant Débit ou Crédit.")
                Return
            End If
            If d > 0 AndAlso c > 0 Then
                RegisterAlert("Une ligne ne peut avoir un montant à la fois en Débit et en Crédit.")
                Return
            End If
        Next

        ' Doit balancer
        Dim totDebit As Double = activeLines.Sum(Function(r) Convert.ToDouble(r("MontantDebit")))
        Dim totCredit As Double = activeLines.Sum(Function(r) Convert.ToDouble(r("MontantCredit")))
        If Math.Abs(totDebit - totCredit) > 0.005 Then
            RegisterAlert("L'écriture n'est pas équilibrée. Débit = " & totDebit.ToString("N2") &
                          " / Crédit = " & totCredit.ToString("N2"))
            Return
        End If
        If totDebit <= 0 Then
            RegisterAlert("Le total de l'écriture doit être supérieur à 0.")
            Return
        End If

        ' --- Sauvegarde via TVP : sp_SaveEcriture ---
        Dim DRconn As New SqlConnection(ConnectionString)
        Dim oCom As New SqlCommand("sp_SaveEcriture", DRconn)
        oCom.CommandType = CommandType.StoredProcedure

        oCom.Parameters.Add(New SqlParameter("@EcritureId", SqlDbType.Int) With {.Value = EcritureId})
        oCom.Parameters.Add(New SqlParameter("@CompanyGUID", SqlDbType.UniqueIdentifier) With {.Value = GetCompanyGUID()})
        oCom.Parameters.Add(New SqlParameter("@JournauxId", SqlDbType.Int) With {.Value = CInt(cbJournal.SelectedValue)})
        oCom.Parameters.Add(New SqlParameter("@PeriodeId", SqlDbType.Int) With {.Value = CInt(cbPeriode.SelectedValue)})
        oCom.Parameters.Add(New SqlParameter("@PartyId", SqlDbType.Int) With {.Value = DBNull.Value})
        oCom.Parameters.Add(New SqlParameter("@DateEcriture", SqlDbType.Date) With {.Value = dpDateEcriture.SelectedDate.Value})
        oCom.Parameters.Add(New SqlParameter("@NumeroPiece", SqlDbType.VarChar, 50) With {.Value = If(String.IsNullOrEmpty(txtNumeroPiece.Text), CType(DBNull.Value, Object), txtNumeroPiece.Text.Trim())})
        oCom.Parameters.Add(New SqlParameter("@Libelle", SqlDbType.VarChar, 250) With {.Value = txtLibelle.Text.Trim()})
        oCom.Parameters.Add(New SqlParameter("@ToValider", SqlDbType.Bit) With {.Value = If(chkValider.Checked, 1, 0)})
        oCom.Parameters.Add(New SqlParameter("@UserId", SqlDbType.Int) With {.Value = GetCurrentUserId()})

        Dim ParamLignes As New SqlParameter("@Lignes", SqlDbType.Structured)
        ParamLignes.Value = dt
        ParamLignes.TypeName = "dbo.TVP_LigneEcriture"
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

        ' Fermeture de la fenêtre
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
        p.Add(New SqlParameter("@CompanyGUID", GetCompanyGUID()))
        Dim ds As DataSet = ExecuteSQLds("s0093Get_PlanComptable_All", p)
        Return ds.Tables(0)
    End Function

    Private Sub rlvAccounts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAccounts.NeedDataSource
        rlvAccounts.DataSource = GetAccountsTable()
    End Sub

    ' =========================================================
    '  PICKER TEMPLATES
    ' =========================================================

    Private Function GetTemplatesTable() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", GetCompanyGUID()))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        p.Add(New SqlParameter("@OnlyActive", 1))
        p.Add(New SqlParameter("@JournauxId", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0120SearchTemplates", p)
        Return ds.Tables(0)
    End Function

    Private Sub rlvTemplates_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvTemplates.NeedDataSource
        rlvTemplates.DataSource = GetTemplatesTable()
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
    ''' s0123ApplyTemplateToEcriture retourne 2 result sets :
    '''   1) En-tête : JournauxId, LibelleDefaut, MontantsPreRemplis
    '''   2) Lignes : PlanComptableId, AccountNumero, AccountName, Libelle,
    '''               MontantDebit, MontantCredit, Ordre
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
            dr("Id") = -ordre  ' Id négatif → considéré comme nouveau à la sauvegarde
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

    Private Function GetCompanyGUID() As Guid
        ' TODO : adapter — Return CType(Session("CompanyGUID"), Guid)
        Return Guid.Empty
    End Function

End Class
