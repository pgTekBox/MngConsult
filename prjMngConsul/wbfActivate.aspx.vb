Imports System.Data
Imports System.Data.SqlClient

Public Class wbfActivate
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        Dim tokenStr As String = Request.QueryString("token")
        Dim token As Guid

        If String.IsNullOrEmpty(tokenStr) OrElse Not Guid.TryParse(tokenStr, token) Then
            ShowInvalid()
            Return
        End If

        ActivateAccount(token)
    End Sub

    Private Sub ActivateAccount(token As Guid)

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Token", token))

            Dim ds As DataSet = ExecuteSQLds("s0221ActivateUser", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowInvalid()
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)

            Dim result As Integer = If(r("Result") Is DBNull.Value, 0, CInt(r("Result")))

            Select Case result

                Case 1   ' Activation OK
                    Dim userId As Integer = CInt(r("UserId"))
                    Dim email As String = If(r("Email") Is DBNull.Value, "", r("Email").ToString())

                    LoadUserSession(userId)

                    litEmail.Text = email
                    ShowSuccess()

                Case -1
                    ShowExpired()

                Case -2
                    ShowAlreadyActivated()

                Case Else
                    ShowInvalid()
            End Select

        Catch
            ShowInvalid()
        End Try
    End Sub

    ''' <summary>
    ''' Charge les infos du user dans la session (auto-login après activation).
    ''' Utilise la stored procedure s0223GetUserSessionInfo.
    ''' </summary>
    Private Sub LoadUserSession(userId As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", userId))

            Dim ds As DataSet = ExecuteSQLds("s0223GetUserSessionInfo", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)

            Session("UserId") = CInt(r("Id"))
            Session("UserEmail") = If(r("Email") Is DBNull.Value, "", r("Email").ToString())
            Session("UserFirstName") = If(r("FirstName") Is DBNull.Value, "", r("FirstName").ToString())
            Session("UserLastName") = If(r("LastName") Is DBNull.Value, "", r("LastName").ToString())
            Session("IsAdmin") = (Not r("IsAdmin") Is DBNull.Value) AndAlso CBool(r("IsAdmin"))
            Session("IsAccountant") = (Not r("IsAccountant") Is DBNull.Value) AndAlso CBool(r("IsAccountant"))
            Session("CompanyGUID") = CType(r("CompanyGUID"), Guid)
            Session("CompanyName") = If(r("CompanyName") Is DBNull.Value, "", r("CompanyName").ToString())

        Catch
            ' Si le chargement échoue, l'utilisateur devra se connecter manuellement
        End Try
    End Sub

    Private Sub ShowSuccess()
        pnlSuccess.Visible = True
    End Sub

    Private Sub ShowExpired()
        pnlExpired.Visible = True
    End Sub

    Private Sub ShowAlreadyActivated()
        pnlAlready.Visible = True
    End Sub

    Private Sub ShowInvalid()
        pnlInvalid.Visible = True
    End Sub

End Class
