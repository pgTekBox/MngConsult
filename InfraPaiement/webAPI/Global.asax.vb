Imports System.Web
Imports System.Web.Routing

Public Class Global_asax
    Inherits HttpApplication

    Sub Application_Start(sender As Object, e As EventArgs)
        ' Route versionnée (canonique) — enregistrée en premier.
        RouteTable.Routes.Add(New Route("api/v1/{*path}", New ApiRouteHandler("v1")))
        ' Fallback non versionné : rétro-compatibilité (traité comme v1, déprécié).
        RouteTable.Routes.Add(New Route("api/{*path}", New ApiRouteHandler("")))
    End Sub

End Class
