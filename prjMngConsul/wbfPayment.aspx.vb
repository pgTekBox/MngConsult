Imports System.Data
Imports System.Data.SqlClient

Public Class wbfPayment
    Inherits clsData

    ' Carte de test acceptée (style Stripe)
    Private Const TEST_CARD_OK As String = "4242424242424242"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté
        If UserId = "" Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            LoadPlanDetails()
        End If
    End Sub
    Private Function GetUserAndCompanyInfo(userId As Integer) As DataRow

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", userId))

        Dim ds As DataSet = ExecuteSQLds("s0230GetUserAndCompanyInfo", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return Nothing
        End If

        Return ds.Tables(0).Rows(0)
    End Function



    ''' <summary>
    ''' Charge les détails du forfait depuis le QueryString (?plan=xxx)
    ''' </summary>
    Private Sub LoadPlanDetails()


        Dim dr As DataRow = GetUserAndCompanyInfo(UserId)

        Company = dr("CompanyGUID")


        Dim planCode As String = dr("Abonnement")

        Dim planName As String
        Dim tagline As String
        Dim amount As Decimal
        Dim features As String()

        Select Case planCode
            Case "solo"
                planName = "Solo"
                tagline = "Pour démarrer en toute simplicité"
                amount = 19D
                features = {"1 utilisateur", "Facturation illimitée", "Support par courriel", "Stockage 5 Go"}

            Case "comsolo"
                planName = "ComSolo"
                tagline = "Pour les équipes en croissance"
                amount = 99D
                features = {"Utilisateurs illimités", "Multi-compagnie", "Support prioritaire 24/7",
                            "Stockage 100 Go", "API et intégrations", "Tableau de bord avancé"}

            Case "com119"
                planName = "COM119"
                tagline = "Pour les grandes entreprises"
                amount = 199D
                features = {"Utilisateurs illimités", "Multi-compagnie", "Support prioritaire 24/7",
                            "Stockage 500 Go", "API et intégrations avancées", "Tableau de bord complet"}

            Case Else
                ' Pro par défaut
                planCode = "pro"
                planName = "Pro"
                tagline = "Pour les professionnels exigeants"
                amount = 49D
                features = {"5 utilisateurs", "Facturation illimitée", "Agenda multi-thérapeutes",
                            "Support prioritaire", "Stockage 25 Go", "Rapports avancés"}
        End Select

        ' Sauvegarder les détails dans ViewState pour le postback
        ViewState("PlanCode") = planCode
        ViewState("PlanName") = planName
        ViewState("PlanAmount") = amount

        ' Calculs taxes
        Dim tps As Decimal = Math.Round(amount * 0.05D, 2)
        Dim tvq As Decimal = Math.Round(amount * 0.09975D, 2)
        Dim total As Decimal = amount + tps + tvq

        ' Affichage
        litPlanName.Text = planName
        litPlanTagline.Text = tagline
        litPlanLabel.Text = "Forfait " & planName
        litPlanAmount.Text = amount.ToString("C")
        litTps.Text = tps.ToString("C")
        litTvq.Text = tvq.ToString("C")
        litTotal.Text = total.ToString("C")

        ' Liste des fonctionnalités (HTML)
        Dim sb As New System.Text.StringBuilder()
        For Each f In features
            sb.Append("<li>")
            sb.Append("<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'>")
            sb.Append("<polyline points='20 6 9 17 4 12'></polyline></svg> ")
            sb.Append(System.Web.HttpUtility.HtmlEncode(f))
            sb.Append("</li>")
        Next
        litFeatures.Text = sb.ToString()
    End Sub


    Protected Sub btnPay_Click(sender As Object, e As EventArgs) Handles btnPay.Click

        ' === Récupération des champs ===
        Dim cardNumber As String = (tbCardNumber.Text & "").Replace(" ", "").Trim()
        Dim cardHolder As String = (tbCardHolder.Text & "").Trim().ToUpper()
        Dim expiry As String = (tbExpiry.Text & "").Trim()
        Dim cvv As String = (tbCvv.Text & "").Trim()

        ' === Validations basiques ===
        If String.IsNullOrEmpty(cardHolder) Then
            ShowError("Veuillez entrer le nom du titulaire de la carte.")
            Return
        End If

        If cardNumber.Length < 13 OrElse cardNumber.Length > 19 OrElse Not IsAllDigits(cardNumber) Then
            ShowError("Le numéro de carte n'est pas valide.")
            Return
        End If

        If Not System.Text.RegularExpressions.Regex.IsMatch(expiry, "^(0[1-9]|1[0-2])\/\d{2}$") Then
            ShowError("La date d'expiration doit être au format MM/AA.")
            Return
        End If

        ' Vérifier que la date n'est pas passée
        Dim parts = expiry.Split("/"c)
        Dim mm As Integer = Integer.Parse(parts(0))
        Dim yy As Integer = 2000 + Integer.Parse(parts(1))
        Dim expDate As New Date(yy, mm, Date.DaysInMonth(yy, mm))
        If expDate < Date.Today Then
            ShowError("Cette carte est expirée.")
            Return
        End If

        If cvv.Length < 3 OrElse cvv.Length > 4 OrElse Not IsAllDigits(cvv) Then
            ShowError("Le CVV n'est pas valide.")
            Return
        End If

        ' === SIMULATION DU PAIEMENT ===
        ' Carte de test 4242 4242 4242 4242 = succès
        ' Toute autre carte = refus
        If cardNumber <> TEST_CARD_OK Then
            ShowError("Votre carte a été refusée. Pour tester un paiement réussi, utilisez le numéro 4242 4242 4242 4242.")
            Return
        End If

        ' === Création de l'abonnement ===
        Try
            Dim planCode As String = If(ViewState("PlanCode"), "solo").ToString()
            Dim planName As String = If(ViewState("PlanName"), "Solo").ToString()
            Dim amount As Decimal = CDec(ViewState("PlanAmount"))

            Dim cardLast4 As String = cardNumber.Substring(cardNumber.Length - 4)
            Dim cardBrand As String = DetectCardBrand(cardNumber)
            Dim transactionId As String = "SIM_" & Guid.NewGuid().ToString("N").Substring(0, 16).ToUpper()

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", CInt(Session("UserId"))))
            p.Add(New SqlParameter("@PlanCode", planCode))
            p.Add(New SqlParameter("@PlanName", planName))
            p.Add(New SqlParameter("@Amount", amount))
            p.Add(New SqlParameter("@Currency", "CAD"))
            p.Add(New SqlParameter("@BillingCycle", "monthly"))
            p.Add(New SqlParameter("@CardLast4", cardLast4))
            p.Add(New SqlParameter("@CardBrand", cardBrand))
            p.Add(New SqlParameter("@CardHolderName", cardHolder))
            p.Add(New SqlParameter("@TransactionId", transactionId))
            p.Add(New SqlParameter("@ProcessorName", "simulation"))
            p.Add(New SqlParameter("@CreatedBy", If(Session("UserEmail"), "")))

            Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outNew)

            ExecuteSQL("s0300CreateSubscription", p)

            Dim subscriptionId As Integer = If(outNew.Value Is Nothing OrElse IsDBNull(outNew.Value),
                                               0,
                                               CInt(outNew.Value))

            ' Redirection vers la page de succès
            Response.Redirect("~/wbfPaymentSuccess.aspx?id=" & subscriptionId.ToString() &
                              "&txn=" & transactionId)

        Catch ex As Exception
            ShowError("Une erreur est survenue : " & ex.Message)
        End Try
    End Sub


    ''' <summary>
    ''' Détecte la marque de carte à partir du numéro
    ''' </summary>
    Private Function DetectCardBrand(cardNumber As String) As String
        If String.IsNullOrEmpty(cardNumber) Then Return "Unknown"
        Dim first As Char = cardNumber(0)
        Dim firstTwo As String = cardNumber.Substring(0, Math.Min(2, cardNumber.Length))

        If first = "4"c Then Return "Visa"
        If firstTwo >= "51" AndAlso firstTwo <= "55" Then Return "Mastercard"
        If firstTwo = "34" OrElse firstTwo = "37" Then Return "Amex"
        If firstTwo = "60" OrElse firstTwo = "65" Then Return "Discover"
        Return "Other"
    End Function

    Private Function IsAllDigits(s As String) As Boolean
        For Each c In s
            If Not Char.IsDigit(c) Then Return False
        Next
        Return True
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
