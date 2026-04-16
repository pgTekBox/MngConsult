
Imports System.Text

Imports System
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Configuration.Install
Imports System.Linq
Imports System.ServiceProcess
Imports System.Windows.Forms
Imports System.Threading



Module modApplication




    Public Sub MainApp()
        Try



            Form1.ShowDialog()


        Catch obEx As Exception
            Dim myLog As New EventLog()
            myLog.Source = tkbService.TkbDisplayName

            '    ' Write an informational entry to the event log.    
            myLog.WriteEntry("1 - Erreur du controleur: " & tkbService.TkbDisplayName & vbCrLf & obEx.Message, EventLogEntryType.Error)



            MsgBox(obEx.Message.ToString, MsgBoxStyle.Critical)
            End
        End Try
    End Sub

End Module
