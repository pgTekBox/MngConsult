Imports System.Data
Imports System.Data.SqlClient

Public Class wbfPaymentSuccess
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' Vérifier la session
        If Session("UserId") Is Nothing Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            LoadSubscriptionDetails()
        End If
    End Sub

    Private Sub LoadSubscriptionDetails()

        Dim txnId As String = If(Request.QueryString("txn"), "")

        ' Récupérer l'abonnement actif depuis la BD
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0301GetActiveSubscription", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ' Pas d'abonnement trouvé : rediriger
            Response.Redirect("~/Default.aspx")
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)

        Dim planName As String = If(r("PlanName") Is DBNull.Value, "", r("PlanName").ToString())
        Dim amount As Decimal = If(r("Amount") Is DBNull.Value, 0D, CDec(r("Amount")))
        Dim cardLast4 As String = If(r("CardLast4") Is DBNull.Value, "••••", r("CardLast4").ToString())
        Dim cardBrand As String = If(r("CardBrand") Is DBNull.Value, "", r("CardBrand").ToString())
        Dim startDate As Date = If(r("StartDate") Is DBNull.Value, Date.Now, CDate(r("StartDate")))
        Dim nextBilling As Date = If(r("NextBillingDate") Is DBNull.Value, Date.Now.AddMonths(1), CDate(r("NextBillingDate")))

        ' Calcul du total avec taxes (déjà calculé sur la page de paiement,
        ' mais on le refait pour l'affichage cohérent)
        Dim tps As Decimal = Math.Round(amount * 0.05D, 2)
        Dim tvq As Decimal = Math.Round(amount * 0.09975D, 2)
        Dim total As Decimal = amount + tps + tvq

        litPlanName.Text = planName
        litPlanName2.Text = planName
        litTransactionId.Text = If(String.IsNullOrEmpty(txnId), "—", txnId)
        litDate.Text = startDate.ToString("dd MMMM yyyy", New Globalization.CultureInfo("fr-CA"))
        litCard.Text = cardBrand & " •••• " & cardLast4
        litNextBilling.Text = nextBilling.ToString("dd MMMM yyyy", New Globalization.CultureInfo("fr-CA"))
        litAmount.Text = total.ToString("C")
    End Sub

End Class
