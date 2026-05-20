Imports System.Data
Imports System.Data.SqlClient

Public Class wbfImportView
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        If Not IsPostBack Then
            LoadView()
        End If
    End Sub

    Protected Sub btnMigrate_Click(sender As Object, e As EventArgs) Handles btnMigrate.Click
        Dim id As Integer
        If Not Integer.TryParse(Request.QueryString("Id"), id) OrElse id <= 0 Then
            ShowError("Identifiant manquant.")
            Return
        End If

        ' Récupérer le TypeImport pour aiguiller vers la bonne proc
        Dim pType As New Collection
        pType.Add(New SqlParameter("@Id", id))
        Dim dsType As DataSet = ExecuteSQLds("s0603GetImportFile", pType)
        If dsType.Tables(0).Rows.Count = 0 Then
            ShowError("Fichier introuvable.")
            Return
        End If
        Dim typeImport As String = Convert.ToString(dsType.Tables(0).Rows(0)("TypeImport"))

        Dim procName As String
        Select Case typeImport
            Case "Client", "Fournisseur" : procName = "s0607MigratePartyImportToProd"
            Case "Produit"               : procName = "s0608MigrateProductImportToProd"
            Case Else
                ShowError($"TypeImport inconnu : {Server.HtmlEncode(typeImport)}")
                Return
        End Select

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@ImportFileId", id))
            Dim ds As DataSet = ExecuteSQLds(procName, p)

            Dim totalPending As Integer = 0, migrated As Integer = 0, skipped As Integer = 0, errors As Integer = 0
            If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                totalPending = If(r("TotalPending") Is DBNull.Value, 0, Convert.ToInt32(r("TotalPending")))
                migrated     = If(r("Migrated")     Is DBNull.Value, 0, Convert.ToInt32(r("Migrated")))
                skipped      = If(r("Skipped")      Is DBNull.Value, 0, Convert.ToInt32(r("Skipped")))
                errors       = If(r("Errors")       Is DBNull.Value, 0, Convert.ToInt32(r("Errors")))
            End If

            Dim icon As String = If(errors > 0, "⚠", "✅")
            Dim destination As String = If(typeImport = "Produit", "produits", "T050Party + T054PartyAddress")
            litMigrateResult.Text = $"{icon} Migration vers {destination} terminée : <strong>{migrated}</strong> migré(s), <strong>{skipped}</strong> ignoré(s), <strong>{errors}</strong> erreur(s) sur {totalPending} ligne(s) en attente."
            pnlMigrateResult.Visible = True
        Catch ex As Exception
            ShowError($"Erreur lors de la migration : {Server.HtmlEncode(ex.Message)}")
        End Try

        ' Rafraîchir l'affichage pour montrer les nouveaux statuts
        LoadView()
    End Sub

    Private Sub LoadView()
        Dim id As Integer
        If Not Integer.TryParse(Request.QueryString("Id"), id) OrElse id <= 0 Then
            ShowError("Identifiant manquant ou invalide. Utilisez l'URL <code>wbfImportView.aspx?Id=&lt;n&gt;</code>.")
            Return
        End If

        ' On regarde d'abord le TypeImport pour choisir la bonne proc
        Dim pType As New Collection
        pType.Add(New SqlParameter("@Id", id))
        Dim dsType As DataSet = ExecuteSQLds("s0603GetImportFile", pType)
        If dsType.Tables(0).Rows.Count = 0 Then
            ShowError($"Aucun fichier trouvé pour Id = {id}.")
            Return
        End If
        Dim typeImport As String = Convert.ToString(dsType.Tables(0).Rows(0)("TypeImport"))

        Dim procName As String
        Select Case typeImport
            Case "Client", "Fournisseur" : procName = "s0605GetPartyImports"
            Case "Produit"               : procName = "s0606GetProductImports"
            Case Else
                ShowError($"TypeImport inconnu : {Server.HtmlEncode(typeImport)}")
                Return
        End Select

        Dim p As New Collection
        p.Add(New SqlParameter("@ImportFileId", id))
        Dim ds As DataSet = ExecuteSQLds(procName, p)

        If ds.Tables.Count < 1 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowError($"Aucun résumé pour Id = {id}.")
            Return
        End If

        ' ── Résumé du fichier ────────────────────────────────────────────────
        Dim summary As DataRow = ds.Tables(0).Rows(0)
        litId.Text = Convert.ToString(summary("Id"))
        litType.Text = Server.HtmlEncode(typeImport)
        litFileName.Text = Server.HtmlEncode(Convert.ToString(summary("OriginalName")))
        litUploadDate.Text = Convert.ToDateTime(summary("UploadDate")).ToString("yyyy-MM-dd HH:mm")
        litStatus.Text = Server.HtmlEncode(Convert.ToString(summary("Status")))
        litRows.Text = If(summary("ProcessedRows") Is DBNull.Value, "—", Convert.ToInt32(summary("ProcessedRows")).ToString())
        litModel.Text = If(summary("ModelUsed") Is DBNull.Value, "—", Server.HtmlEncode(Convert.ToString(summary("ModelUsed"))))

        Dim ti As String = If(summary("InputTokens") Is DBNull.Value, "—", Convert.ToInt32(summary("InputTokens")).ToString("N0"))
        Dim toks As String = If(summary("OutputTokens") Is DBNull.Value, "—", Convert.ToInt32(summary("OutputTokens")).ToString("N0"))
        litTokens.Text = $"{ti} / {toks}"
        litCost.Text = If(summary("EstimatedCostUsd") Is DBNull.Value, "—", Convert.ToDecimal(summary("EstimatedCostUsd")).ToString("0.0000") & " USD")

        litHeaderSub.Text = $"{Server.HtmlEncode(typeImport)} — <strong>{Server.HtmlEncode(Convert.ToString(summary("OriginalName")))}</strong>"

        ' Si le fichier n'a pas été traité par l'IA → avertissement
        If summary("ProcessedRows") Is DBNull.Value OrElse Convert.ToInt32(summary("ProcessedRows")) = 0 Then
            ShowWarning("Aucune ligne extraite vers le staging pour ce fichier. Lancez d'abord le bouton <strong>🤖 Traiter</strong> sur la page d'import.")
        End If

        pnlContent.Visible = True

        ' ── Lignes staging (Table 1) ─────────────────────────────────────────
        If ds.Tables.Count >= 2 Then
            Dim dt As DataTable = ds.Tables(1)
            Select Case typeImport
                Case "Client"
                    litPartyTitle.Text = "Clients en staging"
                    gvParty.DataSource = dt
                    gvParty.DataBind()
                    pnlParty.Visible = True
                Case "Fournisseur"
                    litPartyTitle.Text = "Fournisseurs en staging"
                    gvParty.DataSource = dt
                    gvParty.DataBind()
                    pnlParty.Visible = True
                Case "Produit"
                    gvProduct.DataSource = dt
                    gvProduct.DataBind()
                    pnlProduct.Visible = True
            End Select
        End If
    End Sub

    Private Sub ShowError(html As String)
        pnlError.Visible = True
        litError.Text = html
        pnlContent.Visible = False
    End Sub

    Private Sub ShowWarning(html As String)
        pnlWarning.Visible = True
        litWarning.Text = html
    End Sub

End Class
