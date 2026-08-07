Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Générateur de fichier AFT CPA Norme 005 à partir d'un lot EFT (T050/T051)
''' et de la configuration émetteur (T052). Produit des enregistrements de
''' largeur fixe 1464 : A (entête), C/D (détails, jusqu'à 6 segments), Z (contrôle).
'''
''' ⚠️ Les positions/champs exacts varient selon l'institution financière :
''' ce format est un GABARIT à valider avec le guide d'implantation de la
''' banque parrain avant toute soumission réelle.
''' </summary>
Public Class clsCpa005Builder

    Public Const RecordLength As Integer = 1464
    Public Const SegmentLength As Integer = 240
    Public Const SegmentsPerRecord As Integer = 6

    Public Class Cpa005Result
        Public FileName As String
        Public Content As String
        Public RecordCount As Integer
    End Class

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>Construit le contenu du fichier 005 pour un lot.</summary>
    Public Shared Function BuildFile(batchId As Integer) As Cpa005Result
        Dim orig As DataRow = GetSingle("s0042GetOriginator", Nothing)
        If orig Is Nothing Then Throw New Exception("Configuration émetteur absente (T052EftOriginator).")

        Dim ds As DataSet = GetBatch(batchId)
        If ds.Tables(0).Rows.Count = 0 Then Throw New Exception("Lot introuvable.")
        Dim batch As DataRow = ds.Tables(0).Rows(0)
        Dim items As DataTable = ds.Tables(1)

        Dim clientNo As String = SV(orig, "ClientNumber")
        Dim shortName As String = SV(orig, "ShortName")
        Dim longName As String = SV(orig, "LongName")
        Dim dataCentre As String = SV(orig, "DataCentre")
        Dim cpaDebit As String = SV(orig, "CpaCodeDebit")
        Dim cpaCredit As String = SV(orig, "CpaCodeCredit")
        Dim retBranch As String = "0" & Num(SV(orig, "ReturnInstitution"), 3) & Num(SV(orig, "ReturnTransit"), 5)
        Dim retAccount As String = SV(orig, "ReturnAccount")
        Dim fcn As Long = LNG(batch, "FileCreationNumber")

        Dim sb As New StringBuilder()
        Dim rc As Integer = 0

        ' --- Enregistrement A (entête) ---
        rc += 1
        Dim a As New StringBuilder()
        a.Append("A")
        a.Append(Num(rc.ToString(), 9))
        a.Append(Alpha(clientNo, 10))
        a.Append(Num(fcn.ToString(), 4))
        a.Append(Julian(DateTime.UtcNow))
        a.Append(Num(dataCentre, 5))
        sb.AppendLine(Pad(a.ToString()))

        ' --- Détails : D (débits) puis C (crédits) ---
        Dim debits As List(Of DataRow) = Filter(items, "D")
        Dim credits As List(Of DataRow) = Filter(items, "C")

        For Each rec In Chunk(debits)
            rc += 1
            sb.AppendLine(BuildDetail("D", rc, clientNo, fcn, rec, cpaDebit, shortName, longName, retBranch, retAccount))
        Next
        For Each rec In Chunk(credits)
            rc += 1
            sb.AppendLine(BuildDetail("C", rc, clientNo, fcn, rec, cpaCredit, shortName, longName, retBranch, retAccount))
        Next

        ' --- Enregistrement Z (contrôle) ---
        rc += 1
        Dim z As New StringBuilder()
        z.Append("Z")
        z.Append(Num(rc.ToString(), 9))
        z.Append(Alpha(clientNo, 10))
        z.Append(Num(fcn.ToString(), 4))
        z.Append(Num(LNG(batch, "TotalDebitCents").ToString(), 14))
        z.Append(Num(INT2(batch, "CountDebit").ToString(), 8))
        z.Append(Num(LNG(batch, "TotalCreditCents").ToString(), 14))
        z.Append(Num(INT2(batch, "CountCredit").ToString(), 8))
        sb.AppendLine(Pad(z.ToString()))

        Dim res As New Cpa005Result()
        res.RecordCount = rc
        res.FileName = "AFT_" & Alpha(clientNo, 10).Trim() & "_" & fcn.ToString("D4") & "_" & DateTime.UtcNow.ToString("yyyyMMdd") & ".005"
        res.Content = sb.ToString()
        Return res
    End Function

    Private Shared Function BuildDetail(recType As String, rc As Integer, clientNo As String, fcn As Long,
                                        segRows As List(Of DataRow), cpaCode As String, shortName As String,
                                        longName As String, retBranch As String, retAccount As String) As String
        Dim r As New StringBuilder()
        r.Append(recType)
        r.Append(Num(rc.ToString(), 9))
        r.Append(Alpha(clientNo, 10))
        r.Append(Num(fcn.ToString(), 4))
        For Each item In segRows
            r.Append(BuildSegment(item, cpaCode, shortName, longName, clientNo, retBranch, retAccount))
        Next
        Return Pad(r.ToString())
    End Function

    Private Shared Function BuildSegment(item As DataRow, cpaCode As String, shortName As String, longName As String,
                                         clientNo As String, retBranch As String, retAccount As String) As String
        Dim s As New StringBuilder()
        s.Append(Num(cpaCode, 3))                                             ' code CPA
        s.Append(Num(LNG(item, "AmountCents").ToString(), 10))               ' montant (cents)
        s.Append(Julian2(item, "DueDate"))                                    ' date d'echeance
        s.Append("0" & Num(SV(item, "BankInstitution"), 3) & Num(SV(item, "BankTransit"), 5)) ' succursale (9)
        s.Append(Alpha(SV(item, "BankAccount"), 12))                          ' n. de compte
        s.Append(Alpha(shortName, 15))                                        ' nom court emetteur
        s.Append(Alpha(SV(item, "CounterpartyName"), 30))                     ' nom de la contrepartie
        s.Append(Alpha(longName, 30))                                         ' nom long emetteur
        s.Append(Alpha(clientNo, 10))                                         ' n. client emetteur
        s.Append(retBranch)                                                   ' succursale de retour (9)
        s.Append(Alpha(retAccount, 12))                                       ' compte de retour
        s.Append(Alpha(SV(item, "CrossReference"), 19))                       ' reference croisee
        Return PadTo(s.ToString(), SegmentLength)
    End Function

    ' ---------------- Helpers de mise en forme ----------------

    Private Shared Function Alpha(v As String, len As Integer) As String
        Dim x As String = If(v, "").ToUpperInvariant()
        If x.Length > len Then x = x.Substring(0, len)
        Return x.PadRight(len)
    End Function

    Private Shared Function Num(v As String, len As Integer) As String
        Dim digits As New StringBuilder()
        For Each c As Char In If(v, "")
            If Char.IsDigit(c) Then digits.Append(c)
        Next
        Dim x As String = digits.ToString()
        If x.Length > len Then x = x.Substring(x.Length - len)   ' garder les chiffres de poids faible
        Return x.PadLeft(len, "0"c)
    End Function

    Private Shared Function Julian(d As DateTime) As String
        Return "0" & (d.Year Mod 100).ToString("D2") & d.DayOfYear.ToString("D3")
    End Function

    Private Shared Function Julian2(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return Julian(DateTime.UtcNow)
        Return Julian(CDate(r(col)))
    End Function

    Private Shared Function Pad(s As String) As String
        Return PadTo(s, RecordLength)
    End Function

    Private Shared Function PadTo(s As String, len As Integer) As String
        If s.Length > len Then Return s.Substring(0, len)
        Return s.PadRight(len)
    End Function

    Private Shared Function Filter(dt As DataTable, recType As String) As List(Of DataRow)
        Dim l As New List(Of DataRow)
        For Each r As DataRow In dt.Rows
            If r("RecordType").ToString() = recType Then l.Add(r)
        Next
        Return l
    End Function

    Private Shared Function Chunk(rows As List(Of DataRow)) As List(Of List(Of DataRow))
        Dim result As New List(Of List(Of DataRow))
        Dim i As Integer = 0
        While i < rows.Count
            Dim grp As New List(Of DataRow)
            Dim j As Integer = 0
            While j < SegmentsPerRecord AndAlso i < rows.Count
                grp.Add(rows(i)) : i += 1 : j += 1
            End While
            result.Add(grp)
        End While
        Return result
    End Function

    ' ---------------- Accès BD ----------------

    Private Shared Function GetSingle(proc As String, params As Collection) As DataRow
        Using conn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand(proc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                If params IsNot Nothing Then For Each p As SqlParameter In params : cmd.Parameters.Add(p) : Next
                Dim da As New SqlDataAdapter(cmd) : Dim dt As New DataTable() : da.Fill(dt)
                If dt.Rows.Count = 0 Then Return Nothing
                Return dt.Rows(0)
            End Using
        End Using
    End Function

    Private Shared Function GetBatch(batchId As Integer) As DataSet
        Using conn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("s0046GetEftBatch", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@BatchId", batchId)
                Dim da As New SqlDataAdapter(cmd) : Dim ds As New DataSet() : da.Fill(ds)
                Return ds
            End Using
        End Using
    End Function

    Private Shared Function SV(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function
    Private Shared Function LNG(r As DataRow, col As String) As Long
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt64(r(col))
    End Function
    Private Shared Function INT2(r As DataRow, col As String) As Integer
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
    End Function

End Class
