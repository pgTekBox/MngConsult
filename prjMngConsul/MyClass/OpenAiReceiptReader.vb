Imports Newtonsoft.Json.Linq
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks

Public Class OpenAiUsageResult
    Public Property JsonResult As String
    Public Property InputTokens As Integer
    Public Property OutputTokens As Integer
    Public Property TotalTokens As Integer
End Class

Public Class OpenAiReceiptReader

    ' ✅ Appelle OpenAI (vision) et retourne JSON + tokens
    Public Async Function ReadReceiptAsJsonAsync(
        apiKey As String,
        receiptBytes As Byte(),
        mimeType As String,
        Optional model As String = "gpt-4.1-mini",
        Optional imageDetail As String = "low"
    ) As Task(Of OpenAiUsageResult)

        If String.IsNullOrWhiteSpace(apiKey) Then Throw New ArgumentException("apiKey manquant")
        If receiptBytes Is Nothing OrElse receiptBytes.Length = 0 Then Throw New ArgumentException("receiptBytes vide")
        If String.IsNullOrWhiteSpace(mimeType) Then Throw New ArgumentException("mimeType manquant")

        Dim b64 As String = Convert.ToBase64String(receiptBytes)
        Dim dataUrl As String = $"data:{mimeType};base64,{b64}"

        Dim prompt As String =
            "Tu es un moteur OCR + extraction comptable. " &
            "Lis le reçu fourni (image) et retourne UNIQUEMENT un JSON valide (pas de texte autour). " &
            "Retourne aussi le type de recu dans receipt_type, exemples :Restaurant, essence ou autre" &
            "Schéma souhaité: " &
            "{ receipt_type,receipt_number, merchant_name,merchant_email,number_tps,number_tvq,merchant_website,  merchant_street, merchant_address, merchant_city,merchant_country,merchant_state,merchand_postalcode,merchant_phonenumber, receipt_date, currency, subtotal, taxes:[{name,amount}], total, tip, payment_method, last4, items:[{desc, qty, unit_price, amount}], confidence_notes }." &
            "Si une valeur est inconnue: null."

        ' Corps Responses API (texte + image)
        Dim body As New JObject(
            New JProperty("model", model),
            New JProperty("input", New JArray(
                New JObject(
                    New JProperty("role", "user"),
                    New JProperty("content", New JArray(
                        New JObject(
                            New JProperty("type", "input_text"),
                            New JProperty("text", prompt)
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
            http.DefaultRequestHeaders.Authorization = New AuthenticationHeaderValue("Bearer", apiKey)

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

End Class
