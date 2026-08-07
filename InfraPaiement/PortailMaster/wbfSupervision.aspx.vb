Imports System.Data
Imports System.Globalization

''' <summary>
''' Tableau de bord de supervision (staff) : indicateurs opérationnels +
''' listes à surveiller (paiements en souffrance, webhooks en échec, retours).
''' </summary>
Public Class wbfSupervision
    Inherits clsData

    Private Shared ReadOnly Cult As CultureInfo = New CultureInfo("fr-CA")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            LoadKpis()
            BindLists()
        End If
    End Sub

    Private Sub LoadKpis()
        Try
            Dim r As DataRow = ExecuteSQLds("s0053GetSupervisionKpis", New Collection).Tables(0).Rows(0)
            Dim trust As Long = L(r, "TrustCents"), owed As Long = L(r, "OwedCents"), fees As Long = L(r, "FeesCents")
            litTrust.Text = Money(trust)
            litOwed.Text = Money(owed)
            litFees.Text = Money(fees)
            ' Invariant : Trust = Owed + Fees (+ clearing net, ici agrégé via Owed/Fees)
            litInvariant.Text = If(trust = owed + fees + ClearingNet(),
                                   "<span style=""color:var(--ok);font-weight:800"">✓ Équilibré</span>",
                                   "<span style=""color:var(--danger);font-weight:800"">⚠ À vérifier</span>")

            litVolIn.Text = Money(L(r, "VolEntrantCents"))
            litVolOut.Text = Money(L(r, "VolSortantCents"))
            litRegle.Text = L(r, "NbRegle").ToString()
            litInitie.Text = L(r, "NbInitie").ToString()

            Dim nbPay As Long = L(r, "NbPayments"), nbRet As Long = L(r, "NbRetourne")
            Dim rate As Double = If(nbPay > 0, nbRet / nbPay * 100.0, 0)
            litReturns.Text = nbRet.ToString() & " (" & rate.ToString("0.#", Cult) & " %)"

            Dim nbOverdue As Long = L(r, "NbOverdue")
            litOverdue.Text = nbOverdue.ToString() & " · " & Money(L(r, "OverdueCents"))
            If nbOverdue > 0 Then tileOverdue.Attributes("class") = "tile warn"

            Dim nbWh As Long = L(r, "NbWhPending") + L(r, "NbWhAbandoned")
            litWhIssues.Text = nbWh.ToString()
            If nbWh > 0 Then tileWh.Attributes("class") = "tile warn"

            Dim nbKyb As Long = L(r, "NbKyb")
            litKyb.Text = nbKyb.ToString()
            If nbKyb > 0 Then tileKyb.Attributes("class") = "tile warn"

            litBatches.Text = L(r, "NbBatchesOuverts").ToString()
        Catch ex As Exception
            ShowError("Impossible de charger les indicateurs. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Sup LoadKpis: " & ex.Message)
        End Try
    End Sub

    ''' <summary>Solde net des comptes de clearing EFT (pour l'invariant).</summary>
    Private Function ClearingNet() As Long
        Try
            Dim r As DataRow = ExecuteSQLds("s0018GetPlatformSummary", New Collection).Tables(0).Rows(0)
            Return L(r, "EftOutCents") - L(r, "EftInCents")
        Catch
            Return 0
        End Try
    End Function

    Private Sub BindLists()
        Try
            Dim po As New Collection : po.Add(New Data.SqlClient.SqlParameter("@Top", 20))
            Dim over As DataTable = ExecuteSQLds("s0054ListOverduePayments", po).Tables(0)
            rptOverdue.DataSource = over : rptOverdue.DataBind()
            rptOverdue.Visible = (over.Rows.Count > 0) : pnlNoOverdue.Visible = (over.Rows.Count = 0)

            Dim pw As New Collection : pw.Add(New Data.SqlClient.SqlParameter("@Top", 20))
            Dim wh As DataTable = ExecuteSQLds("s0055ListWebhookIssues", pw).Tables(0)
            rptWh.DataSource = wh : rptWh.DataBind()
            rptWh.Visible = (wh.Rows.Count > 0) : pnlNoWh.Visible = (wh.Rows.Count = 0)

            Dim pr As New Collection : pr.Add(New Data.SqlClient.SqlParameter("@Top", 20))
            Dim ret As DataTable = ExecuteSQLds("s0051ListEftReturns", pr).Tables(0)
            rptReturns.DataSource = ret : rptReturns.DataBind()
            rptReturns.Visible = (ret.Rows.Count > 0) : pnlNoReturns.Visible = (ret.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Sup BindLists: " & ex.Message)
        End Try
    End Sub

    Protected Function Money(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        Return (c / 100D).ToString("N2", Cult) & " $"
    End Function
    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function
    Protected Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function
    Private Function L(r As DataRow, col As String) As Long
        If IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt64(r(col))
    End Function
    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
