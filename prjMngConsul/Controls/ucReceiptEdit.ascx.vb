Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class ucReceiptEdit
    Inherits clsDataUC

    ''' <summary>True quand l'usercontrol est hébergé dans la page pop-up (RadWindow) :
    ''' après enregistrement on ferme la fenêtre ; sinon (master page) on affiche un
    ''' message et on reste sur la page.</summary>
    Public Property IsPopup As Boolean
        Get
            Return CBool(If(ViewState("IsPopup"), False))
        End Get
        Set(value As Boolean)
            ViewState("IsPopup") = value
        End Set
    End Property

    ' =========================================================
    '  PROPRIÉTÉS EN VIEWSTATE
    ' =========================================================

    ''' <summary>
    ''' Sens du règlement : "ENCAISSEMENT" (client) ou "DECAISSEMENT" (fournisseur).
    ''' Récupéré depuis la querystring ?Sens=... au premier load.
    ''' </summary>
    Property Sens() As String
        Get
            Try
                If ViewState("Sens") Is Nothing Then ViewState("Sens") = "ENCAISSEMENT"
                Return ViewState("Sens").ToString()
            Catch
                Return "ENCAISSEMENT"
            End Try
        End Get
        Set(value As String)
            ViewState("Sens") = value
        End Set
    End Property

    Public Function IsEncaissement() As Boolean
        Return Sens = "ENCAISSEMENT"
    End Function

    Public Function IsDecaissement() As Boolean
        Return Sens = "DECAISSEMENT"
    End Function

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

    ''' <summary>
    ''' GUID du tiers (client ou fournisseur selon le sens).
    ''' </summary>
    Property TiersGUID() As Guid
        Get
            Try
                If ViewState("TiersGUID") Is Nothing Then ViewState("TiersGUID") = New Guid("00000000-0000-0000-0000-000000000000")
                Return CType(ViewState("TiersGUID"), Guid)
            Catch
                Return New Guid("00000000-0000-0000-0000-000000000000")
            End Try
        End Get
        Set(value As Guid)
            ViewState("TiersGUID") = value
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
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            ' Récupérer le sens depuis la querystring (ENCAISSEMENT par défaut)
            Dim qsSens As String = Request.QueryString("Sens")
            If String.IsNullOrEmpty(qsSens) Then qsSens = "ENCAISSEMENT"
            qsSens = qsSens.ToUpper()
            If qsSens <> "ENCAISSEMENT" AndAlso qsSens <> "DECAISSEMENT" Then qsSens = "ENCAISSEMENT"
            Sens = qsSens

            ' PartyId optionnel en QueryString pour pré-sélectionner un tiers
            Dim qsParty As Integer = 0
            Integer.TryParse(Request.QueryString("PartyId"), qsParty)
            PartyId = qsParty

            ' Adapter les libellés selon le sens AVANT de charger les données
            ApplyLabelsForSens()

            CreateInvoicesTable()

            If PartyId > 0 Then
                LoadTiersHeader(PartyId)
                LoadOpenInvoicesFromBD(PartyId)
            End If

            ' Date par défaut = aujourd'hui
            dpDateEncaissement.SelectedDate = Date.Today

            ' Type règlement par défaut
            cbTypeReglement.SelectedValue = "CHEQUE"

            BindInvoiceGrid()
            SetTiersClickHandler()
            SetBankClickHandler()
        End If

        ApplyReadOnlyMode()

    End Sub

    ' =========================================================
    '  ADAPTATION DES LIBELLÉS SELON LE SENS
    ' =========================================================

    ''' <summary>
    ''' Adapte tous les libellés visibles selon que l'on soit en mode
    ''' ENCAISSEMENT (client) ou DECAISSEMENT (fournisseur).
    ''' </summary>
    Private Sub ApplyLabelsForSens()
        If IsEncaissement() Then
            Page.Title = L("titleEnc")
            lblTiersLabel.Text = L("client")
            lblCustomer.Text = L("selectClient")
            litLignesTitle.Text = L("openInvoicesEnc")
            lblMontantLabel.Text = L("amountReceived")
            litLabelDiff.Text = L("diffEnc")
            radSave.Text = L("saveEnc")
        Else
            Page.Title = L("titleDec")
            lblTiersLabel.Text = L("supplier")
            lblCustomer.Text = L("selectSupplier")
            litLignesTitle.Text = L("openInvoicesDec")
            lblMontantLabel.Text = L("amountPaid")
            litLabelDiff.Text = L("diffDec")
            radSave.Text = L("saveDec")
        End If

        ' Libellés communs (indépendants du sens)
        litDateLabel.Text = L("opDate")
        litTypeReglLabel.Text = L("paymentType")
        litReferenceLabel.Text = L("reference")
        litComptabiliseLabel.Text = L("posted")
        litCompteBanqueLabel.Text = L("bankAccount")
        lblBank.Text = L("selectBank")
        lblPostedBadge.Text = L("postedBadge")
        btnAutoImpute.Text = L("autoImpute")
        litColNoFacture.Text = L("colNoInvoice")
        litColDate.Text = L("colDate")
        litColTotal.Text = L("colTotal")
        litColDejaRecu.Text = L("colReceived")
        litColReste.Text = L("colRemaining")
        litColAImputer.Text = L("colToApply")
        litTotalDuLabel.Text = L("totalDue")
        litTotalImputeLabel.Text = L("totalApplied")
        txtReference.EmptyMessage = L("refShort")
        SetComboText("CHEQUE", L("payCheque"))
        SetComboText("VIREMENT", L("payTransfer"))
        SetComboText("ESPECES", L("payCash"))
        SetComboText("CARTE", L("payCard"))
        SetComboText("AUTRE", L("payOther"))
    End Sub

    Private Sub SetComboText(value As String, text As String)
        Dim it = cbTypeReglement.Items.FindItemByValue(value)
        If it IsNot Nothing Then it.Text = text
    End Sub

    ' =========================================================
    '  TABLE EN MÉMOIRE DES FACTURES OUVERTES
    ' =========================================================

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
    ''' Charge les factures ouvertes selon le sens :
    '''   - ENCAISSEMENT : factures CLIENTS non totalement encaissées
    '''   - DECAISSEMENT : factures FOURNISSEURS non totalement payées
    ''' </summary>
    Public Sub LoadOpenInvoicesFromBD(pPartyId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@PartyId", pPartyId))

        ' Choix de la procédure selon le sens
        Dim procName As String
        If IsEncaissement() Then
            procName = "s0100GetOpenInvoicesByParty"          ' Factures clients
        Else
            procName = "s0102GetOpenSupplierInvoicesByParty"  ' Factures fournisseurs
        End If

        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds(procName, p)
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

    Public Sub BindInvoiceGrid()
        Dim dt As DataTable = CType(ViewState("InvoicesTable"), DataTable)
        If dt Is Nothing Then Return

        Dim dv As New DataView(dt)
        dv.Sort = "IssueDate ASC"

        rpInvoices.DataSource = dv
        rpInvoices.DataBind()
    End Sub

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
    '  BINDING EN-TÊTE TIERS (client OU fournisseur)
    ' =========================================================

    ''' <summary>
    ''' Charge les infos du tiers sélectionné (client ou fournisseur).
    ''' s0037GetCustomerFullById retourne les infos d'un Party par son Id,
    ''' la même proc fonctionne pour les deux types.
    ''' </summary>
    Sub LoadTiersHeader(pPartyId As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@PartyId", pPartyId))
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0037GetCustomerFullById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim orow As DataRow = ds.Tables(0).Rows(0)
        lblCustomer.Text = orow("Name").ToString()
        rdLabel.Text = orow("FullName").ToString()
        TiersGUID = CType(orow("PartyGUID"), Guid)
    End Sub

    Sub SetTiersClickHandler()
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
    '  SAUVEGARDE
    '   - ENCAISSEMENT : appel de sp_EncaisserFactureClient par ligne
    '   - DECAISSEMENT : appel de sp_PayerFactureFournisseur par ligne
    ' =========================================================

    Private Sub radSave_Click(sender As Object, e As EventArgs) Handles radSave.Click
        If Comptabilise Then Return
        UpdateAllInvoicesInViewstate()

        ' Validation minimale
        If PartyId <= 0 Then
            RegisterAlert(If(IsEncaissement(), L("alertSelClient"), L("alertSelSupplier")))
            Return
        End If

        Dim noCompteBanque As String = hidSelectedBankId.Value
        If String.IsNullOrWhiteSpace(noCompteBanque) Then
            RegisterAlert(L("alertSelBank"))
            Return
        End If

        Dim dateOp As Date = If(dpDateEncaissement.SelectedDate.HasValue, dpDateEncaissement.SelectedDate.Value, Date.Today)
        Dim typeRegl As String = If(cbTypeReglement.SelectedValue, "CHEQUE")
        Dim reference As String = txtReference.Text.Trim()

        Dim dt As DataTable = CType(ViewState("InvoicesTable"), DataTable)
        If dt Is Nothing Then Return

        ' Filtrer les lignes à imputer (> 0)
        Dim linesToPost As List(Of DataRow) = dt.AsEnumerable().
            Where(Function(r) Convert.ToDouble(r("AImputer")) > 0.005).ToList()

        If linesToPost.Count = 0 Then
            RegisterAlert(L("alertNoAmount"))
            Return
        End If

        ' Vérifier que Sum(AImputer) <= MontantReçu (tolérance 1 cent)
        Dim sumImpute As Double = linesToPost.Sum(Function(r) Convert.ToDouble(r("AImputer")))
        Dim montantTotal As Double = ToDoubleAnyCulture(txtMontantRecu.Text)
        ' Note : laissé non bloquant (paiement partiel possible)

        ' Vérifier que chaque AImputer <= Reste
        For Each row As DataRow In linesToPost
            Dim aImputer As Double = Convert.ToDouble(row("AImputer"))
            Dim reste As Double = Convert.ToDouble(row("Reste"))
            If aImputer - reste > 0.005 Then
                RegisterAlert(String.Format(L("alertExceeds"), row("DocumentNumber").ToString()))
                Return
            End If
        Next

        ' Choix de la procédure et des noms de paramètres selon le sens
        Dim procName As String
        Dim paramMontantName As String
        Dim paramDateName As String

        If IsEncaissement() Then
            procName = "sp_EncaisserFactureClient"
            paramMontantName = "@MontantEncaisse"
            paramDateName = "@DateEncaissement"
        Else
            procName = "sp_PayerFactureFournisseur"
            paramMontantName = "@MontantPaye"
            paramDateName = "@DatePaiement"
        End If

        ' Boucler sur chaque facture : 1 appel par ligne, le tout dans une transaction
        Using conn As New SqlConnection(ConnectionString)
            conn.Open()
            Using tx As SqlTransaction = conn.BeginTransaction()
                Try
                    For Each row As DataRow In linesToPost
                        Dim docId As Integer = Convert.ToInt32(row("DocumentId"))
                        Dim aImputer As Double = Convert.ToDouble(row("AImputer"))

                        Using cmd As New SqlCommand(procName, conn, tx)
                            cmd.CommandType = CommandType.StoredProcedure
                            cmd.Parameters.AddWithValue("@DocumentId", docId)
                            cmd.Parameters.AddWithValue(paramMontantName, aImputer)
                            cmd.Parameters.AddWithValue(paramDateName, dateOp)
                            cmd.Parameters.AddWithValue("@CompteBanque", noCompteBanque)
                            cmd.Parameters.AddWithValue("@TypeReglement", typeRegl)
                            cmd.Parameters.AddWithValue("@CompanyGUID", Company)

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

                    Dim Mypdf As New clsGenerateInvoicePDF
                    For Each myrow As DataRow In linesToPost
                        Dim docId As Integer = Convert.ToInt32(myrow("DocumentId"))
                        Mypdf.GenerateAndDownloadPdf(docId)
                    Next






                Catch ex As Exception
                    tx.Rollback()
                    RegisterAlert(L("alertSaveError") & ex.Message)
                    Return
                End Try
            End Using
        End Using

        If IsPopup Then
            ' Hébergé en RadWindow : fermer la fenêtre parente.
            Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
            ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
        Else
            ' Hébergé en page master : message de succès + réinitialisation de l'écran.
            RegisterAlert(L("saved"))
            PartyId = 0
            TiersGUID = New Guid("00000000-0000-0000-0000-000000000000")
            lblCustomer.Text = If(IsEncaissement(), L("selectClient"), L("selectSupplier"))
            lblBank.Text = L("selectBank")
            hidSelectedBankId.Value = ""
            hidBankCompte.Value = ""
            txtMontantRecu.Text = "0.00"
            txtReference.Text = ""
            CreateInvoicesTable()
            BindInvoiceGrid()
        End If
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

    ''' <summary>
    ''' Liste des tiers selon le sens (clients ou fournisseurs).
    ''' Réutilise la même proc s0043Get_Party avec un paramètre différent.
    ''' </summary>
    Private Function GetTiersTable() As DataTable

        Dim ds As DataSet
        If IsEncaissement() Then
            Dim p As New Collection
            p.Add(New SqlParameter("@Type", "Client"))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            ds = ExecuteSQLds("s0043Get_Party", p)
        Else
            Dim p As New Collection
            p.Add(New SqlParameter("@Type", "Fournisseur"))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            ds = ExecuteSQLds("s0043Get_Party", p)
        End If


        Return ds.Tables(0)
    End Function

    Private Function GetBanksTable() As DataTable
        ' Même compte banque pour encaissement et décaissement
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0091Get_GLAccounts_BANQUE", p)
        Return ds.Tables(0)
    End Function

    Private Sub rlvCustomers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCustomers.NeedDataSource
        Dim dt As DataTable = GetTiersTable()
        rlvCustomers.DataSource = dt
    End Sub

    Private Sub rlvBanks_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvBanks.NeedDataSource
        Dim dt As DataTable = GetBanksTable()
        rlvBanks.DataSource = dt
    End Sub

    Private Sub rlvCustomers_PreRender(sender As Object, e As EventArgs) Handles rlvCustomers.PreRender
        SetLiteral(rlvCustomers, "litEmptyCustomers", L("emptyTiers"))
    End Sub

    Private Sub rlvBanks_PreRender(sender As Object, e As EventArgs) Handles rlvBanks.PreRender
        SetLiteral(rlvBanks, "litEmptyBanks", L("emptyBank"))
    End Sub

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

    ' =========================================================
    '  AJAX REQUEST (sélections depuis les pickers JS)
    ' =========================================================

    Private Sub rapReceipt_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles rapReceipt.AjaxRequest
        If Comptabilise Then Return

        Dim AllParam As String() = e.Argument.Split("|"c)
        If AllParam.Length < 2 Then Return

        Dim CommandName As String = AllParam(0)

        Select Case CommandName

            Case "CUSTOMER"
                ' Le picker JS envoie toujours "CUSTOMER" (même nom de commande
                ' pour les deux modes pour ne pas modifier le JS de l'aspx).
                ' L'interprétation côté VB dépend du Sens.
                Dim tiersId As Integer = 0
                If Integer.TryParse(AllParam(1), tiersId) Then
                    UpdateAllInvoicesInViewstate()
                    PartyId = tiersId
                    LoadTiersHeader(tiersId)
                    LoadOpenInvoicesFromBD(tiersId)
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
    ''' <summary>Traductions (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "titleEnc" : Return Choose3(lang, "Encaissement client — 60Sec-AI", "Customer cash receipt — 60Sec-AI", "Cobro de cliente — 60Sec-AI")
            Case "titleDec" : Return Choose3(lang, "Paiement fournisseur — 60Sec-AI", "Supplier payment — 60Sec-AI", "Pago a proveedor — 60Sec-AI")
            Case "client" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "supplier" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "selectClient" : Return Choose3(lang, "Sélectionner un client", "Select a customer", "Seleccionar un cliente")
            Case "selectSupplier" : Return Choose3(lang, "Sélectionner un fournisseur", "Select a supplier", "Seleccionar un proveedor")
            Case "openInvoicesEnc" : Return Choose3(lang, "Factures ouvertes à encaisser", "Open invoices to collect", "Facturas abiertas por cobrar")
            Case "openInvoicesDec" : Return Choose3(lang, "Factures ouvertes à payer", "Open invoices to pay", "Facturas abiertas por pagar")
            Case "amountReceived" : Return Choose3(lang, "Montant reçu total", "Total amount received", "Monto total recibido")
            Case "amountPaid" : Return Choose3(lang, "Montant payé total", "Total amount paid", "Monto total pagado")
            Case "diffEnc" : Return Choose3(lang, "Différence (reçu − imputé)", "Difference (received − applied)", "Diferencia (recibido − aplicado)")
            Case "diffDec" : Return Choose3(lang, "Différence (payé − imputé)", "Difference (paid − applied)", "Diferencia (pagado − aplicado)")
            Case "saveEnc" : Return Choose3(lang, "Enregistrer l'encaissement", "Save cash receipt", "Guardar cobro")
            Case "saveDec" : Return Choose3(lang, "Enregistrer le paiement", "Save payment", "Guardar pago")
            Case "opDate" : Return Choose3(lang, "Date de l'opération", "Operation date", "Fecha de la operación")
            Case "paymentType" : Return Choose3(lang, "Type de règlement", "Payment type", "Tipo de pago")
            Case "reference" : Return Choose3(lang, "Référence (No chèque, etc.)", "Reference (cheque no., etc.)", "Referencia (n.º de cheque, etc.)")
            Case "refShort" : Return Choose3(lang, "Réf…", "Ref…", "Ref…")
            Case "posted" : Return Choose3(lang, "Comptabilisé", "Posted", "Contabilizado")
            Case "postedBadge" : Return Choose3(lang, "Comptabilisé 🔒", "Posted 🔒", "Contabilizado 🔒")
            Case "bankAccount" : Return Choose3(lang, "Compte banque", "Bank account", "Cuenta bancaria")
            Case "selectBank" : Return Choose3(lang, "Sélectionner un compte banque", "Select a bank account", "Seleccionar una cuenta bancaria")
            Case "autoImpute" : Return Choose3(lang, "Imputer automatiquement", "Apply automatically", "Aplicar automáticamente")
            Case "colNoInvoice" : Return Choose3(lang, "No facture", "Invoice no.", "N.º factura")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colTotal" : Return Choose3(lang, "Total", "Total", "Total")
            Case "colReceived" : Return Choose3(lang, "Déjà reçu", "Received", "Recibido")
            Case "colRemaining" : Return Choose3(lang, "Reste", "Remaining", "Saldo")
            Case "colToApply" : Return Choose3(lang, "À imputer", "To apply", "A aplicar")
            Case "totalDue" : Return Choose3(lang, "Total dû (sélection)", "Total due (selection)", "Total adeudado (selección)")
            Case "totalApplied" : Return Choose3(lang, "Total imputé", "Total applied", "Total aplicado")
            Case "payCheque" : Return Choose3(lang, "Chèque", "Cheque", "Cheque")
            Case "payTransfer" : Return Choose3(lang, "Virement", "Transfer", "Transferencia")
            Case "payCash" : Return Choose3(lang, "Espèces", "Cash", "Efectivo")
            Case "payCard" : Return Choose3(lang, "Carte", "Card", "Tarjeta")
            Case "payOther" : Return Choose3(lang, "Autre", "Other", "Otro")
            Case "saved" : Return Choose3(lang, "Enregistré avec succès.", "Saved successfully.", "Guardado con éxito.")
            Case "alertSelClient" : Return Choose3(lang, "Veuillez sélectionner un client.", "Please select a customer.", "Seleccione un cliente.")
            Case "alertSelSupplier" : Return Choose3(lang, "Veuillez sélectionner un fournisseur.", "Please select a supplier.", "Seleccione un proveedor.")
            Case "alertSelBank" : Return Choose3(lang, "Veuillez sélectionner un compte banque.", "Please select a bank account.", "Seleccione una cuenta bancaria.")
            Case "alertNoAmount" : Return Choose3(lang, "Aucun montant à imputer. Saisissez au moins un montant dans la colonne « À imputer ».", "No amount to apply. Enter at least one amount in the ""To apply"" column.", "Ningún monto a aplicar. Ingrese al menos un monto en la columna «A aplicar».")
            Case "alertExceeds" : Return Choose3(lang, "Le montant à imputer sur la facture {0} dépasse le reste.", "The amount to apply on invoice {0} exceeds the remaining balance.", "El monto a aplicar en la factura {0} supera el saldo.")
            Case "alertSaveError" : Return Choose3(lang, "Erreur lors de l'enregistrement : ", "Error while saving: ", "Error al guardar: ")
            Case "alertAmountFirst" : Return Choose3(lang, "Veuillez saisir d'abord le montant reçu total.", "Please enter the total amount received first.", "Ingrese primero el monto total recibido.")
            Case "searchClient" : Return Choose3(lang, "Rechercher un client…", "Search a customer…", "Buscar un cliente…")
            Case "searchSupplier" : Return Choose3(lang, "Rechercher un fournisseur…", "Search a supplier…", "Buscar un proveedor…")
            Case "searchBank" : Return Choose3(lang, "Rechercher un compte banque…", "Search a bank account…", "Buscar una cuenta bancaria…")
            Case "emptyTiers" : Return Choose3(lang, "Aucun tiers trouvé.", "None found.", "No se encontró ninguno.")
            Case "emptyBank" : Return Choose3(lang, "Aucun compte banque trouvé.", "No bank account found.", "No se encontró ninguna cuenta bancaria.")
            Case "close" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
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

    Sub UpdateBankDisplay(noCompte As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@NoCompte", noCompte))
        p.Add(New SqlParameter("@CompanyGUID", Company))
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
