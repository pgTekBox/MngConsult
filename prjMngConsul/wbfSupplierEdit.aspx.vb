Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports Telerik.Web.UI

Public Class wbfSupplierEdit
    Inherits clsData



    Property SupplierId() As Integer
        Get
            Try
                If ViewState("SupplierId") Is Nothing Then ViewState("SupplierId") = 0
                Dim MyRetVal As Integer = ViewState("SupplierId")
                Return MyRetVal

            Catch ex As Exception
                Return 0
            End Try

        End Get
        Set(ByVal Value As Integer)
            ViewState("SupplierId") = Value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            BinDDL()
            CreatePartyAddressTable()
            SupplierId = CInt(Request.QueryString("SupplierId"))
            BindData()
        End If



    End Sub

    Sub BinDDL()
        SetDDL(rddlProvince, "Name", "Value", "s0014GetProvince")
        SetDDL(rddlPays, "Name", "Value", "s0015GetCountry")
    End Sub


    Sub BindData()
        If SupplierId = 0 Then
            'New Supplier

        Else
            'Existing Supplier
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@SupplierId", SupplierId))
            Dim ds As DataSet = ExecuteSQLds("s0012GetOneSuppliers", p)

            txtName.Text = ds.Tables(0).Rows(0)("Name").ToString()
            txtWebsite.Text = ds.Tables(0).Rows(0)("Website").ToString()
            txtNoTPS.Text = ds.Tables(0).Rows(0)("TPS").ToString()
            txtNoTVQ.Text = ds.Tables(0).Rows(0)("TVQ").ToString()

            LoadAddressTable()
            BindAddressGrid()

        End If
    End Sub


    Sub SaveSupplier()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", SupplierId))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@PartyCodeiD", 2))
        p.Add(New SqlClient.SqlParameter("@Website", txtWebsite.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@TPS", txtNoTPS.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@TVQ", txtNoTVQ.Text.Trim()))
        ExecuteSQL("s0017UpdateParty", p)
    End Sub

    Public Sub BindAddressGrid()
        rgAddr.DataSource = CType(ViewState("PartyAddressTable"), DataTable)
        rgAddr.DataBind()
    End Sub

    Public Sub LoadAddressTable()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))

        Dim ds As DataSet = ExecuteSQLds("s0013GetPastyAddress", p)

        For Each orow As DataRow In ds.Tables(0).Rows
            Dim dr As DataRow = CType(ViewState("PartyAddressTable"), DataTable).NewRow()
            dr("Id") = orow("Id")
            dr("AddressTypeId") = orow("AddressTypeId")
            dr("Name") = orow("Name")
            dr("Address1") = orow("Address1")
            dr("Address2") = orow("Address2")
            dr("City") = orow("City")
            dr("StateId") = orow("StateId")
            dr("CountryId") = orow("CountryId")
            dr("PostalCode") = orow("PostalCode")

            CType(ViewState("PartyAddressTable"), DataTable).Rows.Add(dr)

        Next

    End Sub


    Public Sub CreatePartyAddressTable()
        Dim dt As New DataTable
        dt.Columns.Add("Id", GetType(Integer))
        dt.Columns.Add("AddressTypeId", GetType(Integer))
        dt.Columns.Add("Name", GetType(String))
        dt.Columns.Add("Address1", GetType(String))
        dt.Columns.Add("Address2", GetType(String))
        dt.Columns.Add("City", GetType(String))
        dt.Columns.Add("StateId", GetType(Integer))
        dt.Columns.Add("PostalCode", GetType(String))
        dt.Columns.Add("CountryId", GetType(Integer))
        ViewState("PartyAddressTable") = dt
    End Sub



    Private Sub rgAddr_ItemCommand(sender As Object, e As GridCommandEventArgs) Handles rgAddr.ItemCommand
        'If e.CommandArgument Is Nothing Then Return
        If TypeOf e.Item IsNot GridDataItem Then Return
        Dim item = CType(e.Item, GridDataItem)
        Dim addrId As Integer = CInt(item.GetDataKeyValue("Id"))

        Select Case e.CommandName
            Case "EditAddress"
                OpenAddrWindow(addrId)

            Case "DeleteAddress"
                'DeleteAddress(addrId)
                'ReloadAddresses()
                rgAddr.Rebind()
        End Select
    End Sub
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
        Else
            ' Nouveau / introuvable
            txtA1.Text = "" : txtA2.Text = "" : txtCity.Text = "" : txtPostal.Text = "" : txtCountry.Text = ""
        End If
        pnlMsg.Visible = True
        pMsg.InnerText = "OpenAddrWindow appelé - id=" & addrId & " A1=" & txtA1.Text
        ' Ouvre la fenêtre
        ' ✅ Ouvre côté client (marche même en AJAX)
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openRw", "$find('" & rwAddr.ClientID & "').show();", True)

    End Sub
    Private Sub rgAddr_NeedDataSource(sender As Object, e As GridNeedDataSourceEventArgs) Handles rgAddr.NeedDataSource
        rgAddr.DataSource = CType(ViewState("PartyAddressTable"), DataTable)
    End Sub

    Private Sub btnAddrRefresh_Click(sender As Object, e As EventArgs) Handles btnAddrRefresh.Click
        rgAddr.Rebind()
    End Sub
    Private Sub ReloadAddresses()
        ' reset table puis recharge depuis SQL
        CreatePartyAddressTable()
        LoadAddressTable()
    End Sub
    Private Sub btnAddrSave_Click(sender As Object, e As EventArgs) Handles btnAddrSave.Click
        Dim addrId As Integer
        Integer.TryParse(hfAddrId.Value, addrId)

        If addrId <= 0 Then
            addrId = InsertAddress()
            hfAddrId.Value = addrId.ToString()

            rgAddr.Rebind()

            'ferme la fenêtre RadWindow (fonction JS closeAddrWindow(true))
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeRw", "closeAddrWindow(true);", True)
            Return

        Else
            UpdateAddress(addrId)
        End If

        ReloadAddresses()
        rgAddr.Rebind()

        ' ferme la fenêtre RadWindow (fonction JS closeAddrWindow(true))
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeRw", "closeAddrWindow(true);", True)


    End Sub
    Private Function DbNullIfEmpty(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function
    Private Sub InsertAdresseIdViewState()
        Dim dr As DataRow = CType(ViewState("PartyAddressTable"), DataTable).NewRow()
        dr("Id") = 0
        dr("AddressTypeId") = DBNull.Value
        dr("Name") = DbNullIfEmpty("")
        dr("Address1") = DbNullIfEmpty(txtA1.Text)
        dr("Address2") = DbNullIfEmpty("")
        dr("City") = DbNullIfEmpty(txtCity.Text)
        dr("StateId") = DbNullIfEmpty(rddlProvince.SelectedValue)
        dr("CountryId") = DbNullIfEmpty(rddlPays.SelectedValue)
        dr("PostalCode") = DbNullIfEmpty(txtPostal.Text)

        CType(ViewState("PartyAddressTable"), DataTable).Rows.Add(dr)

        rgAddr.Rebind()
    End Sub


    Private Function InsertAddress() As Integer
        InsertAdresseIdViewState()
        Return 0
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))

        ' Si tu n'as pas ces champs dans UI, mets DBNull / ou une valeur par défaut
        p.Add(New SqlClient.SqlParameter("@AddressTypeId", DBNull.Value))
        p.Add(New SqlClient.SqlParameter("@Name", DbNullIfEmpty("")))

        p.Add(New SqlClient.SqlParameter("@Address1", DbNullIfEmpty(txtA1.Text)))
        p.Add(New SqlClient.SqlParameter("@Address2", DbNullIfEmpty(txtA2.Text)))
        p.Add(New SqlClient.SqlParameter("@City", DbNullIfEmpty(txtCity.Text)))

        p.Add(New SqlClient.SqlParameter("@PostalCode", DbNullIfEmpty(txtPostal.Text)))
        p.Add(New SqlClient.SqlParameter("@CountryId", DbNullIfEmpty(rddlPays.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@StateId", DbNullIfEmpty(rddlProvince.SelectedValue)))


        ExecuteSQL("s0015InsertPartyAddress", p)

        Return 1
    End Function

    Private Sub UpdateAddress(addrId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Id", addrId))
        p.Add(New SqlClient.SqlParameter("@AddressTypeId", DBNull.Value))
        p.Add(New SqlClient.SqlParameter("@Name", DbNullIfEmpty("")))
        p.Add(New SqlClient.SqlParameter("@Address1", DbNullIfEmpty(txtA1.Text)))
        p.Add(New SqlClient.SqlParameter("@Address2", DbNullIfEmpty(txtA2.Text)))
        p.Add(New SqlClient.SqlParameter("@City", DbNullIfEmpty(txtCity.Text)))
        p.Add(New SqlClient.SqlParameter("@PostalCode", DbNullIfEmpty(txtPostal.Text)))
        p.Add(New SqlClient.SqlParameter("@CountryId", DbNullIfEmpty(rddlPays.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@StateId", DbNullIfEmpty(rddlProvince.SelectedValue)))
        ExecuteSQL("s0016UpdatePartyAddress", p)
    End Sub
    Private Sub DeleteAddress(addrId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Id", addrId))
        p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))

        ExecuteSQL("s0016PartyAddress_Delete", p)
    End Sub
    Private Sub OpenNewAddrWindow()

        ' 0 / vide = nouveau
        hfAddrId.Value = "0"

        ' clear champs
        txtA1.Text = ""
        txtA2.Text = ""
        txtCity.Text = ""
        txtPostal.Text = ""
        txtCountry.Text = ""

        ' clear dropdowns (important)
        rddlProvince.ClearSelection()
        rddlPays.ClearSelection()

        ' (optionnel) si tu veux afficher le DefaultMessage
        rddlProvince.SelectedIndex = -1
        rddlPays.SelectedIndex = -1

        ' ouvre la fenêtre (AJAX-safe)
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openRwNew",
        "$find('" & rwAddr.ClientID & "').show();", True)
    End Sub
    Private Sub btnNewAddress_Click(sender As Object, e As EventArgs) Handles btnNewAddress.Click
        OpenNewAddrWindow()
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        SaveSupplier()
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)


    End Sub
End Class