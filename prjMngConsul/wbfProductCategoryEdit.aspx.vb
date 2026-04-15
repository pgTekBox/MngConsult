Imports Telerik.Web.UI

Public Class wbfProductCategoryEdit
    Inherits clsData

    Property CategoryId() As Integer
        Get
            Try
                If ViewState("CategoryId") Is Nothing Then ViewState("CategoryId") = 0
                Return CInt(ViewState("CategoryId"))
            Catch ex As Exception
                Return 0
            End Try
        End Get
        Set(ByVal Value As Integer)
            ViewState("CategoryId") = Value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindDDL()
            CategoryId = CInt(Request.QueryString("Id"))
            BindData()
        End If
    End Sub

    ' ── Chargement des listes déroulantes ──

    Sub BindDDL()
        ' Comptes de revenus (classe parente 6 = Revenus, numéros 4000-4499)
        Dim pVente As New Collection
        pVente.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pVente.Add(New SqlClient.SqlParameter("@ClasseParentIds", "6"))  ' Revenus
        SetDDL(rddlCompteVente, "Name", "Value", "s0059GetComptesForDDL", pVente)

        ' Comptes d'achat / CMV (classe parente 7 = CDV + 8 = Charges d'exploitation)
        Dim pAchat As New Collection
        pAchat.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pAchat.Add(New SqlClient.SqlParameter("@ClasseParentIds", "7,8"))  ' CDV + Charges
        SetDDL(rddlCompteAchat, "Name", "Value", "s0059GetComptesForDDL", pAchat)
    End Sub

    ' ── Chargement des données ──

    Sub BindData()
        If CategoryId = 0 Then
            ' Nouvelle catégorie
            lblTitle.Text = "Nouvelle catégorie"
            lblSub.Text = "Remplissez les informations de la catégorie de produit"
            txtCode.Text = ""
            txtName.Text = ""
            txtDescription.Text = ""
            chkActif.Checked = True
            pnlInfo.Visible = False
        Else
            ' Catégorie existante
            lblTitle.Text = "Modifier la catégorie"

            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Id", CategoryId))
            Dim ds As DataSet = ExecuteSQLds("s0057GetOneProductCategory", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim row As DataRow = ds.Tables(0).Rows(0)

            txtCode.Text = row("Code").ToString()
            txtName.Text = row("Name").ToString()
            txtDescription.Text = If(IsDBNull(row("Description")), "", row("Description").ToString())
            chkActif.Checked = CBool(row("Actif"))

            ' Taxe
            If Not IsDBNull(row("TaxeStatusDefault")) Then
                rddlTaxeStatus.SelectedValue = row("TaxeStatusDefault").ToString()
            End If

            ' Comptes du plan comptable
            If Not IsDBNull(row("CompteVente")) AndAlso CInt(row("CompteVente")) > 0 Then
                Try
                    rddlCompteVente.SelectedValue = row("CompteVente").ToString()
                Catch
                End Try
            End If

            If Not IsDBNull(row("CompteAchat")) AndAlso CInt(row("CompteAchat")) > 0 Then
                Try
                    rddlCompteAchat.SelectedValue = row("CompteAchat").ToString()
                Catch
                End Try
            End If

            lblSub.Text = row("Code").ToString() & " — " & row("Name").ToString()

            ' Info
            pnlInfo.Visible = True
            tlblId.Text = row("Id").ToString()
            If Not IsDBNull(row("CategoryGUID")) Then
                tlblGuid.Text = row("CategoryGUID").ToString()
            End If
            If Not IsDBNull(row("Created")) Then
                tlblCreated.Text = CDate(row("Created")).ToString("yyyy-MM-dd HH:mm")
            End If
            If Not IsDBNull(row("Ordre")) Then
                tlblOrdre.Text = row("Ordre").ToString()
            End If
        End If
    End Sub

    ' ── Sauvegarde ──

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        ' Validation
        If String.IsNullOrWhiteSpace(txtCode.Text) Then
            ShowMsg("Le code est obligatoire.", False)
            Return
        End If
        If String.IsNullOrWhiteSpace(txtName.Text) Then
            ShowMsg("Le nom est obligatoire.", False)
            Return
        End If

        If CategoryId = 0 Then
            InsertCategory()
        Else
            UpdateCategory()
        End If

        ' Fermer la fenêtre
        Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
        ScriptManager.RegisterStartupScript(Page, Page.GetType(), "close", script, True)
    End Sub

    Private Sub InsertCategory()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Code", txtCode.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullOrInt(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullOrInt(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusDefault", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        Dim ds As DataSet = ExecuteSQLds("s0060InsertProductCategory", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            CategoryId = CInt(ds.Tables(0).Rows(0)(0))
        End If
    End Sub

    Private Sub UpdateCategory()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", CategoryId))
        p.Add(New SqlClient.SqlParameter("@Code", txtCode.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Name", txtName.Text.Trim()))
        p.Add(New SqlClient.SqlParameter("@Description", DbNullIfEmpty(txtDescription.Text)))
        p.Add(New SqlClient.SqlParameter("@CompteVente", DbNullOrInt(rddlCompteVente.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@CompteAchat", DbNullOrInt(rddlCompteAchat.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@TaxeStatusDefault", DbNullOrInt(rddlTaxeStatus.SelectedValue)))
        p.Add(New SqlClient.SqlParameter("@Actif", chkActif.Checked))

        ExecuteSQL("s0061UpdateProductCategory", p)
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
