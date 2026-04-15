Imports Telerik.Web.UI

Public Class wbfProductEdit
    Inherits clsData

    Property ProductId() As Integer
        Get
            Try
                If ViewState("ProductId") Is Nothing Then ViewState("ProductId") = 0
                Return CInt(ViewState("ProductId"))
            Catch ex As Exception
                Return 0
            End Try
        End Get
        Set(ByVal Value As Integer)
            ViewState("ProductId") = Value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindDDL()
            ProductId = CInt(Request.QueryString("Id"))
            BindData()
        End If
    End Sub

    ' ── Chargement des listes déroulantes ──

    Sub BindDDL()
        ' Catégories
        Dim pCat As New Collection
        pCat.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        SetDDL(rddlCategory, "Name", "Value", "s0081GetCategoriesForDDL", pCat)

        ' Comptes de vente (Revenus — classe parente 6)
        Dim pVente As New Collection
        pVente.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pVente.Add(New SqlClient.SqlParameter("@ClasseParentIds", "6"))
        SetDDL(rddlCompteVente, "Name", "Value", "s0059GetComptesForDDL", pVente)

        ' Comptes d'achat (CDV + Charges — classes parentes 7,8)
        Dim pAchat As New Collection
        pAchat.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pAchat.Add(New SqlClient.SqlParameter("@ClasseParentIds", "7,8"))
        SetDDL(rddlCompteAchat, "Name", "Value", "s0059GetComptesForDDL", pAchat)
    End Sub

    ' ── Chargement des données ──

    Sub BindData()
        If ProductId = 0 Then
            ' Nouveau produit
            lblTitle.Text = "Nouveau produit"
            lblSub.Text = "Remplissez les informations du produit ou service"
            txtName.Text = ""
            txtDescription.Text = ""
            txtPrix.Value = Nothing
            txtDefaultQty.Value = 1
            chkActif.Checked = True
            chkAddToNewInvoice.Checked = False
            pnlInfo.Visible = False
        Else
            ' Produit existant
            lblTitle.Text = "Modifier le produit"

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", ProductId))
            Dim ds As DataSet = ExecuteSQLds("s0077GetOneProduct", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim row As DataRow = ds.Tables(0).Rows(0)

            txtName.Text = row("Name").ToString()
            txtDescription.Text = If(IsDBNull(row("Description")), "", row("Description").ToString())

            If Not IsDBNull(row("Prix")) Then txtPrix.Value = CDec(row("Prix"))
            If Not IsDBNull(row("DefaultQty")) Then txtDefaultQty.Value = CDec(row("DefaultQty"))

            chkAddToNewInvoice.Checked = (Not IsDBNull(row("AddToNewInvoice")) AndAlso CInt(row("AddToNewInvoice")) = 1)
            chkActif.Checked = (Not IsDBNull(row("Actif")) AndAlso CBool(row("Actif")))

            ' Catégorie
            If Not IsDBNull(row("CategoryId")) AndAlso CInt(row("CategoryId")) > 0 Then
                Try : rddlCategory.SelectedValue = row("CategoryId").ToString() : Catch : End Try
            End If

            ' Taxe
            If Not IsDBNull(row("TaxeStatusId")) Then
                Try : rddlTaxeStatus.SelectedValue = row("TaxeStatusId").ToString() : Catch : End Try
            End If

            ' Comptes
            If Not IsDBNull(row("CompteVente")) AndAlso row("CompteVente").ToString() <> "" Then
                Try : rddlCompteVente.SelectedValue = row("CompteVente").ToString() : Catch : End Try
            End If

            If Not IsDBNull(row("CompteAchat")) AndAlso row("CompteAchat").ToString() <> "" Then
                Try : rddlCompteAchat.SelectedValue = row("CompteAchat").ToString() : Catch : End Try
            End If

            lblSub.Text = row("Name").ToString()

            ' Info
            pnlInfo.Visible = True
            tlblId.Text = row("Id").ToString()
            If Not IsDBNull(row("Created")) Then
                tlblCreated.Text = CDate(row("Created")).ToString("yyyy-MM-dd HH:mm")
            End If
        End If
    End Sub

    ' ── Sauvegarde ──

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        If String.IsNullOrWhiteSpace(txtName.Text) Then
            ShowMsg("Le nom du produit est obligatoire.", False)
            Return
        End If

        If ProductId = 0 Then
            InsertProduct()
        Else
            UpdateProduct()
        End If

        ' Fermer la fenêtre
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    Private Sub InsertProduct()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@Prix", If(txtPrix.Value IsNot Nothing, CDec(txtPrix.Value), CDec(0))))
        p.Add(New SqlClient.SqlParameter("@DefaultQty", If(txtDefaultQty.Value IsNot Nothing, CDec(txtDefaultQty.Value), CDec(1))))
        p.Add(New SqlClient.SqlParameter("@AddToNewInvoice", If(chkAddToNewInvoice.Checked, 1, 0)))
        p.Add(New SqlClient.SqlParameter("@NoTaxe", 0))
        p.Add(New SqlClient.SqlParameter("@CategoryId", DbNullOrInt(rddlCategory.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullIfEmpty(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullIfEmpty(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusId", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        Dim ds As DataSet = ExecuteSQLds("s0079InsertProduct", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            ProductId = CInt(ds.Tables(0).Rows(0)(0))
        End If
    End Sub

    Private Sub UpdateProduct()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", ProductId))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@Prix", If(txtPrix.Value IsNot Nothing, CDec(txtPrix.Value), CDec(0))))
        p.Add(New SqlClient.SqlParameter("@DefaultQty", If(txtDefaultQty.Value IsNot Nothing, CDec(txtDefaultQty.Value), CDec(1))))
        p.Add(New SqlClient.SqlParameter("@AddToNewInvoice", If(chkAddToNewInvoice.Checked, 1, 0)))
        p.Add(New SqlClient.SqlParameter("@NoTaxe", 0))
        p.Add(New SqlClient.SqlParameter("@CategoryId", DbNullOrInt(rddlCategory.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullIfEmpty(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullIfEmpty(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusId", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        ExecuteSQL("s0080UpdateProduct", p)
    End Sub

    ' ── Utilitaires ──

    Private Sub ShowMsg(msg As String, success As Boolean)
        lblMsg.Visible = True
        lblMsg.CssClass = If(success, "msg msg-ok", "msg msg-err")
        lblMsg.Text = msg
    End Sub

    Private Function DbNullIfEmpty(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    Private Function DbNullOrInt(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Dim v As Integer
        If Integer.TryParse(s, v) AndAlso v > 0 Then Return v
        Return DBNull.Value
    End Function

End Class
