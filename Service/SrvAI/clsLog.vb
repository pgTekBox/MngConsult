Imports System.Net
Imports System.Net.Mail
Imports System.IO
Imports System.Text
Imports System.Security
Imports System.Security.Cryptography
Imports System.IO.Compression

Imports System.Reflection
Imports System.Threading
Imports System.Diagnostics.Process
Imports System.Windows
Imports System.Xml
Imports System.Windows.Forms


Public Class clsLog

    Public Const logRunningStatusFile = "RunningStatusFile.txt"
    Public Const logRunningFile = "RunningFile.txt"
    Public Const logEventFile = "EventSMTP.txt"
    Public Const logErrorFile = "ErrorSMTP.txt"
    Public Const CommandFile = "CommandeCopy.txt"
    Public Const FileLenghtMax = 100000

    Public Shared Sub RunningStatus(Status As String)


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logRunningStatusFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If

            File.WriteAllText(pathofApp, Status)


        Catch ex As Exception

        End Try

    End Sub


    Public Shared Function ReadRunningStatus() As String


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logRunningStatusFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If


            Dim MyText As String = File.ReadAllText(pathofApp)

            Return MyText



        Catch ex As Exception
            Return "Jamais"
        End Try

    End Function

    Public Shared Sub ClearAllLog()
        Try
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logRunningFile
            File.WriteAllText(pathofApp, "")

            pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logEventFile
            File.WriteAllText(pathofApp, "")

            pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logErrorFile
            File.WriteAllText(pathofApp, "")



        Catch ex As Exception
            Return
        End Try
    End Sub



    Public Shared Function EventReadlog() As String


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logEventFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            Dim MyText As String = File.ReadAllText(pathofApp)


            Return MyText


        Catch ex As Exception
            Return ""
        End Try

    End Function
    Public Shared Function ReadCommand() As String


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & CommandFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            Dim MyText As String = File.ReadAllText(pathofApp)


            Return MyText


        Catch ex As Exception
            Return ""
        End Try

    End Function
    Public Shared Sub WriteCommand(CommandeMessage As String)


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & CommandFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            File.WriteAllText(pathofApp, CommandeMessage)

        Catch ex As Exception

        End Try

    End Sub

    Public Shared Sub EventWritelog(Message As String)


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logEventFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            Dim MyText As String = File.ReadAllText(pathofApp)


            If MyText.Length > FileLenghtMax Then
                MyText = MyText.Substring(MyText.Length - FileLenghtMax)
            End If
            MyText = MyText & "TIME OF LOG ENTRY: " & DateTime.Now.ToString & vbCrLf
            MyText = MyText & "Message:  " & Message & vbCrLf & vbCrLf
            File.WriteAllText(pathofApp, MyText)


        Catch ex As Exception

        End Try

    End Sub

    Public Shared Sub ErrorWritelog(Message As String)


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logErrorFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            Dim MyText As String = File.ReadAllText(pathofApp)



            If MyText.Length > FileLenghtMax Then
                MyText = MyText.Substring(MyText.Length - FileLenghtMax)
            End If
            MyText = MyText & "TIME OF LOG ENTRY: " & DateTime.Now.ToString & vbCrLf
            MyText = MyText & "Message:  " & Message & vbCrLf & vbCrLf
            File.WriteAllText(pathofApp, MyText)


        Catch ex As Exception

        End Try

    End Sub
    Public Shared Function ErrorReadlog() As String


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & logErrorFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            Dim MyText As String = File.ReadAllText(pathofApp)



            Return MyText


        Catch ex As Exception
            Return ""
        End Try

    End Function
End Class
