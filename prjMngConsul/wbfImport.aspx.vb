Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Threading.Tasks

Public Class wbfImport
    Inherits clsData

    Private Shared ReadOnly AllowedExtensions As String() = {".csv", ".xlsx", ".txt"}
    Private Shared ReadOnly AllowedTypes As String() = {"Client", "Fournisseur", "Produit"}
    Private Const MaxFileSizeBytes As Integer = 50 * 1024 * 1024
    Private Const OpenAiModel As String = "gpt-4.1-mini"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            BindRecent()
        End If
    End Sub

    Protected Sub btnUpload_Click(sender As Object, e As EventArgs) Handles btnUpload.Click
        HideMessages()

        Dim typeImport As String = ddlTypeImport.SelectedValue
        If String.IsNullOrEmpty(typeImport) OrElse Array.IndexOf(AllowedTypes, typeImport) < 0 Then
            ShowError("Veuillez choisir un type d'import (Client, Fournisseur ou Produit).")
            Return
        End If

        If Not fuImportFile.HasFile Then
            ShowError("Veuillez sélectionner un fichier avant de téléverser.")
            Return
        End If

        Dim originalName As String = Path.GetFileName(fuImportFile.FileName)
        Dim ext As String = Path.GetExtension(originalName).ToLowerInvariant()

        If Array.IndexOf(AllowedExtensions, ext) < 0 Then
            ShowError($"Format non supporté : <code>{Server.HtmlEncode(ext)}</code>. Formats acceptés : .csv, .xlsx, .txt.")
            Return
        End If

        Dim sizeBytes As Integer = fuImportFile.PostedFile.ContentLength
        If sizeBytes > MaxFileSizeBytes Then
            ShowError("Le fichier dépasse la taille maximale autorisée (50 Mo).")
            Return
        End If

        Try
            Dim content As Byte() = ReadStream(fuImportFile.PostedFile.InputStream, sizeBytes)
            Dim newId As Integer = InsertStaging(typeImport, originalName, ext, sizeBytes,
                                                 fuImportFile.PostedFile.ContentType, content)

            Dim sizeText As String = FormatSize(sizeBytes)
            ShowSuccess($"<strong>{Server.HtmlEncode(originalName)}</strong> ({sizeText}) ajouté à <code>staging.ImportFiles</code> (Id = {newId}, Type = {Server.HtmlEncode(typeImport)}).")

            ddlTypeImport.SelectedValue = ""
            BindRecent()
        Catch ex As Exception
            ShowError($"Erreur lors de l'insertion : {Server.HtmlEncode(ex.Message)}")
        End Try
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs) Handles btnReset.Click
        HideMessages()
        ddlTypeImport.SelectedValue = ""
    End Sub

    Private Function InsertStaging(typeImport As String, originalName As String, ext As String,
                                   sizeBytes As Integer, contentType As String, content As Byte()) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@TypeImport", typeImport))
        p.Add(New SqlParameter("@OriginalName", originalName))
        p.Add(New SqlParameter("@FileExtension", ext))
        p.Add(New SqlParameter("@FileSize", sizeBytes))
        p.Add(New SqlParameter("@ContentType", If(String.IsNullOrEmpty(contentType), CType(DBNull.Value, Object), contentType)))
        p.Add(New SqlParameter("@FileContent", content))
        p.Add(New SqlParameter("@UploadedBy", If(UserId > 0, CType(UserId, Object), DBNull.Value)))
        p.Add(New SqlParameter("@CompanyGUID", If(Company = Guid.Empty, CType(DBNull.Value, Object), Company)))

        Dim ds As DataSet = ExecuteSQLds("s0600InsertImportFile", p)
        Return CInt(ds.Tables(0).Rows(0)(0))
    End Function

    Private Sub BindRecent()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Top", 10))

            Dim ds As DataSet = ExecuteSQLds("s0601GetRecentImportFiles", p)
            If ds.Tables(0).Rows.Count > 0 Then
                gvRecent.DataSource = ds.Tables(0)
                gvRecent.DataBind()
                pnlRecent.Visible = True
            Else
                pnlRecent.Visible = False
            End If
        Catch
            pnlRecent.Visible = False
        End Try
    End Sub

    Private Shared Function ReadStream(stream As Stream, length As Integer) As Byte()
        Dim buf(length - 1) As Byte
        Dim total As Integer = 0
        While total < length
            Dim read As Integer = stream.Read(buf, total, length - total)
            If read <= 0 Then Exit While
            total += read
        End While
        Return buf
    End Function

    Private Shared Function FormatSize(bytes As Long) As String
        Dim kb As Double = bytes / 1024.0
        If kb > 1024 Then Return (kb / 1024.0).ToString("0.00") & " Mo"
        Return kb.ToString("0.0") & " Ko"
    End Function

    Private Sub ShowSuccess(html As String)
        pnlSuccess.Visible = True
        litSuccess.Text = html
        pnlError.Visible = False
    End Sub

    Private Sub ShowError(html As String)
        pnlError.Visible = True
        litError.Text = html
        pnlSuccess.Visible = False
    End Sub

    Private Sub HideMessages()
        pnlSuccess.Visible = False
        pnlError.Visible = False
    End Sub

    ' ─────────────────────────────────────────────────────────────────────────
    ' Traitement par OpenAI (ChatGPT) — bouton "🤖 Traiter" du GridView
    ' ─────────────────────────────────────────────────────────────────────────

    Protected Async Sub gvRecent_RowCommand(sender As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs) Handles gvRecent.RowCommand
        Dim cmd As String = e.CommandName
        If Not (String.Equals(cmd, "ProcessAI",    StringComparison.OrdinalIgnoreCase) OrElse
                String.Equals(cmd, "DeleteImport", StringComparison.OrdinalIgnoreCase)) Then Return

        HideMessages()
        Dim id As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) Then
            ShowError("Identifiant invalide.")
            Return
        End If

        If String.Equals(cmd, "DeleteImport", StringComparison.OrdinalIgnoreCase) Then
            DeleteImportFile(id)
            BindRecent()
            Return
        End If

        Try
            Await ProcessFileWithAI(id)
        Catch ex As Exception
            ShowError($"Erreur lors du traitement IA : {Server.HtmlEncode(ex.Message)}")
            SaveAIError(id, ex.Message)
        End Try

        BindRecent()
    End Sub

    Private Sub DeleteImportFile(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0609DeleteImportFile", p)

            Dim fileDel As Integer = 0, partyDel As Integer = 0, prodDel As Integer = 0
            If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                fileDel  = If(r("FileDeleted")          Is DBNull.Value, 0, Convert.ToInt32(r("FileDeleted")))
                partyDel = If(r("PartyImportDeleted")   Is DBNull.Value, 0, Convert.ToInt32(r("PartyImportDeleted")))
                prodDel  = If(r("ProductImportDeleted") Is DBNull.Value, 0, Convert.ToInt32(r("ProductImportDeleted")))
            End If

            If fileDel = 0 Then
                ShowError($"Aucun fichier #{id} trouvé (déjà supprimé ?).")
            Else
                ShowSuccess($"Fichier #{id} supprimé (avec {partyDel} ligne(s) staging.PartyImport et {prodDel} ligne(s) staging.ProductImport).")
            End If
        Catch ex As Exception
            ShowError($"Erreur lors de la suppression : {Server.HtmlEncode(ex.Message)}")
        End Try
    End Sub

    Private Async Function ProcessFileWithAI(id As Integer) As Task
        ' 1) Lire le fichier depuis staging.ImportFiles
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLds("s0603GetImportFile", p)
        If ds.Tables(0).Rows.Count = 0 Then
            ShowError("Fichier introuvable.")
            Return
        End If
        Dim row As DataRow = ds.Tables(0).Rows(0)
        Dim typeImport As String = Convert.ToString(row("TypeImport"))
        Dim originalName As String = Convert.ToString(row("OriginalName"))
        Dim ext As String = Convert.ToString(row("FileExtension")).ToLowerInvariant()
        Dim fileBytes As Byte() = CType(row("FileContent"), Byte())

        ' 2) Limitation actuelle : XLSX non supporté
        If ext = ".xlsx" Then
            Dim msg As String = "Format .xlsx non supporté pour l'instant (CSV/TXT seulement). Convertissez le fichier en CSV et téléversez-le à nouveau."
            SaveAIError(id, msg)
            ShowError(msg)
            Return
        End If

        ' 3) Décoder les bytes en texte (UTF-8 ou Windows-1252)
        Dim fileText As String = DecodeTextBytes(fileBytes)
        If String.IsNullOrWhiteSpace(fileText) Then
            Dim msg As String = "Le fichier est vide ou illisible."
            SaveAIError(id, msg)
            ShowError(msg)
            Return
        End If

        ' 4) Récupérer la clé API OpenAI (paramètre 'CHATGPT' dans la DB)
        Dim pParam As New Collection
        pParam.Add(New SqlParameter("@Parameter", "CHATGPT"))
        Dim dsParam As DataSet = ExecuteSQLds("s0000GetParameter", pParam)
        If dsParam.Tables(0).Rows.Count = 0 Then
            Dim msg As String = "Clé API OpenAI ('CHATGPT') introuvable dans les paramètres."
            SaveAIError(id, msg)
            ShowError(msg)
            Return
        End If
        Dim apiKey As String = Convert.ToString(dsParam.Tables(0).Rows(0)("Value"))

        ' 5) Construire le prompt selon le type d'import
        Dim prompt As String = BuildPromptForType(typeImport, originalName)

        ' 6) Appeler OpenAI (texte = CSV/TXT envoyé directement dans le prompt)
        Dim reader As New OpenAiReceiptReader(apiKey)
        Dim result As OpenAiParseResult = Await reader.ParseInvoiceEmailAsync(fileText, prompt)

        ' 7) Sauver le résultat
        Dim pSave As New Collection
        pSave.Add(New SqlParameter("@Id", id))
        pSave.Add(New SqlParameter("@JsonResult", If(CObj(result.JsonText), DBNull.Value)))
        pSave.Add(New SqlParameter("@InputTokens", result.InputTokens))
        pSave.Add(New SqlParameter("@OutputTokens", result.OutputTokens))
        pSave.Add(New SqlParameter("@EstimatedCostUsd", result.EstimatedCostUsd))
        pSave.Add(New SqlParameter("@ModelUsed", OpenAiModel))
        pSave.Add(New SqlParameter("@Status", "Done"))
        pSave.Add(New SqlParameter("@ErrorMessage", DBNull.Value))
        ExecuteSQL("s0602UpdateImportFileResult", pSave)

        ' 8) Extraire le JSON vers staging.PartyImport / staging.ProductImport
        Dim insertedCount As Integer = 0
        Dim stagingError As String = Nothing
        Try
            Dim pStage As New Collection
            pStage.Add(New SqlParameter("@ImportFileId", id))
            Dim dsStage As DataSet = ExecuteSQLds("s0604ProcessImportJson", pStage)
            If dsStage IsNot Nothing AndAlso dsStage.Tables.Count > 0 AndAlso dsStage.Tables(0).Rows.Count > 0 Then
                insertedCount = CInt(dsStage.Tables(0).Rows(0)("InsertedCount"))
            End If
        Catch ex As Exception
            stagingError = ex.Message
        End Try

        Dim baseMsg As String = $"Fichier <strong>{Server.HtmlEncode(originalName)}</strong> traité ({result.InputTokens} tokens in / {result.OutputTokens} out, ~{result.EstimatedCostUsd:0.0000} USD)."
        If stagingError Is Nothing Then
            Dim destination As String = If(typeImport = "Produit", "staging.ProductImport", "staging.PartyImport")
            ShowSuccess($"{baseMsg} <strong>{insertedCount}</strong> ligne(s) extraite(s) vers <code>{destination}</code>.")
        Else
            ShowSuccess($"{baseMsg} ⚠ Extraction JSON échouée : {Server.HtmlEncode(stagingError)} (le JSON brut reste dans <code>staging.ImportFiles.JsonResult</code>, vous pouvez relancer <code>s0604ProcessImportJson @ImportFileId = {id}</code> manuellement).")
        End If
    End Function

    Private Sub SaveAIError(id As Integer, message As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@JsonResult", DBNull.Value))
            p.Add(New SqlParameter("@InputTokens", DBNull.Value))
            p.Add(New SqlParameter("@OutputTokens", DBNull.Value))
            p.Add(New SqlParameter("@EstimatedCostUsd", DBNull.Value))
            p.Add(New SqlParameter("@ModelUsed", OpenAiModel))
            p.Add(New SqlParameter("@Status", "Error"))
            p.Add(New SqlParameter("@ErrorMessage", message))
            ExecuteSQL("s0602UpdateImportFileResult", p)
        Catch
            ' best-effort : on n'écrase pas l'erreur originale
        End Try
    End Sub

    Private Function BuildPromptForType(typeImport As String, originalName As String) As String


        Select Case typeImport
            Case "Fournisseur"
                Dim MyParam3 As New Collection
                MyParam3.Add(New Data.SqlClient.SqlParameter("@Parameter", "PROMPT_FILE_SUPPLIER"))
                Dim msds3 As DataSet = ExecuteSQLds("s0032GetPromptOpenAPI", MyParam3)
                Dim prompt As String = msds3.Tables(0).Rows(0)("Prompt")

            Case "Client"
                Dim MyParam3 As New Collection
                MyParam3.Add(New Data.SqlClient.SqlParameter("@Parameter", "PROMPT_FILE_CUSTOMER"))
                Dim msds3 As DataSet = ExecuteSQLds("s0032GetPromptOpenAPI", MyParam3)
                Dim prompt As String = msds3.Tables(0).Rows(0)("Prompt")
                Return prompt


            Case "Produit"
                Dim MyParam3 As New Collection
                MyParam3.Add(New Data.SqlClient.SqlParameter("@Parameter", "PROMPT_FILE_PRODUCT_SERVICE"))
                Dim msds3 As DataSet = ExecuteSQLds("s0032GetPromptOpenAPI", MyParam3)
                Dim prompt As String = msds3.Tables(0).Rows(0)("Prompt")
                Return prompt

            Case Else
                Return "Retourne un JSON avec un tableau ""rows"" représentant chaque ligne du fichier sous forme d'objet clé/valeur."
        End Select
    End Function

    Private Shared Function DecodeTextBytes(bytes As Byte()) As String
        If bytes Is Nothing OrElse bytes.Length = 0 Then Return String.Empty

        ' BOM UTF-8
        If bytes.Length >= 3 AndAlso bytes(0) = &HEF AndAlso bytes(1) = &HBB AndAlso bytes(2) = &HBF Then
            Return Encoding.UTF8.GetString(bytes, 3, bytes.Length - 3)
        End If
        ' BOM UTF-16 LE
        If bytes.Length >= 2 AndAlso bytes(0) = &HFF AndAlso bytes(1) = &HFE Then
            Return Encoding.Unicode.GetString(bytes, 2, bytes.Length - 2)
        End If
        ' BOM UTF-16 BE
        If bytes.Length >= 2 AndAlso bytes(0) = &HFE AndAlso bytes(1) = &HFF Then
            Return Encoding.BigEndianUnicode.GetString(bytes, 2, bytes.Length - 2)
        End If

        ' Pas de BOM : essayer UTF-8 strict, fallback Windows-1252
        Try
            Dim utf8Strict As Encoding = New UTF8Encoding(encoderShouldEmitUTF8Identifier:=False, throwOnInvalidBytes:=True)
            Return utf8Strict.GetString(bytes)
        Catch
            Return Encoding.GetEncoding(1252).GetString(bytes)
        End Try
    End Function

End Class
