Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Stripe
Imports Stripe.Checkout

''' <summary>
''' Page de retour apres paiement fournisseur via Stripe (Direct Charge).
'''
''' URL : wbfSupplierPaymentSuccess.aspx?session_id=cs_xxx&DocumentId=N
'''
''' La session_id appartient au compte CONNECTED (le fournisseur), pas a MngConsul.
''' On utilise l'API Stripe avec Stripe-Account header pour la recuperer.
''' </summary>
Public Class wbfSupplierPaymentSuccess
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            DisplayConfirmation()
        End If
    End Sub

    Private Sub DisplayConfirmation()

        Dim sessionId As String = If(Request.QueryString("session_id"), "").Trim()
        Dim documentIdStr As String = If(Request.QueryString("DocumentId"), "0").Trim()
        Dim documentId As Integer = 0
        Integer.TryParse(documentIdStr, documentId)

        litDocumentId.Text = If(documentId > 0, documentId.ToString(), "—")

        Dim culture As New CultureInfo("fr-CA")
        litDate.Text = Date.Now.ToString("dd MMMM yyyy HH:mm", culture)

        ' Si pas de session_id, affichage minimum
        If String.IsNullOrEmpty(sessionId) OrElse Not sessionId.StartsWith("cs_") Then
            ShowGenericSuccess()
            Return
        End If

        ' Pour recuperer une session sur un compte Connect, on doit connaitre
        ' l'acct_xxx. On le retrouve via DocumentId -> PartyId -> StripeAccountId.
        Dim stripeAccountId As String = GetStripeAccountIdForDocument(documentId)

        If String.IsNullOrEmpty(stripeAccountId) Then
            ShowGenericSuccess()
            Return
        End If

        ' Recuperer la session depuis le compte connecte
        Dim session As Session
        Try
            session = clsStripe.GetCheckoutSessionFromConnectedAccount(sessionId, stripeAccountId)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Session retrieve error: " & ex.Message)
            ShowGenericSuccess()
            pnlWarning.Visible = True
            Return
        End Try

        If session Is Nothing Then
            ShowGenericSuccess()
            pnlWarning.Visible = True
            Return
        End If

        ' Afficher les details
        Dim supplierName As String = GetSupplierNameForDocument(documentId)
        litSupplierName.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(supplierName), "le fournisseur", supplierName))

        ' Methode utilisee
        Dim methodLabel As String = "Carte de crédit"
        If session.PaymentMethodTypes IsNot Nothing AndAlso session.PaymentMethodTypes.Count > 0 Then
            Select Case session.PaymentMethodTypes(0)
                Case "interac_present", "interac" : methodLabel = "Interac en ligne"
                Case "acss_debit"                  : methodLabel = "ACSS Debit (PAD)"
                Case "card"                        : methodLabel = "Carte de crédit"
                Case Else                          : methodLabel = session.PaymentMethodTypes(0)
            End Select
        End If
        litMethod.Text = methodLabel

        ' Montants
        Dim amountTotal As Decimal = If(session.AmountTotal.HasValue, CDec(session.AmountTotal.Value) / 100D, 0D)

        ' Recuperer le montant facture original depuis metadata
        Dim originalAmount As Decimal = 0D
        If session.Metadata IsNot Nothing Then
            Dim origStr As String = Nothing
            If session.Metadata.TryGetValue("MngConsul_OriginalAmount", origStr) AndAlso Not String.IsNullOrEmpty(origStr) Then
                Decimal.TryParse(origStr, NumberStyles.Any, CultureInfo.InvariantCulture, originalAmount)
            End If
        End If

        Dim fees As Decimal = Math.Max(0D, amountTotal - originalAmount)

        litAmount.Text = amountTotal.ToString("N2", culture) & " $ CAD"
        litFees.Text = "+ " & fees.ToString("N2", culture) & " $ (incluses)"
        litTransactionId.Text = If(Not String.IsNullOrEmpty(session.PaymentIntentId), session.PaymentIntentId, sessionId)

        ' Status warning si pas paid
        If session.PaymentStatus <> "paid" AndAlso session.PaymentStatus <> "no_payment_required" Then
            pnlWarning.Visible = True
        End If
    End Sub

    Private Sub ShowGenericSuccess()
        litSupplierName.Text = "le fournisseur"
        litMethod.Text = "—"
        litTransactionId.Text = "—"
        litFees.Text = "—"
        litAmount.Text = "—"
    End Sub

    Private Function GetStripeAccountIdForDocument(documentId As Integer) As String
        Try
            Dim sql As String = "SELECT TOP 1 T050.StripeAccountId " &
                                "FROM dbo.T060Document T060 " &
                                "JOIN dbo.T050Party T050 ON T050.PartyGUID = T060.PartyGUID " &
                                "WHERE T060.Id = @DocumentId"
            Using conn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@DocumentId", documentId)
                    conn.Open()
                    Dim result = cmd.ExecuteScalar()
                    If result IsNot Nothing AndAlso Not IsDBNull(result) Then
                        Return result.ToString()
                    End If
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GetStripeAccountIdForDocument: " & ex.Message)
        End Try
        Return ""
    End Function

    Private Function GetSupplierNameForDocument(documentId As Integer) As String
        Try
            Dim sql As String = "SELECT TOP 1 T050.Name " &
                                "FROM dbo.T060Document T060 " &
                                "JOIN dbo.T050Party T050 ON T050.PartyGUID = T060.PartyGUID " &
                                "WHERE T060.Id = @DocumentId"
            Using conn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@DocumentId", documentId)
                    conn.Open()
                    Dim result = cmd.ExecuteScalar()
                    If result IsNot Nothing AndAlso Not IsDBNull(result) Then
                        Return result.ToString()
                    End If
                End Using
            End Using
        Catch
        End Try
        Return ""
    End Function

End Class
