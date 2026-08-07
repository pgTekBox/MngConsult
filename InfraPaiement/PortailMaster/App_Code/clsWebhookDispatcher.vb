Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Net
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Dispatcher de webhooks : lit les livraisons dues (T042), construit le
''' payload JSON du paiement, le signe en HMAC-SHA256 avec le secret de
''' l'endpoint, POST vers l'URL de l'abonné, puis marque le résultat
''' (succès = Delivered ; échec = relance avec backoff jusqu'à MaxAttempts).
''' Autonome (ADO.NET + HttpWebRequest), déclenchable par le handler
''' WebhookDispatcher.ashx (SQL Agent) ou par un bouton du portail.
''' </summary>
Public Class clsWebhookDispatcher

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>Traite les livraisons dues. Retourne le nombre traité.</summary>
    Public Shared Function ProcessDueDeliveries(Optional max As Integer = 20) As Integer
        Dim due As DataTable = GetDue(max)
        Dim n As Integer = 0
        For Each d As DataRow In due.Rows
            ProcessOne(d)
            n += 1
        Next
        Return n
    End Function

    Private Shared Sub ProcessOne(d As DataRow)
        Dim deliveryId As Long = CLng(d("Id"))
        Dim eventType As String = d("EventType").ToString()
        Dim url As String = d("Url").ToString()
        Dim secret As String = d("Secret").ToString()
        Dim paymentId As Object = d("PaymentId")

        Dim body As String
        Try
            body = BuildPayload(deliveryId, eventType, paymentId)
        Catch ex As Exception
            MarkResult(deliveryId, False, 0, "Payload: " & ex.Message)
            Return
        End Try

        Dim signature As String = HmacHex(secret, body)

        Try
            Dim req As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
            req.Method = "POST"
            req.ContentType = "application/json; charset=utf-8"
            req.Timeout = 10000
            req.Headers("X-Webhook-Signature") = "sha256=" & signature
            req.Headers("X-Webhook-Event") = eventType
            req.Headers("X-Webhook-Delivery-Id") = deliveryId.ToString()
            req.UserAgent = "60secPaiement-Webhooks/1.0"

            Dim bytes As Byte() = Encoding.UTF8.GetBytes(body)
            req.ContentLength = bytes.Length
            Using rs As Stream = req.GetRequestStream()
                rs.Write(bytes, 0, bytes.Length)
            End Using

            Using resp As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
                Dim code As Integer = CInt(resp.StatusCode)
                MarkResult(deliveryId, code >= 200 AndAlso code < 300, code, Nothing)
            End Using

        Catch wex As WebException
            Dim code As Integer = 0
            Dim msg As String = wex.Message
            If wex.Response IsNot Nothing AndAlso TypeOf wex.Response Is HttpWebResponse Then
                code = CInt(CType(wex.Response, HttpWebResponse).StatusCode)
            End If
            MarkResult(deliveryId, False, code, Truncate(msg, 500))
        Catch ex As Exception
            MarkResult(deliveryId, False, 0, Truncate(ex.Message, 500))
        End Try
    End Sub

    ''' <summary>Construit le corps JSON du webhook (payload du paiement).</summary>
    Private Shared Function BuildPayload(deliveryId As Long, eventType As String, paymentId As Object) As String
        Dim sb As New StringBuilder()
        sb.Append("{")
        sb.Append(JField("event", eventType)).Append(",")
        sb.Append("""delivery_id"":").Append(deliveryId).Append(",")

        If paymentId IsNot Nothing AndAlso Not IsDBNull(paymentId) Then
            Dim r As DataRow = LoadPayment(CLng(paymentId))
            If r IsNot Nothing Then
                sb.Append("""data"":{")
                sb.Append("""id"":").Append(CLng(r("Id"))).Append(",")
                sb.Append(JNumField("client_id", r, "ClientId")).Append(",")
                sb.Append(JField("client_name", Sv(r, "ClientNom"))).Append(",")
                sb.Append(JNumField("fournisseur_id", r, "FournisseurId")).Append(",")
                sb.Append(JField("fournisseur_name", Sv(r, "FournisseurNom"))).Append(",")
                sb.Append(JField("direction", Sv(r, "Direction"))).Append(",")
                sb.Append("""amount_cents"":").Append(Lng(r, "AmountCents")).Append(",")
                sb.Append("""fee_cents"":").Append(Lng(r, "FeeCents")).Append(",")
                sb.Append("""net_cents"":").Append(Lng(r, "NetCents")).Append(",")
                sb.Append(JField("currency", Sv(r, "Devise"))).Append(",")
                sb.Append(JField("status", MapStatus(Sv(r, "Status")))).Append(",")
                sb.Append(JField("reference", Sv(r, "Reference"))).Append(",")
                sb.Append(JField("description", Sv(r, "Description"))).Append(",")
                sb.Append(JField("expected_settlement_date", DateStr(r, "ExpectedSettlementDate")))
                sb.Append("}")
            Else
                sb.Append("""data"":null")
            End If
        Else
            sb.Append("""data"":null")
        End If

        sb.Append("}")
        Return sb.ToString()
    End Function

    ' ------------------------------------------------------------------
    ' Accès BD
    ' ------------------------------------------------------------------

    Private Shared Function GetDue(max As Integer) As DataTable
        Using conn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("s0032GetDueDeliveries", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@Max", max)
                Dim da As New SqlDataAdapter(cmd)
                Dim dt As New DataTable() : da.Fill(dt)
                Return dt
            End Using
        End Using
    End Function

    Private Shared Function LoadPayment(id As Long) As DataRow
        Using conn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("s0025GetPayment", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@PaymentId", id)
                Dim da As New SqlDataAdapter(cmd)
                Dim dt As New DataTable() : da.Fill(dt)
                If dt.Rows.Count = 0 Then Return Nothing
                Return dt.Rows(0)
            End Using
        End Using
    End Function

    Private Shared Sub MarkResult(id As Long, success As Boolean, responseStatus As Integer, err As String)
        Using conn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("s0033MarkDeliveryResult", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@Id", id)
                cmd.Parameters.AddWithValue("@Success", success)
                cmd.Parameters.AddWithValue("@ResponseStatus", If(responseStatus = 0, CObj(DBNull.Value), responseStatus))
                cmd.Parameters.AddWithValue("@Error", If(String.IsNullOrEmpty(err), CObj(DBNull.Value), err))
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' ------------------------------------------------------------------
    ' Utilitaires
    ' ------------------------------------------------------------------

    Public Shared Function HmacHex(secret As String, body As String) As String
        Using h As New HMACSHA256(Encoding.UTF8.GetBytes(If(secret, "")))
            Dim hash As Byte() = h.ComputeHash(Encoding.UTF8.GetBytes(If(body, "")))
            Dim sb As New StringBuilder(hash.Length * 2)
            For Each b As Byte In hash
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    Private Shared Function MapStatus(s As String) As String
        Select Case s
            Case "Initie" : Return "initiated"
            Case "Regle" : Return "settled"
            Case "Retourne" : Return "returned"
            Case Else : Return If(s, "")
        End Select
    End Function

    Private Shared Function JField(name As String, value As String) As String
        If value Is Nothing Then Return """" & name & """:null"
        Return """" & name & """:""" & JsonEsc(value) & """"
    End Function

    Private Shared Function JNumField(name As String, r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return """" & name & """:null"
        Return """" & name & """:" & Convert.ToInt64(r(col)).ToString()
    End Function

    Private Shared Function JsonEsc(s As String) As String
        Dim sb As New StringBuilder()
        For Each c As Char In s
            Select Case c
                Case """"c : sb.Append("\""")
                Case "\"c : sb.Append("\\")
                Case ControlChars.Cr : sb.Append("\r")
                Case ControlChars.Lf : sb.Append("\n")
                Case ControlChars.Tab : sb.Append("\t")
                Case Else
                    If AscW(c) < 32 Then sb.Append("\u").Append(AscW(c).ToString("x4")) Else sb.Append(c)
            End Select
        Next
        Return sb.ToString()
    End Function

    Private Shared Function Sv(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return Nothing
        Return r(col).ToString()
    End Function

    Private Shared Function Lng(r As DataRow, col As String) As Long
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt64(r(col))
    End Function

    Private Shared Function DateStr(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return Nothing
        Return CDate(r(col)).ToString("yyyy-MM-dd")
    End Function

    Private Shared Function Truncate(s As String, n As Integer) As String
        If String.IsNullOrEmpty(s) Then Return s
        If s.Length <= n Then Return s
        Return s.Substring(0, n)
    End Function

End Class
