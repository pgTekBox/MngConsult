Imports System.Web

Public Class Global_asax
    Inherits HttpApplication

    Sub Application_Start(sender As Object, e As EventArgs)
        ' Demarrage de l'application PortailABN.
    End Sub

    ''' <summary>
    ''' Restaure la session depuis le cookie « Se souvenir de moi » avant que
    ''' les pages protegees ne redirigent vers la connexion. Ne fait rien si
    ''' l'utilisateur est deja authentifie ou si aucun cookie valide n'existe.
    ''' </summary>
    Sub Application_AcquireRequestState(sender As Object, e As EventArgs)
        Try
            clsRememberMe.TryRestore(HttpContext.Current)
        Catch
            ' Non bloquant : en cas d'echec, l'utilisateur passe simplement par le login.
        End Try
    End Sub

End Class
