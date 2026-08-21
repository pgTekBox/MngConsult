Imports System
Imports System.IO
Imports System.Web

''' <summary>
''' Handler PUBLIC : sert l'APK de l'application mobile 60sec-AI.
''' URL : /AppAndroid.ashx
'''
''' Passer par un handler plutôt que par le fichier statique évite d'avoir à
''' déclarer le type MIME .apk dans IIS (sans quoi IIS répond 404) et garantit
''' un nom de fichier propre côté téléphone, quel que soit le nom du build
''' déposé dans ~/android.
'''
''' Aucune authentification : c'est un téléchargement public, appelé depuis la
''' page « Application mobile » du site vitrine.
''' Si aucun APK n'est déposé, on renvoie 404 (la page publique masque de toute
''' façon le bouton dans ce cas — pas de lien mort).
''' </summary>
Public Class AppAndroid
    Implements IHttpHandler

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim path As String = clsAndroidApp.ResolveApkPath()

        If path.Length = 0 OrElse Not File.Exists(path) Then
            context.Response.StatusCode = 404
            context.Response.ContentType = "text/plain; charset=utf-8"
            context.Response.Write("Aucune version Android n'est disponible pour le moment.")
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
        context.Response.ContentType = clsAndroidApp.ContentType
        context.Response.AddHeader("Content-Disposition",
                                   "attachment; filename=""" & clsAndroidApp.PreferredFileName & """")
        context.Response.AddHeader("Content-Length", length.ToString())
        ' L'APK est remplacé à chaque nouvelle version : pas de cache navigateur.
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        context.Response.TransmitFile(path)
    End Sub

End Class
