Imports System.Data.SqlClient
Imports Telerik.Web.UI




Public Class wbfReceiptEdit
    Inherits clsData

    ' =========================================================
    '  PROPRIÉTÉS EN VIEWSTATE
    ' =========================================================

    Property PartyId() As Integer
        Get
            Try
                If ViewState("PartyId") Is Nothing Then ViewState("PartyId") = 0
                Return CInt(ViewState("PartyId"))
            Catch
                Return 0
            End Try
        End Get
        Set(value As Integer)
            ViewState("PartyId") = value
        End Set
    End Property

    Property CustomerGUID() As Guid
        Get
            Try
                If ViewState("CustomerGUID") Is Nothing Then ViewState("CustomerGUID") = New Guid("00000000-0000-0000-0000-000000000000")
                Return CType(ViewState("CustomerGUID"), Guid)
            Catch
                Return New Guid("00000000-0000-0000-0000-000000000000")
            End Try
        End Get
        Set(value As Guid)
            ViewState("CustomerGUID") = value
        End Set
    End Property

    Property Comptabilise() As Boolean
        Get
            Try
                If ViewState("Comptabilise") Is Nothing Then ViewState("Comptabilise") = False
                Return CBool(ViewState("Comptabilise"))
            Catch
                Return False
            End Try
        End Get
        Set(value As Boolean)
            ViewState("Comptabilise") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LOAD
    ' =========================================================

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then

            ' PartyId optionnel en QueryString pour pré-sélectionner un client
            Dim qsParty As Integer = 0
            Integer.TryParse(Request.QueryString("PartyId"), qsParty)
            PartyId = qsParty

            CreateInvoicesTable()

            If PartyId > 0 Then
                LoadCustomerHeader(PartyId)
                LoadOpenInvoicesFromBD(PartyId)
            End If

            ' Date encaissement par défaut = aujourd'hui
            dpDateEncaissement.SelectedDate = Date.Today

            ' Type règlement par défaut
            cbTypeReglement.SelectedValue = "CHEQUE"

            BindInvoiceGrid()
            SetCustomerClickHandler()
            SetBankClickHandler()
        End If

        ApplyReadOnlyMode()

    End Sub

    ' =========================================================
    '  TABLE EN MÉMOIRE DES FACTURES OUVERTES
    ' =========================================================

    ''' <summary>
    ''' Crée la DataTable vide qui va stocker les factures ouvertes du client
    ''' et le montant à imputer sur chacune.
    ''' </summary>
    Public Sub CreateInvoicesTable()
        Dim dt As New DataTable
        dt.Columns.Add("DocumentId", GetType(Integer))
        dt.Columns.Add("DocumentNumber", GetType(String))
        dt.Columns.Add("IssueDate", GetType(Date))
        dt.Columns.Add("Total", GetType(Double))
        dt.Columns.Add("DejaRecu", GetType(Double))
        dt.Columns.Add("Reste", GetType(Double))
        dt.Columns.Add("AImputer", GetType(Double))
        ViewState("InvoicesTable") = dt
    End Sub

    ''' <summary>
    ''' Charge les factures ouvertes (non totalement payées) d'un client depuis la BD.
    ''' Procédure attendue : s0100GetOpenInvoicesByParty (@PartyId)
    ''' Retourne : DocumentId, DocumentNumber, IssueDate, Total, DejaRecu, Reste
    ''' </summary>
    Public Sub LoadOpenInvoicesFromBD(pPartyId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@PartyId", pPartyId))

        Dim ds As DataSet = ExecuteSQLds("s0100GetOpenInvoicesByParty", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        Dim dt As DataTable = CType(ViewState("InvoicesTable"), DataTable)
        dt.Rows.Clear()

        For Each orow As DataRow In ds.Tables(0).Rows
            Dim dr As DataRow = dt.NewRow()
            dr("DocumentId") = orow("DocumentId")
            dr("DocumentNumber") = orow("DocumentNumber").ToString()
            dr("IssueDate") = Convert.ToDateTime(orow("IssueDate"))
            dr("Total") = If(IsDBNull(orow("Total")), 0D, Convert.ToDouble(orow("Total")))
            dr("DejaRecu") = If(IsDBNull(orow("DejaRecu")), 0D, Convert.ToDouble(orow("DejaRecu")))
            dr("Reste") = If(IsDBNull(orow("Reste")), 0D, Convert.ToDouble(orow("Reste")))
            dr("AImputer") = 0D
            dt.Rows.Add(dr)
        Next

        ViewState("InvoicesTable") = dt
    End Sub

    ''' <summary>
    ''' Binding du Repeater avec les factures ouvertes.
    ''' </summary>
    Public Sub BindInvoiceGrid()
        Dim dt As DataTable = CType(ViewState("InvoicesTable"), DataTable)
        If dt Is Nothing Then Return

        Dim dv As New DataView(dt)
        dv.Sort = "IssueDate ASC"

        rpInvoices.DataSource = dv
        rpInvoices.DataBind()
    End Sub

    ''' <summary>
    ''' Met à jour le ViewState("InvoicesTable") avec les montants saisis par l'utilisateur
    ''' dans chaque ligne du Repeater. À appeler avant toute action serveur.
    ''' </summary>
    Sub UpdateAllInvoicesInViewstate()
        Dim dt As DataTable = TryCast(ViewState("InvoicesTable"), DataTable)
        If dt Is Nothing Then Exit Sub

        For Each item As RepeaterItem In rpInvoices.Items
            If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then
                Continue For
            End If

            Dim hid As HiddenField = TryCast(item.FindControl("hidDocumentId"), HiddenField)
            If hid Is Nothing OrElse String.IsNullOrWhiteSpace(hid.Value) Then Continue For

            Dim docId As Integer
            If Not Integer.TryParse(hid.Value, docId) Then Continue For

            Dim numAImputer As RadTextBox = TryCast(item.FindControl("numAImputer"), RadTextBox)
            Dim aImputer As Double = 0
            If numAImputer IsNot Nothing Then
                aImputer = ToDoubleAnyCulture(numAImputer.Text)
            End If

            Dim rows() As DataRow = dt.Select("DocumentId=" & docId.ToString())
            If rows Is Nothing OrElse rows.Length = 0 Then Continue For
            rows(0)("AImputer") = aImputer
        Next

        ViewState("InvoicesTable") = dt
    End Sub

    ' =========================================================
    '  BINDING EN-TÊTE CLIENT
    ' =========================================================

    ''' <summary>
    ''' Charge les infos du client sélectionné.
    ''' </summary>
    Sub LoadCustomerHeader(pPartyId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@PartyId", pPartyId))

        Dim ds As DataSet = ExecuteSQLds("s0037GetCustomerFullById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim orow As DataRow = ds.Tables(0).Rows(0)
        lblCustomer.Text = orow("Name").ToString()
        rdLabel.Text = orow("FullName").ToString()
        CustomerGUID = CType(orow("PartyGUID"), Guid)
    End Sub

    Sub SetCustomerClickHandler()
        lblCustomer.Attributes.Add("onclick", "openCustomerPicker(this)")
    End Sub

    Sub SetBankClickHandler()
        lblBank.Attributes.Add("onclick", "openBankPicker(this)")
    End Sub

    ' =========================================================
    '  READ-ONLY MODE
    ' =========================================================

    Private Sub ApplyReadOnlyMode()
        If Comptabilise Then
            lblPostedBadge.Visible = True
            chkPost.Enabled = False
            pnlMain.CssClass &= " readonly"
            lblCustomer.CssClass &= " readonly-click-block"
            lblBank.CssClass &= " readonly-click-block"
            dpDateEncaissement.Enabled = False
            cbTypeReglement.Enabled = False
            txtReference.Enabled = False
            txtMontantRecu.Enabled = False
            radSave.Enabled = False

            For Each item As RepeaterItem In rpInvoices.Items
                Dim numAImputer = CType(item.FindControl("numAImputer"), RadTextBox)
                If numAImputer IsNot Nothing Then numAImputer.Enabled = False

                Dim btnFillRest = CType(item.FindControl("btnFillRest"), RadImageButton)
                If btnFillRest IsNot Nothing Then btnFillRest.Visible = False
            Next
        Else
            lblPostedBadge.Visible = False
        End If
    End Sub

    ' =========================================================
    '  SAUVEGARDE — APPEL DE sp_EncaisserFactureClient PAR LIGNE
    ' =========================================================

    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        If Comptabilise Then Return
        UpdateAllInvoicesInViewstate()

        ' Validation minimale
        If PartyId <= 0 Then
            RegisterAlert("Veuillez sélectionner un client.")
            Return
        End If

        Dim noCompteBanque As String = hidSelectedBankId.Value
        If String.IsNullOrWhiteSpace(noCompteBanque) Then
            RegisterAlert("Veuillez sélectionner un compte banque.")
            Return
        End If

        Dim dateEnc As Date = If(dpDateEncaissement.SelectedDate.HasValue, dpDateEncaissement.SelectedDate.Value, Date.Today)
        Dim typeRegl As String = If(cbTypeReglement.SelectedValue, "CHEQUE")
        Dim reference As String = txtReference.Text.Trim()

        Dim dt As DataTable = CType(ViewState("InvoicesTable"), DataTable)
        If dt Is Nothing Then Return

        ' Filtrer les lignes à imputer (> 0)
        Dim linesToPost As List(Of DataRow) = dt.AsEnumerable().
            Where(Function(r) Convert.ToDouble(r("AImputer")) > 0.005).ToList()

        If linesToPost.Count = 0 Then
            RegisterAlert("Aucun montant à imputer. Saisissez au moins un montant dans la colonne ""À imputer"".")
            Return
        End If

        ' Vérifier que Sum(AImputer) <= MontantReçu (tolérance 1 cent)
        Dim sumImpute As Double = linesToPost.Sum(Function(r) Convert.ToDouble(r("AImputer")))
        Dim montantRecu As Double = ToDoubleAnyCulture(txtMontantRecu.Text)
        If montantRecu > 0 AndAlso Math.Abs(sumImpute - montantRecu) > 0.01 Then
            ' Message informatif mais non bloquant (le user peut vouloir un encaissement partiel)
            ' Si vous voulez rendre bloquant, remplacer par Return après l'alerte
        End If

        ' Vérifier que chaque AImputer <= Reste
        For Each row As DataRow In linesToPost
            Dim aImputer As Double = Convert.ToDouble(row("AImputer"))
            Dim reste As Double = Convert.ToDouble(row("Reste"))
            If aImputer - reste > 0.005 Then
                RegisterAlert("Le montant à imputer sur la facture " & row("DocumentNumber").ToString() &
                              " dépasse le reste à recevoir.")
                Return
            End If
        Next

        ' Boucler sur chaque facture : 1 appel à sp_EncaisserFactureClient par ligne
        Using conn As New SqlConnection(ConnectionString)
            conn.Open()
            Using tx As SqlTransaction = conn.BeginTransaction()
                Try
                    For Each row As DataRow In linesToPost
                        Dim docId As Integer = Convert.ToInt32(row("DocumentId"))
                        Dim aImputer As Double = Convert.ToDouble(row("AImputer"))

                        Using cmd As New SqlCommand("sp_EncaisserFactureClient", conn, tx)
                            cmd.CommandType = CommandType.StoredProcedure
                            cmd.Parameters.AddWithValue("@DocumentId", docId)
                            cmd.Parameters.AddWithValue("@MontantEncaisse", aImputer)
                            cmd.Parameters.AddWithValue("@DateEncaissement", dateEnc)
                            cmd.Parameters.AddWithValue("@CompteBanque", noCompteBanque)
                            cmd.Parameters.AddWithValue("@TypeReglement", typeRegl)

                            If Not String.IsNullOrWhiteSpace(reference) Then
                                cmd.Parameters.AddWithValue("@Reference", reference)
                            Else
                                cmd.Parameters.AddWithValue("@Reference", DBNull.Value)
                            End If

                            cmd.Parameters.AddWithValue("@UserId", GetCurrentUserId())
                            cmd.ExecuteNonQuery()
                        End Using
                    Next

                    tx.Commit()
                Catch ex As Exception
                    tx.Rollback()
                    RegisterAlert("Erreur lors de l'enregistrement : " & ex.Message)
                    Return
                End Try
            End Using
        End Using

        ' Fermeture de la RadWindow parente
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    ''' <summary>
    ''' Retourne l'Id de l'utilisateur courant.
    ''' TODO : adapter à votre mécanisme d'authentification (Session, Membership, etc.)
    ''' </summary>
    Private Function GetCurrentUserId() As Integer
        ' Exemple : Return CInt(Session("UserId"))
        Return 1
    End Function

    Private Sub RegisterAlert(msg As String)
        Dim safe As String = msg.Replace("'", "\'").Replace(Chr(13), " ").Replace(Chr(10), " ")
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "alert_" & Guid.NewGuid().ToString("N"),
                                            "alert('" & safe & "');", True)
    End Sub

    ' =========================================================
    '  DATA SOURCES POUR LES PICKERS
    ' =========================================================

    Private Function GetCustomersTable() As DataTable
        Dim ds As DataSet = ExecuteSQLds("s0043Get_Party 'Client'")
        Return ds.Tables(0)
    End Function

    Private Function GetBanksTable() As DataTable
        ' Retourne les comptes de type Banque du plan comptable.
        ' TODO : adapter selon votre procédure (filtrer par ClasseId = 'BANQUE' ou équivalent)
        Dim ds As DataSet = ExecuteSQLds("s0091Get_GLAccounts_BANQUE")
        Return ds.Tables(0)
    End Function

    Private Sub rlvCustomers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCustomers.NeedDataSource
        Dim dt As DataTable = GetCustomersTable()
        rlvCustomers.DataSource = dt
    End Sub

    Private Sub rlvBanks_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvBanks.NeedDataSource
        Dim dt As DataTable = GetBanksTable()
        rlvBanks.DataSource = dt
    End Sub

    ' =========================================================
    '  AJAX REQUEST (sélections depuis les pickers JS)
    ' =========================================================

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If Comptabilise Then Return

        Dim AllParam As String() = e.Argument.Split("|"c)
        If AllParam.Length < 2 Then Return

        Dim CommandName As String = AllParam(0)

        Select Case CommandName

            Case "CUSTOMER"
                Dim customerId As Integer = 0
                If Integer.TryParse(AllParam(1), customerId) Then
                    UpdateAllInvoicesInViewstate()
                    PartyId = customerId
                    LoadCustomerHeader(customerId)
                    LoadOpenInvoicesFromBD(customerId)
                    BindInvoiceGrid()
                End If

            Case "BANK"
                Dim noCompte As String = AllParam(1)
                UpdateBankDisplay(noCompte)

        End Select
    End Sub

    ''' <summary>
    ''' Met à jour l'affichage du compte banque sélectionné.
    ''' </summary>
    Sub UpdateBankDisplay(noCompte As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@NoCompte", noCompte))

        ' Récupère le nom du compte à partir de son numéro.
        ' TODO : adapter au nom de votre procédure.
        Dim ds As DataSet = ExecuteSQLds("s0092Get_GLAccountByNoCompte", p)

        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim orow As DataRow = ds.Tables(0).Rows(0)
            lblBank.Text = orow("NoCompte").ToString() & " - " & orow("Name").ToString()
            hidBankCompte.Value = noCompte
        Else
            lblBank.Text = noCompte
            hidBankCompte.Value = noCompte
        End If
    End Sub

End Class
