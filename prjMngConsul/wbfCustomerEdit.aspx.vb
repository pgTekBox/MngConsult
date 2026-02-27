
Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles
Imports Telerik.Web.UI.Skins


Public Class wbfCustomerEdit
    Inherits clsData



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
        dt.Columns.Add("Dirty", GetType(Integer))
        dt.Columns.Add("Deleted", GetType(Integer))
        ViewState("PartyAddressTable") = dt
    End Sub



    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            BinDDL()
            CreatePartyAddressTable()
            CustomerId = CInt(Request.QueryString("CustomerId"))
            BindData()
        End If



    End Sub

    Sub BinDDL()
        SetDDL(rddlProvince, "Name", "Value", "s0014GetProvince")
        SetDDL(rddlPays, "Name", "Value", "s0015GetCountry")
        SetDDL(rddlAddressType, "Name", "Value", "s0020AddressType")
        SetDDL(rddlPartyType, "Name", "Value", "s0022GetPartyType")
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
            rddlPartyType.SelectedValue = ds.Tables(0).Rows(0)("Type")
            tlblId.Text = ds.Tables(0).Rows(0)("Id").ToString()
            tlblCreated.Text = CDate(ds.Tables(0).Rows(0)("Created")).ToString("yyyy-MM-dd HH:mm")
            LoadAddressTableFromBD()
            BindAddressGrid()

        End If
    End Sub

    ' Bind la DataTable en ViewState au grid
    Public Sub BindAddressGrid()
        rgAddr.DataSource = CType(ViewState("PartyAddressTable"), DataTable)
        rgAddr.DataBind()
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
            dr("Dirty") = 0
            dr("Deleted") = 0
            CType(ViewState("PartyAddressTable"), DataTable).Rows.Add(dr)

        Next

    End Sub


    'Sauvegarde les infos du Customer (hors adresses) dans la BD
    Sub SaveCustomer(CustomerId As Integer)
        If CustomerId = 0 Then
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
            ExecuteSQL("s0017UpdateParty", p)

            UpadateAllAddress()
        End If


    End Sub

    ' Gère les commandes du grid des adresse (Edit, Delete)
    Private Sub rgAddr_ItemCommand(sender As Object, e As GridCommandEventArgs) Handles rgAddr.ItemCommand
        'If e.CommandArgument Is Nothing Then Return
        If TypeOf e.Item IsNot GridDataItem Then Return
        Dim item = CType(e.Item, GridDataItem)

        Dim addrId As Integer = CInt(item.GetDataKeyValue("Id"))

        Select Case e.CommandName
            Case "EditAddress"
                OpenAddrWindow(addrId)

            Case "DeleteAddress"
                DeleteAddress(addrId)
                'ReloadAddresses()
                rgAddr.Rebind()
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
            rddlProvince.SelectedValue = r("StateId")
            rddlPays.SelectedValue = r("CountryId")
            rddlAddressType.SelectedValue = r("AddressTypeId")
            txtAddressName.Text = r("Name").ToString()
            txtAddressNote.Text = r("Note").ToString()

        Else
            ' Nouveau / introuvable
            txtA1.Text = "" : txtA2.Text = "" : txtCity.Text = "" : txtPostal.Text = ""
        End If
        pnlMsg.Visible = True
        pMsg.InnerText = "OpenAddrWindow appelé - id=" & addrId & " A1=" & txtA1.Text
        ' Ouvre la fenêtre
        ' ✅ Ouvre côté client (marche même en AJAX)
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openRw", "$find('" & rwAddr.ClientID & "').show();", True)

    End Sub
    ' Bind la DataTable en ViewState au grid à chaque besoin de données
    Private Sub rgAddr_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs) Handles rgAddr.NeedDataSource

        'rgAddr.DataSource = CType(ViewState("PartyAddressTable"), DataTable)

        Dim dt As DataTable = CType(ViewState("PartyAddressTable"), DataTable)

        If dt IsNot Nothing Then
            Dim dv As New DataView(dt)
            dv.RowFilter = "Deleted = 0"   ' 🔥 ton filtre

            rgAddr.DataSource = dv
        End If


    End Sub

    ' Rafraîchit le grid (rebind) après chaque opération sur les adresses    
    Private Sub btnAddrRefresh_Click(sender As Object, e As EventArgs) Handles btnAddrRefresh.Click
        rgAddr.Rebind()
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

            rgAddr.Rebind()

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
            r("StateId") = DbNullIfEmpty(rddlProvince.SelectedValue)
            r("CountryId") = DbNullIfEmpty(rddlPays.SelectedValue)
            r("AddressTypeId") = DbNullIfEmpty(rddlAddressType.SelectedValue)
            r("Typename") = DbNullIfEmpty(rddlAddressType.SelectedText)


            r("Dirty") = 1 ' Marque comme "à mettre à jour" pour la sauvegarde finale
        End If
    End Sub


    ' Insère une nouvelle adresse dans la DataTable en ViewState (sans toucher à la BD) pour l'afficher immédiatement dans le grid
    Private Sub InsertAdresseIdViewState()
        Dim dr As DataRow = CType(ViewState("PartyAddressTable"), DataTable).NewRow()
        dr("Id") = 0 'Nouvelle adresse
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

        CType(ViewState("PartyAddressTable"), DataTable).Rows.Add(dr)

        rgAddr.Rebind()
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

        txtAddressNote.Text = ""
        txtAddressName.Text = ""
        ' clear dropdowns (important)
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

End Class