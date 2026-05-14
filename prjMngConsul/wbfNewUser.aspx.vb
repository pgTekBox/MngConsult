Imports System.Data
Imports System.Data.SqlClient

Public Class wbfNewUser
    Inherits clsData

    Private Const TRIAL_DAYS As Integer = 30

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ' Vérifier que l'utilisateur est connecté
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            ' Récupérer le plan depuis le QueryString
            Dim plan As String = If(Request.QueryString("plan"), "").ToLower()
            If String.IsNullOrEmpty(plan) Then plan = "solo"
            hfPlan.Value = plan

            ' Pré-remplir les champs avec les infos déjà connues du user
            PrefillUserInfo()
        End If
    End Sub


    ''' <summary>
    ''' Pré-remplit les champs Prénom / Nom à partir de la session
    ''' </summary>
    Private Sub PrefillUserInfo()



        txtFirstName.Text = UserFirstName


        txtLastName.Text = UserLastName



        txtEmail.Text = UserEmail





    End Sub


    ' =====================================================================
    ' ONGLET GÉNÉRALE — Sauvegarde du profil + démarrage essai
    ' =====================================================================
    Protected Sub btnSaveGen_Click(sender As Object, e As EventArgs) Handles btnSaveGen.Click

        ' === Validations basiques ===
        If String.IsNullOrWhiteSpace(txtFirstName.Text) Then
            ShowMessage("Le prénom est obligatoire.", isError:=True)
            Return
        End If
        If String.IsNullOrWhiteSpace(txtLastName.Text) Then
            ShowMessage("Le nom de famille est obligatoire.", isError:=True)
            Return
        End If

        Try

            Dim modifiedBy As String = UserEmail

            ' === 1) Sauvegarder le profil utilisateur (T015User) ===
            SaveUserProfile(UserId, modifiedBy)

            ' === 2) Sauvegarder les infos entreprise (T010Company) — partie Générale ===
            SaveCompanyGeneral(modifiedBy)



            'Dim p As New Collection
            'p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            'Dim ds As DataSet = ExecuteSQLds("s0500InitializeCompanyData", p)




            ' === 3) Mettre à jour la session avec les nouveaux noms ===
            UserFirstName = txtFirstName.Text.Trim()
            UserLastName = txtLastName.Text.Trim()

            ' === 4) Démarrer l'essai gratuit ===
            Dim subscriptionId As Integer = StartFreeTrial(userId, modifiedBy)

            ' === 5) Redirection vers la page de bienvenue ===
            Response.Redirect("~/wbfWelcome.aspx?id=" & subscriptionId.ToString())

        Catch ex As Exception
            ShowMessage("Erreur lors de la sauvegarde : " & ex.Message, isError:=True)
        End Try
    End Sub


    ' =====================================================================
    ' ONGLET GOUVERNEMENTALE — Sauvegarde des infos fiscales
    ' =====================================================================
    Protected Sub btnSaveGov_Click(sender As Object, e As EventArgs) Handles btnSaveGov.Click

        Try
            Dim modifiedBy As String = UserEmail
            SaveCompanyFull(modifiedBy)
            ShowMessage("Informations gouvernementales enregistrées.", isError:=False)
        Catch ex As Exception
            ShowMessage("Erreur lors de la sauvegarde : " & ex.Message, isError:=True)
        End Try
    End Sub


    ' =====================================================================
    ' Boutons Annuler
    ' =====================================================================
    Protected Sub btnCancelGen_Click(sender As Object, e As EventArgs) Handles btnCancelGen.Click
        Response.Redirect("~/Default.aspx")
    End Sub

    Protected Sub btnCancelGov_Click(sender As Object, e As EventArgs) Handles btnCancelGov.Click
        Response.Redirect("~/Default.aspx")
    End Sub


    ' =====================================================================
    ' Helpers BD
    ' =====================================================================

    ''' <summary>
    ''' Sauvegarde des infos personnelles dans T015User
    ''' </summary>
    Private Sub SaveUserProfile(userId As Integer, modifiedBy As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", userId))
        p.Add(New SqlParameter("@FirstName", IfDbStr(txtFirstName.Text)))
        p.Add(New SqlParameter("@LastName", IfDbStr(txtLastName.Text)))
        p.Add(New SqlParameter("@Address1", IfDbStr(txtAddress.Text)))
        p.Add(New SqlParameter("@City", IfDbStr(txtCity.Text)))
        p.Add(New SqlParameter("@Province", IfDbStr(ddlProvince.SelectedValue)))
        p.Add(New SqlParameter("@PostalCode", IfDbStr(txtPostalCode.Text)))
        p.Add(New SqlParameter("@Phone", IfDbStr(txtPhone.Text)))
        p.Add(New SqlParameter("@ModifiedBy", If(String.IsNullOrEmpty(modifiedBy), CObj(DBNull.Value), modifiedBy)))

        ExecuteSQL("s0310SaveUserProfile", p)
    End Sub


    ''' <summary>
    ''' Sauvegarde la structure dans T010Company (onglet Générale)
    ''' </summary>
    Private Sub SaveCompanyGeneral(modifiedBy As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Structure", "solo"))   ' Travailleur autonome

        p.Add(New SqlParameter("@BusinessNumber", DBNull.Value))
        p.Add(New SqlParameter("@SIN", DBNull.Value))
        p.Add(New SqlParameter("@TpsNumber", DBNull.Value))
        p.Add(New SqlParameter("@TpsRegDate", DBNull.Value))
        p.Add(New SqlParameter("@NEQ", DBNull.Value))
        p.Add(New SqlParameter("@TvqNumber", DBNull.Value))
        p.Add(New SqlParameter("@TvqRegDate", DBNull.Value))
        p.Add(New SqlParameter("@CAE", DBNull.Value))
        p.Add(New SqlParameter("@TpsFrequency", DBNull.Value))
        p.Add(New SqlParameter("@TvqFrequency", DBNull.Value))
        p.Add(New SqlParameter("@FiscalYearEnd", DBNull.Value))
        p.Add(New SqlParameter("@PaymentRegime", DBNull.Value))
        p.Add(New SqlParameter("@ModifiedBy", If(String.IsNullOrEmpty(modifiedBy), CObj(DBNull.Value), modifiedBy)))

        ExecuteSQL("s0311SaveCompanyInfo", p)
    End Sub


    ''' <summary>
    ''' Sauvegarde complète des infos entreprise (onglet Gouvernementale)
    ''' </summary>
    Private Sub SaveCompanyFull(modifiedBy As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Structure", "solo"))

        p.Add(New SqlParameter("@BusinessNumber", IfDbStr(txtBusinessNumber.Text)))
        p.Add(New SqlParameter("@SIN", IfDbStr(txtSin.Text)))
        p.Add(New SqlParameter("@TpsNumber", IfDbStr(txtTps.Text)))
        p.Add(New SqlParameter("@TpsRegDate", IfDbDate(txtTpsDate.Text)))

        p.Add(New SqlParameter("@NEQ", IfDbStr(txtNeq.Text)))
        p.Add(New SqlParameter("@TvqNumber", IfDbStr(txtTvq.Text)))
        p.Add(New SqlParameter("@TvqRegDate", IfDbDate(txtTvqDate.Text)))
        p.Add(New SqlParameter("@CAE", IfDbStr(txtCae.Text)))

        p.Add(New SqlParameter("@TpsFrequency", IfDbStr(ddlTpsFrequency.SelectedValue)))
        p.Add(New SqlParameter("@TvqFrequency", IfDbStr(ddlTvqFrequency.SelectedValue)))
        p.Add(New SqlParameter("@FiscalYearEnd", IfDbDate(txtFiscalYearEnd.Text)))
        p.Add(New SqlParameter("@PaymentRegime", IfDbStr(ddlPaymentRegime.SelectedValue)))

        p.Add(New SqlParameter("@ModifiedBy", If(String.IsNullOrEmpty(modifiedBy), CObj(DBNull.Value), modifiedBy)))

        ExecuteSQL("s0311SaveCompanyInfo", p)
    End Sub


    ''' <summary>
    ''' Démarre un abonnement en essai gratuit pour le plan choisi
    ''' </summary>
    Private Function StartFreeTrial(userId As Integer, modifiedBy As String) As Integer

        Dim plan As String = If(hfPlan.Value, "pro").ToLower()

        ' Tarifs (à garder synchronisés avec wbfPayment.aspx.vb)
        Dim planName As String = ""
        Dim amount As Decimal

        Select Case plan
            Case "solo"
                planName = "Solo"
                amount = 19D
            Case "comsolo"
                planName = "ComSolo"
                amount = 99D
            Case "com119"
                planName = "COM119"
                amount = 199D

        End Select

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@UserId", userId))
        p.Add(New SqlParameter("@PlanCode", plan))
        p.Add(New SqlParameter("@PlanName", planName))
        p.Add(New SqlParameter("@Amount", amount))
        p.Add(New SqlParameter("@TrialDays", TRIAL_DAYS))
        p.Add(New SqlParameter("@CreatedBy", If(String.IsNullOrEmpty(modifiedBy), CObj(DBNull.Value), modifiedBy)))

        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outNew)

        ExecuteSQL("s0312StartTrialSubscription", p)

        If outNew.Value Is Nothing OrElse IsDBNull(outNew.Value) Then Return 0
        Return CInt(outNew.Value)
    End Function


    ' =====================================================================
    ' Utility helpers
    ' =====================================================================

    Private Function IfDbStr(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    Private Function IfDbDate(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Dim d As Date
        If Date.TryParse(s, d) Then Return d
        Return DBNull.Value
    End Function

    Private Sub ShowMessage(text As String, isError As Boolean)
        pnlMessage.Visible = True
        litMessage.Text = text
        If isError Then
            pnlMessage.Style("background") = "rgba(239,68,68,.08)"
            pnlMessage.Style("border") = "1px solid rgba(239,68,68,.25)"
            pnlMessage.Style("color") = "#dc2626"
        Else
            pnlMessage.Style("background") = "rgba(16,185,129,.08)"
            pnlMessage.Style("border") = "1px solid rgba(16,185,129,.25)"
            pnlMessage.Style("color") = "#059669"
        End If
    End Sub

End Class
