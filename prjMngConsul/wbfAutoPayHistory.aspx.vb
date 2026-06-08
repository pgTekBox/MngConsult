Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Historique des tentatives d'auto-paiement (T145AutoPayAttempt).
''' Permet de tracer succès et échecs, voir les codes d'erreur Stripe.
''' </summary>
Public Class wbfAutoPayHistory
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            tbFromDate.Text = Date.Today.AddDays(-30).ToString("yyyy-MM-dd")
            tbToDate.Text = Date.Today.ToString("yyyy-MM-dd")
            LoadHistory()
        End If
    End Sub

    Private Sub btnFilter_Click(sender As Object, e As EventArgs) Handles btnFilter.Click
        LoadHistory()
    End Sub

    Private Sub ddlResult_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlResult.SelectedIndexChanged
        LoadHistory()
    End Sub

    Private Sub ddlMaxRows_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlMaxRows.SelectedIndexChanged
        LoadHistory()
    End Sub

    Private Sub LoadHistory()
        Try
            Dim fromDate As Date = Date.Today.AddDays(-30)
            Dim toDate As Date = Date.Today
            Date.TryParse(tbFromDate.Text, fromDate)
            Date.TryParse(tbToDate.Text, toDate)

            Dim resultFilter As String = ddlResult.SelectedValue
            Dim resultParam As Object = If(String.IsNullOrEmpty(resultFilter), CType(DBNull.Value, Object), resultFilter)

            Dim maxRows As Integer = 200
            Integer.TryParse(ddlMaxRows.SelectedValue, maxRows)

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@PartyId", DBNull.Value))
            p.Add(New SqlParameter("@DocumentId", DBNull.Value))
            p.Add(New SqlParameter("@Result", resultParam))
            p.Add(New SqlParameter("@FromDate", fromDate))
            p.Add(New SqlParameter("@ToDate", toDate))
            p.Add(New SqlParameter("@MaxRows", maxRows))

            Dim ds As DataSet = ExecuteSQLds("s0094GetAutoPayHistory", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                pnlEmpty.Visible = True
                pnlList.Visible = False
                rptHistory.DataSource = Nothing
                rptHistory.DataBind()
                Return
            End If

            pnlEmpty.Visible = False
            pnlList.Visible = True
            rptHistory.DataSource = ds.Tables(0)
            rptHistory.DataBind()

        Catch ex As Exception
            ShowError("Erreur chargement historique : " & ex.Message)
        End Try
    End Sub

    Public Function FormatMoney(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return "—"
        Try
            Dim d As Decimal = Convert.ToDecimal(value)
            Return d.ToString("N2", New CultureInfo("fr-CA")) & " $"
        Catch
            Return "—"
        End Try
    End Function

    Public Function RenderMethodSmall(methodType As Object, cardBrand As Object, cardLast4 As Object, bankLast4 As Object) As String
        Dim t As String = If(methodType, "").ToString()
        If t = "card" Then
            Dim brand As String = If(cardBrand Is DBNull.Value OrElse cardBrand Is Nothing, "Carte", cardBrand.ToString()).ToUpper()
            Dim last4 As String = If(cardLast4 Is DBNull.Value OrElse cardLast4 Is Nothing, "????", cardLast4.ToString())
            Return Server.HtmlEncode(brand) & " <span class='mono'>****" & Server.HtmlEncode(last4) & "</span>"
        ElseIf t = "acss_debit" Then
            Dim last4 As String = If(bankLast4 Is DBNull.Value OrElse bankLast4 Is Nothing, "????", bankLast4.ToString())
            Return "PAD <span class='mono'>****" & Server.HtmlEncode(last4) & "</span>"
        Else
            Return Server.HtmlEncode(t)
        End If
    End Function

    Public Function RenderDetails(item As Object) As String
        If item Is Nothing Then Return ""
        Dim row As DataRowView = TryCast(item, DataRowView)
        If row Is Nothing Then Return ""

        Dim sb As New System.Text.StringBuilder()

        Dim result As String = If(row("Result"), "").ToString()

        If result = "SUCCESS" Then
            Dim piId As String = If(row("StripePaymentIntentId") Is DBNull.Value, "", row("StripePaymentIntentId").ToString())
            If Not String.IsNullOrEmpty(piId) Then
                sb.Append("<div class='mono'>PI : ").Append(Server.HtmlEncode(piId)).Append("</div>")
            End If
            If Not (row("ReglementId") Is DBNull.Value) Then
                sb.Append("<div class='mono'>Décaissement #").Append(row("ReglementId").ToString()).Append("</div>")
            End If
        Else
            Dim code As String = If(row("FailureCode") Is DBNull.Value, "", row("FailureCode").ToString())
            Dim msg As String = If(row("FailureMessage") Is DBNull.Value, "", row("FailureMessage").ToString())
            If Not String.IsNullOrEmpty(code) Then
                sb.Append("<div class='mono' style='color:#b91c1c;'>").Append(Server.HtmlEncode(code)).Append("</div>")
            End If
            If Not String.IsNullOrEmpty(msg) Then
                ' Limiter a 200 chars
                If msg.Length > 200 Then msg = msg.Substring(0, 200) & "..."
                sb.Append("<div style='font-size:11px; color:#475569;'>").Append(Server.HtmlEncode(msg)).Append("</div>")
            End If
            Dim url As String = If(row("Requires3DSUrl") Is DBNull.Value, "", row("Requires3DSUrl").ToString())
            If Not String.IsNullOrEmpty(url) Then
                sb.Append("<div><a href='").Append(Server.HtmlEncode(url)).
                    Append("' target='_blank' style='font-size:11px;'>🔗 Auth 3DS</a></div>")
            End If
        End If

        Return sb.ToString()
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
