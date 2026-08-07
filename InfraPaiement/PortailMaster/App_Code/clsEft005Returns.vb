Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Traitement des fichiers CPA-005 de RETOUR (NSF, compte invalide, etc.).
'''   - ImportReturnFile : parse un fichier de retour, rapproche chaque
'''     retour de la transaction d'origine (PaymentId dans la reference
'''     croisee 'P'+id), et contre-passe via s0049ProcessReturn.
'''   - SimulateReturnFile : genere un fichier de retour depuis un lot
'''     (aide de test/demo, en remplacement du fichier reel de la banque).
'''
''' ⚠️ Le format de retour reel varie selon l'institution : les offsets ci-
''' dessous sont un GABARIT (identiques au segment sortant de clsCpa005Builder),
''' a mapper sur le guide de la banque avant usage reel.
''' </summary>
Public Class clsEft005Returns

    Private Const HeaderLen As Integer = 24     ' type(1)+count(9)+client(10)+fcn(4)
    Private Const SegLen As Integer = 240
    Private Const RecLen As Integer = 1464
    ' Offsets dans un segment de 240 :
    Private Const OffAmount As Integer = 3      ' 10
    Private Const OffCrossRef As Integer = 146  ' 19
    Private Const OffReason As Integer = 165    ' 3

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Public Class ImportSummary
        Public Processed As Integer
        Public Unmatched As Integer
        Public Errors As Integer
        Public Total As Integer
        Public Lines As New List(Of String)
    End Class

    ''' <summary>Importe et traite un fichier de retour.</summary>
    Public Shared Function ImportReturnFile(text As String, fileName As String) As ImportSummary
        Dim sum As New ImportSummary()
        If String.IsNullOrWhiteSpace(text) Then Throw New Exception("Fichier vide.")

        Dim rows As String() = text.Replace(vbCr, "").Split(ChrW(10))
        For Each rawLine As String In rows
            Dim line As String = rawLine
            If line.Length < HeaderLen Then Continue For
            Dim recType As Char = line(0)
            If recType <> "E"c AndAlso recType <> "F"c Then Continue For   ' E=retour credit, F=retour debit

            Dim pos As Integer = HeaderLen
            While pos + SegLen <= line.Length
                Dim seg As String = line.Substring(pos, SegLen)
                pos += SegLen
                ProcessSegment(recType, seg, fileName, sum)
            End While
        Next
        Return sum
    End Function

    Private Shared Sub ProcessSegment(recType As Char, seg As String, fileName As String, sum As ImportSummary)
        Dim amount As Long = ParseLong(Mid2(seg, OffAmount, 10))
        Dim crossRef As String = Mid2(seg, OffCrossRef, 19).Trim()
        Dim reason As String = Mid2(seg, OffReason, 3).Trim()

        If amount = 0 AndAlso crossRef.Length = 0 Then Return   ' segment de remplissage

        sum.Total += 1
        Dim reasonLabel As String = ReasonText(reason)
        Dim paymentId As Long = ExtractPaymentId(crossRef)

        If paymentId <= 0 Then
            SaveReturn(Nothing, recType, amount, reason, crossRef, fileName, "Unmatched", "Reference croisee illisible : " & crossRef, Nothing)
            sum.Unmatched += 1 : sum.Lines.Add("Non rapproche (" & crossRef & ")")
            Return
        End If

        Dim r As DataRow = GetPayment(paymentId)
        If r Is Nothing Then
            SaveReturn(paymentId, recType, amount, reason, crossRef, fileName, "Unmatched", "Paiement introuvable", Nothing)
            sum.Unmatched += 1 : sum.Lines.Add("#" & paymentId & " introuvable")
            Return
        End If

        Dim expected As Long = Convert.ToInt64(r("AmountCents"))
        Dim status As String = r("Status").ToString()
        If amount <> expected Then
            SaveReturn(paymentId, recType, amount, reason, crossRef, fileName, "AmountMismatch", "Montant " & amount & " <> " & expected, Nothing)
            sum.Errors += 1 : sum.Lines.Add("#" & paymentId & " montant incoherent")
            Return
        End If
        If status = "Retourne" Then
            SaveReturn(paymentId, recType, amount, reason, crossRef, fileName, "AlreadyReturned", "Deja retourne", Nothing)
            sum.Errors += 1 : sum.Lines.Add("#" & paymentId & " deja retourne")
            Return
        End If

        Try
            Dim txnId As Long = ProcessReturn(paymentId, reasonLabel)
            SaveReturn(paymentId, recType, amount, reason, crossRef, fileName, "Processed", reasonLabel, txnId)
            sum.Processed += 1 : sum.Lines.Add("#" & paymentId & " contre-passe (" & reasonLabel & ")")
        Catch ex As SqlException
            SaveReturn(paymentId, recType, amount, reason, crossRef, fileName, "Error", ex.Message, Nothing)
            sum.Errors += 1 : sum.Lines.Add("#" & paymentId & " erreur : " & ex.Message)
        End Try
    End Sub

    ' -----------------------------------------------------------------
    ' Simulation d'un fichier de retour (aide de test/demo)
    ' -----------------------------------------------------------------

    ''' <summary>Genere un fichier de retour pour tous les items d'un lot.</summary>
    Public Shared Function SimulateReturnFile(batchId As Integer, reasonCode As String) As String
        Dim ds As DataSet = GetBatch(batchId)
        If ds.Tables(0).Rows.Count = 0 Then Throw New Exception("Lot introuvable.")
        Dim items As DataTable = ds.Tables(1)

        Dim sb As New StringBuilder()
        Dim rc As Integer = 1
        sb.AppendLine(PadTo("A" & Num(rc.ToString(), 9), RecLen))   ' entete minimal

        Dim debits As New List(Of DataRow) : Dim credits As New List(Of DataRow)
        For Each r As DataRow In items.Rows
            If r("RecordType").ToString() = "D" Then debits.Add(r) Else credits.Add(r)
        Next

        ' F = retour de debit, E = retour de credit
        For Each grp In Chunk(debits)
            rc += 1 : sb.AppendLine(BuildReturnRecord("F"c, rc, grp, reasonCode))
        Next
        For Each grp In Chunk(credits)
            rc += 1 : sb.AppendLine(BuildReturnRecord("E"c, rc, grp, reasonCode))
        Next

        rc += 1 : sb.AppendLine(PadTo("Z" & Num(rc.ToString(), 9), RecLen))
        Return sb.ToString()
    End Function

    Private Shared Function BuildReturnRecord(recType As Char, rc As Integer, items As List(Of DataRow), reasonCode As String) As String
        Dim r As New StringBuilder()
        r.Append(recType) : r.Append(Num(rc.ToString(), 9)) : r.Append(New String(" "c, HeaderLen - 10))
        For Each item In items
            Dim seg As Char() = New String(" "c, SegLen).ToCharArray()
            Put(seg, OffAmount, Num(item("AmountCents").ToString(), 10))
            Put(seg, OffCrossRef, ("P" & Num(item("PaymentId").ToString(), 10)).PadRight(19))
            Put(seg, OffReason, Num(reasonCode, 3))
            r.Append(New String(seg))
        Next
        Return PadTo(r.ToString(), RecLen)
    End Function

    ' -----------------------------------------------------------------
    ' Helpers
    ' -----------------------------------------------------------------

    Private Shared Function ReasonText(code As String) As String
        Select Case code
            Case "901" : Return "NSF - provision insuffisante"
            Case "902" : Return "Compte gele"
            Case "905" : Return "Compte introuvable / invalide"
            Case "907" : Return "Paiement arrete"
            Case "912" : Return "Compte ferme"
            Case Else : Return If(String.IsNullOrEmpty(code), "Retour", "Retour " & code)
        End Select
    End Function

    Private Shared Function ExtractPaymentId(crossRef As String) As Long
        If String.IsNullOrEmpty(crossRef) Then Return 0
        Dim s As String = crossRef.Trim()
        If s.StartsWith("P") Then s = s.Substring(1)
        Return ParseLong(s)
    End Function

    Private Shared Function ParseLong(s As String) As Long
        Dim digits As New StringBuilder()
        For Each c As Char In If(s, "") : If Char.IsDigit(c) Then digits.Append(c)
        Next
        Dim v As Long
        If Long.TryParse(digits.ToString(), v) Then Return v
        Return 0
    End Function

    Private Shared Function Mid2(s As String, start As Integer, len As Integer) As String
        If start >= s.Length Then Return ""
        Dim n As Integer = Math.Min(len, s.Length - start)
        Return s.Substring(start, n)
    End Function

    Private Shared Function Num(v As String, len As Integer) As String
        Dim d As New StringBuilder()
        For Each c As Char In If(v, "") : If Char.IsDigit(c) Then d.Append(c)
        Next
        Dim x As String = d.ToString()
        If x.Length > len Then x = x.Substring(x.Length - len)
        Return x.PadLeft(len, "0"c)
    End Function

    Private Shared Sub Put(buf As Char(), offset As Integer, value As String)
        For i As Integer = 0 To value.Length - 1
            If offset + i < buf.Length Then buf(offset + i) = value(i)
        Next
    End Sub

    Private Shared Function PadTo(s As String, len As Integer) As String
        If s.Length > len Then Return s.Substring(0, len)
        Return s.PadRight(len)
    End Function

    Private Shared Function Chunk(rows As List(Of DataRow)) As List(Of List(Of DataRow))
        Dim res As New List(Of List(Of DataRow)) : Dim i As Integer = 0
        While i < rows.Count
            Dim g As New List(Of DataRow) : Dim j As Integer = 0
            While j < 6 AndAlso i < rows.Count : g.Add(rows(i)) : i += 1 : j += 1
            End While
            res.Add(g)
        End While
        Return res
    End Function

    ' -------- Acces BD --------

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
            cmd.Parameters.AddWithValue("@Reason", reason)
            Dim dt As New DataTable() : Dim da As New SqlDataAdapter(cmd) : da.Fill(dt)
            If dt.Rows.Count > 0 AndAlso Not IsDBNull(dt.Rows(0)("ReturnTxnId")) Then Return Convert.ToInt64(dt.Rows(0)("ReturnTxnId"))
            Return 0
        End Using : End Using
    End Function

    Private Shared Sub SaveReturn(paymentId As Object, recType As Char, amount As Long, reason As String, crossRef As String, fileName As String, status As String, message As String, txnId As Object)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0050SaveEftReturn", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@PaymentId", If(paymentId Is Nothing, CObj(DBNull.Value), paymentId))
            cmd.Parameters.AddWithValue("@RecordType", recType.ToString())
            cmd.Parameters.AddWithValue("@AmountCents", amount)
            cmd.Parameters.AddWithValue("@ReasonCode", If(String.IsNullOrEmpty(reason), CObj(DBNull.Value), reason))
            cmd.Parameters.AddWithValue("@CrossRef", If(String.IsNullOrEmpty(crossRef), CObj(DBNull.Value), crossRef))
            cmd.Parameters.AddWithValue("@FileName", If(String.IsNullOrEmpty(fileName), CObj(DBNull.Value), fileName))
            cmd.Parameters.AddWithValue("@Status", status)
            cmd.Parameters.AddWithValue("@Message", If(String.IsNullOrEmpty(message), CObj(DBNull.Value), message))
            cmd.Parameters.AddWithValue("@ReturnTxnId", If(txnId Is Nothing, CObj(DBNull.Value), txnId))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

    Private Shared Function GetBatch(batchId As Integer) As DataSet
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0046GetEftBatch", conn)
            cmd.CommandType = CommandType.StoredProcedure : cmd.Parameters.AddWithValue("@BatchId", batchId)
            Dim ds As New DataSet() : Dim da As New SqlDataAdapter(cmd) : da.Fill(ds)
            Return ds
        End Using : End Using
    End Function

End Class
