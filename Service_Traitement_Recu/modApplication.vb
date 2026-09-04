Imports System.Windows.Forms
Imports nspServiceTraitementRecu.clsLog

''' <summary>
''' Ouverture de l'interface (grilles des reçus et des résultats) hors service.
''' </summary>
Module modApplication

    Public Sub MainApp()
        Try
            Application.EnableVisualStyles()
            Form1.ShowDialog()
        Catch obEx As Exception
            clsLog.ErrorWritelog("Erreur à l'ouverture de l'interface : " & obEx.Message, LogType.Erreur)
            MsgBox(obEx.Message, MsgBoxStyle.Critical)
            End
        End Try
    End Sub

End Module
