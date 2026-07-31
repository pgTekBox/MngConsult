Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Linq
Imports System.Text

''' <summary>
''' Diagnostic des connexions bancaires Plaid (console d'administration).
'''
''' URL : wbfPlaidDiagnostic.aspx
'''
''' Affiche :
'''   - Stats agregees (comptes actifs, items, compagnies, institutions, erreurs)
'''   - Liste des comptes connectes (T143PlaidAccount) avec details deroulants
'''   - Journal de synchronisation / erreurs (T144PlaidSyncLog)
'''
''' Procedures : s0702GetPlaidAccounts / s0703GetPlaidStats / s0704GetPlaidSyncLog.
''' Aucune donnee sensible : AccessToken non retourne ; numeros de compte masques.
''' Acces : reserve aux administrateurs (garde globale de clsData.OnLoad).
''' </summary>
Public Class wbfPlaidDiagnostic
    Inherits clsData

    Private ReadOnly _culture As New CultureInfo("fr-CA")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            LoadAll()
        End If
    End Sub

    Protected Sub btnApply_Click(sender As Object, e As EventArgs) Handles btnApply.Click
        LoadAll()
    End Sub

    Protected Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadAll()
    End Sub

    Private Sub LoadAll()
        Dim sinceHours As Integer = 168
        Integer.TryParse(ddlSince.SelectedValue, sinceHours)

        LoadStats(sinceHours)
        LoadAccounts(ddlStatus.SelectedValue, txtSearch.Text.Trim())
        LoadSyncLog(sinceHours)
    End Sub

    Private Sub LoadStats(sinceHours As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@SinceHours", sinceHours))

            Dim ds As DataSet = ExecuteSQLds("s0703GetPlaidStats", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ResetStats()
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim total As Integer = NzInt(r("TotalAccounts"))
            Dim active As Integer = NzInt(r("ActiveAccounts"))
            Dim inactive As Integer = NzInt(r("InactiveAccounts"))

            litActiveAccounts.Text = active.ToString("N0", _culture)
            litTotalAccounts.Text = total.ToString("N0", _culture) & " au total"
            If inactive > 0 Then litTotalAccounts.Text &= " · " & inactive.ToString("N0", _culture) & " inactif(s)"
            litItems.Text = NzInt(r("DistinctItems")).ToString("N0", _culture)
            litCompanies.Text = NzInt(r("DistinctCompanies")).ToString("N0", _culture)
            litBanks.Text = NzInt(r("DistinctBanks")).ToString("N0", _culture)
            litErrors.Text = NzInt(r("ErrorCount")).ToString("N0", _culture)

            If Not IsDBNull(r("LastBalanceUpdate")) AndAlso r("LastBalanceUpdate") IsNot Nothing Then
                litLastBalance.Text = AgeText(CDate(r("LastBalanceUpdate")))
            Else
                litLastBalance.Text = "—"
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Plaid LoadStats error: " & ex.Message)
            ResetStats()
        End Try
    End Sub

    Private Sub ResetStats()
        litActiveAccounts.Text = "0"
        litTotalAccounts.Text = ""
        litItems.Text = "0"
        litCompanies.Text = "0"
        litBanks.Text = "0"
        litErrors.Text = "0"
        litLastBalance.Text = "—"
    End Sub

    Private Sub LoadAccounts(status As String, search As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Status", If(String.IsNullOrEmpty(status), "all", status)))
            p.Add(New SqlParameter("@Search", If(String.IsNullOrEmpty(search), CType(DBNull.Value, Object), search)))
            p.Add(New SqlParameter("@MaxRows", 500))

            Dim ds As DataSet = ExecuteSQLds("s0702GetPlaidAccounts", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                litAccounts.Text = ""
                pnlAccountsEmpty.Visible = True
                Return
            End If

            pnlAccountsEmpty.Visible = False
            Dim sb As New StringBuilder()

            For Each row As DataRow In ds.Tables(0).Rows
                Dim rowId As Integer = CInt(row("Id"))
                Dim active As Boolean = Not IsDBNull(row("Active")) AndAlso CBool(row("Active"))
                Dim bank As String = S(row("BankName"))
                Dim acctName As String = S(row("AccountName"))
                Dim mask As String = S(row("Mask"))
                Dim acctType As String = S(row("AccountType"))
                Dim acctSub As String = S(row("AccountSubtype"))
                Dim companyName As String = S(row("CompanyName"))
                Dim companyCode As String = S(row("CompanyCode"))
                Dim itemId As String = S(row("ItemId"))
                Dim acctId As String = S(row("AccountId"))
                Dim currency As String = S(row("CurrencyCode"))
                Dim payload As String = S(row("accountJson"))

                Dim statusClass As String = If(active, "active", "inactive")

                sb.Append("<div class=""event-card " & statusClass & """ id=""acct-" & rowId & """>")

                ' Header
                sb.Append("<div class=""event-header"">")
                sb.Append("<div>")
                Dim title As String = bank
                If Not String.IsNullOrEmpty(acctName) Then title &= " — " & acctName
                If Not String.IsNullOrEmpty(mask) Then title &= " ••" & mask
                sb.Append("<div class=""event-type"">" & Server.HtmlEncode(title) & "</div>")
                Dim sub2 As String = String.Join(" · ", New String() {acctType, acctSub, If(String.IsNullOrEmpty(companyName), companyCode, companyName)}.
                    Where(Function(x) Not String.IsNullOrEmpty(x)).ToArray())
                sb.Append("<div class=""event-id"">" & Server.HtmlEncode(sub2) & "</div>")
                sb.Append("</div>")

                sb.Append("<div class=""event-meta"">")
                If Not IsDBNull(row("BalanceUpdated")) AndAlso row("BalanceUpdated") IsNot Nothing Then
                    sb.Append("🔄 " & CDate(row("BalanceUpdated")).ToString("dd MMM HH:mm", _culture))
                End If
                sb.Append("</div>")

                sb.Append("<span class=""event-amount"">" & Server.HtmlEncode(Money(row("BalanceCurrent"), currency)) & "</span>")

                sb.Append("<button type=""button"" class=""btn-toggle"" onclick=""toggleDetails(" & rowId & "); return false;"">Détails ▼</button>")
                sb.Append("</div>")

                ' Details
                sb.Append("<div class=""event-details"">")
                DetailRow(sb, "Statut", If(active, "Actif", "Inactif"))
                If Not String.IsNullOrEmpty(companyName) Then DetailRow(sb, "Compagnie", companyName & If(String.IsNullOrEmpty(companyCode), "", " (" & companyCode & ")"))
                DetailRow(sb, "Institution", bank)
                DetailRow(sb, "Compte", acctName & If(String.IsNullOrEmpty(mask), "", " ••" & mask))
                DetailRow(sb, "Type", (acctType & " / " & acctSub).Trim(" "c, "/"c))
                DetailRow(sb, "Solde courant", Money(row("BalanceCurrent"), currency))
                DetailRow(sb, "Solde disponible", Money(row("BalanceAvailable"), currency))
                If Not IsDBNull(row("BalanceLimit")) AndAlso row("BalanceLimit") IsNot Nothing Then _
                    DetailRow(sb, "Limite", Money(row("BalanceLimit"), currency))
                DetailRow(sb, "Institution / Transit", (S(row("InstitutionNumber")) & " / " & S(row("BranchNumber"))).Trim(" "c, "/"c))
                DetailRow(sb, "N° de compte", MaskAccount(S(row("AccountNumber"))))
                DetailRow(sb, "Item ID", itemId)
                DetailRow(sb, "Account ID", acctId)
                If Not IsDBNull(row("Created")) AndAlso row("Created") IsNot Nothing Then _
                    DetailRow(sb, "Connecté le", CDate(row("Created")).ToString("dd MMMM yyyy HH:mm", _culture))

                If Not String.IsNullOrEmpty(payload) Then
                    sb.Append("<div class=""detail-row""><span class=""lbl"">Détails Plaid (JSON)</span></div>")
                    sb.Append("<div class=""payload-box"">" & Server.HtmlEncode(payload) & "</div>")
                End If

                sb.Append("</div>")  ' .event-details
                sb.Append("</div>")  ' .event-card
            Next

            litAccounts.Text = sb.ToString()

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Plaid LoadAccounts error: " & ex.Message)
            litAccounts.Text = "<div class=""empty-state"">Erreur de chargement : " & Server.HtmlEncode(ex.Message) & "</div>"
            pnlAccountsEmpty.Visible = False
        End Try
    End Sub

    Private Sub LoadSyncLog(sinceHours As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@SinceHours", sinceHours))
            p.Add(New SqlParameter("@MaxRows", 200))

            Dim ds As DataSet = ExecuteSQLds("s0704GetPlaidSyncLog", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                litSyncLog.Text = ""
                pnlLogEmpty.Visible = True
                Return
            End If

            pnlLogEmpty.Visible = False
            Dim sb As New StringBuilder()

            For Each row As DataRow In ds.Tables(0).Rows
                Dim companyName As String = S(row("CompanyName"))
                Dim itemId As String = S(row("ItemId"))
                Dim msg As String = S(row("ErrorMessage"))
                Dim created As String = If(IsDBNull(row("Created")), "", CDate(row("Created")).ToString("dd MMM yyyy HH:mm:ss", _culture))

                sb.Append("<div class=""log-item"">")
                sb.Append("<div class=""log-head"">")
                sb.Append("<span>🏦 " & Server.HtmlEncode(If(String.IsNullOrEmpty(companyName), "(compagnie inconnue)", companyName)) &
                          If(String.IsNullOrEmpty(itemId), "", " · <span style=""font-family:monospace"">" & Server.HtmlEncode(itemId) & "</span>") & "</span>")
                sb.Append("<span>" & created & "</span>")
                sb.Append("</div>")
                sb.Append("<div class=""log-msg"">" & Server.HtmlEncode(msg) & "</div>")
                sb.Append("</div>")
            Next

            litSyncLog.Text = sb.ToString()

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Plaid LoadSyncLog error: " & ex.Message)
            litSyncLog.Text = "<div class=""empty-state"">Erreur de chargement du journal : " & Server.HtmlEncode(ex.Message) & "</div>"
            pnlLogEmpty.Visible = False
        End Try
    End Sub

    ' ── Helpers ──

    Private Sub DetailRow(sb As StringBuilder, label As String, value As String)
        If String.IsNullOrEmpty(value) Then Return
        sb.Append("<div class=""detail-row""><span class=""lbl"">" & Server.HtmlEncode(label) &
                  "</span><span class=""val"">" & Server.HtmlEncode(value) & "</span></div>")
    End Sub

    Private Function Money(val As Object, currency As String) As String
        If val Is Nothing OrElse IsDBNull(val) Then Return ""
        Dim d As Decimal
        If Not Decimal.TryParse(val.ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, d) Then Return ""
        Return d.ToString("N2", _culture) & If(String.IsNullOrEmpty(currency), "", " " & currency)
    End Function

    Private Shared Function MaskAccount(acct As String) As String
        If String.IsNullOrEmpty(acct) Then Return ""
        If acct.Length <= 4 Then Return "••••"
        Return "••••" & acct.Substring(acct.Length - 4)
    End Function

    Private Function AgeText(dt As DateTime) As String
        Dim ageMinutes As Double = (Date.Now - dt).TotalMinutes
        If ageMinutes < 1 Then Return "à l'instant"
        If ageMinutes < 60 Then Return "il y a " & CInt(ageMinutes) & " min"
        If ageMinutes < 1440 Then Return "il y a " & CInt(ageMinutes / 60) & " h"
        Return dt.ToString("dd MMM HH:mm", _culture)
    End Function

    Private Shared Function S(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Private Shared Function NzInt(o As Object) As Integer
        If o Is Nothing OrElse IsDBNull(o) Then Return 0
        Return CInt(o)
    End Function

End Class
