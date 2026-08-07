Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Rapprochement bancaire : import de lignes de relevé (CSV) et génération
''' d'un relevé simulé depuis les mouvements TRUST du grand livre (aide de
''' test/démo). Le rapprochement lui-même est fait en SQL (s0061).
''' </summary>
Public Class clsBankRecon

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>
    ''' Importe un relevé CSV : colonnes date,description,montant,reference.
    ''' Montant signé (+ dépôt, - retrait). Retourne le nombre de lignes importées.
    ''' </summary>
    Public Shared Function ImportCsv(text As String, fileName As String) As Integer
        If String.IsNullOrWhiteSpace(text) Then Throw New Exception("Fichier vide.")
        Dim n As Integer = 0
        Dim rows As String() = text.Replace(vbCr, "").Split(ChrW(10))
        For Each raw As String In rows
            Dim line As String = raw.Trim()
            If line.Length = 0 Then Continue For
            Dim cols As String() = line.Split(","c)
            If cols.Length < 3 Then Continue For

            Dim dt As Date
            If Not TryParseDate(cols(0).Trim(), dt) Then Continue For   ' ignore en-tête / lignes non datées

            Dim desc As String = If(cols.Length > 1, cols(1).Trim(), "")
            Dim amount As Long = ParseAmountToCents(cols(2))
            Dim reference As String = If(cols.Length > 3, cols(3).Trim(), "")

            SaveLine(dt, desc, amount, reference, fileName)
            n += 1
        Next
        Return n
    End Function

    ''' <summary>
    ''' Génère un relevé bancaire simulé à partir des mouvements TRUST non
    ''' encore rapprochés (comme si la banque les rapportait). Aide de test.
    ''' </summary>
    Public Shared Function SimulateStatement() As Integer
        Dim mov As DataTable = GetTable("s0060ListUnmatchedTrustMovements")
        Dim n As Integer = 0
        For Each r As DataRow In mov.Rows
            Dim d As Date = CDate(r("EffectiveDate"))
            Dim net As Long = Convert.ToInt64(r("NetCents"))
            Dim label As String = "Relevé bancaire — " & r("TxnType").ToString()
            SaveLine(d, label, net, "SIM-" & r("Id").ToString(), "RELEVE_SIMULE.csv")
            n += 1
        Next
        Return n
    End Function

    ' -----------------------------------------------------------------

    Private Shared Function TryParseDate(s As String, ByRef d As Date) As Boolean
        If Date.TryParseExact(s, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, d) Then Return True
        If Date.TryParse(s, New CultureInfo("fr-CA"), DateTimeStyles.None, d) Then Return True
        Return False
    End Function

    Private Shared Function ParseAmountToCents(s As String) As Long
        Dim v As String = If(s, "").Trim().Replace(" ", "").Replace("$", "")
        Dim neg As Boolean = v.StartsWith("-") OrElse v.StartsWith("(")
        v = v.Replace("(", "").Replace(")", "").Replace("+", "")
        v = v.Replace(",", ".")
        ' garder un seul point décimal
        Dim d As Double
        If Double.TryParse(v.TrimStart("-"c), NumberStyles.Any, CultureInfo.InvariantCulture, d) Then
            Dim cents As Long = CLng(Math.Round(d * 100D, MidpointRounding.AwayFromZero))
            If neg Then Return -cents
            Return cents
        End If
        Return 0
    End Function

    Private Shared Sub SaveLine(dt As Date, desc As String, amount As Long, reference As String, fileName As String)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0058SaveBankLine", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@TxnDate", dt)
            cmd.Parameters.AddWithValue("@Description", If(String.IsNullOrEmpty(desc), CObj(DBNull.Value), desc))
            cmd.Parameters.AddWithValue("@AmountCents", amount)
            cmd.Parameters.AddWithValue("@Reference", If(String.IsNullOrEmpty(reference), CObj(DBNull.Value), reference))
            cmd.Parameters.AddWithValue("@FileName", If(String.IsNullOrEmpty(fileName), CObj(DBNull.Value), fileName))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

    Private Shared Function GetTable(proc As String) As DataTable
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand(proc, conn)
            cmd.CommandType = CommandType.StoredProcedure
            Dim da As New SqlDataAdapter(cmd) : Dim dt As New DataTable() : da.Fill(dt)
            Return dt
        End Using : End Using
    End Function

End Class
