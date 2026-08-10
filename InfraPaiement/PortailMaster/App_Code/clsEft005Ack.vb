Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Traitement des ACCUSÉS DE RÉCEPTION bancaires d'un lot EFT soumis.
''' La banque confirme l'acceptation du fichier (ou le refuse) et liste les
''' items rejetés à l'intake (coordonnées invalides). Ces items sont contre-
''' passés immédiatement (via s0049ProcessReturn), distincts des retours NSF
''' (E/F) qui arrivent plus tard.
'''
''' Format d'accusé (GABARIT pipe-délimité, à mapper sur la banque réelle) :
'''   A|&lt;FileCreationNumber&gt;|ACCEPTED|&lt;message&gt;      (en-tête, 1 par fichier)
'''   R|P&lt;PaymentId&gt;|&lt;reasonCode&gt;|&lt;message&gt;         (0..n items rejetés, si ACCEPTED)
'''   A|&lt;FileCreationNumber&gt;|REJECTED|&lt;message&gt;      (fichier entier refusé)
''' </summary>
Public Class clsEft005Ack

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Public Class AckSummary
        Public BatchId As Integer
        Public FileCreationNumber As Integer
        Public FileStatus As String = "Unmatched"   ' Accepted / Rejected / Unmatched
        Public Reversed As Integer                  ' items contre-passés
        Public Errors As Integer
        Public Lines As New List(Of String)
    End Class

    ''' <summary>Importe et traite un fichier d'accusé de réception.</summary>
    Public Shared Function ProcessAckFile(text As String, fileName As String) As AckSummary
        Dim sum As New AckSummary()
        If String.IsNullOrWhiteSpace(text) Then Throw New Exception("Fichier vide.")

        Dim rows As String() = text.Replace(vbCr, "").Split(ChrW(10))
        Dim fcn As Integer = 0
        Dim fileStatus As String = ""
        Dim headerMsg As String = ""
        Dim rejects As New List(Of String())   ' {crossRef, reason, msg}

        For Each raw As String In rows
            Dim line As String = raw.Trim()
            If line.Length = 0 Then Continue For
            Dim f As String() = line.Split("|"c)
            Select Case f(0).Trim().ToUpperInvariant()
                Case "A"
                    If f.Length >= 3 Then
                        Integer.TryParse(New String(f(1).Trim().Where(AddressOf Char.IsDigit).ToArray()), fcn)
                        fileStatus = f(2).Trim().ToUpperInvariant()
                        headerMsg = If(f.Length >= 4, f(3).Trim(), "")
                    End If
                Case "R"
                    If f.Length >= 2 Then
                        rejects.Add(New String() {f(1).Trim(),
                                                  If(f.Length >= 3, f(2).Trim(), ""),
                                                  If(f.Length >= 4, f(3).Trim(), "")})
                    End If
            End Select
        Next

        If fcn = 0 OrElse fileStatus.Length = 0 Then
            Throw New Exception("Accusé illisible : en-tête A|<n° fichier>|<statut> manquant.")
        End If
        sum.FileCreationNumber = fcn

        ' Retrouver le lot par n° de création de fichier.
        Dim batch As DataRow = GetBatchByFcn(fcn)
        If batch Is Nothing Then
            sum.FileStatus = "Unmatched"
            SaveAck(Nothing, fcn, "Unmatched", 0, "Lot introuvable (fcn " & fcn & ")", fileName)
            sum.Lines.Add("Lot introuvable pour le n° de fichier " & fcn)
            Return sum
        End If
        Dim batchId As Integer = CInt(batch("Id"))
        sum.BatchId = batchId

        If fileStatus = "REJECTED" Then
            ' Fichier entièrement refusé : contre-passer tous les items encore Initie.
            sum.FileStatus = "Rejected"
            For Each pid As Long In GetBatchInitiePayments(batchId)
                ReverseItem(pid, "Rejet du fichier par la banque : " & headerMsg, sum)
            Next
            SaveAck(batchId, fcn, "Rejected", sum.Reversed, headerMsg, fileName)
            sum.Lines.Insert(0, "Fichier REFUSÉ : " & sum.Reversed & " item(s) contre-passé(s).")
        Else
            ' Fichier accepté : contre-passer uniquement les items rejetés à l'intake.
            sum.FileStatus = "Accepted"
            For Each rej In rejects
                Dim pid As Long = ExtractPaymentId(rej(0))
                Dim reason As String = "Rejet à l'intake (" & rej(1) & ") : " & rej(2)
                If pid > 0 Then ReverseItem(pid, reason, sum) Else sum.Errors += 1
            Next
            SaveAck(batchId, fcn, "Accepted", sum.Reversed, headerMsg, fileName)
            sum.Lines.Insert(0, "Fichier ACCEPTÉ : " & sum.Reversed & " item(s) rejeté(s) à l'intake, le reste suit son règlement.")
        End If

        Return sum
    End Function

    ''' <summary>Contre-passe un item (s'il est encore Initie), journalise.</summary>
    Private Shared Sub ReverseItem(paymentId As Long, reason As String, sum As AckSummary)
        Dim p As DataRow = GetPayment(paymentId)
        If p Is Nothing Then
            sum.Errors += 1 : sum.Lines.Add("#" & paymentId & " introuvable") : Return
        End If
        Dim st As String = p("Status").ToString()
        Dim recType As String = If(p("Direction").ToString() = "Sortant", "F", "E")
        Dim amount As Long = Convert.ToInt64(p("AmountCents"))
        If st = "Retourne" Then
            SaveReturn(paymentId, recType, amount, "ACK", reason, "AlreadyReturned", "Deja retourne", Nothing)
            sum.Errors += 1 : sum.Lines.Add("#" & paymentId & " deja retourne") : Return
        End If
        Try
            Dim txnId As Long = ProcessReturn(paymentId, reason)
            SaveReturn(paymentId, recType, amount, "ACK", reason, "Processed", reason, txnId)
            sum.Reversed += 1 : sum.Lines.Add("#" & paymentId & " contre-passe (" & reason & ")")
        Catch ex As SqlException
            SaveReturn(paymentId, recType, amount, "ACK", reason, "Error", ex.Message, Nothing)
            sum.Errors += 1 : sum.Lines.Add("#" & paymentId & " erreur : " & ex.Message)
        End Try
    End Sub

    ' -----------------------------------------------------------------
    ' Simulation d'un accusé (aide de test/démo, en remplacement du fichier banque)
    ' -----------------------------------------------------------------

    ''' <summary>Génère un accusé pour un lot. accept=False -> fichier refusé ;
    ''' sinon accepté avec les @rejectFirstN premiers items rejetés à l'intake.</summary>
    Public Shared Function SimulateAckFile(batchId As Integer, accept As Boolean, rejectFirstN As Integer) As String
        Dim ds As DataSet = GetBatch(batchId)
        If ds.Tables(0).Rows.Count = 0 Then Throw New Exception("Lot introuvable.")
        Dim fcn As Integer = CInt(ds.Tables(0).Rows(0)("FileCreationNumber"))
        Dim items As DataTable = ds.Tables(1)

        Dim sb As New StringBuilder()
        If Not accept Then
            sb.AppendLine("A|" & fcn & "|REJECTED|Fichier refuse (simulation)")
            Return sb.ToString()
        End If

        sb.AppendLine("A|" & fcn & "|ACCEPTED|Fichier accepte (simulation)")
        Dim n As Integer = 0
        For Each r As DataRow In items.Rows
            If n >= rejectFirstN Then Exit For
            Dim pid As String = r("PaymentId").ToString()
            sb.AppendLine("R|P" & pid & "|905|Compte invalide (simulation)")
            n += 1
        Next
        Return sb.ToString()
    End Function

    ' -------- Helpers --------

    Private Shared Function ExtractPaymentId(crossRef As String) As Long
        If String.IsNullOrEmpty(crossRef) Then Return 0
        Dim s As String = crossRef.Trim()
        If s.StartsWith("P", StringComparison.OrdinalIgnoreCase) Then s = s.Substring(1)
        Dim digits As New StringBuilder()
        For Each c As Char In s : If Char.IsDigit(c) Then digits.Append(c)
        Next
        Dim v As Long
        If Long.TryParse(digits.ToString(), v) Then Return v
        Return 0
    End Function

    ' -------- Acces BD --------

    Private Shared Function GetBatchByFcn(fcn As Integer) As DataRow
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0094GetBatchByFcn", conn)
            cmd.CommandType = CommandType.StoredProcedure : cmd.Parameters.AddWithValue("@Fcn", fcn)
            Dim dt As New DataTable() : Dim da As New SqlDataAdapter(cmd) : da.Fill(dt)
            If dt.Rows.Count = 0 Then Return Nothing
            Return dt.Rows(0)
        End Using : End Using
    End Function

    Private Shared Function GetBatch(batchId As Integer) As DataSet
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0046GetEftBatch", conn)
            cmd.CommandType = CommandType.StoredProcedure : cmd.Parameters.AddWithValue("@BatchId", batchId)
            Dim ds As New DataSet() : Dim da As New SqlDataAdapter(cmd) : da.Fill(ds)
            Return ds
        End Using : End Using
    End Function

    ''' <summary>Ids des paiements encore Initie d'un lot (à contre-passer sur refus).</summary>
    Private Shared Function GetBatchInitiePayments(batchId As Integer) As List(Of Long)
        Dim res As New List(Of Long)
        Dim ds As DataSet = GetBatch(batchId)
        If ds.Tables.Count < 2 Then Return res
        For Each r As DataRow In ds.Tables(1).Rows
            res.Add(Convert.ToInt64(r("PaymentId")))
        Next
        Return res
    End Function

    Private Shared Function GetPayment(id As Long) As DataRow
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0052GetPaymentForReturn", conn)
            cmd.CommandType = CommandType.StoredProcedure : cmd.Parameters.AddWithValue("@PaymentId", id)
            Dim dt As New DataTable() : Dim da As New SqlDataAdapter(cmd) : da.Fill(dt)
            If dt.Rows.Count = 0 Then Return Nothing
            Return dt.Rows(0)
        End Using : End Using
    End Function

    Private Shared Function ProcessReturn(paymentId As Long, reason As String) As Long
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0049ProcessReturn", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@PaymentId", paymentId)
            cmd.Parameters.AddWithValue("@Reason", If(reason.Length > 100, reason.Substring(0, 100), reason))
            Dim dt As New DataTable() : Dim da As New SqlDataAdapter(cmd) : da.Fill(dt)
            If dt.Rows.Count > 0 AndAlso Not IsDBNull(dt.Rows(0)("ReturnTxnId")) Then Return Convert.ToInt64(dt.Rows(0)("ReturnTxnId"))
            Return 0
        End Using : End Using
    End Function

    Private Shared Sub SaveReturn(paymentId As Object, recType As String, amount As Long, reasonCode As String, message As String, status As String, msg2 As String, txnId As Object)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0050SaveEftReturn", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@PaymentId", If(paymentId Is Nothing, CObj(DBNull.Value), paymentId))
            cmd.Parameters.AddWithValue("@RecordType", recType)
            cmd.Parameters.AddWithValue("@AmountCents", amount)
            cmd.Parameters.AddWithValue("@ReasonCode", reasonCode)
            cmd.Parameters.AddWithValue("@CrossRef", DBNull.Value)
            cmd.Parameters.AddWithValue("@FileName", "ACCUSE")
            cmd.Parameters.AddWithValue("@Status", status)
            cmd.Parameters.AddWithValue("@Message", If(String.IsNullOrEmpty(msg2), CObj(DBNull.Value), If(msg2.Length > 300, msg2.Substring(0, 300), msg2)))
            cmd.Parameters.AddWithValue("@ReturnTxnId", If(txnId Is Nothing, CObj(DBNull.Value), txnId))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

    Private Shared Sub SaveAck(batchId As Object, fcn As Integer, fileStatus As String, rejectedCount As Integer, message As String, fileName As String)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0095AckEftBatch", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@BatchId", If(batchId Is Nothing, CObj(DBNull.Value), batchId))
            cmd.Parameters.AddWithValue("@FileCreationNumber", fcn)
            cmd.Parameters.AddWithValue("@FileStatus", fileStatus)
            cmd.Parameters.AddWithValue("@RejectedCount", rejectedCount)
            cmd.Parameters.AddWithValue("@Message", If(String.IsNullOrEmpty(message), CObj(DBNull.Value), If(message.Length > 300, message.Substring(0, 300), message)))
            cmd.Parameters.AddWithValue("@FileName", If(String.IsNullOrEmpty(fileName), CObj(DBNull.Value), fileName))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

End Class
