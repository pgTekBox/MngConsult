Imports System.Web.Optimization
Imports QuestPDF.Infrastructure

Public Class Global_asax
    Inherits HttpApplication

    Sub Application_Start(sender As Object, e As EventArgs)
        ' Se déclenche lorsque l'application est démarrée
        QuestPDF.Settings.License = LicenseType.Community
        RouteConfig.RegisterRoutes(RouteTable.Routes)
        BundleConfig.RegisterBundles(BundleTable.Bundles)
    End Sub

    ''' <summary>
    ''' « Se souvenir de moi » : si la session n'est pas authentifiée mais qu'un
    ''' cookie persistant valide est présent, restaure la session avant que les
    ''' pages ne redirigent vers le login. La Session est disponible ici.
    ''' </summary>
    Sub Application_AcquireRequestState(sender As Object, e As EventArgs)
        Dim ctx As System.Web.HttpContext = System.Web.HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session Is Nothing Then Return

        ' Déjà connecté : rien à faire.
        Dim cur As Object = ctx.Session("UserId")
        If cur IsNot Nothing AndAlso Convert.ToInt32(cur) <> 0 Then Return

        ' Pas de cookie « souviens-toi de moi » : éviter tout accès BD inutile.
        If ctx.Request.Cookies(clsRememberMe.CookieName) Is Nothing Then Return

        clsRememberMe.TryRestore(ctx)
    End Sub
End Class