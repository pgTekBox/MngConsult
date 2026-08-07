Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

''' <summary>
''' Rapprochement bancaire du compte fiducie (TRUST) : import/simulation du
''' relevé, rapprochement automatique, écart livre ↔ relevé et éléments non
''' rapprochés.
''' </summary>
Public Class wbfRapprochement
    Inherits clsData

    Private Shared ReadOnly Cult As CultureInfo = New CultureInfo("fr-CA")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            LoadSummary()
            BindLists()
        End If
    End Sub

    Private Sub LoadSummary()
        Try
            Dim r As DataRow = ExecuteSQLds("s0062GetReconSummary", New Collection).Tables(0).Rows(0)
            litLedger.Text = MoneySigned(r("LedgerTrustCents"))
            litStmt.Text = MoneySigned(r("StatementTotalCents"))
            Dim diff As Long = L(r, "DiffCents")
            litDiff.Text = MoneySigned(diff)
            tileDiff.Attributes("class") = If(diff = 0, "tile diff ok", "tile diff bad")
            litUnmLines.Text = L(r, "UnmatchedLines").ToString()
            litUnmMov.Text = L(r, "UnmatchedMovements").ToString()
        Catch ex As Exception
            ShowError("Impossible de charger le résumé. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Rec LoadSummary: " & ex.Message)
        End Try
    End Sub

    Private Sub BindLists()
        Try
            Dim pl As New Collection : pl.Add(New SqlParameter("@Top", 100))
            Dim lines As DataTable = ExecuteSQLds("s0059ListBankLines", pl).Tables(0)
            rptLines.DataSource = lines : rptLines.DataBind()
            rptLines.Visible = (lines.Rows.Count > 0) : pnlNoLines.Visible = (lines.Rows.Count = 0)

            Dim pm As New Collection : pm.Add(New SqlParameter("@Top", 100))
            Dim mov As DataTable = ExecuteSQLds("s0060ListUnmatchedTrustMovements", pm).Tables(0)
            rptMov.DataSource = mov : rptMov.DataBind()
            rptMov.Visible = (mov.Rows.Count > 0) : pnlNoMov.Visible = (mov.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Rec BindLists: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnImport_Click(sender As Object, e As EventArgs)
        If Not fuCsv.HasFile Then
            ShowError("Sélectionnez un fichier CSV.") : Return
        End If
        Try
            Dim text As String = Encoding.UTF8.GetString(fuCsv.FileBytes)
            Dim n As Integer = clsBankRecon.ImportCsv(text, fuCsv.FileName)
            ShowOk(n & " ligne(s) de relevé importée(s).")
            LoadSummary() : BindLists()
        Catch ex As Exception
            ShowError("Import impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Rec Import: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSimulate_Click(sender As Object, e As EventArgs)
        Try
            Dim n As Integer = clsBankRecon.SimulateStatement()
            ShowOk(n & " ligne(s) de relevé simulée(s) générée(s).")
            LoadSummary() : BindLists()
        Catch ex As Exception
            ShowError("Simulation impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Rec Simulate: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnReconcile_Click(sender As Object, e As EventArgs)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@WindowDays", 3))
            Dim dt As DataTable = ExecuteSQLds("s0061RunReconciliation", p).Tables(0)
            Dim n As Integer = If(dt.Rows.Count > 0, CInt(dt.Rows(0)("NbMatched")), 0)
            ShowOk(n & " ligne(s) rapprochée(s).")
            LoadSummary() : BindLists()
        Catch ex As Exception
            ShowError("Rapprochement impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Rec Reconcile: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers ---
    Protected Function MoneySigned(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        Dim txt As String = (Math.Abs(c) / 100D).ToString("N2", Cult) & " $"
        If c < 0 Then Return "<span class=""neg"">-" & txt & "</span>"
        If c > 0 Then Return "<span class=""pos"">+" & txt & "</span>"
        Return txt
    End Function
    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function
    Private Function L(r As DataRow, col As String) As Long
        If IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt64(r(col))
    End Function
    Private Sub ShowOk(msg As String)
        pnlOk.Visible = True : litOk.Text = Server.HtmlEncode(msg)
    End Sub
    Private Sub ShowError(msg As String)
        pnlError.Visible = True : litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
