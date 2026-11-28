Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Optimization
Imports System.Web.Security

Public Class Global_asax
    Inherits HttpApplication

    Sub Application_Start(sender As Object, e As EventArgs)
        ' Fires when the application is started
        RouteConfig.RegisterRoutes(RouteTable.Routes)
        BundleConfig.RegisterBundles(BundleTable.Bundles)
    End Sub

    ''' <summary>
    ''' « Se souvenir de moi » (wbfLogin) : le cookie Forms persistant survit à la
    ''' session ASP.NET (120 min). Quand la session est vide mais que l'administrateur
    ''' est authentifié par ce cookie, on recharge AdminId / AdminEmail depuis la base
    ''' (s0640GetAdminByEmail). Compte introuvable ou désactivé : déconnexion et retour
    ''' à la page de connexion.
    ''' </summary>
    Sub Application_AcquireRequestState(sender As Object, e As EventArgs)
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session Is Nothing Then Return
        If ctx.User Is Nothing OrElse ctx.User.Identity Is Nothing OrElse Not ctx.User.Identity.IsAuthenticated Then Return
        If ctx.Session("AdminId") IsNot Nothing Then Return

        Dim email As String = If(ctx.User.Identity.Name, "").Trim().ToLowerInvariant()
        If email = "" Then Return

        Dim id As Integer = 0
        Dim courriel As String = ""
        Try
            Using cn As New SqlConnection(System.Configuration.ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0640GetAdminByEmail", cn) With {.CommandType = CommandType.StoredProcedure}
                    cmd.Parameters.Add(New SqlParameter("@Email", email))
                    cn.Open()
                    Using rd As SqlDataReader = cmd.ExecuteReader()
                        If rd.Read() Then
                            Dim actif As Boolean = Not IsDBNull(rd("IsActive")) AndAlso CBool(rd("IsActive"))
                            If actif Then
                                id = CInt(rd("Id"))
                                courriel = rd("Email").ToString()
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Reprise de session admin : " & ex.Message)
            Return
        End Try

        If id > 0 Then
            ctx.Session("AdminId") = id
            ctx.Session("AdminEmail") = courriel
        Else
            FormsAuthentication.SignOut()
            ctx.Session.Clear()
            FormsAuthentication.RedirectToLoginPage()
            ctx.ApplicationInstance.CompleteRequest()
        End If
    End Sub
End Class
