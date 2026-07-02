Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Telerik.Web.UI

Public Class wbfPlanEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("id"), id)
            hfId.Value = id.ToString()

            If id > 0 Then
                LoadPlan(id)
                litTitle.Text = "Modifier un forfait"
                btnDelete.Visible = True
            Else
                litTitle.Text = "Nouveau forfait"
                ' Valeurs par défaut pour une création
                txtTrialDays.Text = "0"
                txtDisplayOrder.Text = "0"
            End If
        End If
    End Sub

    Private Sub LoadPlan(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))

        Dim ds As DataSet = ExecuteSQLds("s0633GetPlanById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg("Forfait introuvable.", isError:=True)
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        txtCode.Text = S(r("Code"))
        txtName.Text = S(r("Name"))
        txtTagline.Text = S(r("Tagline"))
        txtDescription.Text = S(r("Description"))
        reDescriptionLong.Content = S(r("DescriptionLong"))
        txtAmount.Text = If(r("Amount") Is DBNull.Value, "", CDec(r("Amount")).ToString("0.00", CultureInfo.InvariantCulture))
        SetDdl(ddlCurrency, S(r("Currency")))
        SetDdl(ddlBillingCycle, S(r("BillingCycle")))
        txtTrialDays.Text = S(r("TrialDays"))
        txtMaxUsers.Text = S(r("MaxUsers"))
        txtMaxClients.Text = S(r("MaxClients"))
        txtMaxDocuments.Text = S(r("MaxDocuments"))
        txtMaxStorageMB.Text = S(r("MaxStorageMB"))
        txtFeatures.Text = S(r("Features"))
        txtDisplayOrder.Text = S(r("DisplayOrder"))
        txtProcessorName.Text = S(r("ProcessorName"))
        txtStripeProductId.Text = S(r("StripeProductId"))
        txtStripePriceId.Text = S(r("StripePriceId"))
        txtEmployeeRange.Text = S(r("EmployeeRange"))
        txtBadgeText.Text = S(r("BadgeText"))
        cbRecommended.Checked = (Not r("IsRecommended") Is DBNull.Value) AndAlso CBool(r("IsRecommended"))
        cbActive.Checked = (Not r("IsActive") Is DBNull.Value) AndAlso CBool(r("IsActive"))
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)

        ' === Validations ===
        Dim code As String = txtCode.Text.Trim()
        If String.IsNullOrEmpty(code) Then
            ShowMsg("Le code est obligatoire.", isError:=True)
            Return
        End If
        Dim name As String = txtName.Text.Trim()
        If String.IsNullOrEmpty(name) Then
            ShowMsg("Le nom est obligatoire.", isError:=True)
            Return
        End If

        Dim amount As Decimal
        If Not TryParseDecimal(txtAmount.Text, amount) Then
            ShowMsg("Le montant n'est pas valide.", isError:=True)
            Return
        End If

        ' === Sauvegarde ===
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@Code", code))
            p.Add(New SqlParameter("@Name", name))
            p.Add(New SqlParameter("@Description", Nz(txtDescription.Text)))
            p.Add(New SqlParameter("@DescriptionLong", Nz(reDescriptionLong.Content)))
            p.Add(New SqlParameter("@Amount", amount))
            p.Add(New SqlParameter("@Currency", ddlCurrency.SelectedValue))
            p.Add(New SqlParameter("@BillingCycle", ddlBillingCycle.SelectedValue))
            p.Add(New SqlParameter("@ProcessorName", Nz(txtProcessorName.Text)))
            p.Add(New SqlParameter("@StripeProductId", Nz(txtStripeProductId.Text)))
            p.Add(New SqlParameter("@StripePriceId", Nz(txtStripePriceId.Text)))
            p.Add(New SqlParameter("@TrialDays", NInt(txtTrialDays.Text, 0)))
            p.Add(New SqlParameter("@MaxUsers", NIntNull(txtMaxUsers.Text)))
            p.Add(New SqlParameter("@MaxClients", NIntNull(txtMaxClients.Text)))
            p.Add(New SqlParameter("@MaxDocuments", NIntNull(txtMaxDocuments.Text)))
            p.Add(New SqlParameter("@MaxStorageMB", NIntNull(txtMaxStorageMB.Text)))
            p.Add(New SqlParameter("@Features", Nz(txtFeatures.Text)))
            p.Add(New SqlParameter("@DisplayOrder", NInt(txtDisplayOrder.Text, 0)))
            p.Add(New SqlParameter("@IsRecommended", cbRecommended.Checked))
            p.Add(New SqlParameter("@IsActive", cbActive.Checked))
            p.Add(New SqlParameter("@Tagline", Nz(txtTagline.Text)))
            p.Add(New SqlParameter("@EmployeeRange", Nz(txtEmployeeRange.Text)))
            p.Add(New SqlParameter("@BadgeText", Nz(txtBadgeText.Text)))
            p.Add(New SqlParameter("@ModifiedBy", UserEmail))

            Dim outNew As New SqlParameter("@NewId", SqlDbType.Int)
            outNew.Direction = ParameterDirection.Output
            p.Add(outNew)

            ExecuteSQL("s0634SavePlan", p)

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        If id <= 0 Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", UserEmail))
        ExecuteSQL("s0635DeletePlan", p)

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
            "if (typeof closeWin === 'function') closeWin();", True)
    End Sub

    ' ---------------------------------------------------------------------
    ' Helpers
    ' ---------------------------------------------------------------------
    Private Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    ''' <summary>Retourne la valeur ou DBNull si vide (pour params NVARCHAR).</summary>
    Private Function Nz(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    ''' <summary>Entier avec valeur par défaut si vide/invalide.</summary>
    Private Function NInt(s As String, def As Integer) As Integer
        Dim v As Integer
        If Integer.TryParse(s.Trim(), v) Then Return v
        Return def
    End Function

    ''' <summary>Entier nullable : DBNull si vide.</summary>
    Private Function NIntNull(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Dim v As Integer
        If Integer.TryParse(s.Trim(), v) Then Return v
        Return DBNull.Value
    End Function

    ''' <summary>Parse décimal tolérant (virgule ou point).</summary>
    Private Function TryParseDecimal(s As String, ByRef result As Decimal) As Boolean
        If String.IsNullOrWhiteSpace(s) Then Return False
        Dim clean As String = s.Trim().Replace(" ", "").Replace(",", ".")
        Return Decimal.TryParse(clean, NumberStyles.Any, CultureInfo.InvariantCulture, result)
    End Function

    Private Sub SetDdl(ddl As DropDownList, value As String)
        ddl.ClearSelection()
        Dim item As ListItem = ddl.Items.FindByValue(value)
        If item IsNot Nothing Then item.Selected = True
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

End Class
