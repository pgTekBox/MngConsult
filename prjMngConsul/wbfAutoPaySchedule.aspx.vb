Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

''' <summary>
''' Calendrier des paiements automatiques sur 30 jours (defaut).
''' Groupe par date pour visualisation facile.
''' </summary>
Public Class wbfAutoPaySchedule
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            tbFromDate.Text = Date.Today.ToString("yyyy-MM-dd")
            tbToDate.Text = Date.Today.AddDays(30).ToString("yyyy-MM-dd")
            LoadSchedule()
        End If
    End Sub

    Private Sub btnFilter_Click(sender As Object, e As EventArgs) Handles btnFilter.Click
        LoadSchedule()
    End Sub

    Private Sub ddlStatus_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlStatus.SelectedIndexChanged
        LoadSchedule()
    End Sub

    Private Sub LoadSchedule()
        Try
            Dim fromDate As Date = Date.Today
            Dim toDate As Date = Date.Today.AddDays(30)
            Date.TryParse(tbFromDate.Text, fromDate)
            Date.TryParse(tbToDate.Text, toDate)

            Dim statusFilter As String = ddlStatus.SelectedValue
            Dim statusParam As Object = If(String.IsNullOrEmpty(statusFilter), CType(DBNull.Value, Object), statusFilter)

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@FromDate", fromDate))
            p.Add(New SqlParameter("@ToDate", toDate))
            p.Add(New SqlParameter("@PartyId", DBNull.Value))
            p.Add(New SqlParameter("@Status", statusParam))

            Dim ds As DataSet = ExecuteSQLds("s0097GetScheduledAutoPays", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                pnlEmpty.Visible = True
                litCalendar.Text = ""
                Return
            End If

            pnlEmpty.Visible = False
            litCalendar.Text = RenderCalendar(ds.Tables(0))

        Catch ex As Exception
            ShowError("Erreur chargement calendrier : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Genere le HTML du calendrier groupe par date.
    ''' </summary>
    Private Function RenderCalendar(dt As DataTable) As String
        Dim sb As New StringBuilder()
        Dim culture As New CultureInfo("fr-CA")
        Dim today As Date = Date.Today

        Dim currentDate As Date = Date.MinValue
        Dim groupOpen As Boolean = False

        For Each row As DataRow In dt.Rows
            Dim rowDate As Date = CDate(row("AutoPayDate"))
            If rowDate <> currentDate Then
                If groupOpen Then sb.Append("</div></div>")
                currentDate = rowDate

                Dim headerClass As String = "day-header"
                If rowDate = today Then
                    headerClass &= " today"
                ElseIf rowDate < today Then
                    headerClass &= " past"
                End If

                Dim dayLabel As String = rowDate.ToString("dddd d MMMM yyyy", culture)
                dayLabel = Char.ToUpper(dayLabel(0)) & dayLabel.Substring(1)

                sb.Append("<div class='day-group'>")
                sb.AppendFormat("<div class='{0}'><span>{1}</span><span>{2}</span></div>",
                                headerClass, Server.HtmlEncode(dayLabel),
                                If(rowDate = today, "AUJOURD'HUI", rowDate.ToString("yyyy-MM-dd")))
                sb.Append("<div class='day-items'>")
                groupOpen = True
            End If

            sb.Append(RenderSchedCard(row))
        Next

        If groupOpen Then sb.Append("</div></div>")

        Return sb.ToString()
    End Function

    Private Function RenderSchedCard(row As DataRow) As String
        Dim culture As New CultureInfo("fr-CA")
        Dim status As String = If(row("AutoPayStatus"), "").ToString()
        Dim statusLower As String = status.ToLowerInvariant()
        Dim partyName As String = If(row("PartyName"), "Fournisseur").ToString()
        Dim docNumber As String = If(row("DocumentNumber"), row("DocumentId").ToString()).ToString()
        Dim docId As Integer = CInt(row("DocumentId"))
        Dim restant As Decimal = CDec(row("RestantAPayer"))
        Dim methodType As String = If(row("PaymentMethodType"), "").ToString()
        Dim cardBrand As String = If(row("CardBrand"), "").ToString()
        Dim cardLast4 As String = If(row("CardLast4"), "").ToString()
        Dim bankLast4 As String = If(row("BankAccountLast4"), "").ToString()
        Dim attempts As Integer = CInt(row("AutoPayAttempts"))

        Dim methodLabel As String = ""
        If methodType = "card" Then
            methodLabel = (If(String.IsNullOrEmpty(cardBrand), "Carte", cardBrand)).ToUpper() &
                          " ****" & If(String.IsNullOrEmpty(cardLast4), "????", cardLast4)
        ElseIf methodType = "acss_debit" Then
            methodLabel = "PAD ****" & If(String.IsNullOrEmpty(bankLast4), "????", bankLast4)
        Else
            methodLabel = methodType
        End If

        Dim preavisOk As Boolean = (Not (row("AutoPayPreavisSentDate") Is DBNull.Value)) OrElse
                                   (Not (row("AutoPayPadPreavisSentDate") Is DBNull.Value))
        Dim preavisLabel As String = If(preavisOk, "✅ Préavis envoyé", "⏳ Préavis pendant")

        Dim cardClass As String = "sched-card " & statusLower
        Dim statusBadge As String = "<span class='sched-status status-" & statusLower & "'>" & Server.HtmlEncode(status) & "</span>"

        Dim cancelBtn As String = ""
        If status = "PLANIFIE" OrElse status = "REQUIRES_3DS" Then
            cancelBtn = "<asp:LinkButton runat='server' CommandName='Cancel' CommandArgument='" & docId &
                        "' OnClientClick='return confirm(""Annuler ce paiement programmé ?"");'>X</asp:LinkButton>"
            ' Note: Repeater LinkButton dynamique pas trivial ici, on fait un lien HTML simple
            cancelBtn = "<a href='wbfAutoPaySchedule.aspx?cancel=" & docId & "' " &
                        "onclick='return confirm(""Annuler ce paiement programmé pour la facture " &
                        Server.HtmlEncode(docNumber) & " ?"");' " &
                        "class='btn-cancel' style='text-decoration:none;'>🚫 Annuler</a>"
        End If

        Return String.Format(
            "<div class='{0}'>" &
            "  <div>" &
            "    <div class='sched-supplier'>{1}</div>" &
            "    <div class='sched-meta'>" &
            "      <span>📄 Facture {2}</span>" &
            "      <span>💳 {3}</span>" &
            "      <span>{4}</span>" &
            "      <span>Tentatives : {5}/3</span>" &
            "    </div>" &
            "    <div style='margin-top:6px;'>{6}</div>" &
            "  </div>" &
            "  <div style='text-align:right;'>" &
            "    <div class='sched-amount'>{7}</div>" &
            "    <div style='margin-top:4px;'>{8}</div>" &
            "  </div>" &
            "</div>",
            cardClass,
            Server.HtmlEncode(partyName),
            Server.HtmlEncode(docNumber),
            Server.HtmlEncode(methodLabel),
            preavisLabel,
            attempts.ToString(),
            statusBadge,
            restant.ToString("N2", culture) & " $",
            cancelBtn
        )
    End Function

    ''' <summary>
    ''' Si querystring "cancel=DocId" present (clic sur "Annuler"), appelle s0095.
    ''' </summary>
    Protected Sub Page_PreLoad(sender As Object, e As EventArgs) Handles Me.PreLoad
        Dim cancelStr As String = Request.QueryString("cancel")
        If String.IsNullOrEmpty(cancelStr) Then Return

        Dim docId As Integer = 0
        Integer.TryParse(cancelStr, docId)
        If docId = 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@DocumentId", docId))
            p.Add(New SqlParameter("@CancelledByUserGUID", DBNull.Value))

            Dim ds As DataSet = ExecuteSQLds("s0095CancelScheduledAutoPay", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

            Dim row As DataRow = ds.Tables(0).Rows(0)
            If CInt(row("RetCode")) = 0 Then
                ShowSuccess("Paiement programmé annulé pour la facture #" & docId.ToString())
            Else
                ShowError(row("ErrorMessage").ToString())
            End If
        Catch ex As Exception
            ShowError("Erreur annulation : " & ex.Message)
        End Try
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
        pnlAlert.Visible = False
    End Sub

    Private Sub ShowSuccess(msg As String)
        pnlAlert.Visible = True
        litAlert.Text = msg
        pnlError.Visible = False
    End Sub

End Class
