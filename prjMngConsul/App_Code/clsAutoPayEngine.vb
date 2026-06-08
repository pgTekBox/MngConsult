Imports System
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text
Imports Stripe

''' <summary>
''' Moteur metier des paiements automatiques fournisseurs.
'''
''' Trois operations principales (toutes idempotentes et sans intervention user) :
'''   1. ProcessDuePayments   : execute les debits dus aujourd'hui
'''   2. SendPreavis24h        : envoie les preavis 24h pour cartes
'''   3. SendPadPreavis3Days   : envoie les preavis PAD legaux (3 jours)
'''
''' Toutes les operations BD passent par les stored procs de la Phase 1
''' (s0085-s0095). Les emails sont inseres dans T400Mails (BD MailService)
''' et envoyes ensuite par SrvAI.
'''
''' Cette classe NE PAS heriter de clsData (qui est lie a System.Web.UI.Page)
''' car elle est appelee depuis un Handler (.ashx) ou une console.
''' </summary>
Public Class clsAutoPayEngine

    ' =========================================================================
    ' Connection strings
    ' =========================================================================

    Private Shared ReadOnly Property ConnString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Private Shared ReadOnly Property ConnStringMail As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionStringMail")
        End Get
    End Property

    Private Shared ReadOnly Property MaxRetries As Integer
        Get
            Dim s As String = ConfigurationManager.AppSettings("AutoPay.MaxRetries")
            Dim n As Integer
            If Integer.TryParse(s, n) AndAlso n > 0 Then Return n
            Return 3
        End Get
    End Property

    ' =========================================================================
    ' Resultat agrege d'une operation
    ' =========================================================================

    Public Class ProcessResult
        Public Property Processed As Integer = 0
        Public Property Succeeded As Integer = 0
        Public Property Failed As Integer = 0
        Public Property RequiresAction As Integer = 0
        Public Property BlockedByCap As Integer = 0
        Public Property EmailsSent As Integer = 0
        Public Property Errors As New List(Of String)()

        Public Function ToJson() As String
            Dim sb As New StringBuilder()
            sb.Append("{")
            sb.AppendFormat("""processed"":{0},", Processed)
            sb.AppendFormat("""succeeded"":{0},", Succeeded)
            sb.AppendFormat("""failed"":{0},", Failed)
            sb.AppendFormat("""requires_action"":{0},", RequiresAction)
            sb.AppendFormat("""blocked_by_cap"":{0},", BlockedByCap)
            sb.AppendFormat("""emails_sent"":{0},", EmailsSent)
            sb.AppendFormat("""errors_count"":{0}", Errors.Count)
            If Errors.Count > 0 Then
                sb.Append(",""errors"":[")
                For i = 0 To Math.Min(Errors.Count, 10) - 1
                    If i > 0 Then sb.Append(",")
                    sb.Append(EscapeJsonString(Errors(i)))
                Next
                sb.Append("]")
            End If
            sb.Append("}")
            Return sb.ToString()
        End Function

        Private Shared Function EscapeJsonString(s As String) As String
            If s Is Nothing Then Return """"""
            Dim sb As New StringBuilder()
            sb.Append(""""c)
            For Each c In s
                Select Case c
                    Case """"c : sb.Append("\""")
                    Case "\"c  : sb.Append("\\")
                    Case ChrW(8) : sb.Append("\b")
                    Case ChrW(9) : sb.Append("\t")
                    Case ChrW(10) : sb.Append("\n")
                    Case ChrW(12) : sb.Append("\f")
                    Case ChrW(13) : sb.Append("\r")
                    Case Else
                        If AscW(c) < 32 Then
                            sb.AppendFormat("\u{0:x4}", AscW(c))
                        Else
                            sb.Append(c)
                        End If
                End Select
            Next
            sb.Append(""""c)
            Return sb.ToString()
        End Function
    End Class

    ' =========================================================================
    ' OPERATION 1 : EXECUTER LES DEBITS AUTOMATIQUES DUS
    ' =========================================================================

    ''' <summary>
    ''' Recupere via s0088GetDuePayments la liste des factures dues, puis pour
    ''' chacune :
    '''   1. Verifie le plafond mensuel via s0093GetMonthlyTotalForParty
    '''   2. Calcule le gross-up
    '''   3. Cree un PaymentIntent off-session via Stripe (clsStripe)
    '''   4. Enregistre le resultat via s0089RecordAutoPayAttempt
    '''   5. Si SUCCESS : cree le decaissement T140Reglement via s0080
    '''   6. Envoie l'email de confirmation ou d'echec
    ''' </summary>
    Public Shared Function ProcessDuePayments(Optional batchSize As Integer = 50) As ProcessResult
        Dim result As New ProcessResult()

        Dim due As DataTable
        Try
            due = GetDuePaymentsBatch(batchSize)
        Catch ex As Exception
            result.Errors.Add("GetDuePaymentsBatch failed : " & ex.Message)
            Return result
        End Try

        If due Is Nothing OrElse due.Rows.Count = 0 Then
            Return result
        End If

        For Each row As DataRow In due.Rows
            Try
                ProcessSingleDuePayment(row, result)
            Catch ex As Exception
                ' Catch globale : si erreur catastrophique sur une ligne, continuer les autres
                result.Failed += 1
                result.Errors.Add("Document " & row("DocumentId").ToString() & " : " & ex.Message)
                System.Diagnostics.Debug.WriteLine("ProcessSingleDuePayment FAILED for DocId=" &
                                                    row("DocumentId").ToString() & " : " & ex.Message)
            End Try
        Next

        Return result
    End Function

    Private Shared Sub ProcessSingleDuePayment(row As DataRow, result As ProcessResult)
        result.Processed += 1

        Dim documentId As Integer = CInt(row("DocumentId"))
        Dim companyGuid As Guid = CType(row("CompanyGUID"), Guid)
        Dim partyId As Integer = CInt(row("PartyId"))
        Dim partyName As String = If(row("PartyName") Is DBNull.Value, "Fournisseur", row("PartyName").ToString())
        Dim authorizationId As Integer = CInt(row("AutoPayAuthorizationId"))
        Dim attempts As Integer = CInt(row("AutoPayAttempts"))
        Dim restantAPayer As Decimal = CDec(row("RestantAPayer"))
        Dim stripeAccountId As String = row("StripeAccountId").ToString()
        Dim stripeCustomerId As String = row("StripeCustomerId").ToString()
        Dim stripePaymentMethodId As String = row("StripePaymentMethodId").ToString()
        Dim paymentMethodType As String = row("PaymentMethodType").ToString()
        Dim authorizedUserGuid As Guid = CType(row("AuthorizedByUserGUID"), Guid)

        Dim maxPerCharge As Decimal? = Nothing
        Dim maxPerMonth As Decimal? = Nothing
        If Not (row("MaxAmountPerCharge") Is DBNull.Value) Then maxPerCharge = CDec(row("MaxAmountPerCharge"))
        If Not (row("MaxAmountPerMonth") Is DBNull.Value) Then maxPerMonth = CDec(row("MaxAmountPerMonth"))

        Dim attemptNumber As Integer = attempts + 1
        Dim documentNumber As String = If(row("DocumentNumber") Is DBNull.Value, documentId.ToString(),
                                            row("DocumentNumber").ToString())

        ' === 1. Verification plafond par debit ===
        If maxPerCharge.HasValue AndAlso restantAPayer > maxPerCharge.Value Then
            result.BlockedByCap += 1
            RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                          restantAPayer, restantAPayer, 0D, paymentMethodType, "BLOCKED_CAP",
                          failureCode:="cap_per_charge_exceeded",
                          failureMessage:="Montant " & restantAPayer.ToString("F2") &
                                          " > plafond/debit " & maxPerCharge.Value.ToString("F2"))
            SendFailureEmail(row, "Plafond par debit depasse", "BLOCKED_CAP", result)
            Return
        End If

        ' === 2. Verification plafond mensuel ===
        If maxPerMonth.HasValue Then
            Dim alreadyCharged As Decimal = GetMonthlyTotalForParty(companyGuid, partyId)
            If (alreadyCharged + restantAPayer) > maxPerMonth.Value Then
                result.BlockedByCap += 1
                RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                              restantAPayer, restantAPayer, 0D, paymentMethodType, "BLOCKED_CAP",
                              failureCode:="cap_per_month_exceeded",
                              failureMessage:="Cumul mensuel " & alreadyCharged.ToString("F2") &
                                              " + " & restantAPayer.ToString("F2") &
                                              " > plafond " & maxPerMonth.Value.ToString("F2"))
                SendFailureEmail(row, "Plafond mensuel depasse", "BLOCKED_CAP", result)
                Return
            End If
        End If

        ' === 3. Calcul gross-up (memes formules que wbfSupplierPaymentChoice) ===
        Dim grossAmount As Decimal = CalculateGrossAmount(restantAPayer, paymentMethodType)
        Dim feeAmount As Decimal = grossAmount - restantAPayer

        ' === 4. Creer PaymentIntent off-session ===
        Dim metadata As New Dictionary(Of String, String) From {
            {"MngConsul_DocumentId", documentId.ToString()},
            {"MngConsul_PartyId", partyId.ToString()},
            {"MngConsul_AuthorizationId", authorizationId.ToString()},
            {"MngConsul_CompanyGUID", companyGuid.ToString()},
            {"MngConsul_PaymentMethod", paymentMethodType},
            {"MngConsul_OriginalAmount", restantAPayer.ToString("F2", CultureInfo.InvariantCulture)},
            {"MngConsul_AutoPay", "true"},
            {"MngConsul_AttemptNumber", attemptNumber.ToString()}
        }

        Dim pi As PaymentIntent = Nothing
        Try
            pi = clsStripe.CreateOffSessionPaymentIntent(
                stripeAccountId:=stripeAccountId,
                customerId:=stripeCustomerId,
                paymentMethodId:=stripePaymentMethodId,
                amountInCents:=CLng(Math.Round(grossAmount * 100)),
                currency:="cad",
                description:="AutoPay Facture #" & documentNumber,
                metadata:=metadata
            )
        Catch ex As StripeException
            ' Erreur Stripe (carte refusee, etc.)
            HandleStripeFailure(ex, row, result, restantAPayer, grossAmount, feeAmount, attemptNumber)
            Return
        Catch ex As Exception
            result.Failed += 1
            RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                          restantAPayer, grossAmount, feeAmount, paymentMethodType, "FAILED",
                          failureCode:="exception",
                          failureMessage:=ex.GetType().Name & " : " & ex.Message)
            result.Errors.Add("Stripe call failed (DocId=" & documentId & ") : " & ex.Message)
            SendFailureEmail(row, ex.Message, "FAILED", result)
            Return
        End Try

        ' === 5. Analyser le resultat du PI ===
        If pi Is Nothing Then
            result.Failed += 1
            RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                          restantAPayer, grossAmount, feeAmount, paymentMethodType, "FAILED",
                          failureCode:="nil_payment_intent",
                          failureMessage:="Stripe a retourne null sans exception")
            SendFailureEmail(row, "Aucun PaymentIntent retourne", "FAILED", result)
            Return
        End If

        Select Case pi.Status
            Case "succeeded"
                result.Succeeded += 1
                Dim chargeId As String = Nothing
                Try
                    If pi.LatestChargeId IsNot Nothing Then chargeId = pi.LatestChargeId
                Catch
                End Try
                ' Enregistrer attempt + status PAYE
                RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                              restantAPayer, grossAmount, feeAmount, paymentMethodType, "SUCCESS",
                              stripePaymentIntentId:=pi.Id,
                              stripeChargeId:=chargeId)
                ' Creer le decaissement T140 + T141 (idempotent via s0080)
                CreateDecaissement(companyGuid, partyId, documentId, restantAPayer,
                                   pi.Id, paymentMethodType, authorizedUserGuid)
                SendSuccessEmail(row, pi, restantAPayer, grossAmount, feeAmount, result)

            Case "requires_action", "requires_source_action"
                result.RequiresAction += 1
                Dim url As String = Nothing
                Try
                    If pi.NextAction IsNot Nothing AndAlso pi.NextAction.RedirectToUrl IsNot Nothing Then
                        url = pi.NextAction.RedirectToUrl.Url
                    End If
                Catch
                End Try
                RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                              restantAPayer, grossAmount, feeAmount, paymentMethodType, "REQUIRES_ACTION",
                              stripePaymentIntentId:=pi.Id,
                              failureCode:="requires_action",
                              failureMessage:="3D Secure requis",
                              requires3DSUrl:=url)
                Send3DSEmail(row, url, result)

            Case Else
                ' "processing", "canceled", "requires_payment_method", etc. -> FAILED
                result.Failed += 1
                RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                              restantAPayer, grossAmount, feeAmount, paymentMethodType, "FAILED",
                              stripePaymentIntentId:=pi.Id,
                              failureCode:=pi.Status,
                              failureMessage:="Status inattendu : " & pi.Status)
                SendFailureEmail(row, "Status: " & pi.Status, "FAILED", result)
        End Select
    End Sub

    ''' <summary>
    ''' Traite une StripeException survenue durant CreateOffSessionPaymentIntent.
    ''' </summary>
    Private Shared Sub HandleStripeFailure(ex As StripeException, row As DataRow, result As ProcessResult,
                                           amount As Decimal, gross As Decimal, fee As Decimal, attemptNumber As Integer)
        Dim documentId As Integer = CInt(row("DocumentId"))
        Dim companyGuid As Guid = CType(row("CompanyGUID"), Guid)
        Dim authorizationId As Integer = CInt(row("AutoPayAuthorizationId"))
        Dim partyId As Integer = CInt(row("PartyId"))
        Dim paymentMethodType As String = row("PaymentMethodType").ToString()

        Dim failureCode As String = ""
        Dim piId As String = Nothing
        Dim requiresAction As Boolean = False
        Dim actionUrl As String = Nothing

        Try
            If ex.StripeError IsNot Nothing Then
                failureCode = If(ex.StripeError.Code, ex.StripeError.Type)
                If ex.StripeError.PaymentIntent IsNot Nothing Then
                    piId = ex.StripeError.PaymentIntent.Id
                    If ex.StripeError.PaymentIntent.Status = "requires_action" OrElse
                       ex.StripeError.PaymentIntent.Status = "requires_source_action" Then
                        requiresAction = True
                        Try
                            actionUrl = ex.StripeError.PaymentIntent.NextAction.RedirectToUrl.Url
                        Catch
                        End Try
                    End If
                End If
            End If
        Catch
        End Try

        If requiresAction Then
            result.RequiresAction += 1
            RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                          amount, gross, fee, paymentMethodType, "REQUIRES_ACTION",
                          stripePaymentIntentId:=piId,
                          failureCode:="authentication_required",
                          failureMessage:=ex.Message,
                          requires3DSUrl:=actionUrl)
            Send3DSEmail(row, actionUrl, result)
        Else
            result.Failed += 1
            RecordAttempt(companyGuid, documentId, authorizationId, partyId, attemptNumber,
                          amount, gross, fee, paymentMethodType, "FAILED",
                          stripePaymentIntentId:=piId,
                          failureCode:=failureCode,
                          failureMessage:=ex.Message)
            SendFailureEmail(row, ex.Message, "FAILED", result)
        End If
    End Sub

    ''' <summary>
    ''' Calcule le montant brut (avec frais Stripe) - meme formule que wbfSupplierPaymentChoice.
    ''' </summary>
    Public Shared Function CalculateGrossAmount(netAmount As Decimal, method As String) As Decimal
        Select Case method
            Case "acss_debit"
                Dim fee As Decimal = Math.Min(netAmount * 0.01D, 12D)
                Return netAmount + fee
            Case Else
                ' card et autres : 2.9% + 0.30 $
                Return Math.Round((netAmount + 0.3D) / 0.971D, 2)
        End Select
    End Function

    ' =========================================================================
    ' OPERATION 2 : ENVOYER PREAVIS 24H POUR CARTES
    ' =========================================================================

    Public Shared Function SendPreavis24h() As ProcessResult
        Dim result As New ProcessResult()
        Dim dt As DataTable
        Try
            dt = ExecProcDt("s0091GetUpcomingPreavis24h", New Dictionary(Of String, Object)())
        Catch ex As Exception
            result.Errors.Add("s0091 failed : " & ex.Message)
            Return result
        End Try

        If dt Is Nothing OrElse dt.Rows.Count = 0 Then Return result

        For Each row As DataRow In dt.Rows
            result.Processed += 1
            Try
                Dim companyGuid As Guid = CType(row("CompanyGUID"), Guid)
                Dim documentId As Integer = CInt(row("DocumentId"))
                Dim toEmail As String = If(row("PayerEmail") Is DBNull.Value, "", row("PayerEmail").ToString())
                If String.IsNullOrEmpty(toEmail) Then
                    result.Errors.Add("DocId=" & documentId & " : PayerEmail vide, preavis non envoye")
                    Continue For
                End If

                Dim subj As String = "Preavis : prelevement automatique demain - Facture " &
                                     If(row("DocumentNumber"), documentId.ToString()).ToString()
                Dim body As String = BuildPreavis24hEmail(row)

                InsertOutboundMail(toEmail, subj, body)
                result.EmailsSent += 1

                ' Marquer comme envoye
                ExecProc("s0091bMarkPreavisSent", New Dictionary(Of String, Object) From {
                    {"@CompanyGUID", companyGuid},
                    {"@DocumentId", documentId}
                })
            Catch ex As Exception
                result.Failed += 1
                result.Errors.Add("DocId=" & row("DocumentId").ToString() & " preavis24h : " & ex.Message)
            End Try
        Next

        Return result
    End Function

    ' =========================================================================
    ' OPERATION 3 : ENVOYER PREAVIS PAD (3 JOURS) LEGAL
    ' =========================================================================

    Public Shared Function SendPadPreavis3Days(Optional daysAhead As Integer = 3) As ProcessResult
        Dim result As New ProcessResult()
        Dim dt As DataTable
        Try
            dt = ExecProcDt("s0092GetUpcomingPadPreavis3Days", New Dictionary(Of String, Object) From {
                {"@DaysAhead", daysAhead}
            })
        Catch ex As Exception
            result.Errors.Add("s0092 failed : " & ex.Message)
            Return result
        End Try

        If dt Is Nothing OrElse dt.Rows.Count = 0 Then Return result

        For Each row As DataRow In dt.Rows
            result.Processed += 1
            Try
                Dim companyGuid As Guid = CType(row("CompanyGUID"), Guid)
                Dim documentId As Integer = CInt(row("DocumentId"))
                Dim toEmail As String = If(row("PayerEmail") Is DBNull.Value, "", row("PayerEmail").ToString())
                If String.IsNullOrEmpty(toEmail) Then
                    result.Errors.Add("DocId=" & documentId & " : PayerEmail vide, preavis PAD non envoye")
                    Continue For
                End If

                Dim subj As String = "Preavis PAD : prelevement bancaire dans 3 jours - Facture " &
                                     If(row("DocumentNumber"), documentId.ToString()).ToString()
                Dim body As String = BuildPreavisPadEmail(row)

                InsertOutboundMail(toEmail, subj, body)
                result.EmailsSent += 1

                ExecProc("s0092bMarkPadPreavisSent", New Dictionary(Of String, Object) From {
                    {"@CompanyGUID", companyGuid},
                    {"@DocumentId", documentId}
                })
            Catch ex As Exception
                result.Failed += 1
                result.Errors.Add("DocId=" & row("DocumentId").ToString() & " preavisPAD : " & ex.Message)
            End Try
        Next

        Return result
    End Function

    ' =========================================================================
    ' DB ACCESS HELPERS
    ' =========================================================================

    Private Shared Function GetDuePaymentsBatch(batchSize As Integer) As DataTable
        Return ExecProcDt("s0088GetDuePayments", New Dictionary(Of String, Object) From {
            {"@MaxAttempts", MaxRetries},
            {"@BatchSize", batchSize}
        })
    End Function

    Private Shared Function GetMonthlyTotalForParty(companyGuid As Guid, partyId As Integer) As Decimal
        Dim dt As DataTable = ExecProcDt("s0093GetMonthlyTotalForParty", New Dictionary(Of String, Object) From {
            {"@CompanyGUID", companyGuid},
            {"@PartyId", partyId},
            {"@ReferenceDate", DBNull.Value}
        })
        If dt Is Nothing OrElse dt.Rows.Count = 0 Then Return 0D
        Dim r As DataRow = dt.Rows(0)
        If r("TotalCharged") Is DBNull.Value Then Return 0D
        Return CDec(r("TotalCharged"))
    End Function

    Private Shared Sub RecordAttempt(companyGuid As Guid, documentId As Integer, authorizationId As Integer,
                                      partyId As Integer, attemptNumber As Integer,
                                      amount As Decimal, gross As Decimal, fee As Decimal,
                                      paymentMethodType As String, resultCode As String,
                                      Optional stripePaymentIntentId As String = Nothing,
                                      Optional stripeChargeId As String = Nothing,
                                      Optional failureCode As String = Nothing,
                                      Optional failureMessage As String = Nothing,
                                      Optional requires3DSUrl As String = Nothing,
                                      Optional reglementId As Integer? = Nothing)
        Try
            ExecProc("s0089RecordAutoPayAttempt", New Dictionary(Of String, Object) From {
                {"@CompanyGUID", companyGuid},
                {"@DocumentId", documentId},
                {"@AuthorizationId", authorizationId},
                {"@PartyId", partyId},
                {"@AttemptNumber", attemptNumber},
                {"@Amount", amount},
                {"@AmountGross", gross},
                {"@FeeAmount", fee},
                {"@Currency", "cad"},
                {"@PaymentMethodType", paymentMethodType},
                {"@Result", resultCode},
                {"@StripePaymentIntentId", If(String.IsNullOrEmpty(stripePaymentIntentId), CType(DBNull.Value, Object), stripePaymentIntentId)},
                {"@StripeChargeId", If(String.IsNullOrEmpty(stripeChargeId), CType(DBNull.Value, Object), stripeChargeId)},
                {"@FailureCode", If(String.IsNullOrEmpty(failureCode), CType(DBNull.Value, Object), failureCode)},
                {"@FailureMessage", If(String.IsNullOrEmpty(failureMessage), CType(DBNull.Value, Object), failureMessage)},
                {"@Requires3DSUrl", If(String.IsNullOrEmpty(requires3DSUrl), CType(DBNull.Value, Object), requires3DSUrl)},
                {"@ReglementId", If(reglementId.HasValue, CType(reglementId.Value, Object), DBNull.Value)},
                {"@MaxAttempts", MaxRetries},
                {"@RetryIntervalHours", 24}
            })
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("RecordAttempt failed : " & ex.Message)
        End Try
    End Sub

    Private Shared Sub CreateDecaissement(companyGuid As Guid, partyId As Integer, documentId As Integer,
                                           amount As Decimal, paymentIntentId As String,
                                           paymentMethodType As String, userGuid As Guid)
        ' s0080CreateDecaissementFromStripe attend un sessionId comme cle d'idempotence.
        ' Pour les debits AutoPay, il n'y a pas de checkout.session, on utilise le PI.
        ' Le webhook payment_intent.succeeded de Stripe (si configure) creerait aussi
        ' un decaissement, donc l'idempotence repose sur cette cle.
        Try
            ExecProc("s0080CreateDecaissementFromStripe", New Dictionary(Of String, Object) From {
                {"@CompanyGUID", companyGuid},
                {"@PartyId", partyId},
                {"@DocumentId", documentId},
                {"@Amount", amount},
                {"@StripeSessionId", paymentIntentId},
                {"@StripePaymentIntentId", paymentIntentId},
                {"@PaymentMethod", paymentMethodType},
                {"@CreatedByUserId", DBNull.Value}
            })
        Catch ex As Exception
            ' Non-bloquant : le paiement Stripe est reussi.
            System.Diagnostics.Debug.WriteLine("CreateDecaissement failed (NON-BLOCKING) : " & ex.Message)
        End Try
    End Sub

    Private Shared Function ExecProcDt(procName As String, params_ As Dictionary(Of String, Object)) As DataTable
        Using conn As New SqlConnection(ConnString)
            Using cmd As New SqlCommand(procName, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                Using da As New SqlDataAdapter(cmd)
                    Dim ds As New DataSet()
                    da.Fill(ds)
                    If ds.Tables.Count > 0 Then Return ds.Tables(0)
                End Using
            End Using
        End Using
        Return Nothing
    End Function

    Private Shared Sub ExecProc(procName As String, params_ As Dictionary(Of String, Object))
        Using conn As New SqlConnection(ConnString)
            Using cmd As New SqlCommand(procName, conn)
                cmd.CommandType = CommandType.StoredProcedure
                For Each kvp In params_
                    cmd.Parameters.AddWithValue(kvp.Key, If(kvp.Value, DBNull.Value))
                Next
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' =========================================================================
    ' EMAILS - Insertion dans T400Mails (BD MailService)
    ' =========================================================================

    Private Shared Sub InsertOutboundMail(toEmail As String, subject As String, htmlBody As String)
        If String.IsNullOrEmpty(toEmail) Then Return
        Using conn As New SqlConnection(ConnStringMail)
            Using cmd As New SqlCommand("s0610InsertOutboundMail", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@To", toEmail)
                cmd.Parameters.AddWithValue("@Subject", subject)
                cmd.Parameters.AddWithValue("@HTMLBody", htmlBody)
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Shared Sub SendSuccessEmail(row As DataRow, pi As PaymentIntent, amount As Decimal,
                                         gross As Decimal, fee As Decimal, result As ProcessResult)
        Try
            Dim toEmail As String = TryGetPayerEmail(row)
            If String.IsNullOrEmpty(toEmail) Then Return

            Dim partyName As String = If(row("PartyName"), "fournisseur").ToString()
            Dim documentNumber As String = If(row("DocumentNumber"), row("DocumentId").ToString()).ToString()
            Dim subj As String = "Paiement automatique reussi - " & partyName & " - " & amount.ToString("F2") & " $"

            Dim body As String = BuildSuccessHtml(partyName, documentNumber, amount, gross, fee, pi.Id)
            InsertOutboundMail(toEmail, subj, body)
            result.EmailsSent += 1
        Catch ex As Exception
            result.Errors.Add("SendSuccessEmail : " & ex.Message)
        End Try
    End Sub

    Private Shared Sub SendFailureEmail(row As DataRow, reason As String, statusCode As String, result As ProcessResult)
        Try
            Dim toEmail As String = TryGetPayerEmail(row)
            If String.IsNullOrEmpty(toEmail) Then Return

            Dim partyName As String = If(row("PartyName"), "fournisseur").ToString()
            Dim documentNumber As String = If(row("DocumentNumber"), row("DocumentId").ToString()).ToString()
            Dim subj As String = "[Echec] Paiement automatique - " & partyName & " - " & documentNumber

            Dim body As String = BuildFailureHtml(partyName, documentNumber, reason, statusCode)
            InsertOutboundMail(toEmail, subj, body)
            result.EmailsSent += 1
        Catch ex As Exception
            result.Errors.Add("SendFailureEmail : " & ex.Message)
        End Try
    End Sub

    Private Shared Sub Send3DSEmail(row As DataRow, actionUrl As String, result As ProcessResult)
        Try
            Dim toEmail As String = TryGetPayerEmail(row)
            If String.IsNullOrEmpty(toEmail) Then Return

            Dim partyName As String = If(row("PartyName"), "fournisseur").ToString()
            Dim documentNumber As String = If(row("DocumentNumber"), row("DocumentId").ToString()).ToString()
            Dim subj As String = "[Action requise] Authentification 3D Secure - " & partyName

            Dim body As String = Build3DSHtml(partyName, documentNumber, actionUrl)
            InsertOutboundMail(toEmail, subj, body)
            result.EmailsSent += 1
        Catch ex As Exception
            result.Errors.Add("Send3DSEmail : " & ex.Message)
        End Try
    End Sub

    Private Shared Function TryGetPayerEmail(row As DataRow) As String
        ' Le scheduler n'a pas necessairement PayerEmail dans s0088, donc lookup au besoin.
        Try
            If row.Table.Columns.Contains("PayerEmail") AndAlso Not (row("PayerEmail") Is DBNull.Value) Then
                Return row("PayerEmail").ToString()
            End If
            ' Fallback : lookup T015User par UserGUID
            If row.Table.Columns.Contains("AuthorizedByUserGUID") AndAlso Not (row("AuthorizedByUserGUID") Is DBNull.Value) Then
                Dim userGuid As Guid = CType(row("AuthorizedByUserGUID"), Guid)
                Using conn As New SqlConnection(ConnString)
                    Using cmd As New SqlCommand("SELECT Email FROM dbo.T015User WHERE UserGUID = @G", conn)
                        cmd.Parameters.AddWithValue("@G", userGuid)
                        conn.Open()
                        Dim res = cmd.ExecuteScalar()
                        If res IsNot Nothing AndAlso Not IsDBNull(res) Then Return res.ToString()
                    End Using
                End Using
            End If
        Catch
        End Try
        Return ""
    End Function

    ' =========================================================================
    ' TEMPLATES HTML
    ' =========================================================================

    Private Shared Function BuildPreavis24hEmail(row As DataRow) As String
        Dim partyName As String = If(row("PartyName"), "fournisseur").ToString()
        Dim documentNumber As String = If(row("DocumentNumber"), row("DocumentId").ToString()).ToString()
        Dim total As Decimal = If(row("Total") Is DBNull.Value, 0D, CDec(row("Total")))
        Dim autopayDate As Date = If(row("AutoPayDate") Is DBNull.Value, Date.Today, CDate(row("AutoPayDate")))
        Dim cardBrand As String = If(row.Table.Columns.Contains("CardBrand") AndAlso Not (row("CardBrand") Is DBNull.Value),
                                     row("CardBrand").ToString(), "Carte")
        Dim cardLast4 As String = If(row.Table.Columns.Contains("CardLast4") AndAlso Not (row("CardLast4") Is DBNull.Value),
                                     row("CardLast4").ToString(), "????")

        Return Wrapper(
            "Preavis : prelevement automatique demain",
            "<p>Bonjour,</p>" &
            "<p>Ceci est un preavis informatif : un prelevement automatique est prevu <strong>demain</strong> " &
            "sur votre " & HtmlEnc(cardBrand) & " se terminant par " & HtmlEnc(cardLast4) & ".</p>" &
            "<table style='width:100%; border-collapse:collapse; margin:16px 0;'>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Fournisseur</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(partyName) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Facture</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(documentNumber) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Montant</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & total.ToString("N2") & " $</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Date du debit</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & autopayDate.ToString("yyyy-MM-dd") & "</td></tr>" &
            "</table>" &
            "<p>Si vous souhaitez annuler ce prelevement, connectez-vous a MngConsul et utilisez la page " &
            "<strong>Paiements automatiques</strong>.</p>" &
            "<p style='color:#64748b; font-size:12px;'>Cet email est envoye automatiquement.</p>"
        )
    End Function

    Private Shared Function BuildPreavisPadEmail(row As DataRow) As String
        Dim partyName As String = If(row("PartyName"), "fournisseur").ToString()
        Dim documentNumber As String = If(row("DocumentNumber"), row("DocumentId").ToString()).ToString()
        Dim total As Decimal = If(row("Total") Is DBNull.Value, 0D, CDec(row("Total")))
        Dim autopayDate As Date = If(row("AutoPayDate") Is DBNull.Value, Date.Today, CDate(row("AutoPayDate")))
        Dim bankLast4 As String = If(row.Table.Columns.Contains("BankAccountLast4") AndAlso Not (row("BankAccountLast4") Is DBNull.Value),
                                     row("BankAccountLast4").ToString(), "????")
        Dim mandateId As String = If(row.Table.Columns.Contains("StripeMandateId") AndAlso Not (row("StripeMandateId") Is DBNull.Value),
                                     row("StripeMandateId").ToString(), "")

        Return Wrapper(
            "Preavis legal PAD - Prelevement bancaire dans 3 jours",
            "<p>Bonjour,</p>" &
            "<p>Conformement a la <strong>Regle H1 de Paiements Canada</strong>, voici votre preavis pour un " &
            "prelevement bancaire pre-autorise (PAD) prevu dans 3 jours.</p>" &
            "<table style='width:100%; border-collapse:collapse; margin:16px 0;'>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Beneficiaire</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(partyName) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Facture</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(documentNumber) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Compte debite</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>****" & HtmlEnc(bankLast4) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Montant</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & total.ToString("N2") & " $ CAD</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Date de debit</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & autopayDate.ToString("yyyy-MM-dd") & "</td></tr>" &
            If(Not String.IsNullOrEmpty(mandateId),
                "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Numero de mandat</strong></td>" &
                "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(mandateId) & "</td></tr>",
                "") &
            "</table>" &
            "<p><strong>Vos droits :</strong></p>" &
            "<ul>" &
            "<li>Droit de contestation : 10 jours apres le debit</li>" &
            "<li>Droit au remboursement : 90 jours en cas de non-conformite</li>" &
            "<li>Vous pouvez annuler ce debit en vous connectant a MngConsul (page Paiements automatiques)</li>" &
            "</ul>"
        )
    End Function

    Private Shared Function BuildSuccessHtml(partyName As String, documentNumber As String,
                                              amount As Decimal, gross As Decimal, fee As Decimal,
                                              paymentIntentId As String) As String
        Return Wrapper(
            "Paiement automatique reussi",
            "<p>Bonjour,</p>" &
            "<p>Le paiement automatique a <strong>" & HtmlEnc(partyName) & "</strong> a ete effectue avec succes.</p>" &
            "<table style='width:100%; border-collapse:collapse; margin:16px 0;'>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Facture</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(documentNumber) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Montant credit au fournisseur</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & amount.ToString("N2") & " $</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Frais de transaction</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & fee.ToString("N2") & " $</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Total debourse</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'><strong>" & gross.ToString("N2") & " $</strong></td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Reference Stripe</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0; font-family:monospace; font-size:11px;'>" & HtmlEnc(paymentIntentId) & "</td></tr>" &
            "</table>" &
            "<p>Cette facture a ete automatiquement marquee comme payee dans MngConsul.</p>"
        )
    End Function

    Private Shared Function BuildFailureHtml(partyName As String, documentNumber As String,
                                              reason As String, statusCode As String) As String
        Return Wrapper(
            "Echec du paiement automatique",
            "<p>Bonjour,</p>" &
            "<p>Un paiement automatique vers <strong>" & HtmlEnc(partyName) & "</strong> a echoue.</p>" &
            "<table style='width:100%; border-collapse:collapse; margin:16px 0;'>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Facture</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(documentNumber) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Raison</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0; color:#dc2626;'>" & HtmlEnc(reason) & "</td></tr>" &
            "<tr><td style='padding:8px; border:1px solid #e2e8f0;'><strong>Code</strong></td>" &
            "<td style='padding:8px; border:1px solid #e2e8f0;'>" & HtmlEnc(statusCode) & "</td></tr>" &
            "</table>" &
            "<p><strong>Que faire ?</strong></p>" &
            "<ul>" &
            "<li>Si le moyen de paiement est expire/refuse : reactiver une nouvelle autorisation</li>" &
            "<li>Si plafond depasse : ajuster le plafond ou payer manuellement</li>" &
            "<li>Sinon : MngConsul reessayera automatiquement dans 24h (max 3 tentatives)</li>" &
            "</ul>" &
            "<p>Connectez-vous a MngConsul pour gerer cette facture.</p>"
        )
    End Function

    Private Shared Function Build3DSHtml(partyName As String, documentNumber As String, actionUrl As String) As String
        Dim ctaButton As String = ""
        If Not String.IsNullOrEmpty(actionUrl) Then
            ctaButton = "<p style='text-align:center; margin:24px 0;'>" &
                        "<a href='" & HtmlAttr(actionUrl) & "' style='display:inline-block; padding:12px 24px; " &
                        "background:#2563eb; color:white; text-decoration:none; border-radius:8px; font-weight:700;'>" &
                        "Confirmer l'authentification 3D Secure" &
                        "</a></p>"
        End If

        Return Wrapper(
            "Action requise : authentification 3D Secure",
            "<p>Bonjour,</p>" &
            "<p>Le paiement automatique vers <strong>" & HtmlEnc(partyName) & "</strong> " &
            "(facture " & HtmlEnc(documentNumber) & ") necessite une <strong>authentification 3D Secure</strong> " &
            "supplementaire de votre part.</p>" &
            ctaButton &
            "<p style='color:#dc2626;'><strong>Important :</strong> sans cette confirmation, le paiement sera " &
            "annule par votre banque dans 24h.</p>"
        )
    End Function

    Private Shared Function Wrapper(title As String, content As String) As String
        Dim sb As New StringBuilder()
        sb.Append("<!DOCTYPE html><html><head><meta charset='utf-8'/></head><body style='font-family:Arial,sans-serif; color:#1e293b; max-width:600px; margin:0 auto; padding:24px;'>")
        sb.Append("<div style='background:#fff; border-radius:12px; padding:24px; box-shadow:0 1px 3px rgba(0,0,0,.08);'>")
        sb.Append("<h2 style='margin:0 0 16px 0; color:#2563eb;'>" & HtmlEnc(title) & "</h2>")
        sb.Append(content)
        sb.Append("<hr style='border:none; border-top:1px solid #e2e8f0; margin:24px 0 16px 0;'>")
        sb.Append("<p style='font-size:11px; color:#94a3b8; margin:0;'>MngConsul - Gestion des paiements automatiques fournisseurs</p>")
        sb.Append("</div></body></html>")
        Return sb.ToString()
    End Function

    Private Shared Function HtmlEnc(s As String) As String
        If String.IsNullOrEmpty(s) Then Return ""
        Return System.Web.HttpUtility.HtmlEncode(s)
    End Function

    Private Shared Function HtmlAttr(s As String) As String
        If String.IsNullOrEmpty(s) Then Return ""
        Return System.Web.HttpUtility.HtmlAttributeEncode(s)
    End Function

End Class
