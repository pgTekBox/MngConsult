
Imports System.Diagnostics.Eventing
Imports System.Runtime.InteropServices
Imports Telerik.Web.UI
Imports Telerik.Web.UI.OrgChartStyles
Imports Telerik.Web.UI.Skins


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

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            BinDDL()
            CreatePartyAddressTable()
            SupplierId = CInt(Request.QueryString("Id"))
            BindData()
        End If

        ApplyLocalization()

    End Sub

    ''' <summary>Applique la langue courante (fr/en/es) aux contrôles serveur (titre, boutons, combos).</summary>
    Private Sub ApplyLocalization()
        Page.Title = L("pageTitle")
        lnkBack.Text = "← " & L("back")
        lnkStripeOnboarding.Text = "💳 " & L("configStripe")
        btnSave.Text = L("save")
        rddlPartyType.DefaultMessage = L("select")
        btnNewAddress.Text = "+ " & L("addAddress")
        rwAddr.Title = L("addrWinTitle")
        rddlAddressType.DefaultMessage = L("select")
        rddlProvince.DefaultMessage = L("select")
        rddlPays.DefaultMessage = L("select")
        btnAddrSave.Text = L("save")
        btnAddrCancel.Text = L("cancel")

        ' Libellés HTML : passés par des Literal (et non des blocs <%= %>) car le
        ' RadAjaxManager déplace le RadUpdatePanel de rlvAddr/pnlAddrEditor en modifiant
        ' la collection Controls de form1 — impossible si form1 contient des blocs de code.
        SetLiteral(Me, "litTitle", L("pageTitleShort"))
        SetLiteral(Me, "litSupplierInfo", L("supplierInfo"))
        SetLiteral(Me, "litLblId", L("id"))
        SetLiteral(Me, "litLblOrigin", L("origin"))
        SetLiteral(Me, "litLblCreated", L("created"))
        SetLiteral(Me, "litLblName", L("name"))
        SetLiteral(Me, "litLblDisplayName", L("displayName"))
        SetLiteral(Me, "litLblPartyType", L("type"))
        SetLiteral(Me, "litLblWebsite", L("website"))
        SetLiteral(Me, "litLblNoTps", L("noTps"))
        SetLiteral(Me, "litLblNoTvq", L("noTvq"))
        SetLiteral(Me, "litLblNote", L("note"))
        SetLiteral(Me, "litAddresses", L("addresses"))
        SetLiteral(Me, "litLblAddrType", L("type"))
        SetLiteral(Me, "litLblAddrName", L("name"))
        SetLiteral(Me, "litLblAddr1", L("address1"))
        SetLiteral(Me, "litLblAddr2", L("address2"))
        SetLiteral(Me, "litLblCity", L("city"))
        SetLiteral(Me, "litLblProvince", L("province"))
        SetLiteral(Me, "litLblCountry", L("country"))
        SetLiteral(Me, "litLblPostal", L("postalCode"))
        SetLiteral(Me, "litLblAddrEmail", L("addrEmail"))
        SetLiteral(Me, "litLblAddrNote", L("note"))
    End Sub

    ''' <summary>Localise les libellés du LayoutTemplate / EmptyDataTemplate du RadListView
    ''' des adresses. Interdiction d'y mettre des blocs &lt;%# %&gt; : le RadListView doit
    ''' modifier la collection Controls du LayoutTemplate (injection dans addrPlaceholder).
    ''' On passe donc par des Literal renseignés ici.</summary>
    Private Sub rlvAddr_PreRender(sender As Object, e As EventArgs) Handles rlvAddr.PreRender
        SetLiteral(rlvAddr, "litAddrColType", L("colType"))
        SetLiteral(rlvAddr, "litAddrColAddress", L("colAddress"))
        SetLiteral(rlvAddr, "litAddrColActions", L("colActions"))
        SetLiteral(rlvAddr, "litAddrEmpty", L("noAddress"))
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

    ''' <summary>Traductions de l'interface Édition Fournisseur (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Fournisseur — Édition", "Supplier — Edit", "Proveedor — Edición")
            Case "pageTitleShort" : Return Choose3(lang, "Édition — Fournisseur", "Edit — Supplier", "Edición — Proveedor")
            Case "back" : Return Choose3(lang, "Retour à la liste", "Back to list", "Volver a la lista")
            Case "configStripe" : Return Choose3(lang, "Configurer Stripe", "Configure Stripe", "Configurar Stripe")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "cancel" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "select" : Return Choose3(lang, "Sélectionner…", "Select…", "Seleccionar…")
            Case "supplierInfo" : Return Choose3(lang, "Informations Fournisseur", "Supplier information", "Información del proveedor")
            Case "id" : Return Choose3(lang, "Id", "Id", "Id")
            Case "origin" : Return Choose3(lang, "Origine", "Origin", "Origen")
            Case "created" : Return Choose3(lang, "Créé", "Created", "Creado")
            Case "name" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "displayName" : Return Choose3(lang, "Nom d'affichage", "Display name", "Nombre para mostrar")
            Case "type" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "website" : Return Choose3(lang, "Site web", "Website", "Sitio web")
            Case "noTps" : Return Choose3(lang, "No TPS", "GST No.", "No. TPS")
            Case "noTvq" : Return Choose3(lang, "No TVQ", "QST No.", "No. TVQ")
            Case "note" : Return Choose3(lang, "Note", "Note", "Nota")
            Case "addresses" : Return Choose3(lang, "Adresses", "Addresses", "Direcciones")
            Case "addAddress" : Return Choose3(lang, "Ajouter une adresse", "Add an address", "Agregar una dirección")
            Case "colType" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "colAddress" : Return Choose3(lang, "Adresse", "Address", "Dirección")
            Case "colActions" : Return Choose3(lang, "Actions", "Actions", "Acciones")
            Case "edit" : Return Choose3(lang, "Modifier", "Edit", "Editar")
            Case "delete" : Return Choose3(lang, "Supprimer", "Delete", "Eliminar")
            Case "noAddress" : Return Choose3(lang, "Aucune adresse enregistrée pour ce fournisseur.", "No address saved for this supplier.", "Ninguna dirección registrada para este proveedor.")
            Case "addrWinTitle" : Return Choose3(lang, "Édition adresse", "Edit address", "Edición de dirección")
            Case "address1" : Return Choose3(lang, "Adresse 1", "Address 1", "Dirección 1")
            Case "address2" : Return Choose3(lang, "Adresse 2", "Address 2", "Dirección 2")
            Case "city" : Return Choose3(lang, "Ville", "City", "Ciudad")
            Case "province" : Return Choose3(lang, "Province", "Province", "Provincia")
            Case "country" : Return Choose3(lang, "Pays", "Country", "País")
            Case "postalCode" : Return Choose3(lang, "Code postal", "Postal code", "Código postal")
            Case "addrEmail" : Return Choose3(lang, "Courriel", "Email", "Correo")
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

    Sub BinDDL()
        SetDDL(rddlProvince, "Name", "Value", "s0014GetProvince")
        SetDDL(rddlPays, "Name", "Value", "s0015GetCountry")
        SetDDL(rddlAddressType, "Name", "Value", "s0020AddressType")
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@Type", 2))
        SetDDL(rddlPartyType, "Name", "Value", "s0022GetPartyType", p)
    End Sub


    Sub BindData()
        If SupplierId = 0 Then
            'New Supplier

            txtName.Text = ""
            txtWebsite.Text = ""
            txtNoTPS.Text = ""
            txtNoTVQ.Text = ""

            txtNote.Text = ""

            ' Bouton Stripe : non visible pour un nouveau fournisseur (besoin d'un PartyId)
            lnkStripeOnboarding.Visible = False

        Else
            'Existing Supplier
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))
            Dim ds As DataSet = ExecuteSQLds("s0012GetOneSuppliersSupplier", p)

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

            ' Activer le bouton Stripe Connect (ouvre dans nouvelle fenêtre)
            lnkStripeOnboarding.Visible = True
            lnkStripeOnboarding.NavigateUrl = "wbfSupplierStripeOnboarding.aspx?PartyId=" & SupplierId.ToString()
            lnkStripeOnboarding.Target = "_blank"

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
        p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))

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


    'Sauvegarde les infos du Supplier (hors adresses) dans la BD
    Sub SaveSupplier(MySupplierId As Integer)
        If MySupplierId = 0 Then
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))

            p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
            'p.Add(New SqlClient.SqlParameter("@Note", txtAddressNote.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@PartyCodeiD", 2))
            p.Add(New SqlClient.SqlParameter("@Website", txtWebsite.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@TPS", txtNoTPS.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@TVQ", txtNoTVQ.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@DisplayName", txtDisplayName.Text.Trim()))

            p.Add(New SqlClient.SqlParameter("@Note", txtNote.Text.Trim()))
            p.Add(New SqlClient.SqlParameter("@Type", rddlPartyType.SelectedValue))
            p.Add(New SqlClient.SqlParameter("@Origin", 1))


            Dim ds As DataSet = ExecuteSQLds("s0021InsertParty", p)

            SupplierId = ds.Tables(0).Rows(0)(0)
            UpadateAllAddress()



        Else

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", SupplierId))
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
            rddlProvince.SelectedValue = r("StateId")
            rddlPays.SelectedValue = r("CountryId")
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
        ' ✅ Ouvre côté fournisseur (marche même en AJAX)
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

        Dim Newid As Integer = (CType(ViewState("PartyAddressTable"), DataTable).Rows.Count + 1) * -1 ' Id négatif temporaire pour différencier les nouvelles lignes (les lignes existantes ont des Id positifs issus de la BD, les nouvelles lignes auront des Id négatifs générés à la volée)    

        Dim dr As DataRow = CType(ViewState("PartyAddressTable"), DataTable).NewRow()

        dr("Id") = Newid
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
                p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))
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
                p.Add(New SqlClient.SqlParameter("@PartyId", SupplierId))
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

        If SupplierId = 0 Then
            SaveSupplier(0)
        Else

            SaveSupplier(SupplierId)
        End If






        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)


    End Sub


    Private Function DbNullIfEmpty(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function


End Class