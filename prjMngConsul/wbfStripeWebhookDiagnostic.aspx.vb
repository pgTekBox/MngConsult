Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

''' <summary>
''' Page de diagnostic des webhooks Stripe.
'''
''' URL : wbfStripeWebhookDiagnostic.aspx
'''
''' Affiche :
'''   - Stats agregees (total, processed, failed, etc.)
'''   - Liste des events recents avec filtres (status, type, periode)
'''   - Details deroulants par event (payload JSON, ErrorMessage)
'''
''' Acces : utilisateurs admin uniquement (a securiser selon ton modele).
''' </summary>
Public Class wbfStripeWebhookDiagnostic
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Restriction admin (decommenter si necessaire) :
        ' If Not isAdmin Then
        '     Response.Redirect("~/Default.aspx")
        '     Return
        ' End If

        If Not IsPostBack Then
            LoadStatsAndEvents()
        End If
    End Sub

    Protected Sub btnApply_Click(sender As Object, e As EventArgs) Handles btnApply.Click
        LoadStatsAndEvents()
    End Sub

    Protected Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadStatsAndEvents()
    End Sub

    Private Sub LoadStatsAndEvents()
        Dim sinceHours As Integer = 168
        Integer.TryParse(ddlSince.SelectedValue, sinceHours)

        LoadStats(sinceHours)
        LoadEvents(ddlStatus.SelectedValue, ddlEventType.SelectedValue, sinceHours)
    End Sub

    Private Sub LoadStats(sinceHours As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@SinceHours", sinceHours))

            Dim ds As DataSet = ExecuteSQLds("s0084GetStripeEventStats", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ResetStats()
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim total As Integer = If(r("TotalEvents") Is DBNull.Value, 0, CInt(r("TotalEvents")))
            Dim processed As Integer = If(r("ProcessedCount") Is DBNull.Value, 0, CInt(r("ProcessedCount")))
            Dim failed As Integer = If(r("FailedCount") Is DBNull.Value, 0, CInt(r("FailedCount")))
            Dim pending As Integer = If(r("PendingCount") Is DBNull.Value, 0, CInt(r("PendingCount")))
            Dim skipped As Integer = If(r("SkippedCount") Is DBNull.Value, 0, CInt(r("SkippedCount")))

            litTotalEvents.Text = total.ToString("N0", New CultureInfo("fr-CA"))
            litProcessedEvents.Text = processed.ToString("N0", New CultureInfo("fr-CA"))
            litFailedEvents.Text = failed.ToString("N0", New CultureInfo("fr-CA"))
            litPendingEvents.Text = pending.ToString("N0", New CultureInfo("fr-CA"))
            litSkippedEvents.Text = skipped.ToString("N0", New CultureInfo("fr-CA"))

            If total > 0 Then
                litProcessedPct.Text = (processed * 100 \ total).ToString() & " %"
                litFailedPct.Text = (failed * 100 \ total).ToString() & " %"
            Else
                litProcessedPct.Text = "—"
                litFailedPct.Text = "—"
            End If

            If Not r("LastEventOn") Is DBNull.Value Then
                Dim lastEvent As DateTime = CDate(r("LastEventOn"))
                Dim ageMinutes As Double = (Date.Now - lastEvent).TotalMinutes
                Dim ageText As String

                If ageMinutes < 1 Then
                    ageText = "à l'instant"
                ElseIf ageMinutes < 60 Then
                    ageText = "il y a " & CInt(ageMinutes) & " min"
                ElseIf ageMinutes < 1440 Then
                    ageText = "il y a " & CInt(ageMinutes / 60) & " h"
                Else
                    ageText = lastEvent.ToString("dd MMM HH:mm", New CultureInfo("fr-CA"))
                End If

                litLastEvent.Text = ageText
            Else
                litLastEvent.Text = "Aucun"
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LoadStats error: " & ex.Message)
            ResetStats()
        End Try
    End Sub

    Private Sub ResetStats()
        litTotalEvents.Text = "0"
        litProcessedEvents.Text = "0"
        litFailedEvents.Text = "0"
        litPendingEvents.Text = "0"
        litSkippedEvents.Text = "0"
        litProcessedPct.Text = "—"
        litFailedPct.Text = "—"
        litLastEvent.Text = "—"
    End Sub

    Private Sub LoadEvents(status As String, eventType As String, sinceHours As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Status", status))
            p.Add(New SqlParameter("@EventType", eventType))
            p.Add(New SqlParameter("@SinceHours", sinceHours))
            p.Add(New SqlParameter("@MaxRows", 200))

            Dim ds As DataSet = ExecuteSQLds("s0083GetStripeEvents", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                litEvents.Text = ""
                pnlEmpty.Visible = True
                Return
            End If

            pnlEmpty.Visible = False
            Dim sb As New StringBuilder()
            Dim culture As New CultureInfo("fr-CA")

            For Each row As DataRow In ds.Tables(0).Rows
                Dim rowId As Integer = CInt(row("Id"))
                Dim eventId As String = If(row("StripeEventId") Is DBNull.Value, "", row("StripeEventId").ToString())
                Dim evType As String = If(row("EventType") Is DBNull.Value, "", row("EventType").ToString())
                Dim procStatus As String = If(row("ProcessingStatus") Is DBNull.Value, "received", row("ProcessingStatus").ToString())
                Dim receivedOn As Date = If(row("ReceivedOn") Is DBNull.Value, Date.MinValue, CDate(row("ReceivedOn")))
                Dim processedOn As Object = row("ProcessedOn")
                Dim errorMsg As String = If(row("ErrorMessage") Is DBNull.Value, "", row("ErrorMessage").ToString())
                Dim payload As String = If(row("Payload") Is DBNull.Value, "", row("Payload").ToString())
                Dim duration As Integer = If(row("ProcessingDurationSec") Is DBNull.Value, 0, CInt(row("ProcessingDurationSec")))
                Dim custId As String = If(row("StripeCustomerId") Is DBNull.Value, "", row("StripeCustomerId").ToString())
                Dim subId As String = If(row("StripeSubscriptionId") Is DBNull.Value, "", row("StripeSubscriptionId").ToString())

                Dim cardClass As String = "event-card " & procStatus

                sb.Append("<div class=""" & cardClass & """ id=""event-" & rowId & """>")

                ' Header
                sb.Append("<div class=""event-header"">")
                sb.Append("<div>")
                sb.Append("<div class=""event-type"">" & Server.HtmlEncode(evType) & "</div>")
                sb.Append("<div class=""event-id"">" & Server.HtmlEncode(eventId) & "</div>")
                sb.Append("</div>")

                sb.Append("<div class=""event-meta"">")
                If receivedOn <> Date.MinValue Then
                    sb.Append("📥 " & receivedOn.ToString("dd MMM HH:mm:ss", culture))
                End If
                If duration > 0 Then
                    sb.Append(" · ⏱ " & duration & "s")
                End If
                sb.Append("</div>")

                sb.Append("<span class=""event-status " & procStatus & """>")
                Select Case procStatus
                    Case "processed" : sb.Append("✓ Traité")
                    Case "failed"    : sb.Append("✗ Échec")
                    Case "received"  : sb.Append("⏳ En cours")
                    Case "skipped"   : sb.Append("⊝ Ignoré")
                    Case Else        : sb.Append(Server.HtmlEncode(procStatus))
                End Select
                sb.Append("</span>")

                sb.Append("<button type=""button"" class=""btn-toggle"" onclick=""toggleDetails(" & rowId & "); return false;"">Détails ▼</button>")
                sb.Append("</div>")

                ' Details
                sb.Append("<div class=""event-details"">")

                sb.Append("<div class=""detail-row""><span class=""lbl"">Event ID</span><span class=""val"">" & Server.HtmlEncode(eventId) & "</span></div>")
                sb.Append("<div class=""detail-row""><span class=""lbl"">Type</span><span class=""val"">" & Server.HtmlEncode(evType) & "</span></div>")
                sb.Append("<div class=""detail-row""><span class=""lbl"">Status</span><span class=""val"">" & procStatus & "</span></div>")
                If receivedOn <> Date.MinValue Then
                    sb.Append("<div class=""detail-row""><span class=""lbl"">Reçu le</span><span class=""val"">" & receivedOn.ToString("dd MMMM yyyy HH:mm:ss", culture) & "</span></div>")
                End If
                If Not IsDBNull(processedOn) AndAlso processedOn IsNot Nothing Then
                    sb.Append("<div class=""detail-row""><span class=""lbl"">Traité le</span><span class=""val"">" & CDate(processedOn).ToString("dd MMMM yyyy HH:mm:ss", culture) & "</span></div>")
                End If
                If Not String.IsNullOrEmpty(custId) Then
                    sb.Append("<div class=""detail-row""><span class=""lbl"">Stripe Customer</span><span class=""val"">" & Server.HtmlEncode(custId) & "</span></div>")
                End If
                If Not String.IsNullOrEmpty(subId) Then
                    sb.Append("<div class=""detail-row""><span class=""lbl"">Subscription</span><span class=""val"">" & Server.HtmlEncode(subId) & "</span></div>")
                End If

                ' Erreur si presente
                If Not String.IsNullOrEmpty(errorMsg) Then
                    sb.Append("<div class=""error-box"">" & Server.HtmlEncode(errorMsg) & "</div>")
                End If

                ' Payload JSON
                If Not String.IsNullOrEmpty(payload) Then
                    sb.Append("<div class=""detail-row""><span class=""lbl"">Payload JSON</span></div>")
                    sb.Append("<div class=""payload-box"">" & Server.HtmlEncode(payload) & "</div>")
                End If

                sb.Append("</div>")  ' .event-details
                sb.Append("</div>")  ' .event-card
            Next

            litEvents.Text = sb.ToString()

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LoadEvents error: " & ex.Message)
            litEvents.Text = "<div class=""empty-state"">Erreur de chargement : " & Server.HtmlEncode(ex.Message) & "</div>"
        End Try
    End Sub

End Class
