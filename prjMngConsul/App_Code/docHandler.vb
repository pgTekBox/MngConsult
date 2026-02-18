Imports System.Drawing
Imports Microsoft.SqlServer.Server

Public Class docHandler
    Implements IHttpHandler

    Public ReadOnly Property IsReusable() As Boolean Implements System.Web.IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(ByVal context As System.Web.HttpContext) Implements System.Web.IHttpHandler.ProcessRequest

        Try


            Dim sFileName As String = ""
            Dim sPath As String = context.Server.MapPath(".")

            sFileName = context.Request.Url.Segments(context.Request.Url.Segments.Length - 1)
            'ImageModel_213'_1_Z.jpg


            If sFileName.Length < 1 Then Return

            Dim arrFileName() As String = sFileName.Split("_")
            Dim MyGUID As String = arrFileName(1)
            Dim arrMyGUID() As String = MyGUID.Split(".")
            MyGUID = arrMyGUID(0)

            Dim oImg As New clsImage

            If arrFileName(0) = "Optimized" Then
                oImg.LoadOptimizedImage(context, sFileName, "", New Guid(MyGUID))
            End If


            If arrFileName(0) = "Voirlerecu" Then
                oImg.LoadImage(context, sFileName, "", New Guid(MyGUID))
            End If






            'Dim MyDuration As Integer = CType(System.Configuration.ConfigurationManager.AppSettings("ImageBrowserCacheDuration"), Integer)


            'If arrFileName.Length = 5 And arrFileName(0).ToUpper = ("ImageSkin").ToUpper Then

            '    Dim sThemeId As String = "ThemeId=" & arrFileName(1)
            '    Dim sImageName As String = "&ImageName=" & arrFileName(2)
            '    'Dim sFormat As String = "&Format=" & arrFileName(3)
            '    Dim sLanguage As String = "&Language=" & Mid(arrFileName(4), 1, InStr(arrFileName(4), ".") - 1)
            '    Dim oImg As New clsImageSkin
            '    context.Response.Cache.SetExpires(DateTime.Now.AddSeconds(MyDuration))
            '    context.Response.Cache.SetCacheability(HttpCacheability.Public)
            '    oImg.LoadByHandler(context, sFileName, arrFileName(1), arrFileName(2), arrFileName(3), Mid(arrFileName(4), 1, InStr(arrFileName(4), ".") - 1))

            'ElseIf arrFileName.Length = 4 And arrFileName(0).ToUpper = ("ImageProduct").ToUpper Then
            '    Dim oImg As New clsProductImageCat
            '    context.Response.Cache.SetExpires(DateTime.Now.AddSeconds(MyDuration))
            '    context.Response.Cache.SetCacheability(HttpCacheability.Public)
            '    oImg.LoadImage(context, sFileName, arrFileName(1), arrFileName(2), Mid(arrFileName(3), 1, InStr(arrFileName(3), ".") - 1))



            'ElseIf arrFileName.Length = 5 And arrFileName(0).ToUpper = ("ImageProduct").ToUpper Then
            '    Dim oImg As New clsModelImageCat
            '    context.Response.Cache.SetExpires(DateTime.Now.AddSeconds(MyDuration))
            '    context.Response.Cache.SetCacheability(HttpCacheability.Public)
            '    'Nouveau format pour tous les image du portail
            '    'ImageProduct_213'_1_80_Z.jpg
            '    iProductId = arrFileName(1)
            '    iLanguage = arrFileName(2)
            '    iScale = arrFileName(3)
            '    sFormat = Mid(arrFileName(4), 1, InStr(arrFileName(4), ".") - 1)
            '    oImg.LoadImage(context, sFileName, "", iProductId, iLanguage, iScale, sFormat)


            'ElseIf arrFileName.Length = 4 And arrFileName(0).ToUpper = ("ImageModel").ToUpper Then
            '    'ImageModel_213'_1_Z.jpg
            '    Dim oImg As New clsModelImageCat
            '    context.Response.Cache.SetExpires(DateTime.Now.AddSeconds(MyDuration))
            '    context.Response.Cache.SetCacheability(HttpCacheability.Public)
            '    oImg.LoadImage(context, sFileName, arrFileName(1), "", arrFileName(2), 0, Mid(arrFileName(3), 1, InStr(arrFileName(3), ".") - 1))



            'ElseIf arrFileName.Length = 5 And arrFileName(0).ToUpper = ("ImageModel").ToUpper Then
            '    'Nouveau format pour tous les image du portail
            '    'ImageModel_213'_1_80_Z.jpg
            '    iModelId = arrFileName(1)
            '    iLanguage = arrFileName(2)
            '    iScale = arrFileName(3)
            '    sFormat = Mid(arrFileName(4), 1, InStr(arrFileName(4), ".") - 1)

            '    Dim oImg As New clsModelImageCat
            '    context.Response.Cache.SetExpires(DateTime.Now.AddSeconds(MyDuration))
            '    context.Response.Cache.SetCacheability(HttpCacheability.Public)
            '    oImg.LoadImage(context, sFileName, iModelId, "", iLanguage, iScale, sFormat)
            'Else
            '    Dim oImg As System.Drawing.Image = System.Drawing.Image.FromFile(sPath & "\" & sFileName, True)
            '    context.Response.Cache.SetExpires(DateTime.Now.AddSeconds(MyDuration))
            '    context.Response.Cache.SetCacheability(HttpCacheability.Public)






            '    If sFileName.ToLower.EndsWith("gif") Then
            '        oImg.Save(context.Response.OutputStream, System.Drawing.Imaging.ImageFormat.Gif)
            '    End If
            '    If sFileName.ToLower.EndsWith("jpg") Then
            '        oImg.Save(context.Response.OutputStream, System.Drawing.Imaging.ImageFormat.Jpeg)
            '    End If
            '    If sFileName.ToLower.EndsWith("png") Then
            '        'oImg.Save(context.Response.OutputStream, System.Drawing.Imaging.ImageFormat.Png)

            '        Dim MemStream As System.IO.MemoryStream = New System.IO.MemoryStream
            '        Dim bitmap As Bitmap = New Bitmap(oImg)
            '        ' set the content type 
            '        context.Response.ContentType = "image/png"
            '        'send the image to the memory stream then output 
            '        bitmap.Save(MemStream, System.Drawing.Imaging.ImageFormat.Png)
            '        MemStream.WriteTo(context.Response.OutputStream)

            '    End If

            'oImg.Dispose()
            'End If
        Catch et As System.Threading.ThreadAbortException


        Catch ex As Exception
            'clsMyError.LogError("ProcessRequest", "clsSkinImageHandler", ex.Message)

        End Try



    End Sub
End Class
