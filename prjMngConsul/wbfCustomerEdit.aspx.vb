
Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports Newtonsoft.Json.Linq
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles
Imports Telerik.Web.UI.Skins


Public Class wbfCustomerEdit
    Inherits clsData

    ''' <summary>
    ''' Prompt d'extraction pour un CLIENT : à partir d'une carte d'affaires, d'une
    ''' facture, d'un en-tête de lettre, etc., retourne un JSON avec les champs du client.
    ''' </summary>
    Private Const EXTRACT_PROMPT_CLIENT As String =
        "Tu es un extracteur d'informations d'entreprise / de client. " &
        "À partir du document fourni (carte d'affaires, facture, en-tête de lettre, devis, etc.), " &
        "retourne UNIQUEMENT un objet JSON valide avec exactement ces clés (mets null si absent) : " &
        "{""name"": string, ""display_name"": string, ""website"": string, ""gst_number"": string, " &
        """qst_number"": string, ""phone"": string, ""email"": string, ""address"": string, " &
        """city"": string, ""postal_code"": string}. " &
        "name = raison sociale / nom de l'entreprise (ou nom de la personne si particulier). " &
        "display_name = nom court usuel. website = site web. gst_number = numéro de TPS. " &
        "qst_number = numéro de TVQ. phone = téléphone. email = courriel. " &
        "address = adresse civique (numéro et rue). city = ville. postal_code = code postal. " &
        "Ne retourne que le JSON, sans texte ni balises de code autour."



    Property CustomerId() As Integer
        Get
            Try
                If ViewState("CustomerId") Is Nothing Then ViewState("CustomerId") = 0
                Dim MyRetVal As Integer = ViewState("CustomerId")
                Return MyRetVal

            Catch ex As Exception
                Return 0
            End Try

        End Get
        Set(ByVal Value As Integer)
            ViewState("CustomerId") = Value
        End Set
    End Property

    ' Crée une DataTable en ViewState pour stocker les adresses temporairement
    Public Sub CreatePartyAddressTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("Note", GetType(String))
        dt.Columns.Add("Name", GetType(String))
        dt.Columns.Add("AddressTypeId", GetType(Integer))
        dt.Columns.Add("Typename", GetType(String))
        dt.Columns.Add("Address", GetType(String))
        dt.Columns.Add("Address1", GetType(String))
        dt.Columns.Add("Address2", GetType(String))
        dt.Columns.Add("City", GetType(String))
        dt.Columns.Add("StateId", GetType(Integer))
        dt.Columns.Add("PostalCode", GetType(String))
        dt.Columns.Add("CountryId", GetType(Integer))
        dt.Columns.Add("Email", GetType(String))
        dt.Columns.Add("Dirty", GetType(Integer))
        dt.Columns.Add("Deleted", GetType(Integer))
        ViewState("PartyAddressTable") = dt
    End Sub



    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            BinDDL()
            CreatePartyAddressTable()
            CustomerId = CInt(Request.QueryString("Id"))
            BindData()
        End If



    End Sub

    ''' <summary>
    ''' Délai de paiement saisi, en jours : 0 si le champ est vide, borné à [0, 365].
    ''' C'est ce délai qui fixe l'échéance de la facture au moment de sa
    ''' comptabilisation (DueDate = date de facture + délai).
    ''' </summary>
    Private Function TermDaysValue() As Integer
        If Not numTermDays.Value.HasValue Then Return 0
        Dim d As Integer = CInt(Math.Round(numTermDays.Value.Value))
        If d < 0 Then Return 0
        If d > 365 Then Return 365
        Return d
    End Function

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    Private Sub ApplyLocalization()
        lnkBack.Text = "← " & L("backToList")
        btnSave.Text = L("save")
        rddlPartyType.DefaultMessage = L("selectPh")
        btnNewAddress.Text = "+ " & L("addAddress")
        rwAddr.Title = L("addrWinTitle")

        ' Zone de scan / remplissage automatique
        btnExtract.Text = L("scanBtn")
        Dim scanToggle As Control = FindDeep(Me, "btnScanToggle")
        If TypeOf scanToggle Is System.Web.UI.HtmlControls.HtmlControl Then
            Dim hc = CType(scanToggle, System.Web.UI.HtmlControls.HtmlControl)
            hc.Attributes("title") = L("scanToggle")
            hc.Attributes("aria-label") = L("scanToggle")
        End If
        SetLiteral(Me, "litScanTitle", L("scanTitle"))
        SetLiteral(Me, "litScanHint", L("scanHint"))
        SetLiteral(Me, "litDropZone", L("scanDrop"))

        ' Libellés statiques du corps (Literal — pas de <%= %> à cause du RadAjaxManager)
        SetLiteral(Me, "litEditTitle", L("editTitle"))
        SetLiteral(Me, "litCustomerInfo", L("customerInfo"))
        SetLiteral(Me, "litOriginLbl", L("origin"))
        SetLiteral(Me, "litCreatedLbl", L("created"))
        SetLiteral(Me, "litLblName", L("lblName"))
        SetLiteral(Me, "litLblDisplayName", L("lblDisplayName"))
        SetLiteral(Me, "litLblType", L("lblType"))
        SetLiteral(Me, "litLblWebsite", L("lblWebsite"))
        SetLiteral(Me, "litLblTPS", L("lblTPS"))
        SetLiteral(Me, "litLblTVQ", L("lblTVQ"))
        SetLiteral(Me, "litLblTermDays", L("lblTermDays"))
        SetLiteral(Me, "litLblNote", L("lblNote"))
        SetLiteral(Me, "litAddresses", L("addresses"))

        ' Éditeur d'adresse (dans le RadWindow, rafraîchi en AJAX)
        rddlAddressType.DefaultMessage = L("selectPh")
        rddlProvince.DefaultMessage = L("selectPh")
        rddlPays.DefaultMessage = L("selectPh")
        btnAddrSave.Text = L("save")
        btnAddrCancel.Text = L("cancel")

        SetLiteral(Me, "litAddrType", L("addrType"))
        SetLiteral(Me, "litAddrName", L("addrName"))
        SetLiteral(Me, "litAddr1", L("addr1"))
        SetLiteral(Me, "litAddr2", L("addr2"))
        SetLiteral(Me, "litCity", L("city"))
        SetLiteral(Me, "litProvince", L("province"))
        SetLiteral(Me, "litCountry", L("country"))
        SetLiteral(Me, "litPostal", L("postal"))
        SetLiteral(Me, "litAddrEmail", L("email"))
        SetLiteral(Me, "litAddrNote", L("addrNote"))
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView adresses.</summary>
    Private Sub rlvAddr_PreRender(sender As Object, e As EventArgs) Handles rlvAddr.PreRender
        SetLiteral(rlvAddr, "litAddrColType", L("addrType"))
        SetLiteral(rlvAddr, "litAddrColAddress", L("colAddress"))
        SetLiteral(rlvAddr, "litAddrColActions", L("colActions"))
        SetLiteral(rlvAddr, "litAddrEmpty", L("addrEmpty"))
    End Sub

    Sub BinDDL()
        BindProvinces(0)
        SetDDL(rddlPays, "Name", "Value", "s0015GetCountry")
        SetDDL(rddlAddressType, "Name", "Value", "s0020AddressType")

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Type", 1))
        SetDDL(rddlPartyType, "Name", "Value", "s0022GetPartyType", p)
    End Sub

    ''' <summary>Charge la liste des provinces/états (langue courante). countryId=0 → tous.</summary>
    Private Sub BindProvinces(countryId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Lang", CurrentLang))
        p.Add(New SqlClient.SqlParameter("@CountryId", countryId))
        SetDDL(rddlProvince, "Name", "Value", "s0014GetProvince", p)
    End Sub

    ''' <summary>Cascade Pays → Province : ne montre que les états/provinces du pays choisi.</summary>
    Protected Sub rddlPays_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles rddlPays.SelectedIndexChanged
        Dim cid As Integer = 0
        Integer.TryParse(rddlPays.SelectedValue, cid)
        BindProvinces(cid)
        rddlProvince.ClearSelection()
        rddlProvince.SelectedIndex = -1
    End Sub


    Sub BindData()
        If CustomerId = 0 Then
            'New Supplier

            txtName.Text = ""
            txtWebsite.Text = ""
            txtNoTPS.Text = ""
            txtNoTVQ.Text = ""

            txtNote.Text = ""


        Else
            'Existing Supplier
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@PartyId", CustomerId))
            Dim ds As DataSet = ExecuteSQLds("s0012GetOneSuppliersCustomer", p)

            txtName.Text = ds.Tables(0).Rows(0)("Name").ToString()
            txtWebsite.Text = ds.Tables(0).Rows(0)("Website").ToString()
            txtNoTPS.Text = ds.Tables(0).Rows(0)("TPS").ToString()
            txtNoTVQ.Text = ds.Tables(0).Rows(0)("TVQ").ToString()
            txtNote.Text = ds.Tables(0).Rows(0)("Note").ToString()
            txtDisplayName.Text = ds.Tables(0).Rows(0)("DisplayName").ToString()
            tlblOrigine.Text = ds.Tables(0).Rows(0)("Origin").ToString()
            ' Délai de paiement : sert à calculer l'échéance à la comptabilisation.
            numTermDays.Value = If(IsDBNull(ds.Tables(0).Rows(0)("PaymentTermDays")), 0.0,
                                   Convert.ToDouble(ds.Tables(0).Rows(0)("PaymentTermDays")))
            rddlPartyType.SelectedValue = ds.Tables(0).Rows(0)("Type")
            tlblCreated.Text = CDate(ds.Tables(0).Rows(0)("Created")).ToString("yyyy-MM-dd HH:mm")
            LoadAddressTableFromBD()
            BindAddressGrid()

        End If
    End Sub

    ' Bind la DataTable en ViewState au grid
    Public Sub BindAddressGrid()
        rlvAddr.DataSource = CType(ViewState("PartyAddressTable"), DataTable)
        rlvAddr.DataBind()
    End Sub

    ' Charge les adresses depuis la BD et les met dans la DataTable en ViewState
    Public Sub LoadAddressTableFromBD()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@PartyId", CustomerId))

        Dim ds As DataSet = ExecuteSQLds("s0013GetPastyAddress", p)

        For Each orow As DataRow In ds.Tables(0).Rows
            Dim dr As DataRow = CType(ViewState("PartyAddressTable"), DataTable).NewRow()
            dr("Id") = orow("Id")
            dr("AddressTypeId") = orow("AddressTypeId")
            dr("Name") = orow("Name")
            dr("Note") = orow("Note")

            dr("Typename") = orow("Typename")
            dr("Address") = orow("Address1") & "<br />" & orow("Address2")
            dr("Address1") = orow("Address1")
            dr("Address2") = orow("Address2")
            dr("City") = orow("City")
            dr("StateId") = orow("StateId")
            dr("CountryId") = orow("CountryId")
            dr("PostalCode") = orow("PostalCode")
            dr("Email") = orow("Email")
            dr("Dirty") = 0
            dr("Deleted") = 0
            CType(ViewState("PartyAddressTable"), DataTable).Rows.Add(dr)

        Next

    End Sub


    'Sauvegarde les infos du Customer (hors adresses) dans la BD
    Sub SaveCustomer(MyCustomerId As Integer)
        If MyCustomerId = 0 Then
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

            p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
            'p.Add(New SqlClient.SqlParameter("@Note", txtAddressNote.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@PartyCodeiD", 1))
            p.Add(New SqlClient.SqlParameter("@Website", txtWebsite.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@TPS", txtNoTPS.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@TVQ", txtNoTVQ.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@DisplayName", txtDisplayName.Text.Trim()))

            p.Add(New SqlClient.SqlParameter("@Note", txtNote.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@Type", rddlPartyType.SelectedValue))
            p.Add(New SqlClient.SqlParameter("@Origin", 1))
            p.Add(New SqlClient.SqlParameter("@PaymentTermDays", TermDaysValue()))


            Dim ds As DataSet = ExecuteSQLds("s0021InsertParty", p)

            CustomerId = ds.Tables(0).Rows(0)(0)
            UpadateAllAddress()



        Else

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", CustomerId))
            p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@DisplayName", txtDisplayName.Text.Trim()))
            'p.Add(New SqlClient.SqlParameter("@Note", txtAddressNote.Text.Trim()))

            p.Add(New SqlClient.SqlParameter("@Website", txtWebsite.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@TPS", txtNoTPS.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@TVQ", txtNoTVQ.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@Note", txtNote.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@Type", rddlPartyType.SelectedValue))
            p.Add(New SqlClient.SqlParameter("@PaymentTermDays", TermDaysValue()))
            ExecuteSQL("s0017UpdateParty", p)

            UpadateAllAddress()
        End If


    End Sub

    ''' <summary>
    ''' Gère les commandes du RadListView des adresses (EditAddress, DeleteAddress).
    ''' Le CommandArgument contient l'Id de l'adresse, passé via Eval("Id") dans l'ItemTemplate.
    ''' </summary>
    Private Sub rlvAddr_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvAddr.ItemCommand

        ' Ignorer les commandes système (ex: Rebind)
        If TypeOf e.ListViewItem IsNot RadListViewItem Then Return

        ' Lire l'Id depuis CommandArgument (défini dans le bouton ASPX)
        Dim addrId As Integer = 0
        If Not Integer.TryParse(e.CommandArgument?.ToString(), addrId) Then Return

        Select Case e.CommandName
            Case "EditAddress"
                OpenAddrWindow(addrId)

            Case "DeleteAddress"
                DeleteAddress(addrId)
                rlvAddr.Rebind()
        End Select

    End Sub

    Sub DeleteAddress(addrId As Integer)
        ' Marque l'adresse comme "Deleted" dans la DataTable en ViewState (pas besoin de requete SQL supplémentaire, on fera un batch à la fin pour tout supprimer en une fois)
        Dim dt = TryCast(ViewState("PartyAddressTable"), DataTable)
        Dim rows = dt.Select("Id=" & addrId)
        If rows.Length > 0 Then
            Dim r = rows(0)
            r("Deleted") = 1

        End If
    End Sub

    ' Ouvre la fenêtre d'édition d'adresse et charge les données de l'adresse sélectionnée
    ' a partir de la DataTable en ViewState (pas besoin de requete SQL supplémentaire)
    Private Sub OpenAddrWindow(addrId As Integer)

        hfAddrId.Value = addrId.ToString()

        ' Charge depuis ta DataTable (ou depuis SQL si tu préfères)
        Dim dt = TryCast(ViewState("PartyAddressTable"), DataTable)
        Dim rows = dt.Select("Id=" & addrId)

        If rows.Length > 0 Then
            Dim r = rows(0)
            txtA1.Text = r("Address1").ToString()
            txtA2.Text = r("Address2").ToString()
            txtCity.Text = r("City").ToString()

            txtPostal.Text = r("PostalCode").ToString()
            txtAddrEmail.Text = r("Email").ToString()

            ' Cascade : charger les provinces du pays de l'adresse AVANT de sélectionner la province
            Dim cid As Integer = 0
            If Not IsDBNull(r("CountryId")) Then Integer.TryParse(r("CountryId").ToString(), cid)
            rddlPays.SelectedValue = If(cid > 0, cid.ToString(), "")
            BindProvinces(cid)
            If Not IsDBNull(r("StateId")) Then
                rddlProvince.SelectedValue = r("StateId").ToString()
            Else
                rddlProvince.ClearSelection()
            End If

            rddlAddressType.SelectedValue = r("AddressTypeId")
            txtAddressName.Text = r("Name").ToString()
            txtAddressNote.Text = r("Note").ToString()

        Else
            ' Nouveau / introuvable
            txtA1.Text = "" : txtA2.Text = "" : txtCity.Text = "" : txtPostal.Text = "" : txtAddrEmail.Text = ""
        End If
        pnlMsg.Visible = True
        pMsg.InnerText = "OpenAddrWindow appelé - id=" & addrId & " A1=" & txtA1.Text
        ' Ouvre la fenêtre
        ' ✅ Ouvre côté client (marche même en AJAX)
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openRw", "$find('" & rwAddr.ClientID & "').show();", True)

    End Sub
    ''' <summary>
    ''' Bind la DataTable en ViewState au RadListView des adresses à chaque besoin de données.
    ''' Filtre les lignes supprimées (Deleted = 0).
    ''' </summary>
    Private Sub rlvAddr_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAddr.NeedDataSource
        Dim dt As DataTable = CType(ViewState("PartyAddressTable"), DataTable)
        If dt IsNot Nothing Then
            Dim dv As New DataView(dt)
            dv.RowFilter = "Deleted = 0"
            rlvAddr.DataSource = dv
        End If
    End Sub


    ' Rafraîchit le grid (rebind) après chaque opération sur les adresses    
    Private Sub btnAddrRefresh_Click(sender As Object, e As EventArgs) Handles btnAddrRefresh.Click
        rlvAddr.Rebind()
    End Sub


    Private Sub ReloadAddresses()
        ' reset table puis recharge depuis SQL
        CreatePartyAddressTable()
        LoadAddressTableFromBD()
    End Sub

    ' Sauvegarde l'adresse (insert ou update selon le cas) puis rafraîchit le grid
    Private Sub btnAddrSave_Click(sender As Object, e As EventArgs) Handles btnAddrSave.Click
        Dim addrId As Integer
        Integer.TryParse(hfAddrId.Value, addrId)


        If addrId <= 0 Then
            ' Nouvelle adresse: insert puis rebind
            InsertAdresseIdViewState()
            hfAddrId.Value = 0

            rlvAddr.Rebind()

            'ferme la fenêtre RadWindow (fonction JS closeAddrWindow(true))
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeRw", "closeAddrWindow(true);", True)
            Return

        Else
            ' Adresse existante: update dans la ViewState (marque comme "Dirty") puis rebind (pas besoin de toucher à la BD maintenant, on fera un batch à la fin pour tout mettre à jour en une fois)
            UpdateAddressViewState(addrId)
            'ferme la fenêtre RadWindow (fonction JS closeAddrWindow(true))
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeRw", "closeAddrWindow(true);", True)
            Return
        End If

        'ReloadAddresses()
        'rgAddr.Rebind()

        '' ferme la fenêtre RadWindow (fonction JS closeAddrWindow(true))
        'ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeRw", "closeAddrWindow(true);", True)


    End Sub

    Sub UpdateAddressViewState(AddressId As Integer)
        Dim dt = TryCast(ViewState("PartyAddressTable"), DataTable)
        Dim rows = dt.Select("Id=" & AddressId)
        If rows.Length > 0 Then
            Dim r = rows(0)
            r("Address1") = DbNullIfEmpty(txtA1.Text)
            r("Address2") = DbNullIfEmpty(txtA2.Text)
            r("Address") = DbNullIfEmpty(txtA1.Text) & "<br />" & DbNullIfEmpty(txtA2.Text)

            r("Name") = DbNullIfEmpty(txtAddressName.Text)
            r("Note") = DbNullIfEmpty(txtAddressNote.Text)
            r("City") = DbNullIfEmpty(txtCity.Text)
            r("PostalCode") = DbNullIfEmpty(txtPostal.Text)
            r("Email") = DbNullIfEmpty(txtAddrEmail.Text)
            r("StateId") = DbNullIfEmpty(rddlProvince.SelectedValue)
            r("CountryId") = DbNullIfEmpty(rddlPays.SelectedValue)
            r("AddressTypeId") = DbNullIfEmpty(rddlAddressType.SelectedValue)
            r("Typename") = DbNullIfEmpty(rddlAddressType.SelectedText)


            r("Dirty") = 1 ' Marque comme "à mettre à jour" pour la sauvegarde finale
        End If
    End Sub


    ' Insère une nouvelle adresse dans la DataTable en ViewState (sans toucher à la BD) pour l'afficher immédiatement dans le grid
    Private Sub InsertAdresseIdViewState()

        Dim Newid As Integer = (CType(ViewState("ItemsTable"), DataTable).Rows.Count + 1) * -1 ' Id négatif temporaire pour différencier les nouvelles lignes (les lignes existantes ont des Id positifs issus de la BD, les nouvelles lignes auront des Id négatifs générés à la volée)    


        Dim dr As DataRow = CType(ViewState("PartyAddressTable"), DataTable).NewRow()
        dr("Id") = Newid 'Nouvelle adresse
        dr("Dirty") = 1
        dr("Deleted") = 0
        dr("AddressTypeId") = DbNullIfEmpty(rddlAddressType.SelectedValue)
        dr("Name") = DbNullIfEmpty(txtAddressName.Text)
        dr("Note") = DbNullIfEmpty(txtAddressNote.Text)
        dr("Address1") = DbNullIfEmpty(txtA1.Text)
        dr("Address") = DbNullIfEmpty(txtA1.Text) & "<br /" & DbNullIfEmpty(txtA2.Text)
        dr("Address2") = DbNullIfEmpty("")
        dr("City") = DbNullIfEmpty(txtCity.Text)
        dr("StateId") = DbNullIfEmpty(rddlProvince.SelectedValue)
        dr("CountryId") = DbNullIfEmpty(rddlPays.SelectedValue)
        dr("Typename") = DbNullIfEmpty(rddlAddressType.SelectedText)
        dr("PostalCode") = DbNullIfEmpty(txtPostal.Text)
        dr("Email") = DbNullIfEmpty(txtAddrEmail.Text)

        CType(ViewState("PartyAddressTable"), DataTable).Rows.Add(dr)

        rlvAddr.Rebind()
    End Sub

    '
    Private Sub UpadateAllAddress()

        Dim dtVS As DataTable = CType(ViewState("PartyAddressTable"), DataTable)
        For Each orow As DataRow In dtVS.Rows

            If orow("Deleted") = 1 Then
                Dim p As New Collection
                p.Add(New SqlClient.SqlParameter("@Id", orow("Id")))
                p.Add(New SqlClient.SqlParameter("@PartyId", CustomerId))
                ExecuteSQL("s0018DeleteAddress", p)


            ElseIf orow("Dirty") = 1 AndAlso CInt(orow("Id")) > 0 Then
                'Update en BD
                Dim p As New Collection
                p.Add(New SqlClient.SqlParameter("@Id", orow("Id")))
                p.Add(New SqlClient.SqlParameter("@AddressTypeId", orow("AddressTypeId")))
                p.Add(New SqlClient.SqlParameter("@Name", orow("Name")))
                p.Add(New SqlClient.SqlParameter("@Note", orow("Note")))
                p.Add(New SqlClient.SqlParameter("@Address1", orow("Address1")))
                p.Add(New SqlClient.SqlParameter("@Address2", orow("Address2")))
                p.Add(New SqlClient.SqlParameter("@City", orow("City")))
                p.Add(New SqlClient.SqlParameter("@PostalCode", orow("PostalCode")))
                p.Add(New SqlClient.SqlParameter("@CountryId", orow("CountryId")))
                p.Add(New SqlClient.SqlParameter("@StateId", orow("StateId")))
                p.Add(New SqlClient.SqlParameter("@Email", orow("Email")))
                ExecuteSQL("s0016UpdatePartyAddress", p)

            ElseIf orow("Dirty") = 1 AndAlso CInt(orow("Id")) <= 0 Then

                Dim p As New Collection
                p.Add(New SqlClient.SqlParameter("@PartyId", CustomerId))
                p.Add(New SqlClient.SqlParameter("@AddressTypeId", orow("AddressTypeId")))
                p.Add(New SqlClient.SqlParameter("@Name", orow("Name")))
                p.Add(New SqlClient.SqlParameter("@Note", orow("Note")))
                p.Add(New SqlClient.SqlParameter("@Address1", orow("Address1")))
                p.Add(New SqlClient.SqlParameter("@Address2", orow("Address2")))
                p.Add(New SqlClient.SqlParameter("@City", orow("City")))
                p.Add(New SqlClient.SqlParameter("@PostalCode", orow("PostalCode")))
                p.Add(New SqlClient.SqlParameter("@CountryId", orow("CountryId")))
                p.Add(New SqlClient.SqlParameter("@StateId", orow("StateId")))
                p.Add(New SqlClient.SqlParameter("@Email", orow("Email")))
                ExecuteSQL("s0015InsertPartyAddress", p)

            End If


        Next




    End Sub


    Private Sub OpenNewAddrWindow()

        ' 0 / vide = nouveau
        hfAddrId.Value = "0"

        ' clear champs
        txtA1.Text = ""
        txtA2.Text = ""
        txtCity.Text = ""
        txtPostal.Text = ""
        txtAddrEmail.Text = ""

        txtAddressNote.Text = ""
        txtAddressName.Text = ""
        ' clear dropdowns (important)
        BindProvinces(0)
        rddlProvince.ClearSelection()
        rddlPays.ClearSelection()
        rddlAddressType.ClearSelection()
        ' (optionnel) si tu veux afficher le DefaultMessage
        rddlProvince.SelectedIndex = -1
        rddlPays.SelectedIndex = -1
        rddlAddressType.SelectedIndex = -1

        ' ouvre la fenêtre (AJAX-safe)
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openRwNew",
        "$find('" & rwAddr.ClientID & "').show();", True)
    End Sub


    Private Sub btnNewAddress_Click(sender As Object, e As EventArgs) Handles btnNewAddress.Click
        OpenNewAddrWindow()
    End Sub

    ' Sauvegarde les infos du fournisseur et les adresse et ferme la fenêtre d'édition
    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        If CustomerId = 0 Then
            SaveCustomer(0)
        Else

            SaveCustomer(CustomerId)
        End If






        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)


    End Sub


    Private Function DbNullIfEmpty(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    ' =====================================================================
    ' SCAN DE DOCUMENT : extraction IA (OpenAI) → remplissage des champs VIDES
    ' =====================================================================
    Protected Async Sub btnExtract_Click(sender As Object, e As EventArgs) Handles btnExtract.Click

        If Not fileDoc.HasFile Then
            ShowUpload(L("upChoose"))
            Return
        End If

        Try
            Dim bytes As Byte() = fileDoc.FileBytes
            If bytes Is Nothing OrElse bytes.Length = 0 Then
                ShowUpload(L("upEmpty"))
                Return
            End If

            Dim fileName As String = If(fileDoc.FileName, "").ToLowerInvariant()
            Dim ct As String = If(fileDoc.PostedFile IsNot Nothing, If(fileDoc.PostedFile.ContentType, ""), "").ToLowerInvariant()

            Dim apiKey As String = GetParam("CHATGPT")
            If String.IsNullOrEmpty(apiKey) Then
                ShowUpload(L("upNoKey"))
                Return
            End If

            Dim reader As New OpenAiReceiptReader(apiKey)
            Dim json As String

            If ct.Contains("pdf") OrElse fileName.EndsWith(".pdf") Then
                Dim res = Await reader.ParseInvoicePdfAsync(bytes, EXTRACT_PROMPT_CLIENT)
                json = res.JsonText
            ElseIf ct.StartsWith("image") OrElse fileName.EndsWith(".jpg") OrElse fileName.EndsWith(".jpeg") OrElse fileName.EndsWith(".png") Then
                Dim mime As String = If(ct.StartsWith("image"), ct, If(fileName.EndsWith(".png"), "image/png", "image/jpeg"))
                Dim res = Await reader.ReadReceiptAsJsonAsync(bytes, mime, EXTRACT_PROMPT_CLIENT)
                json = res.JsonResult
            Else
                ShowUpload(L("upFormat"))
                Return
            End If

            Dim n As Integer = FillFromJson(json)
            If n > 0 Then
                ShowUpload(String.Format(L("upFilled"), n))
            Else
                ShowUpload(L("upNone"))
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("wbfCustomerEdit extract error: " & ex.Message)
            ShowUpload(L("upError"))
        End Try
    End Sub

    ''' <summary>
    ''' Remplit les champs du client à partir du JSON OpenAI.
    ''' Ne remplit QUE les champs actuellement vides. Retourne le nombre de champs remplis.
    ''' </summary>
    Private Function FillFromJson(json As String) As Integer
        If String.IsNullOrWhiteSpace(json) Then Return 0

        Dim iStart As Integer = json.IndexOf("{"c)
        Dim iEnd As Integer = json.LastIndexOf("}"c)
        If iStart < 0 OrElse iEnd <= iStart Then Return 0

        Dim jo As JObject
        Try
            jo = JObject.Parse(json.Substring(iStart, iEnd - iStart + 1))
        Catch
            Return 0
        End Try

        Dim n As Integer = 0
        Dim nm As String = J(jo, "name")
        Dim disp As String = J(jo, "display_name")

        n += SetIfEmpty(txtName, If(String.IsNullOrWhiteSpace(nm), disp, nm))
        n += SetIfEmpty(txtDisplayName, If(String.IsNullOrWhiteSpace(disp), nm, disp))
        n += SetIfEmpty(txtWebsite, J(jo, "website"))
        n += SetIfEmpty(txtNoTPS, J(jo, "gst_number"))
        n += SetIfEmpty(txtNoTVQ, J(jo, "qst_number"))

        ' Adresse → table des adresses (nouvelle ligne, seulement si aucune adresse existante)
        n += AddScannedAddress(J(jo, "address"), J(jo, "city"), J(jo, "postal_code"),
                               J(jo, "email"), J(jo, "phone"))

        Return n
    End Function

    ''' <summary>
    ''' Ajoute l'adresse extraite comme NOUVELLE ligne dans la table des adresses,
    ''' uniquement si le tiers n'a encore aucune adresse (respect du « seulement si vide »).
    ''' Le téléphone va dans la note de l'adresse (pas de colonne dédiée).
    ''' Retourne 1 si une adresse a été ajoutée, sinon 0.
    ''' </summary>
    Private Function AddScannedAddress(address1 As String, city As String, postal As String,
                                       email As String, phone As String) As Integer

        If String.IsNullOrWhiteSpace(address1) AndAlso String.IsNullOrWhiteSpace(city) _
           AndAlso String.IsNullOrWhiteSpace(postal) AndAlso String.IsNullOrWhiteSpace(email) Then
            Return 0
        End If

        Dim dt As DataTable = TryCast(ViewState("PartyAddressTable"), DataTable)
        If dt Is Nothing Then Return 0

        ' Ne rien ajouter s'il existe déjà une adresse non supprimée
        For Each r As DataRow In dt.Rows
            If Convert.ToInt32(If(IsDBNull(r("Deleted")), 0, r("Deleted"))) = 0 Then Return 0
        Next

        Dim noteVal As String = ""
        If Not String.IsNullOrWhiteSpace(phone) Then noteVal = "Tél. : " & phone.Trim()

        Dim cityLine As String = JoinPart("", city, " ")
        cityLine = JoinPart(cityLine, postal, " ")
        Dim displayAddr As String = JoinPart(If(String.IsNullOrWhiteSpace(address1), "", address1.Trim()), cityLine, "<br />")

        Dim dr As DataRow = dt.NewRow()
        dr("Id") = -(dt.Rows.Count + 1)
        dr("Dirty") = 1
        dr("Deleted") = 0
        dr("AddressTypeId") = 1                     ' 1 = Billing
        dr("Typename") = GetAddressTypeName(1)
        dr("Name") = DBNull.Value
        dr("Note") = DbNullIfEmpty(noteVal)
        dr("Address1") = DbNullIfEmpty(address1)
        dr("Address2") = DBNull.Value
        dr("Address") = displayAddr
        dr("City") = DbNullIfEmpty(city)
        dr("StateId") = DBNull.Value
        dr("CountryId") = DBNull.Value
        dr("PostalCode") = DbNullIfEmpty(postal)
        dr("Email") = DbNullIfEmpty(email)
        dt.Rows.Add(dr)

        ViewState("PartyAddressTable") = dt
        rlvAddr.Rebind()
        Return 1
    End Function

    Private Function GetAddressTypeName(typeId As Integer) As String
        Try
            Dim it = rddlAddressType.FindItemByValue(typeId.ToString())
            If it IsNot Nothing Then Return it.Text
        Catch
        End Try
        Return ""
    End Function

    Private Shared Function J(jo As JObject, key As String) As String
        Dim t As JToken = jo(key)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return ""
        Return t.ToString().Trim()
    End Function

    ''' <summary>N'affecte la valeur QUE si le champ est vide (et la valeur non nulle). Retourne 1 si rempli.</summary>
    Private Shared Function SetIfEmpty(tb As Telerik.Web.UI.RadTextBox, val As String) As Integer
        If String.IsNullOrWhiteSpace(val) OrElse val.Equals("null", StringComparison.OrdinalIgnoreCase) Then Return 0
        If Not String.IsNullOrWhiteSpace(tb.Text) Then Return 0
        tb.Text = val.Trim()
        Return 1
    End Function

    Private Shared Function JoinPart(acc As String, part As String, sep As String) As String
        If String.IsNullOrWhiteSpace(part) Then Return acc
        If String.IsNullOrWhiteSpace(acc) Then Return part.Trim()
        Return acc & sep & part.Trim()
    End Function

    Private Sub ShowUpload(msg As String)
        pnlUpload.Visible = True
        litUpload.Text = Server.HtmlEncode(msg)
    End Sub

    Private Function GetParam(key As String) As String
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@Parameter", key))
            Dim ds As DataSet = ExecuteSQLds("s0000GetParameter", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)("Value").ToString()
            End If
        Catch
        End Try
        Return ""
    End Function

    ''' <summary>Traductions de l'écran d'édition Client (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Client — Édition", "Customer — Edit", "Cliente — Edición")
            Case "editTitle" : Return Choose3(lang, "Édition — Client", "Edit — Customer", "Edición — Cliente")
            Case "backToList" : Return Choose3(lang, "Retour à la liste", "Back to list", "Volver a la lista")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "cancel" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "customerInfo" : Return Choose3(lang, "Informations Client", "Customer information", "Información del cliente")
            Case "id" : Return Choose3(lang, "Id", "Id", "Id")
            Case "origin" : Return Choose3(lang, "Origine", "Origin", "Origen")
            Case "created" : Return Choose3(lang, "Créé", "Created", "Creado")
            Case "lblName" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "lblDisplayName" : Return Choose3(lang, "Nom d'affichage", "Display name", "Nombre para mostrar")
            Case "lblType" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "lblWebsite" : Return Choose3(lang, "Site web", "Website", "Sitio web")
            Case "lblTPS" : Return Choose3(lang, "No TPS", "GST no.", "N.º GST")
            Case "lblTVQ" : Return Choose3(lang, "No TVQ", "QST no.", "N.º QST")
            Case "lblTermDays" : Return Choose3(lang, "Délai de paiement (jours)", "Payment terms (days)", "Plazo de pago (días)")
            Case "lblNote" : Return Choose3(lang, "Note", "Note", "Nota")
            Case "selectPh" : Return Choose3(lang, "Sélectionner…", "Select…", "Seleccionar…")
            Case "addresses" : Return Choose3(lang, "Adresses", "Addresses", "Direcciones")
            Case "addAddress" : Return Choose3(lang, "Ajouter une adresse", "Add an address", "Agregar una dirección")
            Case "colAddress" : Return Choose3(lang, "Adresse", "Address", "Dirección")
            Case "colActions" : Return Choose3(lang, "Actions", "Actions", "Acciones")
            Case "addrEmpty" : Return Choose3(lang, "Aucune adresse enregistrée pour ce client.", "No address recorded for this customer.", "Ninguna dirección registrada para este cliente.")
            Case "addrWinTitle" : Return Choose3(lang, "Édition adresse", "Edit address", "Editar dirección")
            Case "addrType" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "addrName" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "addr1" : Return Choose3(lang, "Adresse 1", "Address 1", "Dirección 1")
            Case "addr2" : Return Choose3(lang, "Adresse 2", "Address 2", "Dirección 2")
            Case "city" : Return Choose3(lang, "Ville", "City", "Ciudad")
            Case "province" : Return Choose3(lang, "Province", "Province", "Provincia")
            Case "country" : Return Choose3(lang, "Pays", "Country", "País")
            Case "postal" : Return Choose3(lang, "Code postal", "Postal code", "Código postal")
            Case "email" : Return Choose3(lang, "Courriel", "Email", "Correo electrónico")
            Case "addrNote" : Return Choose3(lang, "Note", "Note", "Nota")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")

            ' === Scan de document / remplissage automatique ===
            Case "scanTitle" : Return Choose3(lang, "Remplissage automatique par document", "Auto-fill from a document", "Autocompletar desde un documento")
            Case "scanHint" : Return Choose3(lang, "Déposez une carte d'affaires, une facture ou un en-tête de lettre : l'IA remplit les champs vides.", "Drop a business card, invoice or letterhead: AI fills in the empty fields.", "Suelte una tarjeta de presentación, factura o membrete: la IA rellena los campos vacíos.")
            Case "scanDrop" : Return Choose3(lang, "Glissez un fichier ici ou cliquez pour choisir (PDF, JPG, PNG)", "Drag a file here or click to choose (PDF, JPG, PNG)", "Arrastre un archivo aquí o haga clic para elegir (PDF, JPG, PNG)")
            Case "scanBtn" : Return Choose3(lang, "Analyser le document", "Analyze document", "Analizar documento")
            Case "scanToggle" : Return Choose3(lang, "Réduire / Agrandir", "Collapse / Expand", "Contraer / Expandir")
            Case "upChoose" : Return Choose3(lang, "Veuillez d'abord choisir un fichier.", "Please choose a file first.", "Elija un archivo primero.")
            Case "upEmpty" : Return Choose3(lang, "Le fichier est vide.", "The file is empty.", "El archivo está vacío.")
            Case "upNoKey" : Return Choose3(lang, "Clé OpenAI absente. Contactez l'administrateur.", "OpenAI key missing. Contact the administrator.", "Falta la clave de OpenAI. Contacte al administrador.")
            Case "upFormat" : Return Choose3(lang, "Format non pris en charge (PDF, JPG ou PNG uniquement).", "Unsupported format (PDF, JPG or PNG only).", "Formato no admitido (solo PDF, JPG o PNG).")
            Case "upFilled" : Return Choose3(lang, "{0} champ(s) rempli(s) automatiquement. Vérifiez avant d'enregistrer.", "{0} field(s) filled automatically. Please review before saving.", "{0} campo(s) rellenado(s) automáticamente. Revise antes de guardar.")
            Case "upNone" : Return Choose3(lang, "Aucune information exploitable trouvée (ou champs déjà remplis).", "No usable information found (or fields already filled).", "No se encontró información utilizable (o los campos ya están llenos).")
            Case "upError" : Return Choose3(lang, "Erreur lors de l'analyse du document.", "Error while analyzing the document.", "Error al analizar el documento.")

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