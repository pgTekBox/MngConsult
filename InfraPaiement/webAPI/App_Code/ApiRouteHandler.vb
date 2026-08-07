Imports System.Web
Imports System.Web.Routing

''' <summary>
''' Route « api/v1/{*path} » (et le fallback « api/{*path} ») vers ApiHandler,
''' en passant la version et le chemin restant (ex. "clients/5") au handler.
''' </summary>
Public Class ApiRouteHandler
    Implements IRouteHandler

    Private ReadOnly _version As String

    ''' <param name="version">"v1" pour la route versionnée ; "" pour la route
    ''' non versionnée (rétro-compatibilité, traitée comme v1 + dépréciée).</param>
    Public Sub New(version As String)
        _version = If(version, "")
    End Sub

    Public Function GetHttpHandler(requestContext As RequestContext) As IHttpHandler Implements IRouteHandler.GetHttpHandler
        Dim path As String = ""
        If requestContext.RouteData.Values.ContainsKey("path") AndAlso requestContext.RouteData.Values("path") IsNot Nothing Then
            path = requestContext.RouteData.Values("path").ToString()
        End If
        Return New ApiHandler(path, _version)
    End Function

End Class
