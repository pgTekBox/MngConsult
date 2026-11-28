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
    ''' « Se souvenir de moi » (wbfLogin, clsAdminRememberMe) : si la requête n'est pas
    ''' authentifiée (cookie Forms de session disparu à la fermeture du navigateur)
    ''' mais porte le cookie mémorisé, on le valide en base et on reconnecte
    ''' l'administrateur : nouveau cookie Forms de session, et Context.User posé pour
    ''' que cette requête passe le contrôle d'accès (deny users="?"). Seulement pour
    ''' les pages (pas les .css/.js/images), pour limiter les rotations concurrentes.
    ''' </summary>
    Sub Application_PostAuthenticateRequest(sender As Object, e As EventArgs)
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing Then Return
        If ctx.User IsNot Nothing AndAlso ctx.User.Identity IsNot Nothing AndAlso ctx.User.Identity.IsAuthenticated Then Return
        If Not clsAdminRememberMe.HasCookie(ctx) Then Return
        Dim ext As String = System.IO.Path.GetExtension(ctx.Request.Path).ToLowerInvariant()
        If ext <> "" AndAlso ext <> ".aspx" AndAlso ext <> ".ashx" Then Return

        Dim adminId As Integer = 0
        Dim email As String = clsAdminRememberMe.TryRestore(ctx, adminId)
        If email = "" OrElse adminId = 0 Then Return

        FormsAuthentication.SetAuthCookie(email, False)
        Dim ticket As New FormsAuthenticationTicket(email, False, CInt(FormsAuthentication.Timeout.TotalMinutes))
        ctx.User = New System.Security.Principal.GenericPrincipal(New FormsIdentity(ticket), New String() {})
    End Sub

    ''' <summary>
    ''' Le cookie Forms (de session, ou reposé par la reprise ci-dessus) survit à la
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
