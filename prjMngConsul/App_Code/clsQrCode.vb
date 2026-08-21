Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.Text
Imports QRCoder

''' <summary>
''' Génération de codes QR côté serveur, rendus en SVG inline.
'''
''' L'encodage (versions, correction d'erreurs Reed-Solomon, masques) est
''' délégué à QRCoder (MIT) ; on ne reprend que la matrice de modules et on
''' dessine nous-mêmes le SVG, pour maîtriser les couleurs et rester
''' indépendant de System.Drawing (pas de bitmap, pas de handler d'image :
''' le code QR part directement dans le HTML de la page).
'''
''' Le SVG est en niveau de correction M (~15 % de redondance), le compromis
''' habituel pour une URL courte affichée à l'écran.
''' </summary>
Public NotInheritable Class clsQrCode

    Private Sub New()
    End Sub

    ''' <summary>
    ''' Rend le contenu passé en paramètre sous forme de SVG inline carré.
    ''' Retourne "" si le texte est vide ou si l'encodage échoue : l'appelant
    ''' doit alors simplement ne rien afficher.
    ''' </summary>
    ''' <param name="text">Contenu encodé (ici : l'URL absolue de l'APK).</param>
    ''' <param name="sizePx">Côté du SVG en pixels.</param>
    ''' <param name="darkHex">Couleur des modules sombres (ex. "#020617").</param>
    ''' <param name="altText">Texte alternatif accessible.</param>
    Public Shared Function BuildSvg(text As String, sizePx As Integer,
                                    darkHex As String, altText As String) As String
        If String.IsNullOrEmpty(text) Then Return ""

        Try
            Using generator As New QRCodeGenerator()
                Using data As QRCodeData = generator.CreateQrCode(text, QRCodeGenerator.ECCLevel.M)
                    Dim rows As List(Of BitArray) = data.ModuleMatrix
                    If rows Is Nothing OrElse rows.Count = 0 Then Return ""
                    Dim n As Integer = rows.Count

                    Dim sb As New StringBuilder()
                    sb.Append("<svg xmlns=""http://www.w3.org/2000/svg"" viewBox=""0 0 ")
                    sb.Append(n).Append(" ").Append(n)
                    sb.Append(""" width=""").Append(sizePx)
                    sb.Append(""" height=""").Append(sizePx)
                    sb.Append(""" shape-rendering=""crispEdges"" role=""img"" aria-label=""")
                    sb.Append(HtmlAttr(altText)).Append(""">")

                    ' Fond blanc : la zone de silence fait partie de la matrice
                    ' retournée par QRCoder, il ne faut donc rien rogner.
                    sb.Append("<rect width=""").Append(n).Append(""" height=""").Append(n)
                    sb.Append(""" fill=""#ffffff""/>")

                    ' Un seul <path> pour tous les modules sombres : les modules
                    ' consécutifs d'une même ligne sont fusionnés en un rectangle,
                    ' ce qui divise nettement la taille du SVG.
                    sb.Append("<path fill=""").Append(darkHex).Append(""" d=""")
                    For y As Integer = 0 To n - 1
                        Dim row As BitArray = rows(y)
                        Dim x As Integer = 0
                        While x < n
                            If row.Get(x) Then
                                Dim runLength As Integer = 1
                                While x + runLength < n AndAlso row.Get(x + runLength)
                                    runLength += 1
                                End While
                                sb.Append("M").Append(x).Append(" ").Append(y)
                                sb.Append("h").Append(runLength).Append("v1h-").Append(runLength).Append("z")
                                x += runLength
                            Else
                                x += 1
                            End If
                        End While
                    Next
                    sb.Append("""/></svg>")

                    Return sb.ToString()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsQrCode.BuildSvg: " & ex.Message)
            Return ""
        End Try
    End Function

    ''' <summary>Échappement minimal pour une valeur d'attribut SVG/HTML.</summary>
    Private Shared Function HtmlAttr(value As String) As String
        If String.IsNullOrEmpty(value) Then Return ""
        Return value.Replace("&", "&amp;").Replace("""", "&quot;").Replace("<", "&lt;").Replace(">", "&gt;")
    End Function

End Class
