Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Telerik.Web.UI

Public Class wbfCompanyEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            LoadPlans()

            Dim guidStr As String = If(Request.QueryString("guid"), "").Trim()
            Dim g As Guid
            If Not Guid.TryParse(guidStr, g) Then
                ShowMsg("Compagnie introuvable.", isError:=True)
                btnSave.Enabled = False
                Return
            End If
            hfGuid.Value = g.ToString()
            LoadCompany(g)
            LoadSubscription(g)
        End If
    End Sub

    ''' <summary>Remplit le sélecteur de forfait (codes distincts).</summary>
    Private Sub LoadPlans()
        ddlPlan.Items.Clear()
        ddlPlan.Items.Add(New ListItem("(aucun)", ""))
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", ""))
        Dim ds As DataSet = ExecuteSQLds("s0632GetPlansList", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            Dim seen As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
            For Each r As DataRow In ds.Tables(0).Rows
                Dim code As String = If(r("Code") Is DBNull.Value, "", r("Code").ToString())
                If code <> "" AndAlso seen.Add(code) Then
                    Dim nm As String = If(r("Name") Is DBNull.Value, code, r("Name").ToString())
                    ddlPlan.Items.Add(New ListItem(code & " — " & nm, code))
                End If
            Next
        End If
    End Sub

    Private Sub LoadCompany(g As Guid)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", g))
        Dim ds As DataSet = ExecuteSQLds("s0654GetCompanyById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg("Compagnie introuvable.", isError:=True)
            btnSave.Enabled = False
            Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)
        litTitle.Text = "Compagnie — " & S(r("Name"))
        hfOrigName.Value = S(r("Name"))
        litConfirmName.Text = Server.HtmlEncode(S(r("Name")))
        txtName.Text = S(r("Name"))
        txtLegalName.Text = S(r("LegalName"))
        txtCode.Text = S(r("CompanyCode"))
        txtStructure.Text = S(r("Structure"))
        txtBusinessNumber.Text = S(r("BusinessNumber"))
        txtNEQ.Text = S(r("NEQ"))
    End Sub

    Private Sub LoadSubscription(g As Guid)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", g))
        Dim ds As DataSet = ExecuteSQLds("s0656GetSubscriptionByCompany", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            hfSubId.Value = "0"
            Return
        End If
        Dim r As DataRow = ds.Tables(0).Rows(0)
        hfSubId.Value = r("Id").ToString()
        SetDdl(ddlPlan, S(r("PlanCode")))
        SetDdl(ddlStatus, S(r("Status")))
        SetDdl(ddlCurrency, S(r("Currency")))
        SetDdl(ddlCycle, S(r("BillingCycle")))
        txtAmount.Text = If(r("Amount") Is DBNull.Value, "", CDec(r("Amount")).ToString("0.00", CultureInfo.InvariantCulture))
        cbTrial.Checked = (Not r("IsTrial") Is DBNull.Value) AndAlso CBool(r("IsTrial"))
        txtStartDate.Text = D(r("StartDate"))
        txtEndDate.Text = D(r("EndDate"))
        txtNextBilling.Text = D(r("NextBillingDate"))
        txtTrialEnd.Text = D(r("TrialEndOn"))
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        Dim g As Guid
        If Not Guid.TryParse(hfGuid.Value, g) Then
            ShowMsg("Compagnie introuvable.", isError:=True) : Return
        End If

        Dim name As String = txtName.Text.Trim()
        If String.IsNullOrEmpty(name) Then
            ShowMsg("Le nom de la compagnie est obligatoire.", isError:=True) : Return
        End If

        Try
            ' 1) Compagnie
            Dim pc As New Collection
            pc.Add(New SqlParameter("@CompanyGUID", g))
            pc.Add(New SqlParameter("@Name", name))
            pc.Add(New SqlParameter("@LegalName", Nz(txtLegalName.Text)))
            pc.Add(New SqlParameter("@CompanyCode", Nz(txtCode.Text)))
            pc.Add(New SqlParameter("@Structure", Nz(txtStructure.Text)))
            pc.Add(New SqlParameter("@BusinessNumber", Nz(txtBusinessNumber.Text)))
            pc.Add(New SqlParameter("@NEQ", Nz(txtNEQ.Text)))
            pc.Add(New SqlParameter("@ModifiedBy", UserEmail))
            ExecuteSQL("s0655SaveCompany", pc)

            ' 2) Abonnement (seulement si un forfait est sélectionné)
            Dim planCode As String = ddlPlan.SelectedValue
            If Not String.IsNullOrEmpty(planCode) Then
                Dim amount As Decimal
                If Not TryParseDecimal(txtAmount.Text, amount) Then amount = 0D

                Dim planName As String = ddlPlan.SelectedItem.Text
                Dim sep As Integer = planName.IndexOf(" — ")
                If sep >= 0 Then planName = planName.Substring(sep + 3)

                Dim subId As Integer = 0
                Integer.TryParse(hfSubId.Value, subId)

                Dim ps As New Collection
                ps.Add(New SqlParameter("@Id", subId))
                ps.Add(New SqlParameter("@CompanyGUID", g))
                ps.Add(New SqlParameter("@PlanCode", planCode))
                ps.Add(New SqlParameter("@PlanName", planName))
                ps.Add(New SqlParameter("@Amount", amount))
                ps.Add(New SqlParameter("@Currency", ddlCurrency.SelectedValue))
                ps.Add(New SqlParameter("@BillingCycle", ddlCycle.SelectedValue))
                ps.Add(New SqlParameter("@Status", ddlStatus.SelectedValue))
                ps.Add(New SqlParameter("@StartDate", NDate(txtStartDate.Text)))
                ps.Add(New SqlParameter("@EndDate", NDate(txtEndDate.Text)))
                ps.Add(New SqlParameter("@NextBillingDate", NDate(txtNextBilling.Text)))
                ps.Add(New SqlParameter("@IsTrial", cbTrial.Checked))
                ps.Add(New SqlParameter("@TrialEndOn", NDate(txtTrialEnd.Text)))
                ps.Add(New SqlParameter("@UserId", 0))
                ps.Add(New SqlParameter("@ModifiedBy", UserEmail))
                Dim outNew As New SqlParameter("@NewId", SqlDbType.Int)
                outNew.Direction = ParameterDirection.Output
                ps.Add(outNew)
                ExecuteSQL("s0657SaveSubscription", ps)
            End If

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    ''' <summary>
    ''' Suppression DÉFINITIVE de la compagnie et de toutes ses données
    ''' (proc s0658DeleteCompanyCascade). Confirmation forte : le nom saisi
    ''' doit correspondre exactement au nom de la compagnie.
    ''' </summary>
    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click

        Dim g As Guid
        If Not Guid.TryParse(hfGuid.Value, g) Then
            ShowMsg("Compagnie introuvable.", isError:=True) : Return
        End If

        Dim typed As String = txtConfirmDelete.Text.Trim()
        If String.IsNullOrEmpty(typed) OrElse
           Not String.Equals(typed, hfOrigName.Value.Trim(), StringComparison.OrdinalIgnoreCase) Then
            ShowMsg("Le nom saisi ne correspond pas au nom de la compagnie. Suppression annulée.", isError:=True)
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", g))
            p.Add(New SqlParameter("@ModifiedBy", UserEmail))
            ExecuteSQL("s0658DeleteCompanyCascade", p)

            ' Fermer la fenêtre -> la liste se rafraîchit (compagnie disparue).
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As Exception
            ShowMsg("Erreur lors de la suppression : " & ex.Message, isError:=True)
        End Try
    End Sub

    ' --------------------------- Helpers ---------------------------
    Private Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    ''' <summary>Date -> "yyyy-MM-dd" ou vide.</summary>
    Private Function D(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return CDate(o).ToString("yyyy-MM-dd")
    End Function

    Private Function Nz(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    ''' <summary>Texte -> Date (DBNull si vide/invalide).</summary>
    Private Function NDate(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Dim dt As DateTime
        If DateTime.TryParse(s.Trim(), CultureInfo.GetCultureInfo("fr-CA"), DateTimeStyles.None, dt) Then Return dt
        If DateTime.TryParse(s.Trim(), CultureInfo.InvariantCulture, DateTimeStyles.None, dt) Then Return dt
        Return DBNull.Value
    End Function

    Private Function TryParseDecimal(s As String, ByRef result As Decimal) As Boolean
        If String.IsNullOrWhiteSpace(s) Then Return False
        Dim clean As String = s.Trim().Replace(" ", "").Replace(",", ".")
        Return Decimal.TryParse(clean, NumberStyles.Any, CultureInfo.InvariantCulture, result)
    End Function

    Private Sub SetDdl(ddl As DropDownList, value As String)
        ddl.ClearSelection()
        Dim item As ListItem = ddl.Items.FindByValue(value)
        If item Is Nothing AndAlso Not String.IsNullOrEmpty(value) Then
            ' Valeur existante hors liste : on l'ajoute pour ne pas la perdre.
            item = New ListItem(value, value)
            ddl.Items.Add(item)
        End If
        If item IsNot Nothing Then item.Selected = True
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

End Class
