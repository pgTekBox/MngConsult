Imports System.Collections.Generic
Imports Telerik.Web.UI

Public Class wbfProducts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            BindFilterDDL()
            rlvProducts.Rebind()
            HandleSquareReturn()
            If IsSquareConnected() Then btnConnectSquare.Text = "Reconnecter Square"
        End If
    End Sub

    ''' <summary>Affiche un message selon le retour OAuth Square (?square=...).</summary>
    Private Sub HandleSquareReturn()
        Dim s As String = Request.QueryString("square")
        If String.IsNullOrEmpty(s) Then Return
        Select Case s
            Case "connected" : ShowSquareMessage("Compte Square connecté avec succès.")
            Case "denied" : ShowSquareMessage("Connexion Square refusée par l'utilisateur.")
            Case "badstate" : ShowSquareMessage("Échec de sécurité OAuth (state invalide). Réessaie la connexion.")
            Case "error" : ShowSquareMessage("Erreur lors de la connexion à Square.")
        End Select
    End Sub

    Private Sub BindFilterDDL()
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        SetDDL(rddlFilterCat, "Name", "Value", "s0081GetCategoriesForDDL", p)
    End Sub

    Private Sub rlvProducts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvProducts.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvProducts.DataSource = dt

        If dt IsNot Nothing Then
            lblInfo.Text = dt.Rows.Count & " produit(s)"
        End If
    End Sub

    Private Sub rlvProducts_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvProducts.ItemCommand
        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName
            Case "DeleteProduct"
                Dim prodId As Integer = CInt(e.CommandArgument)
                DeleteProduct(prodId)
                rlvProducts.Rebind()
        End Select
    End Sub

    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim catId As Integer = 0
        If Not String.IsNullOrEmpty(rddlFilterCat.SelectedValue) Then
            Integer.TryParse(rddlFilterCat.SelectedValue, catId)
        End If

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        p.Add(New SqlClient.SqlParameter("@CategoryId", catId))

        Dim ds As DataSet = ExecuteSQLds("s0076GetProducts", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteProduct(prodId As Integer)
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Id", prodId))
        ExecuteSQL("s0078DeleteProduct", p)
    End Sub

    ' ── Filtre catégorie ──

    Protected Sub rddlFilterCat_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles rddlFilterCat.SelectedIndexChanged
        rlvProducts.Rebind()
    End Sub

    ' ── Recherche ──

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvProducts.Rebind()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rddlFilterCat.ClearSelection()
        rlvProducts.Rebind()
    End Sub

    ' ── Export vers Square ──

    Protected Sub btnExportSquare_Click(sender As Object, e As EventArgs) Handles btnExportSquare.Click
        Try
            ' 1. Lire les produits/services actifs a exporter (+ mapping existant)
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0660GetProductsForSquareSync", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowSquareMessage("Aucun produit actif a exporter.")
                Return
            End If

            ' 2. Construire la liste pour Square
            Dim items As New List(Of clsSquare.SquareProductInput)
            For Each row As DataRow In ds.Tables(0).Rows
                Dim inp As New clsSquare.SquareProductInput
                inp.ProductId = CInt(row("Id"))
                inp.Name = If(IsDBNull(row("Name")), "", CStr(row("Name")))
                inp.Description = If(IsDBNull(row("Description")), "", CStr(row("Description")))
                Dim prix As Decimal = If(IsDBNull(row("Prix")), 0D, CDec(row("Prix")))
                inp.PriceCents = CLng(Math.Round(prix * 100D))
                If Not IsDBNull(row("SquareItemId")) Then inp.ExistingItemId = CStr(row("SquareItemId"))
                If Not IsDBNull(row("SquareVariationId")) Then inp.ExistingVariationId = CStr(row("SquareVariationId"))
                If Not IsDBNull(row("SquareItemVersion")) Then inp.ExistingItemVersion = CLng(row("SquareItemVersion"))
                If Not IsDBNull(row("SquareVariationVersion")) Then inp.ExistingVariationVersion = CLng(row("SquareVariationVersion"))
                items.Add(inp)
            Next

            ' 3. Pousser vers Square (BatchUpsertCatalogObjects)
            '    Jeton de l'abonne (OAuth) avec refresh auto ; fallback Web.config.
            Dim token As String = GetValidSquareAccessToken()
            Dim results As List(Of clsSquare.SquareSyncResult) = clsSquare.BatchUpsertCatalog(token, items)

            ' 4. Sauvegarder les identifiants Square sur le produit (T075Products)
            Dim okCount As Integer = 0
            For Each r As clsSquare.SquareSyncResult In results
                If Not String.IsNullOrEmpty(r.ItemId) Then
                    Dim pm As New Collection
                    pm.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                    pm.Add(New SqlClient.SqlParameter("@ProductId", r.ProductId))
                    pm.Add(New SqlClient.SqlParameter("@SquareItemId", r.ItemId))
                    pm.Add(New SqlClient.SqlParameter("@SquareVariationId", If(String.IsNullOrEmpty(r.VariationId), CObj(DBNull.Value), r.VariationId)))
                    pm.Add(New SqlClient.SqlParameter("@SquareItemVersion", r.ItemVersion))
                    pm.Add(New SqlClient.SqlParameter("@SquareVariationVersion", r.VariationVersion))
                    pm.Add(New SqlClient.SqlParameter("@Status", "OK"))
                    ExecuteSQL("s0661UpdateProductSquareIds", pm)
                    okCount += 1
                End If
            Next

            ShowSquareMessage(okCount & " produit(s) exporte(s) vers Square sur " & items.Count & ".")
        Catch ex As Exception
            ShowSquareMessage("Erreur lors de l'export Square : " & ex.Message)
        End Try
    End Sub

    ' ── Import des produits depuis Square (sens entrant, a la demande) ──

    Protected Sub btnImportSquare_Click(sender As Object, e As EventArgs) Handles btnImportSquare.Click
        Try
            Dim token As String = GetValidSquareAccessToken()
            Dim remotes As List(Of clsSquare.SquareProductRemote) = clsSquare.ListCatalogItems(token)

            If remotes Is Nothing OrElse remotes.Count = 0 Then
                ShowSquareMessage("Aucun produit a importer depuis Square.")
                rlvProducts.Rebind()
                Return
            End If

            Dim created As Integer = 0, updated As Integer = 0
            For Each p As clsSquare.SquareProductRemote In remotes
                If String.IsNullOrEmpty(p.ItemId) Then Continue For

                Dim pr As New Collection
                pr.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
                pr.Add(New SqlClient.SqlParameter("@SquareItemId", p.ItemId))
                pr.Add(New SqlClient.SqlParameter("@SquareVariationId", NzProd(p.VariationId)))
                pr.Add(New SqlClient.SqlParameter("@SquareItemVersion", If(p.ItemVersion > 0, CObj(p.ItemVersion), DBNull.Value)))
                pr.Add(New SqlClient.SqlParameter("@SquareVariationVersion", If(p.VariationVersion > 0, CObj(p.VariationVersion), DBNull.Value)))
                pr.Add(New SqlClient.SqlParameter("@Name", NzProd(p.Name)))
                pr.Add(New SqlClient.SqlParameter("@Description", NzProd(p.Description)))
                pr.Add(New SqlClient.SqlParameter("@PriceCents", If(p.PriceCents > 0, CObj(p.PriceCents), DBNull.Value)))
                Dim ds As DataSet = ExecuteSQLds("s0670UpsertProductFromSquare", pr)

                Dim action As String = ""
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
                   AndAlso Not IsDBNull(ds.Tables(0).Rows(0)("Action")) Then
                    action = CStr(ds.Tables(0).Rows(0)("Action"))
                End If
                If action = "created" Then created += 1 Else updated += 1
            Next

            ShowSquareMessage(created & " produit(s) cree(s) et " & updated & " mis a jour depuis Square (" & remotes.Count & " trouve(s)).")
            rlvProducts.Rebind()
        Catch ex As Exception
            ShowSquareMessage("Erreur lors de l'import Square : " & ex.Message)
        End Try
    End Sub

    Private Shared Function NzProd(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return s
    End Function

    Private Sub ShowSquareMessage(msg As String)
        Dim safe As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(ControlChars.Cr, " ").Replace(ControlChars.Lf, " ")
        Dim script As String = "radalert('" & safe & "', 400, 200, 'Export Square');"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "squareMsg", script, True)
    End Sub

    ' ── Helpers ──

    Public Function FormatPrix(prix As Object) As String
        If prix Is Nothing OrElse IsDBNull(prix) Then Return "—"
        Return CDec(prix).ToString("N2") & " $"
    End Function

    Public Function FormatQty(qty As Object) As String
        If qty Is Nothing OrElse IsDBNull(qty) Then Return "—"
        Dim d As Decimal = CDec(qty)
        If d = Math.Floor(d) Then Return CInt(d).ToString()
        Return d.ToString("N2")
    End Function

    Public Function TruncateText(txt As Object, maxLen As Integer) As String
        If txt Is Nothing OrElse IsDBNull(txt) Then Return ""
        Dim s As String = txt.ToString()
        If s.Length <= maxLen Then Return s
        Return s.Substring(0, maxLen) & "…"
    End Function

    Public Function IsActif(val As Object) As Boolean
        If val Is Nothing OrElse IsDBNull(val) Then Return False
        Return CBool(val)
    End Function

    Public Function GetTaxeBadgeClass(taxeStatus As Object) As String
        If taxeStatus Is Nothing OrElse IsDBNull(taxeStatus) Then Return "badge-zero"
        Select Case CInt(taxeStatus)
            Case 1 : Return "badge-taxable"
            Case 2 : Return "badge-exempt"
            Case Else : Return "badge-zero"
        End Select
    End Function

    Public Function GetTaxeLabel(taxeStatus As Object) As String
        If taxeStatus Is Nothing OrElse IsDBNull(taxeStatus) Then Return "—"
        Select Case CInt(taxeStatus)
            Case 1 : Return "Taxable"
            Case 2 : Return "Exempt"
            Case Else : Return "—"
        End Select
    End Function

End Class
