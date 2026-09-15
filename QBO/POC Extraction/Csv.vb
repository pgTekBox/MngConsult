Imports System.Text

''' <summary>
''' Écrit un CSV : UTF-8 avec BOM (Excel reconnaît alors les accents), fins de
''' ligne CRLF, et guillemets autour de toute valeur qui contient le
''' séparateur, un guillemet ou un saut de ligne (RFC 4180).
''' </summary>
Public Module Csv

    Public Sub Ecrire(chemin As String, entetes As IEnumerable(Of String),
                      lignes As IEnumerable(Of IEnumerable(Of String)), separateur As Char)
        Try
            Using w As New StreamWriter(chemin, False, New UTF8Encoding(True))
                w.NewLine = vbCrLf
                w.WriteLine(Ligne(entetes, separateur))
                For Each l In lignes
                    w.WriteLine(Ligne(l, separateur))
                Next
            End Using
        Catch ex As IOException
            Throw New IOException($"Impossible d'écrire « {Path.GetFileName(chemin)} » : le fichier est peut-être ouvert dans Excel. ({ex.Message})", ex)
        End Try
    End Sub

    Private Function Ligne(valeurs As IEnumerable(Of String), separateur As Char) As String
        Return String.Join(separateur, valeurs.Select(Function(v) Champ(v, separateur)))
    End Function

    Private Function Champ(valeur As String, separateur As Char) As String
        If String.IsNullOrEmpty(valeur) Then Return ""
        If valeur.IndexOfAny({separateur, """"c, ControlChars.Cr, ControlChars.Lf}) >= 0 OrElse
           valeur(0) = " "c OrElse valeur(valeur.Length - 1) = " "c Then
            Return """" & valeur.Replace("""", """""") & """"
        End If
        Return valeur
    End Function

End Module
