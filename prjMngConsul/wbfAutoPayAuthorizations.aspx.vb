Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Page principale de gestion des autorisations d'auto-paiement fournisseurs.
''' Liste les autorisations actives + revoked, permet la revocation.
'''
''' Lors d'une revocation :
'''   1. Appel s0090RevokeAuthorization (soft-delete + annule scheduled)
'''   2. Detach de la PaymentMethod cote Stripe (clsStripe.DetachPaymentMethodFromConnectedAccount)
''' </summary>
Public Class wbfAutoPayAuthorizations
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            LoadStats()
            LoadAuthorizations()
        End If
    End Sub

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadStats()
        LoadAuthorizations()
    End Sub

    Private Sub chkShowRevoked_CheckedChanged(sender As Object, e As EventArgs) Handles chkShowRevoked.CheckedChanged
        LoadAuthorizations()
    End Sub

    ''' <summary>
    ''' Lit les stats globales (compteurs en haut de page).
    ''' </summary>
    Private Sub LoadStats()
        Try
            Dim sql As String =
                "SELECT " &
                "  (SELECT COUNT(*) FROM dbo.T144AuthorizationAutoPay WHERE CompanyGUID=@C AND RevokedDate IS NULL) AS ActiveCount, " &
                "  (SELECT COUNT(*) FROM dbo.T060Document WHERE CompanyGUID=@C AND AutoPay=1 AND AutoPayStatus='PLANIFIE') AS ScheduledCount, " &
                "  (SELECT COUNT(*) FROM dbo.T145AutoPayAttempt WHERE CompanyGUID=@C AND Result='SUCCESS' AND AttemptDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AS SuccessThisMonth, " &
                "  (SELECT ISNULL(SUM(Amount), 0) FROM dbo.T145AutoPayAttempt WHERE CompanyGUID=@C AND Result='SUCCESS' AND AttemptDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AS TotalThisMonth"

            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@C", Company)
                    conn.Open()
                    Using rdr = cmd.ExecuteReader()
                        If rdr.Read() Then
                            litStatActive.Text = rdr("ActiveCount").ToString()
                            litStatScheduled.Text = rdr("ScheduledCount").ToString()
                            litStatSuccess.Text = rdr("SuccessThisMonth").ToString()
                            Dim totalMonth As Decimal = CDec(rdr("TotalThisMonth"))
                            litStatTotalAmount.Text = totalMonth.ToString("N2", New CultureInfo("fr-CA")) & " $"
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LoadStats error : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Charge la liste des autorisations selon le filtre OnlyActive.
    ''' </summary>
    Private Sub LoadAuthorizations()
        Try
            Dim onlyActive As Boolean = Not chkShowRevoked.Checked

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@OnlyActive", If(onlyActive, 1, 0)))
            p.Add(New SqlParameter("@PartyId", DBNull.Value))

            Dim ds As DataSet = ExecuteSQLds("s0096ListAllAuthorizations", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                pnlEmpty.Visible = True
                rptAuth.DataSource = Nothing
                rptAuth.DataBind()
                Return
            End If

            pnlEmpty.Visible = False
            rptAuth.DataSource = ds.Tables(0)
            rptAuth.DataBind()

        Catch ex As Exception
            ShowError("Erreur chargement autorisations : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Clic sur "Revoquer" : appelle s0090 + detach PM Stripe.
    ''' </summary>
    Private Sub rptAuth_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptAuth.ItemCommand
        If e.CommandName <> "Revoke" Then Return

        Dim authId As Integer = 0
        Integer.TryParse(e.CommandArgument.ToString(), authId)
        If authId = 0 Then Return

        RevokeAuthorization(authId)
        LoadStats()
        LoadAuthorizations()
    End Sub

    Private Sub RevokeAuthorization(authId As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@AuthorizationId", authId))
            p.Add(New SqlParameter("@RevokedByUserGUID", UserGUIDValue))
            p.Add(New SqlParameter("@RevokedReason", "Revoquee par l'utilisateur"))

            Dim ds As DataSet = ExecuteSQLds("s0090RevokeAuthorization", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowError("Aucun retour de s0090.")
                Return
            End If

            Dim row As DataRow = ds.Tables(0).Rows(0)
            Dim retCode As Integer = CInt(row("RetCode"))

            If retCode <> 0 Then
                ShowError("Echec revocation : " & row("ErrorMessage").ToString())
                Return
            End If

            ' Detach PaymentMethod cote Stripe (best-effort, non-bloquant)
            Try
                Dim pmId As String = If(row("StripePaymentMethodId") Is DBNull.Value, "", row("StripePaymentMethodId").ToString())
                Dim acctId As String = If(row("StripeAccountId") Is DBNull.Value, "", row("StripeAccountId").ToString())
                If Not String.IsNullOrEmpty(pmId) AndAlso Not String.IsNullOrEmpty(acctId) Then
                    clsStripe.DetachPaymentMethodFromConnectedAccount(pmId, acctId)
                End If
            Catch detachEx As Exception
                System.Diagnostics.Debug.WriteLine("Detach PM failed (non-blocking) : " & detachEx.Message)
            End Try

            Dim cancelCount As Integer = CInt(row("CancelledScheduledCount"))
            ShowSuccess("Autorisation revoquee. " & cancelCount.ToString() & " paiement(s) programme(s) annule(s).")

        Catch ex As Exception
            ShowError("Erreur revocation : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Recupere l'UserGUID de l'utilisateur courant.
    ''' </summary>
    Private ReadOnly Property UserGUIDValue As Guid
        Get
            Try
                If Session("UserGUID") IsNot Nothing Then Return CType(Session("UserGUID"), Guid)
            Catch
            End Try
            ' Fallback : lookup BD
            Try
                Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                    Using cmd As New SqlCommand("SELECT UserGUID FROM T015User WHERE Id = @Id", conn)
                        cmd.Parameters.AddWithValue("@Id", UserId)
                        conn.Open()
                        Dim r = cmd.ExecuteScalar()
                        If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CType(r, Guid)
                    End Using
                End Using
            Catch
            End Try
            Return Guid.Empty
        End Get
    End Property

    ' =========================================================================
    ' Helpers de rendu (appeles depuis le markup)
    ' =========================================================================

    Public Function RenderMethodBadge(methodType As Object, cardBrand As Object, cardLast4 As Object, bankLast4 As Object) As String
        Dim t As String = If(methodType, "").ToString()
        If t = "card" Then
            Dim brand As String = If(cardBrand Is DBNull.Value OrElse cardBrand Is Nothing, "Carte", cardBrand.ToString())
            Dim last4 As String = If(cardLast4 Is DBNull.Value OrElse cardLast4 Is Nothing, "????", cardLast4.ToString())
            Return "<span class='badge-method-card'>" & Server.HtmlEncode(brand.ToUpper()) & "</span> se terminant par " & Server.HtmlEncode(last4)
        ElseIf t = "acss_debit" Then
            Dim last4 As String = If(bankLast4 Is DBNull.Value OrElse bankLast4 Is Nothing, "????", bankLast4.ToString())
            Return "<span class='badge-method-acss'>ACSS DEBIT</span> compte se terminant par " & Server.HtmlEncode(last4)
        Else
            Return Server.HtmlEncode(t)
        End If
    End Function

    Public Function FormatMoneyOrEmpty(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Try
            Dim d As Decimal = Convert.ToDecimal(value)
            Return d.ToString("N2", New CultureInfo("fr-CA")) & " $"
        Catch
            Return ""
        End Try
    End Function

    Public Function FormatDate(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Try
            Return CDate(value).ToString("yyyy-MM-dd")
        Catch
            Return ""
        End Try
    End Function

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
