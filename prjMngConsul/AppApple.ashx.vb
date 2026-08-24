Imports System
Imports System.IO
Imports System.Text
Imports System.Web

''' <summary>
''' Handler PUBLIC : sert la distribution iOS de l'application 60sec-AI.
'''
'''   /AppApple.ashx              -> le paquet .ipa, sous son propre nom
'''   /AppApple.ashx?manifest=1   -> le descripteur d'installation, avec
'''                                  l'URL du paquet réécrite vers ce site
'''
''' iOS n'installe pas un fichier téléchargé : c'est le lien itms-services://
''' de la page publique qui pointe sur le manifeste, et iOS va ensuite
''' chercher le paquet lui-même. Les deux réponses sont donc nécessaires.
'''
''' Aucune authentification : appelé depuis la page « Application mobile ».
''' Si les fichiers ne sont pas déposés, on renvoie 404 (la page masque de
''' toute façon le bouton dans ce cas — pas de lien mort).
''' </summary>
Public Class AppApple
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        If context.Request.QueryString("manifest") = "1" Then
            ServeManifest(context)
        Else
            ServePackage(context)
        End If
    End Sub

    ''' <summary>Renvoie le manifeste, URL du paquet remise à jour.</summary>
    Private Sub ServeManifest(context As HttpContext)
        Dim ipaUrl As String = AbsoluteUrl(context, clsAppleApp.DownloadUrl)
        Dim xml As String = clsAppleApp.BuildManifest(ipaUrl)

        If xml.Length = 0 Then
            NotFound(context)
            Return
        End If

        context.Response.Clear()
        context.Response.ContentType = "text/xml"
        context.Response.ContentEncoding = Encoding.UTF8
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        context.Response.Write(xml)
    End Sub

    ''' <summary>Renvoie le paquet .ipa.</summary>
    Private Sub ServePackage(context As HttpContext)
        Dim path As String = clsAppleApp.ResolveIpaPath()

        If path.Length = 0 OrElse Not File.Exists(path) Then
            NotFound(context)
            Return
        End If

        Dim length As Long
        Try
            length = New FileInfo(path).Length
        Catch ex As Exception
            context.Response.StatusCode = 500
            Return
        End Try

        context.Response.Clear()
        context.Response.Buffer = False
        context.Response.ContentType = clsAppleApp.IpaContentType
        context.Response.AddHeader("Content-Disposition",
                                   "attachment; filename=""" & clsAppleApp.GetFileName() & """")
        context.Response.AddHeader("Content-Length", length.ToString())
        ' Le paquet est remplacé à chaque nouvelle version : pas de cache.
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        context.Response.TransmitFile(path)
    End Sub

    ''' <summary>URL absolue d'une ressource de l'application.</summary>
    Private Shared Function AbsoluteUrl(context As HttpContext, relative As String) As String
        Try
            Dim root As String = VirtualPathUtility.ToAbsolute("~/" & relative)
            Return New Uri(context.Request.Url, root).AbsoluteUri
        Catch ex As Exception
            Return relative
        End Try
    End Function

    Private Shared Sub NotFound(context As HttpContext)
        context.Response.StatusCode = 404
        context.Response.ContentType = "text/plain; charset=utf-8"
        context.Response.Write("Aucune version iOS n'est disponible pour le moment.")
    End Sub

End Class
