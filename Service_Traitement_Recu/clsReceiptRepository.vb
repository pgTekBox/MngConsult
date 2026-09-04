Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Un recu reserve par le service, tel que renvoye par s0730ClaimNextReceipt.
''' </summary>
Public Class ReceiptWorkItem
    Public Property Id As Integer
    Public Property ImageGUID As Guid
    Public Property FileName As String
    Public Property ContentType As String
    Public Property ReceiptTypeId As Integer
    Public Property ProcessingStatus As Integer
    Public Property AttemptCount As Integer
    Public Property ImageSource As Byte()
    Public Property ImageSourceText As String
    Public Property ImageForAI As Byte()
    Public Property AiJson As String
End Class

''' <summary>
''' Tout l'acces a la base MngConsul passe par ici, et uniquement par des
''' procedures stockees (meme regle que l'application web : aucun SQL en dur).
''' </summary>
Public Class clsReceiptRepository

    Private ReadOnly _connectionString As String

    Public Sub New(connectionString As String)
        _connectionString = connectionString
    End Sub

#Region "Helpers"

    Private Function Exec(procName As String, ParamArray parameters As SqlParameter()) As DataSet
        Using cnn As New SqlConnection(_connectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 120
                If parameters IsNot Nothing Then
                    For Each p As SqlParameter In parameters
                        If p IsNot Nothing Then cmd.Parameters.Add(p)
                    Next
                End If

                Dim ds As New DataSet()
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
                Return ds
            End Using
        End Using
    End Function

    Private Sub ExecNonQuery(procName As String, ParamArray parameters As SqlParameter())
        Using cnn As New SqlConnection(_connectionString)
            Using cmd As New SqlCommand(procName, cnn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 120
                If parameters IsNot Nothing Then
                    For Each p As SqlParameter In parameters
                        If p IsNot Nothing Then cmd.Parameters.Add(p)
                    Next
                End If
                cnn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Shared Function P(name As String, value As Object) As SqlParameter
        Return New SqlParameter(name, If(value, DBNull.Value))
    End Function

    Private Shared Function Str(row As DataRow, col As String) As String
        If Not row.Table.Columns.Contains(col) Then Return ""
        If IsDBNull(row(col)) Then Return ""
        Return Convert.ToString(row(col))
    End Function

    Private Shared Function Num(row As DataRow, col As String) As Integer
        If Not row.Table.Columns.Contains(col) Then Return 0
        If IsDBNull(row(col)) Then Return 0
        Return Convert.ToInt32(row(col))
    End Function

    Private Shared Function Bytes(row As DataRow, col As String) As Byte()
        If Not row.Table.Columns.Contains(col) Then Return Nothing
        If IsDBNull(row(col)) Then Return Nothing
        Return CType(row(col), Byte())
    End Function

    Private Shared Function HasRow(ds As DataSet) As Boolean
        Return ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0
    End Function

#End Region

#Region "File d'attente"

    ''' <summary>
    ''' Reserve le prochain recu a traiter (le plus ancien d'abord) et pose un
    ''' verrou dessus. Renvoie Nothing quand il n'y a plus rien a faire.
    ''' </summary>
    Public Function ClaimNextReceipt(lockSeconds As Integer, maxAttempts As Integer) As ReceiptWorkItem
        Dim ds As DataSet = Exec("s0730ClaimNextReceipt",
                                 P("@LockSeconds", lockSeconds),
                                 P("@MaxAttempts", maxAttempts),
                                 P("@MachineName", Environment.MachineName))

        If Not HasRow(ds) Then Return Nothing

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Return New ReceiptWorkItem With {
            .Id = Num(r, "Id"),
            .ImageGUID = CType(r("imageGUID"), Guid),
            .FileName = Str(r, "FileName"),
            .ContentType = Str(r, "ContentType"),
            .ReceiptTypeId = Num(r, "ReceiptTypeId"),
            .ProcessingStatus = Num(r, "ProcessingStatus"),
            .AttemptCount = Num(r, "SvcAttemptCount"),
            .ImageSource = Bytes(r, "ImageSource"),
            .ImageSourceText = Str(r, "ImageSourceText"),
            .ImageForAI = Bytes(r, "ImageForAI"),
            .AiJson = Str(r, "AI_JSON")
        }
    End Function

    Public Function GetQueue(onlyPending As Boolean, top As Integer) As DataTable
        Dim ds As DataSet = Exec("s0729GetReceiptQueue",
                                 P("@OnlyPending", If(onlyPending, 1, 0)),
                                 P("@Top", top))
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Public Function GetProcessLog(top As Integer, Optional imageGUID As Object = Nothing) As DataTable
        Dim ds As DataSet = Exec("s0734GetReceiptProcessLog",
                                 P("@Top", top),
                                 P("@imageGUID", imageGUID))
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>Compteurs affiches en haut de l'interface (a faire / termines / erreurs).</summary>
    Public Function GetStats() As DataRow
        Dim ds As DataSet = Exec("s0736GetReceiptStats")
        If Not HasRow(ds) Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

    Public Sub MarkDone(imageGUID As Guid)
        ExecNonQuery("s0731SaveReceiptProcessDone", P("@imageGUID", imageGUID))
    End Sub

    Public Sub MarkError(imageGUID As Guid, message As String)
        ExecNonQuery("s0732SaveReceiptProcessError",
                     P("@imageGUID", imageGUID),
                     P("@Message", If(message, "")))
    End Sub

    Public Sub ResetForRetry(imageGUID As Guid, fromStep As Integer)
        ExecNonQuery("s0735ResetReceiptForRetry",
                     P("@imageGUID", imageGUID),
                     P("@FromStep", fromStep))
    End Sub

    ''' <summary>Ajoute une ligne au journal de traitement (grille « Résultat »).</summary>
    Public Sub LogStep(imageGUID As Guid,
                       stepName As String,
                       success As Boolean,
                       message As String,
                       Optional json As String = Nothing,
                       Optional inputToken As Integer? = Nothing,
                       Optional outputToken As Integer? = Nothing,
                       Optional costUsd As Decimal? = Nothing,
                       Optional durationMs As Integer? = Nothing)

        ExecNonQuery("s0733LogReceiptProcess",
                     P("@imageGUID", imageGUID),
                     P("@Step", stepName),
                     P("@Success", If(success, 1, 0)),
                     P("@Message", message),
                     P("@Json", json),
                     P("@InputToken", If(inputToken.HasValue, CObj(inputToken.Value), Nothing)),
                     P("@OutputToken", If(outputToken.HasValue, CObj(outputToken.Value), Nothing)),
                     P("@EstimatedCostUsd", If(costUsd.HasValue, CObj(costUsd.Value), Nothing)),
                     P("@DurationMs", If(durationMs.HasValue, CObj(durationMs.Value), Nothing)),
                     P("@MachineName", Environment.MachineName))
    End Sub

#End Region

#Region "Etapes du traitement (memes procedures que wbfReceipt.aspx)"

    ''' <summary>Cle API OpenAI, lue en base comme le fait l'application web.</summary>
    Public Function GetOpenAiKey() As String
        Dim ds As DataSet = Exec("s0000GetParameter", P("@Parameter", "CHATGPT"))
        If Not HasRow(ds) Then Return ""
        Return Str(ds.Tables(0).Rows(0), "Value")
    End Function

    ''' <summary>Prompt d'extraction du recu (parametre PROMPT_RECEIPT).</summary>
    Public Function GetReceiptPrompt() As String
        Dim ds As DataSet = Exec("s0032GetPromptOpenAPI", P("@Parameter", "PROMPT_RECEIPT"))
        If Not HasRow(ds) Then Return ""
        Return Str(ds.Tables(0).Rows(0), "Prompt")
    End Function

    ''' <summary>Enregistre l'image noir et blanc (ProcessingStatus passe a 2).</summary>
    Public Sub SaveOptimizedImage(imageGUID As Guid, optimizedImage As Byte())
        ExecNonQuery("s0004SaveoptimizedImage",
                     P("@imageGUID", imageGUID),
                     P("@optimizedImage", optimizedImage))
    End Sub

    ''' <summary>Enregistre le JSON rendu par ChatGPT (ProcessingStatus passe a 3).</summary>
    Public Sub SaveAiReturn(imageGUID As Guid, json As String, inputToken As Integer, outputToken As Integer, costUsd As Decimal)
        ExecNonQuery("s0006SaveAIReturn",
                     P("@imageGUID", imageGUID),
                     P("@JSON", json),
                     P("@InputToken", inputToken),
                     P("@OutputToken", outputToken),
                     P("@EstimatedCostUsd", costUsd))
    End Sub

    ''' <summary>Relit le reçu apres l'optimisation, pour recuperer ImageForAI.</summary>
    Public Function GetDoc(imageGUID As Guid) As DataRow
        Dim ds As DataSet = Exec("s0003GetDoc", P("@imageGUID", imageGUID))
        If Not HasRow(ds) Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

    Public Function GetJson(imageGUID As Guid) As String
        Dim ds As DataSet = Exec("s0007GetJSON", P("@imageGUID", imageGUID))
        If Not HasRow(ds) Then Return ""
        Return Str(ds.Tables(0).Rows(0), "AI_JSON")
    End Function

    ''' <summary>
    ''' « Process JSON » pour une facture fournisseur : cree le marchand puis le
    ''' document. Ce sont exactement les deux procedures appelees par
    ''' ReceiptAI.ProcesJSON dans l'application web.
    ''' </summary>
    Public Sub ProcessJsonSupplier(imageGUID As Guid)
        ExecNonQuery("s0008SaveMerchant", P("@imageGUID", imageGUID))
        ExecNonQuery("s0009SaveDocument", P("@imageGUID", imageGUID))
    End Sub

    ''' <summary>
    ''' « Process JSON » pour une facture client (ReceiptTypeId = 1), equivalent
    ''' de ReceiptAI.ProcesJSONForCustomerInvoice.
    ''' </summary>
    Public Sub ProcessJsonCustomer(imageGUID As Guid)
        ExecNonQuery("s0033SaveCustomer", P("@imageGUID", imageGUID))
        ExecNonQuery("s0034SaveCustomerDocument", P("@imageGUID", imageGUID))
    End Sub

#End Region

End Class
