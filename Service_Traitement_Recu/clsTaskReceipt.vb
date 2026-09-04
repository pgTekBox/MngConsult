Imports System.Data
Imports System.Text.RegularExpressions
Imports System.Threading.Tasks
Imports nspServiceTraitementRecu.clsLog

''' <summary>
''' Le traitement d'un reçu, repris tel quel de wbfReceipt.aspx :
'''
'''   1. « Process » — si c'est une photo, l'image est convertie en noir et
'''      blanc et allegee (clsReceiptImageOptimizer), puis enregistree par
'''      s0004SaveoptimizedImage (ProcessingStatus = 2).
'''   2. « Process » (suite) — le document est lu par ChatGPT
'''      (OpenAiReceiptReader) selon son type : texte, PDF ou image. Le JSON
'''      rendu est enregistre par s0006SaveAIReturn (ProcessingStatus = 3).
'''   3. « Process JSON » — le JSON est valide puis transforme en marchand et
'''      en document par s0008/s0009 (fournisseur) ou s0033/s0034 (client),
'''      exactement comme ReceiptAI.ProcesJSON (ProcessingStatus = 4).
'''
''' Chaque etape est journalisee dans T0002ReceiptProcessLog, ce qui alimente
''' la grille « Résultat » de l'application.
''' </summary>
Public Class clsTaskReceipt

    Private ReadOnly _repo As clsReceiptRepository
    Private ReadOnly _config As clsXmlConfig

    Public Sub New(config As clsXmlConfig)
        _config = config
        _repo = New clsReceiptRepository(config.ConnectionString)
    End Sub

    ''' <summary>
    ''' Traite jusqu'a BatchSize reçus. Renvoie le nombre de reçus effectivement
    ''' repris (0 = la file etait vide, le service se rendort).
    ''' </summary>
    Public Async Function ProcessBatchAsync() As Task(Of Integer)

        Dim lockSeconds As Integer = clsXmlConfig.ToInt(_config.LockSeconds, 300)
        Dim maxAttempts As Integer = clsXmlConfig.ToInt(_config.MaxAttempts, 3)
        Dim batchSize As Integer = clsXmlConfig.ToInt(_config.BatchSize, 5)

        ' Cle et prompt sont lus une seule fois par lot : ils ne changent pas
        ' d'un reçu a l'autre et ce sont deux allers-retours en base.
        Dim apiKey As String = _repo.GetOpenAiKey()
        Dim prompt As String = _repo.GetReceiptPrompt()

        If String.IsNullOrWhiteSpace(apiKey) Then
            Throw New Exception("Clé OpenAI absente : le paramètre CHATGPT est vide dans T0000Parameters.")
        End If

        Dim done As Integer = 0

        For i As Integer = 1 To batchSize
            Dim item As ReceiptWorkItem = _repo.ClaimNextReceipt(lockSeconds, maxAttempts)
            If item Is Nothing Then Exit For   ' plus rien a faire

            done += 1

            SyncLock thisLock
                ReceiptStatus.Etape = "3"
                ReceiptStatus.LastReceipt = If(item.FileName, "(sans nom)")
                ReceiptStatus.StatusText = "Traitement de " & If(item.FileName, "(sans nom)")
            End SyncLock

            Try
                Await ProcessOneAsync(item, apiKey, prompt)

                _repo.MarkDone(item.ImageGUID)
                CounterReceiptDone += 1

                SyncLock thisLock
                    ReceiptStatus.CounterDone = CounterReceiptDone.ToString()
                End SyncLock

            Catch ex As Exception
                ' Un reçu qui echoue ne doit pas arreter le lot : on le marque,
                ' on le journalise, et on passe au suivant.
                CounterReceiptError += 1

                _repo.MarkError(item.ImageGUID, ex.Message)
                SafeLog(item.ImageGUID, "COMPLET", False, ex.Message)

                clsLog.ErrorWritelog("Reçu " & item.ImageGUID.ToString() & " (" & item.FileName & ") : " & ex.Message, LogType.Erreur)

                SyncLock thisLock
                    ReceiptStatus.CounterError = CounterReceiptError.ToString()
                    ReceiptStatus.LastError = ex.Message
                End SyncLock
            End Try
        Next

        Return done
    End Function

    ''' <summary>Enchaine les etapes qui restent a faire sur un reçu.</summary>
    Private Async Function ProcessOneAsync(item As ReceiptWorkItem, apiKey As String, prompt As String) As Task

        Dim contentType As String = If(item.ContentType, "").ToLowerInvariant().Trim()

        ' ---- Etape 1 : noir et blanc (photos seulement) ----------------------
        If item.ProcessingStatus < 2 AndAlso contentType = "image/jpeg" Then
            OptimizeImage(item)
        End If

        ' ---- Etape 2 : lecture par ChatGPT -----------------------------------
        If item.ProcessingStatus < 3 OrElse String.IsNullOrWhiteSpace(item.AiJson) Then
            Await ReadWithAiAsync(item, apiKey, prompt, contentType)
        End If

        ' ---- Etape 3 : Process JSON ------------------------------------------
        ProcessJson(item)
    End Function

#Region "Etape 1 — noir et blanc"

    Private Sub OptimizeImage(item As ReceiptWorkItem)
        Dim sw As Stopwatch = Stopwatch.StartNew()

        If item.ImageSource Is Nothing OrElse item.ImageSource.Length = 0 Then
            Throw New Exception("Image source absente : rien à optimiser.")
        End If

        Dim opt As New clsReceiptImageOptimizer()
        Dim optimized As Byte()

        Try
            optimized = opt.OptimizeReceiptForAI(
                item.ImageSource,
                maxWidth:=clsXmlConfig.ToInt(_config.ImageMaxWidth, 1024),
                jpegQuality:=clsXmlConfig.ToInt(_config.ImageJpegQuality, 55),
                autoContrast:=True,
                toGrayscale:=True)
        Catch ex As Exception
            ' GDI+ ne dit que « Le paramètre n'est pas valide. » quand il ne sait
            ' pas décoder le fichier. Sans le nom et le format, impossible de
            ' savoir lequel des reçus est en cause ni pourquoi.
            Throw New Exception("Image illisible (" & If(item.FileName, "sans nom") &
                                ", " & If(item.ContentType, "format inconnu") &
                                ", " & item.ImageSource.Length.ToString("N0") & " octets) : " & ex.Message)
        End Try

        If optimized Is Nothing OrElse optimized.Length = 0 Then
            Throw New Exception("L'optimisation de l'image n'a rien produit.")
        End If

        _repo.SaveOptimizedImage(item.ImageGUID, optimized)
        item.ImageForAI = optimized
        item.ProcessingStatus = 2

        sw.Stop()
        SafeLog(item.ImageGUID, "OPTIMISATION", True,
                "Image noir et blanc : " & item.ImageSource.Length.ToString("N0") &
                " → " & optimized.Length.ToString("N0") & " octets",
                durationMs:=CInt(sw.ElapsedMilliseconds))
    End Sub

#End Region

#Region "Etape 2 — lecture par ChatGPT"

    Private Async Function ReadWithAiAsync(item As ReceiptWorkItem, apiKey As String, prompt As String, contentType As String) As Task

        Dim sw As Stopwatch = Stopwatch.StartNew()
        Dim reader As New OpenAiReceiptReader(apiKey)

        Dim json As String
        Dim inputTokens As Integer
        Dim outputTokens As Integer
        Dim costUsd As Decimal

        Select Case contentType

            Case "text/plain"
                If String.IsNullOrWhiteSpace(item.ImageSourceText) Then
                    Throw New Exception("Contenu texte absent : rien à envoyer à l'IA.")
                End If
                Dim res = Await reader.ParseInvoiceEmailAsync(item.ImageSourceText, prompt)
                json = res.JsonText
                inputTokens = res.InputTokens
                outputTokens = res.OutputTokens
                costUsd = res.EstimatedCostUsd

            Case "application/pdf"
                If item.ImageSource Is Nothing OrElse item.ImageSource.Length = 0 Then
                    Throw New Exception("PDF absent : rien à envoyer à l'IA.")
                End If
                Dim res = Await reader.ParseInvoicePdfAsync(item.ImageSource, prompt)
                json = res.JsonText
                inputTokens = res.InputTokens
                outputTokens = res.OutputTokens
                costUsd = res.EstimatedCostUsd

            Case Else
                ' Images : on envoie la version noir et blanc, pas l'originale.
                ' Elle vient d'etre ecrite en base, on la relit pour etre sur de
                ' travailler sur ce qui y est reellement stocke.
                Dim imageBytes As Byte() = item.ImageForAI
                If imageBytes Is Nothing OrElse imageBytes.Length = 0 Then
                    Dim row As DataRow = _repo.GetDoc(item.ImageGUID)
                    If row IsNot Nothing AndAlso row.Table.Columns.Contains("ImageForAI") AndAlso Not IsDBNull(row("ImageForAI")) Then
                        imageBytes = CType(row("ImageForAI"), Byte())
                    End If
                End If
                If imageBytes Is Nothing OrElse imageBytes.Length = 0 Then
                    Throw New Exception("Image optimisée absente : rien à envoyer à l'IA.")
                End If

                Dim res = Await reader.ReadReceiptAsJsonAsync(imageBytes, If(contentType = "", "image/jpeg", contentType), prompt)
                json = res.JsonResult
                inputTokens = res.InputTokens
                outputTokens = res.OutputTokens
                costUsd = 0D
        End Select

        json = CleanJson(json)

        If String.IsNullOrWhiteSpace(json) Then
            Throw New Exception("L'IA n'a retourné aucun JSON.")
        End If

        ' Validation avant d'ecrire : s0006SaveAIReturn refuse silencieusement
        ' un texte qui n'est pas du JSON (ISJSON = 0). Sans ce controle, le reçu
        ' resterait indefiniment au meme etat sans qu'on sache pourquoi.
        ReceiptJsonValidator.EnsureValidJson(json)

        _repo.SaveAiReturn(item.ImageGUID, json, inputTokens, outputTokens, costUsd)
        item.AiJson = json
        item.ProcessingStatus = 3

        sw.Stop()
        SafeLog(item.ImageGUID, "IA", True,
                ReceiptJsonValidator.Describe(json),
                json:=json,
                inputToken:=inputTokens,
                outputToken:=outputTokens,
                costUsd:=costUsd,
                durationMs:=CInt(sw.ElapsedMilliseconds))
    End Function

    ''' <summary>
    ''' Retire l'emballage que le modele ajoute parfois autour du JSON
    ''' (```json ... ```), sinon ISJSON le rejette cote SQL.
    ''' </summary>
    Private Shared Function CleanJson(raw As String) As String
        If String.IsNullOrWhiteSpace(raw) Then Return ""

        Dim s As String = raw.Trim()

        If s.StartsWith("```") Then
            s = Regex.Replace(s, "^```[a-zA-Z]*\s*", "")
            If s.EndsWith("```") Then s = s.Substring(0, s.Length - 3)
            s = s.Trim()
        End If

        Return s
    End Function

#End Region

#Region "Etape 3 — Process JSON"

    Private Sub ProcessJson(item As ReceiptWorkItem)
        Dim sw As Stopwatch = Stopwatch.StartNew()

        Dim json As String = item.AiJson
        If String.IsNullOrWhiteSpace(json) Then json = _repo.GetJson(item.ImageGUID)

        ReceiptJsonValidator.EnsureValidJson(json)

        If item.ReceiptTypeId = 1 Then
            _repo.ProcessJsonCustomer(item.ImageGUID)   ' facture client
        Else
            _repo.ProcessJsonSupplier(item.ImageGUID)   ' facture fournisseur
        End If

        sw.Stop()
        SafeLog(item.ImageGUID, "JSON", True,
                ReceiptJsonValidator.Describe(json),
                json:=json,
                durationMs:=CInt(sw.ElapsedMilliseconds))

        PostIfAuto(item)

        SafeLog(item.ImageGUID, "COMPLET", True, "Traitement terminé")
    End Sub

    ''' <summary>
    ''' Comptabilise le document si la compagnie a coché « Reçu comptabilisé
    ''' automatiquement » dans l'onglet Traitement des paramètres.
    '''
    ''' Un refus de la comptabilisation (période fermée, compte manquant, total
    ''' à zéro…) ne fait PAS échouer le reçu : le document est créé, il reste en
    ''' brouillon et se comptabilise à la main. Le faire échouer remettrait le
    ''' reçu en file alors que son document existe déjà — il ne se passerait
    ''' plus rien d'utile, et l'erreur reviendrait à chaque tentative.
    ''' </summary>
    Private Sub PostIfAuto(item As ReceiptWorkItem)
        Dim sw As Stopwatch = Stopwatch.StartNew()

        Try
            Dim res As AutoPostResult = _repo.PostDocumentIfAuto(item.ImageGUID)
            sw.Stop()

            ' Paramètre à « Non » : rien à faire et rien à journaliser.
            If res Is Nothing OrElse Not res.AutoPost Then Return

            If res.Comptabilise Then
                SafeLog(item.ImageGUID, "COMPTABILISATION", True,
                        "Document " & If(res.DocumentNumber, "") & " comptabilisé",
                        durationMs:=CInt(sw.ElapsedMilliseconds))
            Else
                SafeLog(item.ImageGUID, "COMPTABILISATION", False,
                        "Aucun document à comptabiliser pour ce reçu.",
                        durationMs:=CInt(sw.ElapsedMilliseconds))
            End If

        Catch ex As Exception
            sw.Stop()
            SafeLog(item.ImageGUID, "COMPTABILISATION", False, ex.Message,
                    durationMs:=CInt(sw.ElapsedMilliseconds))
            clsLog.ErrorWritelog("Comptabilisation automatique du reçu " & item.ImageGUID.ToString() &
                                 " : " & ex.Message, LogType.Erreur)
        End Try
    End Sub

#End Region

    ''' <summary>Le journal ne doit jamais faire echouer le traitement lui-meme.</summary>
    Private Sub SafeLog(imageGUID As Guid,
                        stepName As String,
                        success As Boolean,
                        message As String,
                        Optional json As String = Nothing,
                        Optional inputToken As Integer? = Nothing,
                        Optional outputToken As Integer? = Nothing,
                        Optional costUsd As Decimal? = Nothing,
                        Optional durationMs As Integer? = Nothing)
        Try
            _repo.LogStep(imageGUID, stepName, success, message, json, inputToken, outputToken, costUsd, durationMs)
        Catch ex As Exception
            clsLog.ErrorWritelog("Journal de traitement indisponible : " & ex.Message, LogType.Erreur)
        End Try
    End Sub

End Class
