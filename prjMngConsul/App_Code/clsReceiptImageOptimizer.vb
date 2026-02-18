
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Drawing.Imaging
Imports System.IO
Imports System.Linq


Public Class clsReceiptImageOptimizer

    Public Function OptimizeReceiptForAI(inputJpegBytes As Byte(),
                                         Optional maxWidth As Integer = 1024,
                                         Optional jpegQuality As Long = 55,
                                         Optional autoContrast As Boolean = True,
                                         Optional toGrayscale As Boolean = True) As Byte()

        If inputJpegBytes Is Nothing OrElse inputJpegBytes.Length = 0 Then
            Return Array.Empty(Of Byte)()
        End If

        Using msIn As New MemoryStream(inputJpegBytes)
            Using srcImg As Image = Image.FromStream(msIn)

                ' 1) Resize (gros gain)
                Dim scale As Double = 1.0
                If srcImg.Width > maxWidth AndAlso maxWidth > 0 Then
                    scale = maxWidth / CDbl(srcImg.Width)
                End If

                Dim newW As Integer = CInt(Math.Round(srcImg.Width * scale))
                Dim newH As Integer = CInt(Math.Round(srcImg.Height * scale))
                If newW < 1 Then newW = 1
                If newH < 1 Then newH = 1

                Using resized As New Bitmap(newW, newH, PixelFormat.Format24bppRgb)
                    resized.SetResolution(96, 96)

                    Using g As Graphics = Graphics.FromImage(resized)
                        g.CompositingMode = CompositingMode.SourceCopy
                        g.CompositingQuality = CompositingQuality.HighQuality
                        g.SmoothingMode = SmoothingMode.HighQuality
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic
                        g.PixelOffsetMode = PixelOffsetMode.HighQuality

                        Using ia As New ImageAttributes()
                            ia.SetWrapMode(WrapMode.TileFlipXY)

                            If toGrayscale Then
                                ia.SetColorMatrix(GetGrayMatrix())
                            End If

                            g.DrawImage(srcImg,
                                        New Rectangle(0, 0, newW, newH),
                                        0, 0, srcImg.Width, srcImg.Height,
                                        GraphicsUnit.Pixel,
                                        ia)
                        End Using
                    End Using

                    ' 2) Auto-contrast léger (optionnel mais utile pour OCR)
                    If autoContrast Then
                        ApplyAutoContrastInPlace(resized)
                    End If

                    ' 3) Save JPEG compressé
                    Return SaveAsJpegBytes(resized, jpegQuality)

                End Using
            End Using
        End Using
    End Function

    ' --- Helpers ---

    Private Function SaveAsJpegBytes(bmp As Bitmap, quality As Long) As Byte()
        Dim q As Long = Math.Max(20, Math.Min(95, quality))

        Dim jpgEncoder = ImageCodecInfo.GetImageEncoders().
            First(Function(c) c.FormatID = ImageFormat.Jpeg.Guid)

        Using msOut As New MemoryStream()
            Using ep As New EncoderParameters(1)
                ep.Param(0) = New EncoderParameter(Encoder.Quality, q)
                bmp.Save(msOut, jpgEncoder, ep)
            End Using
            Return msOut.ToArray()
        End Using
    End Function

    Private Function GetGrayMatrix() As ColorMatrix
        ' Standard luminance grayscale
        Return New ColorMatrix(New Single()() {
            New Single() {0.299F, 0.299F, 0.299F, 0, 0},
            New Single() {0.587F, 0.587F, 0.587F, 0, 0},
            New Single() {0.114F, 0.114F, 0.114F, 0, 0},
            New Single() {0, 0, 0, 1, 0},
            New Single() {0, 0, 0, 0, 1}
        })
    End Function

    Private Sub ApplyAutoContrastInPlace(bmp As Bitmap)
        ' Auto-contrast simple: étire les niveaux en 24bpp (rapide, bon pour reçus)
        Dim rect As New Rectangle(0, 0, bmp.Width, bmp.Height)
        Dim data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb)

        Try
            Dim stride = data.Stride
            Dim bytes = Math.Abs(stride) * bmp.Height
            Dim buf(bytes - 1) As Byte
            Runtime.InteropServices.Marshal.Copy(data.Scan0, buf, 0, bytes)

            Dim minV As Integer = 255
            Dim maxV As Integer = 0

            ' Comme on est en grayscale (souvent), R=G=B, on lit un canal.
            For i = 0 To buf.Length - 1 Step 3
                Dim v = CInt(buf(i)) ' B
                If v < minV Then minV = v
                If v > maxV Then maxV = v
            Next

            ' Évite division par zéro / image déjà plate
            If maxV <= minV + 5 Then Return

            Dim scale As Double = 255.0 / (maxV - minV)

            For i = 0 To buf.Length - 1 Step 3
                Dim v = CInt(buf(i))
                Dim nv = CInt((v - minV) * scale)
                If nv < 0 Then nv = 0
                If nv > 255 Then nv = 255
                Dim b As Byte = CByte(nv)
                buf(i) = b       ' B
                If i + 1 < buf.Length Then

                    buf(i + 1) = b   ' G
                End If
                If i + 2 < buf.Length Then
                    buf(i + 2) = b   ' R
                End If

            Next

            Runtime.InteropServices.Marshal.Copy(buf, 0, data.Scan0, bytes)
        Finally
            bmp.UnlockBits(data)
        End Try
    End Sub
End Class
