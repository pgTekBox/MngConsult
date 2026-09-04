
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

    ''' <summary>
    ''' Réduit une photo destinée à un envoi par courriel : couleur conservée,
    ''' contrainte sur le plus grand côté, ré-encodage JPEG. Contrairement à
    ''' OptimizeReceiptForAI, qui vise l'OCR (niveaux de gris, contraste forcé),
    ''' celle-ci vise un rendu fidèle chez le destinataire.
    '''
    ''' L'orientation EXIF est appliquée aux pixels avant le redimensionnement,
    ''' puis abandonnée avec le reste des métadonnées : sans cela, une photo de
    ''' téléphone prise en portrait arriverait couchée, l'étiquette qui la
    ''' redressait ayant disparu au ré-encodage.
    '''
    ''' Ne renvoie jamais Nothing ni un résultat plus lourd que l'entrée : si
    ''' l'image est illisible, d'un format non géré, ou déjà plus légère que ce
    ''' qu'on produirait, les octets d'origine sont retournés tels quels.
    ''' </summary>
    ''' <param name="maxLongEdge">Plus grand côté en pixels ; 0 = pas de redimensionnement.</param>
    ''' <param name="jpegQuality">Qualité JPEG 20-95 (bornée par SaveAsJpegBytes).</param>
    Public Function OptimizeForEmail(inputBytes As Byte(),
                                     Optional maxLongEdge As Integer = 1600,
                                     Optional jpegQuality As Long = 80) As Byte()

        If inputBytes Is Nothing OrElse inputBytes.Length = 0 Then Return inputBytes

        Try
            Using msIn As New MemoryStream(inputBytes)
                Using srcImg As Image = Image.FromStream(msIn)

                    ApplyExifOrientation(srcImg)

                    ' On contraint le plus grand côté (et non la largeur seule) :
                    ' une photo portrait resterait sinon très haute.
                    Dim longEdge As Integer = Math.Max(srcImg.Width, srcImg.Height)
                    Dim scale As Double = 1.0
                    If maxLongEdge > 0 AndAlso longEdge > maxLongEdge Then
                        scale = maxLongEdge / CDbl(longEdge)
                    End If

                    Dim newW As Integer = Math.Max(1, CInt(Math.Round(srcImg.Width * scale)))
                    Dim newH As Integer = Math.Max(1, CInt(Math.Round(srcImg.Height * scale)))

                    Using resized As New Bitmap(newW, newH, PixelFormat.Format24bppRgb)
                        resized.SetResolution(96, 96)

                        Using g As Graphics = Graphics.FromImage(resized)
                            g.CompositingQuality = CompositingQuality.HighQuality
                            g.SmoothingMode = SmoothingMode.HighQuality
                            g.InterpolationMode = InterpolationMode.HighQualityBicubic
                            g.PixelOffsetMode = PixelOffsetMode.HighQuality

                            Using ia As New ImageAttributes()
                                ia.SetWrapMode(WrapMode.TileFlipXY)  ' évite le liseré sur les bords
                                g.DrawImage(srcImg,
                                            New Rectangle(0, 0, newW, newH),
                                            0, 0, srcImg.Width, srcImg.Height,
                                            GraphicsUnit.Pixel, ia)
                            End Using
                        End Using

                        Dim out As Byte() = SaveAsJpegBytes(resized, jpegQuality)
                        If out Is Nothing OrElse out.Length = 0 OrElse out.Length >= inputBytes.Length Then
                            Return inputBytes
                        End If
                        Return out
                    End Using
                End Using
            End Using

        Catch
            ' Format non géré ou fichier corrompu : mieux vaut joindre l'original
            ' que perdre la pièce jointe.
            Return inputBytes
        End Try
    End Function

    ' --- Helpers ---

    Private Const ExifOrientationId As Integer = &H112   ' 274

    ''' <summary>Applique l'orientation EXIF aux pixels puis retire l'étiquette.</summary>
    Private Sub ApplyExifOrientation(img As Image)
        Try
            If Not img.PropertyIdList.Contains(ExifOrientationId) Then Return

            Dim prop As PropertyItem = img.GetPropertyItem(ExifOrientationId)
            If prop Is Nothing OrElse prop.Value Is Nothing OrElse prop.Value.Length < 2 Then Return

            Select Case CInt(BitConverter.ToUInt16(prop.Value, 0))
                Case 2 : img.RotateFlip(RotateFlipType.RotateNoneFlipX)
                Case 3 : img.RotateFlip(RotateFlipType.Rotate180FlipNone)
                Case 4 : img.RotateFlip(RotateFlipType.Rotate180FlipX)
                Case 5 : img.RotateFlip(RotateFlipType.Rotate90FlipX)
                Case 6 : img.RotateFlip(RotateFlipType.Rotate90FlipNone)
                Case 7 : img.RotateFlip(RotateFlipType.Rotate270FlipX)
                Case 8 : img.RotateFlip(RotateFlipType.Rotate270FlipNone)
            End Select

            img.RemovePropertyItem(ExifOrientationId)
        Catch
            ' Pas d'EXIF exploitable : on garde l'image telle quelle.
        End Try
    End Sub

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
