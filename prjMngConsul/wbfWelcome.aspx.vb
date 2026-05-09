Imports System.Data
Imports System.Data.SqlClient

Public Class wbfWelcome
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté
        If Session("UserId") Is Nothing Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            LoadWelcomeInfo()
        End If
    End Sub


    Private Sub LoadWelcomeInfo()

        ' === Prénom de l'utilisateur ===
        Dim firstName As String = If(Session("UserFirstName"), "").ToString()
        If String.IsNullOrEmpty(firstName) Then firstName = "à bord"
        litFirstName.Text = firstName

        ' === Charger l'abonnement actif (le plus récent) ===
        Dim planName As String = "Solo"
        Dim trialEnd As Date = Date.Now.AddDays(30)

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0301GetActiveSubscription", p)

            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                planName = If(r("PlanName") Is DBNull.Value, "Solo", r("PlanName").ToString())

                ' Pour la date de fin d'essai, on utilise NextBillingDate
                ' (la procédure s0312 met TrialEndOn = NextBillingDate)
                If Not r("NextBillingDate") Is DBNull.Value Then
                    trialEnd = CDate(r("NextBillingDate"))
                End If
            End If
        Catch
            ' Si erreur, on garde les valeurs par défaut
        End Try

        litPlanName.Text = planName

        ' Format de date français : "8 décembre 2025"
        Dim culture As New Globalization.CultureInfo("fr-CA")
        litTrialEnd.Text = trialEnd.ToString("d MMMM yyyy", culture)
    End Sub

End Class
