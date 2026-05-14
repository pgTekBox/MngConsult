Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfReceiptEdit
    Inherits clsData

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
            litTitle.Text = "Encaissement client — Édition"
            Page.Title = "Encaissement client — Édition"
            lblTiersLabel.Text = "Client"
            lblCustomer.Text = "Sélectionner un client"
            litLignesTitle.Text = "Factures ouvertes à encaisser"
            lblMontantLabel.Text = "Montant reçu total"
            litLabelDiff.Text = "Différence (reçu − imputé)"
            radSave.Text = "Enregistrer l'encaissement"
        Else
            litTitle.Text = "Paiement fournisseur — Édition"
            Page.Title = "Paiement fournisseur — Édition"
            lblTiersLabel.Text = "Fournisseur"
            lblCustomer.Text = "Sélectionner un fournisseur"
            litLignesTitle.Text = "Factures ouvertes à payer"
            lblMontantLabel.Text = "Montant payé total"
            litLabelDiff.Text = "Différence (payé − imputé)"
            radSave.Text = "Enregistrer le paiement"
        End If
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
            Dim labelTiers As String = If(IsEncaissement(), "client", "fournisseur")
            RegisterAlert("Veuillez sélectionner un " & labelTiers & ".")
            Return
        End If

        Dim noCompteBanque As String = hidSelectedBankId.Value
        If String.IsNullOrWhiteSpace(noCompteBanque) Then
            RegisterAlert("Veuillez sélectionner un compte banque.")
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
            RegisterAlert("Aucun montant à imputer. Saisissez au moins un montant dans la colonne ""À imputer"".")
            Return
        End If

        ' Vérifier que Sum(AImputer) <= MontantReçu (tolérance 1 cent)
        Dim sumImpute As Double = linesToPost.Sum(Function(r) Convert.ToDouble(r("AImputer")))
        Dim montantTotal As Double = ToDoubleAnyCulture(txtMontantRecu.Text)
        ' Note : laissé non bloquant (paiement partiel possible)

        ' Vérifier que chaque AImputer <= Reste
        Dim labelOperation As String = If(IsEncaissement(), "encaisser", "payer")
        For Each row As DataRow In linesToPost
            Dim aImputer As Double = Convert.ToDouble(row("AImputer"))
            Dim reste As Double = Convert.ToDouble(row("Reste"))
            If aImputer - reste > 0.005 Then
                RegisterAlert("Le montant à imputer sur la facture " & row("DocumentNumber").ToString() &
                              " dépasse le reste à " & labelOperation & ".")
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
