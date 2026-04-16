Imports System.Net
Imports System.Net.Mail
Imports system.Data.SqlClient
Imports System
Imports System.Windows.Forms
Imports System.Reflection
Imports System.Runtime.InteropServices


Imports System.IO.Pipes


Imports System.Threading
Imports System.IO
Imports System.Diagnostics.Process
Imports System.Windows
Imports System.Xml
Imports System.ComponentModel

Public Class Form1
    Private PipeClientThread As Thread
    Dim oThreadState As New clsThreadState
    Dim ConnectionString As String = ""
    Dim UseDatabase As String = ""

    Dim pipeClient As NamedPipeClientStream



    Function Version() As String

        Return "1.1.20"
    End Function
    Function Display() As String
        With System.Diagnostics.FileVersionInfo.GetVersionInfo(System.Reflection.Assembly.GetExecutingAssembly.Location)
            Return .Comments
        End With
    End Function
    Dim Initmode As Boolean = True
    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Dim oXMLconfig As New clsXmlConfig

        ConnectionString = oXMLconfig.ConnectionString

        UseDatabase = oXMLconfig.UseDatabase


        BindListView()


        StartPipeThread()


        Me.Text = "Service SMTP " & Version()


        'ReadLastRun()


        'GetCount()
        Initmode = False
        Timer1.Enabled = True
    End Sub



    Sub StartPipeThread()
        PipeClientThread = New Thread(AddressOf DoTaskPipeClient)
        PipeClientThread.Name = "SMTP_Pipe_Client"
        PipeClientThread.Start()
        clsLog.EventWritelog("CLIENT: Le Pipe client est démaré.")
    End Sub


    Sub DoTaskPipeClient()


        Dim toClose As Boolean = False
        Dim oclsSMTPStatus As New clsSMTPStatus
        'l'instance oThreadState est defini au niveau du processus et monitor permet de locker cette instance
        Monitor.Enter(oThreadState)
        toClose = oThreadState.StateStop
        Monitor.Exit(oThreadState)

        Do Until toClose = True
            Monitor.Enter(oThreadState)
            toClose = oThreadState.StateStop
            Monitor.Exit(oThreadState)

            'Creation du Pipe client
            pipeClient = New NamedPipeClientStream(".", "tekboxpipe", PipeDirection.In, PipeOptions.None)

            ' Connect to the pipe or wait until the pipe is available.
            'clsLog.EventWritelog("CLIENT: Attempting to connect to the pipe server...")
            Try

                'ici on connect sur le Pipe Server et on Timeout de 1000, le serveur doit repondre si non bug
                pipeClient.Connect(1000)
                'clsLog.EventWritelog("CLIENT: Connection au server pipe...")
                'Lecture du stream 
                Dim sr As New StreamReader(pipeClient)
                Dim sStatutString As String
                sStatutString = sr.ReadLine()
                If sStatutString Is Nothing Then
                    clsLog.EventWritelog("CLIENT: Aucunne données en provenance du serveur Pipe.")
                End If
                'While Not sStatutString Is Nothing
                'Verifie  si on kill le thread
                Monitor.Enter(oThreadState)
                toClose = oThreadState.StateStop
                Monitor.Exit(oThreadState)


                'On restore tout les parametre dans la class de statut
                oclsSMTPStatus.RestoreParam(sStatutString)
                lblCounterEmailInput.Text = oclsSMTPStatus.CounterEmailInput
                lblStatusSMTPStepInput.Text = oclsSMTPStatus.StatusSMTPStepInput
                lblMailSizeInput.Text = oclsSMTPStatus.MailSizeInput
                lblLastRecipient.Text = oclsSMTPStatus.LastRecipient
                lblLastDomainName.Text = oclsSMTPStatus.LastDomainName
                lblThreadSMTPInputStarted.Text = oclsSMTPStatus.ThreadSMTPInputStarted
                lblThreadSMTPLastReceived.Text = oclsSMTPStatus.ThreadSMTPLastReceived
                lblSMTPClientIP.Text = oclsSMTPStatus.SMTPClientIP


                Select Case oclsSMTPStatus.SMTPStep
                    Case "0"
                        lblSMTPStep.Text = "Le Thread SMTP n'est pas initialisé."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.Transparent

                    Case "1"
                        lblSMTPStep.Text = "Initialisation du Thread SMTP (mode Listen)"
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.Yellow
                    Case "2"
                        lblSMTPStep.Text = "Erreur fatale, le Thread SMTP a été arrêté."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.Red
                    Case "3"
                        lblSMTPStep.Text = "En attente d'une connexion pour la réception d'un courriel..."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.GreenYellow
                    Case "4"
                        lblSMTPStep.Text = "Réception d'une commande protocole SMTP."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.SkyBlue
                    Case "5"
                        lblSMTPStep.Text = "Fin de réception d'un courriel..."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.Transparent
                    Case "6"
                        lblSMTPStep.Text = "Erreur fatale gèré, le Thread SMTP a été arrêté."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.Red
                    Case "7"
                        lblSMTPStep.Text = "Le Thread SMTP a été arrêté."
                        lblSMTPStep.ForeColor = Drawing.Color.Black
                        lblSMTPStep.BackColor = Drawing.Color.Red
                End Select


                Select Case oclsSMTPStatus.SendStep
                    Case "0"
                        lblSendStep.Text = "Le Thread Send Mail n'est pas initialisé."
                        lblSendStep.ForeColor = Drawing.Color.Black
                        lblSendStep.BackColor = Drawing.Color.Transparent

                    Case "1"
                        lblSendStep.Text = "Début du Thread du Send mail"
                        lblSendStep.ForeColor = Drawing.Color.Black
                        lblSendStep.BackColor = Drawing.Color.Yellow

                    Case "2"
                        lblSendStep.Text = "En attente de transmission d'un courriel..."
                        lblSendStep.ForeColor = Drawing.Color.Black
                        lblSendStep.BackColor = Drawing.Color.GreenYellow


                    Case "3"
                        lblSendStep.Text = "Transmission d'un courriel..."
                        lblSendStep.ForeColor = Drawing.Color.Black
                        lblSendStep.BackColor = Drawing.Color.SkyBlue

                    Case "4"
                        lblSendStep.Text = "Courriel transmis..."
                        lblSendStep.ForeColor = Drawing.Color.Black
                        lblSendStep.BackColor = Drawing.Color.GreenYellow
                End Select



                lblNbSendMail.Text = oclsSMTPStatus.CounterEmailSend
                lblSendTo.Text = oclsSMTPStatus.SendTo
                lblSendFrom.Text = oclsSMTPStatus.SendFrom
                lblLastSend.Text = oclsSMTPStatus.LastSend



                'Li le status suivant si dispo
                sStatutString = sr.ReadLine()

                'End While
                pipeClient.Close()

            Catch ex As Exception
                'clsLog.ErrorWritelog("CLIENT: Pipe error reading: " & ex.Message)
                Try
                    pipeClient.Close()
                    pipeClient.Dispose()
                Catch Mex As Exception

                End Try
            End Try
        Loop
        'Le thread sera arrete lorsque la methode sera termine. Join ne tu pas immediatement le thread, il faut que la methode en cours 
        'soit finalise corectement
        PipeClientThread.Join()

    End Sub
    Sub StopPipeThread()
        Try
            pipeClient.Close()
            pipeClient.Dispose()
        Catch ex As Exception

        End Try


        Monitor.Enter(oThreadState)
        oThreadState.StateStop = True
        Monitor.Exit(oThreadState)
        Thread.Sleep(TimeSpan.FromMilliseconds(100))
        If PipeClientThread.ThreadState = ThreadState.Stopped Then
            clsLog.EventWritelog("CLIENT: Le pipe client est arrêté.(ThreadState.Stopped)")

        End If
        clsLog.EventWritelog("Le pipe client est arrêté. (Join)")
        PipeClientThread.Join(TimeSpan.FromMilliseconds(100))

        ' If the thread is still running, abort it.
        If (PipeClientThread.ThreadState And ThreadState.Running) = ThreadState.Running Then
            PipeClientThread.Abort()
            clsLog.EventWritelog("CLIENT: Le pipe client est arrêté.(Abort)")
        End If

    End Sub

    Sub ReadEventFile()
        Dim sText As String = clsTaskMail.EventReadlog
        SetEventLog(sText)


    End Sub

    Sub ReadErrorFile()
        Dim sText As String = clsTaskMail.ErrorReadlog
        SetErrorLog(sText)


    End Sub



    Sub SetEventLog(ByVal sText As String)
        Try


            If txtLogEvent.Text = sText Then Return
            txtLogEvent.Text = sText
            txtLogEvent.SelectionStart = sText.Length
            txtLogEvent.SelectionLength = 1
            txtLogEvent.ScrollToCaret()
        Catch ex As Exception

        End Try
    End Sub

    Sub SetErrorLog(ByVal sText As String)
        Try


            If txtlogError.Text = sText Then Return
            txtlogError.Text = sText
            txtlogError.SelectionStart = sText.Length
            txtlogError.SelectionLength = 1
            txtlogError.ScrollToCaret()
        Catch ex As Exception

        End Try
    End Sub



    Private Sub AjustementToolStripMenuItem_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles AjustementToolStripMenuItem.Click
        Dim oFrmSetting As frmSetting = New frmSetting
        oFrmSetting.ShowDialog()

    End Sub



    Private Sub Button5_Click(sender As System.Object, e As System.EventArgs) Handles btnDelEvents.Click
        Try
            Dim pathofApp As String


            pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logEventFile
            File.WriteAllText(pathofApp, "")




        Catch ex As Exception
            Return
        End Try
        ReadAllFile()
    End Sub
    Sub ReadAllFile()

        ReadErrorFile()


        ReadEventFile()

    End Sub

    Private Sub Timer1_Tick(sender As Object, e As EventArgs) Handles Timer1.Tick
        ReadAllFile()
    End Sub



    Private Sub btnDelError_Click(sender As Object, e As EventArgs) Handles btnDelError.Click
        Try
            Dim pathofApp As String
            pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logErrorFile
            File.WriteAllText(pathofApp, "")
        Catch ex As Exception
            Return
        End Try
    End Sub

    Private Sub Form1_Closing(sender As Object, e As CancelEventArgs) Handles Me.Closing
        Timer1.Enabled = False

        StopPipeThread()
        e.Cancel = False
    End Sub

    Private Sub Button1_Click(sender As Object, e As EventArgs)
        StopPipeThread()
    End Sub

    Private Sub Button2_Click(sender As Object, e As EventArgs)
        StartPipeThread()
    End Sub




    Private Sub Button1_Click_2(sender As Object, e As EventArgs) Handles Button1.Click
        Me.Close()
    End Sub

    Private Sub btnRefresh_Click_1(sender As Object, e As EventArgs) Handles btnRefresh.Click
        BindListView()
    End Sub

    Sub BindDetail(MailId As Integer)




        If MailId = -1 Then
            lblCurrentEmailId.Text = "Aucun"
        Else
            lblCurrentEmailId.Text = MailId

        End If



        Dim MyParse As clsMail



        BindListViewError(MailId)




        txtMail.Text = ReadMail(MailId)
        lblRCPT.Text = ReadRCPT(MailId)
        lblIP.Text = ReadIP(MailId)


        MyParse = New clsMail(lblRCPT.Text, txtMail.Text, lblIP.Text)

        txtHTML.Text = MyParse.HtmlBody
        txtText.Text = MyParse.TextBody
        lblSubject.Text = MyParse.Subject



        lblDomaine.Text = MyParse.DomaineName
        lblIP.Text = MyParse.ClientIP



        lblFrom.Text = MyParse.From
        lblBCC.Text = MyParse.BCC
        lblCC.Text = MyParse.CC
        lblReplyTo.Text = MyParse.ReplyTo
        lblResentBcc.Text = MyParse.ResentBcc
        lblResentCc.Text = MyParse.ResentCc
        lblResentFrom.Text = MyParse.ResentFrom
        lblResentReplyTo.Text = MyParse.ResentReplyTo
        lblResentSender.Text = MyParse.ResentSender
        lblResentTo.Text = MyParse.ResentReplyTo
        lblSender.Text = MyParse.ResentSender
        lblTo.Text = MyParse.To
        lblInReplyTo.Text = MyParse.InReplyTo
        lblImportance.Text = MyParse.Importance
        lblXPriority.Text = MyParse.XPriority
        lblMessageId.Text = MyParse.MessageId
        lblResentMessageId.Text = MyParse.ResentMessageId

        lblErrorParsing.Text = MyParse.ErrorParsing
        dgvAttachment.DataSource = MyParse.Attachment


    End Sub



    Function ReadRCPT(MailId) As String

        Try


            If MailId = -1 Then Return ""

            If UseDatabase <> "1" Then Return ""



            Dim cnn As New SqlClient.SqlConnection
            cnn.ConnectionString = ConnectionString
            Dim comm As SqlCommand
            comm = cnn.CreateCommand()
            comm.CommandType = System.Data.CommandType.Text
            comm.CommandText = "select coalesce(RCPT,'') RCPT from T400Mails  where id =" & MailId.ToString

            Dim MyDA As New SqlDataAdapter
            Dim MyDS As New DataSet
            comm.Connection = cnn
            MyDA.SelectCommand = comm
            MyDA.Fill(MyDS)

            Dim MyRCPT As String = ""
            If MyDS.Tables(0).Rows.Count > 0 Then
                Dim orow As DataRow = MyDS.Tables(0).Rows(0)
                MyRCPT = orow("RCPT")
            End If



            Return MyRCPT
        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in form1.ExecuteSQLds()" & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            MessageBox.Show(SetLog)
            Return ""
        End Try



    End Function
    Function ReadIP(MailId) As String
        Try


            If MailId = -1 Then Return ""
            If UseDatabase <> "1" Then Return ""

            Dim cnn As New SqlClient.SqlConnection
            cnn.ConnectionString = ConnectionString
            Dim comm As SqlCommand
            comm = cnn.CreateCommand()
            comm.CommandType = System.Data.CommandType.Text
            comm.CommandText = "select coalesce(ClientIP,'') ClientIP from T400Mails  where id =" & MailId.ToString

            Dim MyDA As New SqlDataAdapter
            Dim MyDS As New DataSet
            comm.Connection = cnn
            MyDA.SelectCommand = comm
            MyDA.Fill(MyDS)

            Dim MyIP As String = ""
            If MyDS.Tables(0).Rows.Count > 0 Then
                Dim orow As DataRow = MyDS.Tables(0).Rows(0)
                MyIP = orow("ClientIP")
            End If



            Return MyIP

        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in form1.ReadIP()" & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            MessageBox.Show(SetLog)
            Return ""
        End Try
    End Function
    Function ReadMail(MailId) As String
        Try


            If MailId = -1 Then Return ""
            If UseDatabase <> "1" Then Return ""
            Dim cnn As New SqlClient.SqlConnection
            cnn.ConnectionString = ConnectionString
            Dim comm As SqlCommand
            comm = cnn.CreateCommand()
            comm.CommandType = System.Data.CommandType.Text
            comm.CommandText = "select coalesce(Mail,'') Mail from T400Mails  where id =" & MailId.ToString

            Dim MyDA As New SqlDataAdapter
            Dim MyDS As New DataSet
            comm.Connection = cnn
            MyDA.SelectCommand = comm
            MyDA.Fill(MyDS)
            Dim MyMail As String = ""
            If MyDS.Tables(0).Rows.Count > 0 Then
                Dim orow As DataRow = MyDS.Tables(0).Rows(0)
                MyMail = orow("Mail")
            End If



            Return MyMail

        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in form1.ReadMail()" & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            MessageBox.Show(SetLog)
            Return ""
        End Try

    End Function
    Sub BindListView()
        Try


            If UseDatabase <> "1" Then Return
            Dim cnn As New SqlClient.SqlConnection
            cnn.ConnectionString = ConnectionString
            Dim comm As SqlCommand
            comm = cnn.CreateCommand()
            comm.CommandType = System.Data.CommandType.StoredProcedure
            'comm.CommandText = "select top 5000 Id,coalesce(RCPT,'') RCPT,coalesce(ClientIP,'') ClientIP,coalesce(Received,null) Received,coalesce(Sended,null) Sended ,coalesce([To],'') [To],coalesce(tosend,0) tosend ,coalesce(SendWithSuccess,0) SendWithSuccess,SendAt,countResend Retry from T400Mails  where SMTPMail = 1 or coalesce(tosend,0) = 1 order by id desc"
            comm.CommandText = "s4105GetEmailforSMTP"
            comm.Parameters.Add(New SqlParameter("@filtre", SqlDbType.VarChar)).Value = txtFiltre.Text





            Dim MyDA As New SqlDataAdapter
            Dim MyDS As New DataSet
            comm.Connection = cnn
            MyDA.SelectCommand = comm
            MyDA.Fill(MyDS)
            dvListMail.AutoGenerateColumns = False
            dvListMail.DataSource = MyDS.Tables(0)

            dvListMail.Columns("Sended").DefaultCellStyle.Format = "dd/MMM/yyyy hh:mm"
            dvListMail.Columns("Received").DefaultCellStyle.Format = "dd/MMM/yyyy hh:mm"


            If MyDS.Tables(0).Rows.Count = 0 Then
                BindDetail(-1)
            End If

        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in form1.BindListView()" & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            MessageBox.Show(SetLog)

        End Try


    End Sub

    Sub BindListViewError(MailId As Integer)
        Try


            If UseDatabase <> "1" Then Return
            Dim cnn As New SqlClient.SqlConnection
            cnn.ConnectionString = ConnectionString
            Dim comm As SqlCommand
            comm = cnn.CreateCommand()
            comm.CommandType = System.Data.CommandType.Text
            comm.CommandText = "select top 1000 Id,MailId, coalesce([To],'') [To],coalesce(ErrorMessage,'') ErrorMessage,  Created dCreated  from T403SendErrorMessage  where MailId=" & MailId.ToString & " order by id desc"

            Dim MyDA As New SqlDataAdapter
            Dim MyDS As New DataSet
            comm.Connection = cnn
            MyDA.SelectCommand = comm
            MyDA.Fill(MyDS)
            dvListError.AutoGenerateColumns = False
            dvListError.DataSource = MyDS.Tables(0)

            dvListError.Columns("dCreated").DefaultCellStyle.Format = "dd/MMM/yyyy hh:mm"




            lblMessageError.Text = ""
        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in form1.BindListViewError()" & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            MessageBox.Show(SetLog)
        End Try

    End Sub




    Private Sub dvListMail_RowPrePaint(sender As Object, e As DataGridViewRowPrePaintEventArgs) Handles dvListMail.RowPrePaint
        If dvListMail.Rows(e.RowIndex).Cells("tosend").Value = "1" Then
            dvListMail.Rows(e.RowIndex).DefaultCellStyle.BackColor = Drawing.Color.Beige
            If dvListMail.Rows(e.RowIndex).Cells("SendWithSuccess").Value = "0" Then
                dvListMail.Rows(e.RowIndex).Cells("Id").Style.BackColor = Drawing.Color.Red


            End If
        End If







    End Sub
    Private Sub dvListMail_CellClick(sender As Object, e As DataGridViewCellEventArgs) Handles dvListMail.CellClick
        Dim i As Integer

        Dim MailId As Integer = -1

        i = dvListMail.CurrentRow.Index
        If IsDBNull(dvListMail.Item(0, i).Value) Then
            MailId = -1
        Else
            MailId = dvListMail.Item(0, i).Value
        End If

        BindDetail(MailId)




    End Sub
    Private Sub dvListError_CellClick(sender As Object, e As DataGridViewCellEventArgs) Handles dvListError.CellClick
        Dim i As Integer


        lblMessageError.Text = ""
        i = dvListError.CurrentRow.Index
        lblMessageError.Text = dvListError.Item(3, i).Value



    End Sub

    Private Sub dvListMail_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dvListMail.CellDoubleClick
        Dim i As Integer



        Dim MailId As Integer = -1

        i = dvListMail.CurrentRow.Index
        If IsDBNull(dvListMail.Item(0, i).Value) Then
            MailId = -1
        Else
            MailId = dvListMail.Item(0, i).Value
        End If

        Dim Myform As frmMailDetail = New frmMailDetail
        Myform.MailId = MailId
        Myform.ConnectionString = ConnectionString

        Myform.ShowDialog()



    End Sub

    Private Sub btnResend_Click(sender As Object, e As EventArgs) Handles btnResend.Click
        Try



            Dim MailId As Integer = -1
        Dim i As Integer
        i = dvListMail.CurrentRow.Index
        If IsDBNull(dvListMail.Item(0, i).Value) Then
            MailId = -1
            Return

        Else
            MailId = dvListMail.Item(0, i).Value
        End If


        Dim cnn As New SqlClient.SqlConnection
        cnn.ConnectionString = ConnectionString
        Dim comm As SqlCommand
        comm = cnn.CreateCommand()
        comm.CommandType = System.Data.CommandType.Text
        comm.CommandText = "update T400Mails set sendwithsuccess=NULL ,Sended= NULL , CountResend=0 where id =" & MailId.ToString

        Dim MyDA As New SqlDataAdapter
        Dim MyDS As New DataSet
        comm.Connection = cnn
        MyDA.SelectCommand = comm
        MyDA.Fill(MyDS)
            MessageBox.Show("Mail " & MailId.ToString & " sended!")

        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in form1.btnResend_Click()" & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            MessageBox.Show(SetLog)

        End Try
    End Sub

    Private Sub MenuStrip1_ItemClicked(sender As Object, e As ToolStripItemClickedEventArgs) Handles MenuStrip1.ItemClicked

    End Sub

    Private Sub btnX_Click(sender As Object, e As EventArgs) Handles btnX.Click
        txtFiltre.Text = ""
        BindListView()
    End Sub

    Private Sub btnSet_Click(sender As Object, e As EventArgs) Handles btnSet.Click
        BindListView()
    End Sub
End Class
