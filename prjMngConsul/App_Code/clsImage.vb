Imports System.IO
Imports System.Data.SqlClient
Imports System.Data
Imports System.Drawing



Public Class clsImage
    Inherits clsData

    Structure CacheImage

        Public ContentType As String
        Public AppendHeader As String
        Public FormatImage As String
        Public Binary() As Byte
    End Structure

    Function CacheExist(ByVal CacheName As String) As Boolean
        If Cache.Item(CacheName) Is Nothing Then
            Return False
        Else
            Return True
        End If
    End Function



    Public Sub LoadOptimizedImage(ByVal oContext As System.Web.HttpContext, ByVal ImageName As String, ByVal FormatImage As String, ByVal ImgGUID As Guid)
        Dim MyCon As New SqlConnection(Me.ConnectionString)
        Try

            Dim CacheName As String = ImageName & FormatImage

            'If CacheExist(CacheName) Then
            '    Dim MyCache As CacheImage = Cache.Item(CacheName)
            '    Response.Cache.SetExpires(DateTime.Now.AddDays(1))
            '    Response.Cache.SetCacheability(HttpCacheability.Public)
            '    Response.ContentType = MyCache.ContentType
            '    Response.AppendHeader("content-disposition", MyCache.AppendHeader)
            '    Response.BinaryWrite(MyCache.Binary)
            '    Response.End()
            '    Return
            'End If

            Dim MyParam As New Collection
            MyParam.Add(New Data.SqlClient.SqlParameter("@imageGUID", ImgGUID))
            Dim ds As DataSet = Me.ExecuteSQLds("s0005GetOptimizedImage", MyParam)
            oContext.Response.ContentType = ds.Tables(0)(0)("ContentType").ToString()
            Dim arrimg() As Byte = FaitFormatTimbre(CType(ds.Tables(0)(0)("ImageForAI"), Byte()), "F")
            oContext.Response.AppendHeader("content-disposition", "attachment; filename=" & ds.Tables(0)(0)("FileName").ToString())
            oContext.Response.BinaryWrite(arrimg)
            oContext.Response.End()


            ''    If Not IsDBNull(oDr("ContentType")) Then
            ''        Dim arrimg() As Byte = FaitFormatTimbre(CType(oDr("Image"), Byte()), FormatImage)
            ''        Dim MyCache As New CacheImage
            ''        MyCache.ContentType = oDr("ContentType").ToString()
            ''        MyCache.AppendHeader = "attachment; filename=" & oDr("FileName").ToString()
            ''        MyCache.Binary = arrimg
            ''        Cache.Add(CacheName, MyCache, Nothing, DateTime.Now.AddHours(24), TimeSpan.Zero, System.Web.Caching.CacheItemPriority.High, Nothing)
            ''        Response.ContentType = oDr("ContentType").ToString()
            ''        Response.AppendHeader("content-disposition", "attachment; filename=" & oDr("FileName").ToString())
            ''        Response.BinaryWrite(arrimg)
            ''        oDr.Close()
            ''        MyCon.Close()
            ''        Response.End()
            ''        Return
            ''    End If
            ''End If
            ''oDr.Close()
            'MyCon.Close() 'Put user code to initialize the page here
            'Response.End()
            Return
        Catch ex As System.Threading.ThreadAbortException
        Catch ex As Exception
            If MyCon.State = ConnectionState.Open Then MyCon.Close()
            'clsMyError.LogError("LoadImage", "clsImageSkin", ex.Message)
            Throw ex
        End Try
    End Sub




    Public Sub LoadImage(ByVal oContext As System.Web.HttpContext, ByVal ImageName As String, ByVal FormatImage As String, ByVal ImgGUID As Guid)
        Dim MyCon As New SqlConnection(Me.ConnectionString)
        Try

            Dim CacheName As String = ImageName & FormatImage

            'If CacheExist(CacheName) Then
            '    Dim MyCache As CacheImage = Cache.Item(CacheName)
            '    Response.Cache.SetExpires(DateTime.Now.AddDays(1))
            '    Response.Cache.SetCacheability(HttpCacheability.Public)
            '    Response.ContentType = MyCache.ContentType
            '    Response.AppendHeader("content-disposition", MyCache.AppendHeader)
            '    Response.BinaryWrite(MyCache.Binary)
            '    Response.End()
            '    Return
            'End If

            Dim MyParam As New Collection
            MyParam.Add(New Data.SqlClient.SqlParameter("@imageGUID", ImgGUID))
            Dim ds As DataSet = Me.ExecuteSQLds("s0002GetImage", MyParam)
            oContext.Response.ContentType = ds.Tables(0)(0)("ContentType").ToString()
            Dim arrimg() As Byte = FaitFormatTimbre(CType(ds.Tables(0)(0)("ImageSource"), Byte()), "F")
            oContext.Response.AppendHeader("content-disposition", "attachment; filename=" & ds.Tables(0)(0)("FileName").ToString())
            oContext.Response.BinaryWrite(arrimg)
            oContext.Response.End()


            ''    If Not IsDBNull(oDr("ContentType")) Then
            ''        Dim arrimg() As Byte = FaitFormatTimbre(CType(oDr("Image"), Byte()), FormatImage)
            ''        Dim MyCache As New CacheImage
            ''        MyCache.ContentType = oDr("ContentType").ToString()
            ''        MyCache.AppendHeader = "attachment; filename=" & oDr("FileName").ToString()
            ''        MyCache.Binary = arrimg
            ''        Cache.Add(CacheName, MyCache, Nothing, DateTime.Now.AddHours(24), TimeSpan.Zero, System.Web.Caching.CacheItemPriority.High, Nothing)
            ''        Response.ContentType = oDr("ContentType").ToString()
            ''        Response.AppendHeader("content-disposition", "attachment; filename=" & oDr("FileName").ToString())
            ''        Response.BinaryWrite(arrimg)
            ''        oDr.Close()
            ''        MyCon.Close()
            ''        Response.End()
            ''        Return
            ''    End If
            ''End If
            ''oDr.Close()
            'MyCon.Close() 'Put user code to initialize the page here
            'Response.End()
            Return
        Catch ex As System.Threading.ThreadAbortException
        Catch ex As Exception
            If MyCon.State = ConnectionState.Open Then MyCon.Close()
            'clsMyError.LogError("LoadImage", "clsImageSkin", ex.Message)
            Throw ex
        End Try
    End Sub



    Function FaitFormatTimbre(ByVal BigImagebyte As Byte(), ByVal MyFormatImage As String) As Byte()
        Dim lHauteur As Integer = 1024
        Dim lLargeur As Integer = 1024
        If MyFormatImage.StartsWith("F") Then Return BigImagebyte
        Dim lFacteur As Integer = CType(Mid(MyFormatImage, 2), Integer)
        'If MyFormatImage.StartsWith("T") Then
        '    lHauteur = 1024 / CType(Mid(MyFormatImage, 2), Integer)
        '    lLargeur = 1024 / CType(Mid(MyFormatImage, 2), Integer)
        'End If
        Dim memoBigImage As New MemoryStream(BigImagebyte)

        Dim BigImage As New Bitmap(memoBigImage)
        Dim SmallImage As Bitmap

        lLargeur = CType(BigImage.Width, Double) * (CType(lFacteur, Double) / 100)
        lHauteur = CType(BigImage.Height, Double) * (CType(lFacteur, Double) / 100)


        If lLargeur = 0 Then lLargeur = 1
        If lHauteur = 0 Then lHauteur = 1




        'If (BigImage.Width >= lLargeur) Or (BigImage.Height >= lHauteur) Then
        '    LargeurRatio = CType(BigImage.Width, Double) / CType(lLargeur, Double)
        '    HauteurRatio = CType(BigImage.Height, Double) / CType(lHauteur, Double)

        '    If LargeurRatio = HauteurRatio Then
        SmallImage = CType(BigImage.GetThumbnailImage(lLargeur, lHauteur, Nothing, IntPtr.Zero), Bitmap)
        '    ElseIf LargeurRatio > HauteurRatio Then
        '        SmallImage = CType(BigImage.GetThumbnailImage(lLargeur, BigImage.Height / LargeurRatio, Nothing, IntPtr.Zero), Bitmap)
        '    ElseIf LargeurRatio < HauteurRatio Then
        '        SmallImage = CType(BigImage.GetThumbnailImage(BigImage.Width / HauteurRatio, lHauteur, Nothing, IntPtr.Zero), Bitmap)
        '    End If
        'Else
        '    SmallImage = BigImage
        'End If

        Dim MemoSmallImage As MemoryStream = New MemoryStream

        SmallImage.Save(MemoSmallImage, BigImage.RawFormat)
        Return MemoSmallImage.ToArray
    End Function


End Class
