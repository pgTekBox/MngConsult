Imports Newtonsoft.Json.Linq
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks

Public Class OpenAiParseResult
    Public Property JsonText As String
    Public Property InputTokens As Integer
    Public Property OutputTokens As Integer
    Public Property TotalTokens As Integer
    Public Property EstimatedCostUsd As Decimal
End Class

Public Class OpenAiUsageResult
    Public Property JsonResult As String
    Public Property InputTokens As Integer
    Public Property OutputTokens As Integer
    Public Property TotalTokens As Integer
End Class

Public Class OpenAiReceiptReader

    Private ReadOnly _http As HttpClient
    Private ReadOnly _apiKey As String

    Public Sub New(apiKey As String)
        _apiKey = apiKey
        _http = New HttpClient()
        _http.DefaultRequestHeaders.Authorization =
            New AuthenticationHeaderValue("Bearer", _apiKey)
    End Sub
    ' =============================
    ' MÉTHODE PRINCIPALE
    ' =============================
    Public Async Function ParseInvoicePdfAsync(
    pdfBytes As Byte(),
    promptText As String
) As Task(Of OpenAiParseResult)

        ' 1️⃣ upload
        Dim fileId = Await UploadFileAsync(pdfBytes)

        ' 2️⃣ call model
        Return Await CallModelAsync(fileId, promptText)

    End Function

    ' =============================
    ' UPLOAD DU PDF
    ' =============================
    Private Async Function UploadFileAsync(pdfBytes As Byte()) As Task(Of String)

        Using form As New MultipartFormDataContent()

            Dim fileContent = New ByteArrayContent(pdfBytes)
            fileContent.Headers.ContentType =
                New MediaTypeHeaderValue("application/pdf")

            form.Add(fileContent, "file", "invoice.pdf")
            form.Add(New StringContent("user_data"), "purpose")

            Dim resp = Await _http.PostAsync(
                "https://api.openai.com/v1/files",
                form)

            Dim txt = Await resp.Content.ReadAsStringAsync()

            If Not resp.IsSuccessStatusCode Then
                Throw New Exception("OpenAI upload error: " & txt)
            End If

            Dim jo = JObject.Parse(txt)
            Return jo("id").ToString()
        End Using
    End Function

    ' =============================
    ' APPEL GPT-4.1-mini
    ' =============================
    Private Async Function CallModelAsync(
    fileId As String,
    promptText As String
) As Task(Of OpenAiParseResult)

        Dim payload =
$"{{
  ""model"": ""gpt-4.1-mini"",
  ""input"": [
    {{
      ""role"": ""user"",
      ""content"": [
        {{
          ""type"": ""input_text"",
          ""text"": {Newtonsoft.Json.JsonConvert.ToString(promptText)}
        }},
        {{
          ""type"": ""input_file"",
          ""file_id"": ""{fileId}""
        }}
      ]
    }}
  ]
}}"

        Dim content = New StringContent(payload, Encoding.UTF8, "application/json")

        Dim resp = Await _http.PostAsync(
        "https://api.openai.com/v1/responses",
        content)

        Dim txt = Await resp.Content.ReadAsStringAsync()

        If Not resp.IsSuccessStatusCode Then
            Throw New Exception("OpenAI response error: " & txt)
        End If

        Dim jo = JObject.Parse(txt)

        ' =========================
        ' 🔥 TEXTE EXTRAIT
        ' =========================
        Dim outputText =
        jo("output")(0)("content")(0)("text").ToString()

        ' =========================
        ' 🔥 TOKENS UTILISÉS
        ' =========================
        Dim inputTokens As Integer = jo("usage")("input_tokens")
        Dim outputTokens As Integer = jo("usage")("output_tokens")
        Dim totalTokens As Integer = jo("usage")("total_tokens")

        ' =========================
        ' 💰 ESTIMATION COÛT (approx)
        ' gpt-4.1-mini (à ajuster si pricing change)
        ' =========================
        Dim costUsd As Decimal =
        (inputTokens * 0.00000015D) +
        (outputTokens * 0.0000006D)

        Return New OpenAiParseResult With {
        .JsonText = outputText,
        .InputTokens = inputTokens,
        .OutputTokens = outputTokens,
        .TotalTokens = totalTokens,
        .EstimatedCostUsd = costUsd
    }

    End Function
    ' ✅ Appelle OpenAI (vision) et retourne JSON + tokens
    Public Async Function ReadReceiptAsJsonAsync(
               receiptBytes As Byte(),
        mimeType As String, Prompt As String,
        Optional model As String = "gpt-4.1-mini",
        Optional imageDetail As String = "low"
    ) As Task(Of OpenAiUsageResult)

        If String.IsNullOrWhiteSpace(_apiKey) Then Throw New ArgumentException("apiKey manquant")
        If receiptBytes Is Nothing OrElse receiptBytes.Length = 0 Then Throw New ArgumentException("receiptBytes vide")
        If String.IsNullOrWhiteSpace(mimeType) Then Throw New ArgumentException("mimeType manquant")

        Dim b64 As String = Convert.ToBase64String(receiptBytes)
        Dim dataUrl As String = $"data:{mimeType};base64,{b64}"



        ' Corps Responses API (texte + image)
        Dim body As New JObject(
            New JProperty("model", model),
            New JProperty("input", New JArray(
                New JObject(
                    New JProperty("role", "user"),
                    New JProperty("content", New JArray(
                        New JObject(
                            New JProperty("type", "input_text"),
                            New JProperty("text", Prompt)
                        ),
                        New JObject(
                            New JProperty("type", "input_image"),
                            New JProperty("image_url", dataUrl),
                            New JProperty("detail", imageDetail)
                        )
                    ))
                )
            ))
        )

        ' Aide le modèle à sortir du JSON strict
        body("text") = New JObject(
            New JProperty("format", New JObject(New JProperty("type", "json_object")))
        )

        Using http As New HttpClient()
            http.Timeout = TimeSpan.FromSeconds(60)
            http.DefaultRequestHeaders.Authorization = New AuthenticationHeaderValue("Bearer", _apiKey)

            Dim payload As String = body.ToString(Newtonsoft.Json.Formatting.None)

            Using content As New StringContent(payload, Encoding.UTF8, "application/json")
                Dim resp As HttpResponseMessage = Await http.PostAsync("https://api.openai.com/v1/responses", content).ConfigureAwait(False)
                Dim respText As String = Await resp.Content.ReadAsStringAsync().ConfigureAwait(False)

                If Not resp.IsSuccessStatusCode Then
                    Throw New Exception($"OpenAI error {(CInt(resp.StatusCode))}: {respText}")
                End If

                Dim result As New OpenAiUsageResult()
                Dim root As JObject = JObject.Parse(respText)

                ' ===== TOKENS =====
                Dim usage As JObject = TryCast(root("usage"), JObject)
                If usage IsNot Nothing Then
                    result.InputTokens = usage.Value(Of Integer?)("input_tokens").GetValueOrDefault()
                    result.OutputTokens = usage.Value(Of Integer?)("output_tokens").GetValueOrDefault()
                    result.TotalTokens = usage.Value(Of Integer?)("total_tokens").GetValueOrDefault()
                End If

                ' ===== EXTRACTION output_text =====
                Dim outputArr As JArray = TryCast(root("output"), JArray)
                If outputArr IsNot Nothing Then
                    For Each outItem As JObject In outputArr.OfType(Of JObject)()
                        Dim contentArr As JArray = TryCast(outItem("content"), JArray)
                        If contentArr Is Nothing Then Continue For

                        For Each c As JObject In contentArr.OfType(Of JObject)()
                            If String.Equals(c.Value(Of String)("type"), "output_text", StringComparison.OrdinalIgnoreCase) Then
                                Dim txt As String = c.Value(Of String)("text")
                                If Not String.IsNullOrWhiteSpace(txt) Then
                                    result.JsonResult = txt.Trim()
                                    Return result
                                End If
                            End If
                        Next
                    Next
                End If

                ' fallback (selon variations)
                Dim direct As String = root.Value(Of String)("output_text")
                If Not String.IsNullOrWhiteSpace(direct) Then
                    result.JsonResult = direct.Trim()
                    Return result
                End If

                Throw New Exception("Aucun output_text trouvé dans la réponse OpenAI.")
            End Using
        End Using

    End Function
    ' =============================
    ' MÉTHODE POUR EMAIL / HTML
    ' =============================
    Public Async Function ParseInvoiceEmailAsync(
        emailContent As String,
        promptText As String
    ) As Task(Of OpenAiParseResult)
        ' Pas besoin d'upload : on envoie le contenu directement dans le prompt
        Return Await CallModelWithTextAsync(emailContent, promptText)
    End Function

    ' =============================
    ' APPEL GPT-4.1-mini AVEC TEXTE
    ' =============================
    Private Async Function CallModelWithTextAsync(
        emailContent As String,
        promptText As String
    ) As Task(Of OpenAiParseResult)

        ' On combine le prompt + le contenu du mail dans un seul message
        Dim fullPrompt = promptText & vbCrLf & vbCrLf &
                         "--- DÉBUT DU COURRIEL ---" & vbCrLf &
                         emailContent & vbCrLf &
                         "--- FIN DU COURRIEL ---"

        Dim payload =
    $"{{
  ""model"": ""gpt-4.1-mini"",
  ""input"": [
    {{
      ""role"": ""user"",
      ""content"": [
        {{
          ""type"": ""input_text"",
          ""text"": {Newtonsoft.Json.JsonConvert.ToString(fullPrompt)}
        }}
      ]
    }}
  ]
}}"

        Dim content = New StringContent(payload, Encoding.UTF8, "application/json")
        Dim resp = Await _http.PostAsync(
            "https://api.openai.com/v1/responses",
            content)

        Dim txt = Await resp.Content.ReadAsStringAsync()
        If Not resp.IsSuccessStatusCode Then
            Throw New Exception("OpenAI response error: " & txt)
        End If

        Dim jo = JObject.Parse(txt)

        Dim outputText = jo("output")(0)("content")(0)("text").ToString()

        Dim inputTokens As Integer = jo("usage")("input_tokens")
        Dim outputTokens As Integer = jo("usage")("output_tokens")
        Dim totalTokens As Integer = jo("usage")("total_tokens")

        Dim costUsd As Decimal =
            (inputTokens * 0.00000015D) +
            (outputTokens * 0.0000006D)

        Return New OpenAiParseResult With {
            .JsonText = outputText,
            .InputTokens = inputTokens,
            .OutputTokens = outputTokens,
            .TotalTokens = totalTokens,
            .EstimatedCostUsd = costUsd
        }
    End Function
End Class
