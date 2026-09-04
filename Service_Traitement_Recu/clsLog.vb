Imports System.IO

''' <summary>
''' Journaux fichier du service, ecrits a cote de l'executable. Deux familles :
'''   - Traitement : le deroulement normal (un recu pris, une etape faite)
'''   - Erreur     : ce qui a echoue
''' Chaque fichier est tronque a FileLenghtMax caracteres pour ne jamais grossir
''' indefiniment sur le serveur.
''' </summary>
Public Class clsLog

    Public Const logRunningStatusFile = "RunningStatusFile.txt"
    Public Const logEventFileTraitement = "EventTraitementRecu.txt"
    Public Const logErrorFileTraitement = "ErrorTraitementRecu.txt"

    Public Const FileLenghtMax = 200000

    Public Enum LogType
        Traitement
        Erreur
    End Enum

    ''' <summary>Chemin complet d'un fichier journal, a cote de l'executable.</summary>
    Private Shared Function PathOf(fileName As String) As String
        Return Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & fileName
    End Function

    Private Shared Function FileFor(theLog As LogType) As String
        If theLog = LogType.Erreur Then
            Return PathOf(logErrorFileTraitement)
        Else
            Return PathOf(logEventFileTraitement)
        End If
    End Function

    Private Shared Sub EnsureFile(fullPath As String)
        If Not File.Exists(fullPath) Then
            Dim f As StreamWriter = File.CreateText(fullPath)
            f.Flush()
            f.Close()
        End If
    End Sub

    ''' <summary>Ecrit l'heure du dernier passage du service (affichee dans l'interface).</summary>
    Public Shared Sub RunningStatus(status As String)
        Try
            Dim p As String = PathOf(logRunningStatusFile)
            EnsureFile(p)
            File.WriteAllText(p, status)
        Catch
        End Try
    End Sub

    Public Shared Function ReadRunningStatus() As String
        Try
            Dim p As String = PathOf(logRunningStatusFile)
            EnsureFile(p)
            Return File.ReadAllText(p)
        Catch
            Return "Jamais"
        End Try
    End Function

    Public Shared Sub EventWritelog(message As String, theLog As LogType)
        Append(message, FileFor(theLog))
    End Sub

    Public Shared Sub ErrorWritelog(message As String, theLog As LogType)
        ' Une erreur va toujours dans le journal d'erreur, quel que soit l'appelant :
        ' c'est le fichier qu'on ouvre en premier quand quelque chose cloche.
        Append(message, PathOf(logErrorFileTraitement))
    End Sub

    Private Shared Sub Append(message As String, fullPath As String)
        Try
            EnsureFile(fullPath)
            Dim txt As String = File.ReadAllText(fullPath)

            If txt.Length > FileLenghtMax Then
                txt = txt.Substring(txt.Length - FileLenghtMax)
            End If

            txt = txt & "TIME OF LOG ENTRY: " & DateTime.Now.ToString() & vbCrLf
            txt = txt & "Message:  " & message & vbCrLf & vbCrLf
            File.WriteAllText(fullPath, txt)
        Catch
            ' Un journal qui ne s'ecrit pas ne doit jamais arreter le traitement.
        End Try
    End Sub

    Public Shared Function EventReadlog(theLog As LogType) As String
        Try
            Dim p As String = FileFor(theLog)
            EnsureFile(p)
            Return File.ReadAllText(p)
        Catch
            Return ""
        End Try
    End Function

    Public Shared Sub ClearLog(theLog As LogType)
        Try
            File.WriteAllText(FileFor(theLog), "")
        Catch
        End Try
    End Sub

    Public Shared Sub ClearAllLog()
        ClearLog(LogType.Traitement)
        ClearLog(LogType.Erreur)
    End Sub

End Class
