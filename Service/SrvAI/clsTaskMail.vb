Imports System.Net
Imports System.Net.Mail
Imports System.Data.SqlClient
Imports System
Imports System.Windows.Forms
Imports System.Reflection
Imports System.Runtime.InteropServices
Imports System.IO
Imports System.Text
Imports System.Net.Sockets
Imports Microsoft.VisualBasic
Imports MailKit
Imports MimeKit
Imports System.Text.RegularExpressions
Imports System.Net.Dns
Imports DnsClient
Imports MailKit.Net.Smtp
Imports System.Security.Cryptography.X509Certificates
Imports System.Net.Security

Imports System.Threading.Tasks








Public Class clsTaskMail


    ''Public Const logEventFile = "EventSMTP.txt"
    'Public Const logErrorFile = "ErrorSMTP.txt"
    Public Const FileLenghtMax = 1000000
    Sub New()
        LoadSetting()

    End Sub

    Sub LoadSetting()

        Dim oXMLconfig As New clsXmlConfig


        ConnectionString = oXMLconfig.ConnectionString
        UseDatabase = oXMLconfig.UseDatabase
        IpAdresse = oXMLconfig.IpAdresse
        SocketPort = oXMLconfig.SocketPort


    End Sub

#Region "Propriete"
    Private _UseDatabase As String
    Public Property UseDatabase As String
        Set(value As String)
            _UseDatabase = value
        End Set
        Get
            Return _UseDatabase
        End Get
    End Property

    Private _ConnectionString As String
    Public Property ConnectionString As String
        Set(value As String)
            _ConnectionString = value
        End Set
        Get
            Return _ConnectionString
        End Get
    End Property

    Private _IpAdresse As String
    Public Property IpAdresse As String
        Set(value As String)
            _IpAdresse = value
        End Set
        Get
            Return _IpAdresse
        End Get
    End Property

    Private _SocketPort As String
    Public Property SocketPort As String
        Set(value As String)
            _SocketPort = value
        End Set
        Get
            Return _SocketPort
        End Get
    End Property

#End Region





#Region "LOG"





    Public Shared Sub ClearAllLog()
        Try
            Dim pathofApp As String


            pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logEventFile
            File.WriteAllText(pathofApp, "")

            pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logErrorFile
            File.WriteAllText(pathofApp, "")



        Catch ex As Exception
            Return
        End Try
    End Sub

    Public Shared Function EventReadlog() As String


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logEventFile

            If Not File.Exists(pathofApp) Then
                _logFile = File.CreateText(pathofApp)
                _logFile.Flush()
                _logFile.Close()
            End If
            Dim MyText As String = File.ReadAllText(pathofApp)
            'Filtre pour caractere non valide dans le textbox, genre ETX ou autre truc
            For i As Integer = 0 To 9
                MyText = Replace(MyText, Chr(0), "[" & i & "]")
            Next
            For i As Integer = 127 To 255
                MyText = Replace(MyText, Chr(0), "[" & i & "]")
            Next
            Return MyText


        Catch ex As Exception
            Return ""
        End Try

    End Function
    Function GetAdresse(MyAdd As MimeKit.MailboxAddress) As String

        If MyAdd Is Nothing Then Return ""

        Return MyAdd.Address

    End Function
    Function GetAdresse(MyAddL As MimeKit.InternetAddressList) As String
        If MyAddL Is Nothing Then Return ""
        If MyAddL.Count = 0 Then Return ""
        Dim Retval As String = ""
        Dim MyAdd As MimeKit.MailboxAddress
        For i As Integer = 0 To MyAddL.Count - 1
            MyAdd = MyAddL.Item(i)

            Retval = Retval & MyAdd.Name & "<" & MyAdd.Address & ">;"
        Next

        Return Retval

    End Function
    Function GetStringMimeKit(ObjectMK As Object) As String

        If ObjectMK Is Nothing Then Return ""

        Return ObjectMK.ToString()


    End Function
    Function GetStringMimeKitImportance(ObjectMK As MimeKit.MessageImportance) As String

        Try



            Select Case ObjectMK
                Case MimeKit.MessageImportance.High
                    Return "High"
                Case MimeKit.MessageImportance.Low
                    Return "Low"
                Case MimeKit.MessageImportance.Normal
                    Return "Normal"

            End Select



        Catch ex As Exception
            Return "Unknow"
        End Try
        Return "Unknow"
    End Function
    Function GetStringMimeKitXPriority(ObjectMK As MimeKit.XMessagePriority) As String

        Try



            Select Case ObjectMK
                Case MimeKit.XMessagePriority.High
                    Return "High"
                Case MimeKit.XMessagePriority.Low
                    Return "Low"
                Case MimeKit.XMessagePriority.Normal
                    Return "Normal"
                Case MimeKit.XMessagePriority.Lowest
                    Return "Lowest"
                Case MimeKit.XMessagePriority.Lowest
                    Return "Lowest"



            End Select



        Catch ex As Exception
            Return "Unknow"
        End Try
        Return "Unknow"
    End Function





    '**************************************************************************************************************
    ' Inscription d un nouveau mail dans la base de donnees.
    '**************************************************************************************************************
    Public Sub StoreToBD(RCPT As String, Message As String, ClientIp As String)

        Dim byteArray As Byte()
        Dim stream As System.IO.MemoryStream
        Dim MyMessage As MimeKit.MimeMessage = Nothing

        Dim ssubject As String = ""
        Dim sTextBody As String = ""
        Dim sHtmlBody As String = ""

        Dim sFrom As String = ""
        Dim sBCC As String = ""
        Dim sCC As String = ""
        Dim sReplyTo As String = ""
        Dim sResentBcc As String = ""
        Dim sResentCc As String = ""
        Dim sResentFrom As String = ""
        Dim sResentReplyTo As String = ""
        Dim sResentSender As String = ""
        Dim sResentTo As String = ""
        Dim sSender As String = ""
        Dim sTo As String = ""
        Dim sInReplyTo As String = ""
        Dim sImportance As String = ""
        Dim sXPriority As String = ""
        Dim sMessageId As String = ""
        Dim sResentMessageId As String = ""

        Try

            'Prepare le message mail pour la creation dans le MimeKit
            byteArray = Encoding.UTF8.GetBytes(Message)
            stream = New System.IO.MemoryStream(byteArray)
            MyMessage = MimeKit.MimeMessage.Load(stream)
            clsTaskMail.EventWritelog("To avant traitement: " & MyMessage.Headers("To"))

            If Not MyMessage.Headers("To") Is Nothing Then
                If MyMessage.Headers("To").Length > 0 Then
                    MyMessage.Headers("To") = Replace(MyMessage.Headers("To"), ";", ",")
                End If
            End If

            If Not MyMessage.Headers("From") Is Nothing Then
                If MyMessage.Headers("From").Length > 0 Then
                    MyMessage.Headers("From") = Replace(MyMessage.Headers("From"), ";", ",")
                End If
            End If

            If Not MyMessage.Headers("Bcc") Is Nothing Then
                If MyMessage.Headers("Bcc").Length > 0 Then
                    MyMessage.Headers("Bcc") = Replace(MyMessage.Headers("Bcc"), ";", ",")
                End If
            End If

            If Not MyMessage.Headers("Cc") Is Nothing Then
                If MyMessage.Headers("Cc").Length > 0 Then
                    MyMessage.Headers("Cc") = Replace(MyMessage.Headers("Cc"), ";", ",")
                End If
            End If
            clsTaskMail.EventWritelog("To apres traitement: " & MyMessage.Headers("To"))


            ssubject = GetStringMimeKit(MyMessage.Subject)
            sTextBody = GetStringMimeKit(MyMessage.TextBody)
            sHtmlBody = GetStringMimeKit(MyMessage.HtmlBody)

            sFrom = GetAdresse(MyMessage.From)
            sBCC = GetAdresse(MyMessage.Bcc)
            sCC = GetAdresse(MyMessage.Cc)
            sCC = GetAdresse(MyMessage.Cc)
            sReplyTo = GetAdresse(MyMessage.ReplyTo)
            sResentBcc = GetAdresse(MyMessage.ResentBcc)
            sResentCc = GetAdresse(MyMessage.ResentCc)
            sResentFrom = GetAdresse(MyMessage.ResentFrom)
            sResentReplyTo = GetAdresse(MyMessage.ResentReplyTo)
            sResentSender = GetAdresse(MyMessage.ResentSender)
            sResentTo = GetAdresse(MyMessage.ResentTo)
            sSender = GetAdresse(MyMessage.Sender)
            sTo = GetAdresse(MyMessage.To)
            sInReplyTo = GetStringMimeKit(MyMessage.InReplyTo)
            sImportance = GetStringMimeKitImportance(MyMessage.Importance)
            sXPriority = GetStringMimeKitXPriority(MyMessage.XPriority)
            sMessageId = GetStringMimeKit(MyMessage.MessageId)
            sResentMessageId = GetStringMimeKit(MyMessage.ResentMessageId)

        Catch ex As Exception
            ErrorWritelog("Error in mime kit: " & ex.Message)
        End Try


        Try
            If UseDatabase = "1" Then
                Try


                    Dim cnn As New SqlClient.SqlConnection
                    cnn.ConnectionString = ConnectionString
                    Dim comm As SqlCommand
                    comm = cnn.CreateCommand()
                    comm.CommandType = System.Data.CommandType.StoredProcedure
                    comm.CommandText = "s1549InsertMail_A"
                    comm.Parameters.AddWithValue("@Message", Message)
                    comm.Parameters.AddWithValue("@RCPT", RCPT)

                    comm.Parameters.AddWithValue("@subject", ssubject)

                    comm.Parameters.AddWithValue("@TextBody", sTextBody)
                    comm.Parameters.AddWithValue("@HtmlBody", sHtmlBody)

                    comm.Parameters.AddWithValue("@From", sFrom)
                    comm.Parameters.AddWithValue("@BCC", sBCC)
                    comm.Parameters.AddWithValue("@CC", sCC)
                    comm.Parameters.AddWithValue("@ReplyTo", sReplyTo)
                    comm.Parameters.AddWithValue("@ResentBcc", sResentBcc)
                    comm.Parameters.AddWithValue("@ResentCc", sResentCc)
                    comm.Parameters.AddWithValue("@ResentFrom", sResentFrom)
                    comm.Parameters.AddWithValue("@ResentReplyTo", sResentReplyTo)
                    comm.Parameters.AddWithValue("@ResentSender", sResentSender)
                    comm.Parameters.AddWithValue("@ResentTo", sResentTo)
                    comm.Parameters.AddWithValue("@Sender", sSender)
                    comm.Parameters.AddWithValue("@To", sTo)
                    comm.Parameters.AddWithValue("@InReplyTo", sInReplyTo)
                    comm.Parameters.AddWithValue("@Importance", sImportance)
                    comm.Parameters.AddWithValue("@XPriority", sXPriority)

                    comm.Parameters.AddWithValue("@MessageId", sMessageId)
                    comm.Parameters.AddWithValue("@ResentMessageId", sResentMessageId)
                    comm.Parameters.AddWithValue("@ClientIP", ClientIp)

                    'cnn.Open()
                    'comm.ExecuteScalar()
                    'cnn.Close()

                    Dim MyDA As New SqlDataAdapter
                    Dim MyDS As New DataSet

                    comm.Connection = cnn

                    MyDA.SelectCommand = comm
                    MyDA.Fill(MyDS)

                    For i As Integer = 0 To MyMessage.Attachments.Count - 1
                        Dim MyMim As MimeEntity
                        MyMim = MyMessage.Attachments(i)
                        Dim mystr As New System.IO.MemoryStream()
                        MyMim.WriteTo(mystr, True)

                        Dim thebuye As Byte() = mystr.ToArray
                        Dim Mystrw As String = MimeKit.Utils.Rfc2047.DecodeText(thebuye)
                        Dim Mbytes = Convert.FromBase64String(Mystrw)

                        For Each orow In MyDS.Tables(0).Rows
                            Dim MailId As Integer = orow("MailId")
                            Dim cnn2 As New SqlClient.SqlConnection
                            cnn2.ConnectionString = ConnectionString
                            Dim comm2 As SqlCommand
                            comm2 = cnn2.CreateCommand()
                            comm2.CommandType = System.Data.CommandType.StoredProcedure
                            comm2.CommandText = "s1579InsertAttachemnt_B"
                            comm2.Parameters.AddWithValue("@MailId", MailId)
                            comm2.Parameters.AddWithValue("@Content", Mbytes)
                            comm2.Parameters.AddWithValue("@FileName", MyMim.ContentDisposition.FileName)
                            If Not MyMim.ContentDisposition.Disposition Is Nothing Then
                                comm2.Parameters.AddWithValue("@ContentDisposition", MyMim.ContentDisposition.Disposition)
                            Else
                                comm2.Parameters.AddWithValue("@ContentDisposition", "Nothing")
                            End If


                            comm2.Parameters.AddWithValue("@ContentType", MyMim.ContentType.MimeType)

                            cnn2.Open()
                            comm2.ExecuteScalar()
                            cnn2.Close()


                        Next

                    Next

                Catch ex As Exception
                    Dim SetLog As String = ""
                    SetLog = SetLog & "Error in clsTaskMail.StoreToBD1" & vbCrLf

                    SetLog = SetLog & "Error:" & ex.Message & vbCrLf
                    clsTaskMail.ErrorWritelog(SetLog)
                End Try
            End If

        Catch ex As Exception
            clsTaskMail.ErrorWritelog("Error in StoreToBD2:" & ex.Message)
        End Try
    End Sub

    Async Function SendOneMail() As Task
        'Sub SendOneMail()

        Dim AllAdressTo As String = ""
        Dim AllAdressCC As String = ""
        Dim AllAdressBCC As String = ""
        Dim MessageText As String = ""
        Dim MessageHTML As String = ""
        Dim MessageSubject As String = ""
        Dim FromAddress As String = ""
        Dim ReplyToAddress As String = ""
        Dim MailId As Integer = 0
        Dim sStep As String = ""

        Try




            If UseDatabase = "1" Then


                Try


                    sStep = "1 - Debut de SendOneMail"
                    Dim cnn As New SqlClient.SqlConnection
                    cnn.ConnectionString = ConnectionString
                    Dim comm As SqlCommand
                    Dim rd As SqlDataReader
                    comm = cnn.CreateCommand()
                    comm.CommandType = System.Data.CommandType.StoredProcedure
                    comm.CommandText = "s1570GetOneMail_A"

                    cnn.Open()
                    rd = comm.ExecuteReader()
                    If rd.Read() Then
                        MailId = rd("Id")
                        AllAdressTo = rd("To")
                        FromAddress = rd("Sender")
                        ' Reply-To : porte l'adresse verifiee de la compagnie pour les
                        ' courriels envoyes en son nom. Le From reste le notre (SPF).
                        If Not IsDBNull(rd("ReplyTo")) Then ReplyToAddress = CStr(rd("ReplyTo"))
                        MessageSubject = rd("Subject")
                        MessageText = rd("TextBody")
                        MessageHTML = rd("HTMLBody")
                        AllAdressBCC = rd("BCC")
                        AllAdressCC = rd("CC")
                    Else
                        rd.Close()
                        cnn.Close()
                        Return
                    End If
                    rd.Close()
                    cnn.Close()

                    If AllAdressTo = "" Then
                        SaveErrorMessage(MailId, "...", "Adresse TO est vide???")
                        Return
                    End If



                    clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                Catch ex As Exception
                    clsTaskMail.EventWritelog("Erreur SendOneMail-1: " & ex.Message)
                    Dim SetLog As String = ""
                    SetLog = SetLog & "Error in clsTaskMail.SendOneMail2()" & vbCrLf
                    SetLog = SetLog & "Error:" & ex.Message & vbCrLf
                    clsTaskMail.ErrorWritelog(SetLog)
                    Return
                End Try
                sStep = "2 - Le mail est lu, MailId:" & MailId.ToString

                CounterMailSend = CounterMailSend + 1
                SyncLock thisLock
                    SMTPStatus.CounterEmailSend = CounterMailSend.ToString
                    SMTPStatus.SendTo = AllAdressTo
                    SMTPStatus.SendFrom = FromAddress
                    SMTPStatus.SendStep = "3"
                End SyncLock
                sStep = "2.1 - SMTPStatus est initialise"
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)

                Dim MailBoxFROM As MailboxAddress = GetMailBox(FromAddress)
                sStep = "2.2 MailBoxFROM est initialise"
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                Dim MyMailAd As List(Of MailboxAddress) = GetMailBoxList(AllAdressTo)
                sStep = "2.3 MyMailAd est initialise"
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                Dim mimeMessage = New MimeMessage()
                sStep = "2.4 mimeMessage  est initialise"
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                GetMailBoxList(AllAdressTo, mimeMessage.[To])
                GetMailBoxList(AllAdressCC, mimeMessage.Cc)
                GetMailBoxList(AllAdressBCC, mimeMessage.Bcc)
                GetMailBoxList(ReplyToAddress, mimeMessage.ReplyTo)
                sStep = "2.5 Toutes les adresse sont initialise"
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                mimeMessage.Subject = MessageSubject

                Dim MyBody As New BodyBuilder
                MyBody.TextBody = MessageText
                MyBody.HtmlBody = MessageHTML


                Dim dsAtt As DataSet = ExecuteSQLds("exec s1578GetAttachment @MailId=" & MailId.ToString)

                Dim attCols = dsAtt.Tables(0).Columns
                For Each orow In dsAtt.Tables(0).Rows
                    Dim attFileName As String = orow("FileName").ToString()
                    Dim attContent As Byte() = CType(orow("content"), Byte())
                    Dim attCt As String = If(attCols.Contains("ContentType") AndAlso Not IsDBNull(orow("ContentType")), orow("ContentType").ToString(), "")
                    Dim attCid As String = ""
                    Dim attDisp As String = ""
                    If attCols.Contains("ContentId") AndAlso Not IsDBNull(orow("ContentId")) Then attCid = orow("ContentId").ToString().Trim(New Char() {"<"c, ">"c, " "c})
                    If attCols.Contains("ContentDisposition") AndAlso Not IsDBNull(orow("ContentDisposition")) Then attDisp = orow("ContentDisposition").ToString()
                    Dim attIsInline As Boolean = (attCid <> "" AndAlso (attDisp = "" OrElse String.Equals(attDisp, "inline", StringComparison.OrdinalIgnoreCase)))
                    If attIsInline Then
                        ' Image inline (cid:) -> ressource liee -> rendu inline dans le corps HTML
                        Dim res As MimeKit.MimeEntity
                        If attCt <> "" Then
                            res = MyBody.LinkedResources.Add(attFileName, attContent, MimeKit.ContentType.Parse(attCt))
                        Else
                            res = MyBody.LinkedResources.Add(attFileName, attContent)
                        End If
                        res.ContentId = attCid
                    Else
                        MyBody.Attachments.Add(attFileName, attContent)
                    End If
                Next

                mimeMessage.Body = MyBody.ToMessageBody


                Dim MyDomain As List(Of String) = GetAllDomain(AllAdressTo, AllAdressCC, AllAdressBCC)
                sStep = "4 La liste des domaine des adresses sont identifier"
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                For Each sDomain As String In MyDomain
                    Dim mailBoxTos As List(Of MailboxAddress) = New List(Of MailboxAddress)
                    For Each MyMailB As MailboxAddress In mimeMessage.[To]
                        If MyMailB.Address.Contains(sDomain) Then
                            Dim MailBoxTO As New MailboxAddress(MyMailB.Name, MyMailB.Address)
                            mailBoxTos.Add(MailBoxTO)
                        End If
                    Next
                    For Each MyMailB As MailboxAddress In mimeMessage.Cc
                        If MyMailB.Address.Contains(sDomain) Then
                            Dim MailBoxTO As New MailboxAddress(MyMailB.Name, MyMailB.Address)
                            mailBoxTos.Add(MailBoxTO)
                        End If
                    Next
                    For Each MyMailB As MailboxAddress In mimeMessage.Bcc
                        If MyMailB.Address.Contains(sDomain) Then
                            Dim MailBoxTO As New MailboxAddress(MyMailB.Name, MyMailB.Address)
                            mailBoxTos.Add(MailBoxTO)
                        End If
                    Next
                    sStep = "4 Sauve le mail dans la BD"
                    clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
                    'Sauve le mail dans la BD
                    SaveMimeMessage(MailId, mimeMessage)

                    'Cette boucle corrige le send pour Office 365, il ne support pas plusieur addresse dans le TO.
                    'Evite l erreur suivante
                    '4.5.3 Too many recipients (AS780090) [TO1CAN01FT005.eop-CAN01.prod.protection.outlook.com]
                    'Donc les mail sont envoyer de facon individuel
                    For Each MailboxAddress In mailBoxTos
                        Dim mailBoxToSend As List(Of MailboxAddress) = New List(Of MailboxAddress)
                        Dim sName As String = MailboxAddress.Name
                        Dim sAdresse As String = MailboxAddress.Address.ToLower
                        Dim MyMailBox As New MailboxAddress(sName, sAdresse)
                        mailBoxToSend.Add(MyMailBox)
                        Dim simpleTask As Task = SendMessageSMTP(mimeMessage, MailBoxFROM, mailBoxToSend, sDomain, MailId)
                        Await simpleTask
                    Next
                    sStep = "5"

                Next
                sStep = "6 fin de procedure."



                SyncLock thisLock
                    SMTPStatus.SendStep = "4"
                    SMTPStatus.LastSend = Now.ToLongDateString & " " & Now.ToLongTimeString
                End SyncLock
                clsTaskMail.EventWritelog("Étape SendOneMail: Step:" & sStep & ". MailId: " & MailId.ToString)
            End If
        Catch ex As Exception
            clsTaskMail.EventWritelog("Erreur SendOneMail-2: " & ex.Message)
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in SendOneMail()" & vbCrLf
            SetLog = SetLog & "Error reading database step:" & sStep & vbCrLf
            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            clsTaskMail.ErrorWritelog(SetLog)


        End Try
    End Function
    Public Function ExecuteSQLds(ByVal SQLStatement As String) As DataSet
        Try


            If UseDatabase <> "1" Then Return Nothing
            Dim oDa As New SqlClient.SqlDataAdapter(SQLStatement, ConnectionString)
            Dim oDs As New DataSet
            oDa.Fill(oDs)
            Return oDs
        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in clsTaskMail.ExecuteSQLds()" & vbCrLf

            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            clsTaskMail.ErrorWritelog(SetLog)
            Return Nothing
        End Try
    End Function
    Sub SaveMimeMessage(MailId As Integer, ByVal ErrorMessage As String)
        Try


            If UseDatabase <> "1" Then Return
        Dim cnn As New SqlClient.SqlConnection
        cnn.ConnectionString = ConnectionString
        Dim comm As SqlCommand
        comm = cnn.CreateCommand()
        comm.CommandType = System.Data.CommandType.StoredProcedure
        comm.CommandText = "s1575ErrorSendEmail"
        comm.Parameters.AddWithValue("@MailId", MailId)
        comm.Parameters.AddWithValue("@ErrorMessage", ErrorMessage)


        cnn.Open()
        comm.ExecuteScalar()
        cnn.Close()
        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in clsTaskMail.SaveMimeMessage()" & vbCrLf

            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
        clsTaskMail.ErrorWritelog(SetLog)

        End Try
    End Sub


    Sub SaveMimeMessage(MailId As Integer, ByVal msg As MimeMessage)
        Try


            If UseDatabase <> "1" Then Return
        Dim cnn As New SqlClient.SqlConnection
        cnn.ConnectionString = ConnectionString
        Dim comm As SqlCommand
        comm = cnn.CreateCommand()
        comm.CommandType = System.Data.CommandType.StoredProcedure
        comm.CommandText = "s1574SaveMimeMessage"
        comm.Parameters.AddWithValue("@MailId", MailId)
        comm.Parameters.AddWithValue("@Message", msg.ToString)


        cnn.Open()
        comm.ExecuteScalar()
        cnn.Close()

        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in clsTaskMail.SaveMimeMessage()" & vbCrLf

            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            clsTaskMail.ErrorWritelog(SetLog)

        End Try

    End Sub
    Function GetAllDomain(MailAdressesTO As String, MailAdressesCC As String, MailAdressesBCC As String) As List(Of String)
        Dim DomainList As List(Of String) = New List(Of String)
        Dim sNom As String = ""
        Dim sAdresse As String = ""


        If MailAdressesTO.Trim <> "" Then
            Dim aAllAdresseTO() As String = MailAdressesTO.Split(";")

            For i = 0 To aAllAdresseTO.Count - 1
                Dim AddNom As String = aAllAdresseTO(i)


                If AddNom.Contains("<") Then
                    If AddNom.Contains(">") Then
                        sNom = AddNom.Substring(0, AddNom.IndexOf("<"))
                        sAdresse = AddNom.Substring(AddNom.IndexOf("<"))
                    End If
                Else
                    sAdresse = AddNom
                End If

                sAdresse = Replace(sAdresse, "<", "")
                sAdresse = Replace(sAdresse, ">", "")
                Dim sDomain As String = sAdresse.Substring(sAdresse.IndexOf("@") + 1).ToLower
                If Not DomainList.Contains(sDomain) Then
                    DomainList.Add(sDomain)
                End If
            Next
        End If


        If MailAdressesCC.Trim <> "" Then
            Dim aAllAdresseCC() As String = MailAdressesCC.Split(";")
            For i = 0 To aAllAdresseCC.Count - 1
                Dim AddNom As String = aAllAdresseCC(i)
                If AddNom.Contains("<") Then
                    If AddNom.Contains(">") Then
                        sNom = AddNom.Substring(0, AddNom.IndexOf("<"))
                        sAdresse = AddNom.Substring(AddNom.IndexOf("<"))
                    End If
                Else
                    sAdresse = AddNom
                End If
                sAdresse = Replace(sAdresse, "<", "")
                sAdresse = Replace(sAdresse, ">", "")
                Dim sDomain As String = sAdresse.Substring(sAdresse.IndexOf("@") + 1).ToLower
                If Not DomainList.Contains(sDomain) Then
                    DomainList.Add(sDomain)
                End If
            Next
        End If

        If MailAdressesBCC.Trim <> "" Then


            Dim aAllAdresseBCC() As String = MailAdressesBCC.Split(";")
            For i = 0 To aAllAdresseBCC.Count - 1
                Dim AddNom As String = aAllAdresseBCC(i)
                If AddNom.Contains("<") Then
                    If AddNom.Contains(">") Then
                        sNom = AddNom.Substring(0, AddNom.IndexOf("<"))
                        sAdresse = AddNom.Substring(AddNom.IndexOf("<"))
                    End If
                Else
                    sAdresse = AddNom
                End If
                sAdresse = Replace(sAdresse, "<", "")
                sAdresse = Replace(sAdresse, ">", "")
                Dim sDomain As String = sAdresse.Substring(sAdresse.IndexOf("@") + 1).ToLower
                If Not DomainList.Contains(sDomain) Then
                    DomainList.Add(sDomain)
                End If
            Next
        End If
        Return DomainList

    End Function
    Sub GetMailBoxList(MailAdresses As String, iaList As InternetAddressList)
        If MailAdresses.Trim = "" Then Return
        Dim aAllAdresse() As String = MailAdresses.Split(";")
        Dim sNom As String = ""
        Dim sAdresse As String = ""
        For i = 0 To aAllAdresse.Count - 1
            'akeita@we-plus.ca;jblanchard@we-plus.ca;hnguyen@we-plus.ca;dayache@we-plus.ca
            'ici il faut re-initialiser snom a blanc
            sNom = ""


            Dim AddNom As String = aAllAdresse(i)

            If AddNom.Contains("<") Then
                If AddNom.Contains(">") Then
                    sNom = AddNom.Substring(0, AddNom.IndexOf("<"))
                    sAdresse = AddNom.Substring(AddNom.IndexOf("<"))
                End If
            Else

                sAdresse = AddNom
            End If
            If sNom = "" Then sNom = sAdresse

            sAdresse = Replace(sAdresse, "<", "")
            sAdresse = Replace(sAdresse, ">", "")

            Dim TheMailBox As New MailboxAddress(sNom, sAdresse)


            iaList.Add(TheMailBox)
        Next

    End Sub


    Function GetMailBoxList(MailAdresses As String) As List(Of MailboxAddress)
        Dim sNom As String = ""
        Dim sAdresse As String = ""
        Dim aAllAdresse() As String = MailAdresses.Split(";")
        Dim mailBoxList As List(Of MailboxAddress) = New List(Of MailboxAddress)
        For i = 0 To aAllAdresse.Count - 1
            sNom = ""
            sAdresse = ""
            Dim AddNom As String = aAllAdresse(i)

            If AddNom.Contains("<") Then
                If AddNom.Contains(">") Then
                    sNom = AddNom.Substring(0, AddNom.IndexOf("<"))
                    sAdresse = AddNom.Substring(AddNom.IndexOf("<"))
                End If
            Else
                sAdresse = AddNom
            End If
            If sNom = "" Then sNom = sAdresse
            sAdresse = Replace(sAdresse, "<", "")
            sAdresse = Replace(sAdresse, ">", "")





            If isGroupMail(sAdresse) Then
                Dim AllAdresse As String = GetGroupMailAdresse(sAdresse)
                If AllAdresse.Length > 0 Then
                    Dim aAllGroupAdresse() As String = AllAdresse.Split(",")
                    For z = 0 To aAllGroupAdresse.Count - 1
                        Dim AddAdressg As String = aAllGroupAdresse(i)
                        Dim TheMailBox As New MailboxAddress("", AddAdressg)
                        mailBoxList.Add(TheMailBox)
                    Next

                End If



            Else
                Dim TheMailBox As New MailboxAddress(sNom, sAdresse)
                mailBoxList.Add(TheMailBox)
            End If

            'ici il faut re-initialiser snom a blanc
            sNom = ""


        Next
        Return mailBoxList
    End Function

    Function GetGroupMailAdresse(GroupName As String) As String

        If UseDatabase <> "1" Then Return ""


        Return ExecuteSQLds("s1684GetMailFromGroup " & GroupName).Tables(0).Rows(0).Item(0)


    End Function


    Function isGroupMail(MailString As String) As Boolean
        If MailString.Contains("@") Then
            Return False
        End If
        Return True

    End Function


    Function GetMailBox(MailAdresse As String) As MailboxAddress
        Dim sNom As String = ""
        Dim sAdresse As String = ""

        If MailAdresse.Contains("<") Then
            If MailAdresse.Contains(">") Then
                sNom = MailAdresse.Substring(0, MailAdresse.IndexOf("<"))
                sAdresse = MailAdresse.Substring(MailAdresse.IndexOf("<"))
            End If
        Else
            sAdresse = MailAdresse
        End If
        If sNom = "" Then sNom = sAdresse
        sAdresse = Replace(sAdresse, "<", "")
        sAdresse = Replace(sAdresse, ">", "")

        Dim TheMailBox As New MailboxAddress(sNom, sAdresse)
        Return TheMailBox
    End Function

    Public Sub ExecuteSQL(ByVal SQLstatement As String)
        Try

            If UseDatabase <> "1" Then Return


        Dim myConnection As New SqlClient.SqlConnection(ConnectionString)

        Dim myCommand As SqlClient.SqlCommand
        myCommand = New SqlClient.SqlCommand(SQLstatement, myConnection)
        myCommand.CommandType = System.Data.CommandType.Text
        myConnection.Open()
        myCommand.ExecuteNonQuery()
        myConnection.Close()

        Catch ex As Exception
        Dim SetLog As String = ""
            SetLog = SetLog & "Error in clsTaskMail.ExecuteSQL()" & vbCrLf

            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            clsTaskMail.ErrorWritelog(SetLog)

        End Try
    End Sub

    Async Function SendMessageSMTP(ByVal msg As MimeMessage, MailBoxFROM As MailboxAddress, mailBoxTos As List(Of MailboxAddress), ByVal domain As String, MailId As Integer) As Task

        Dim sStep As String = "1"
        Try

            Dim oXMLconfig As New clsXmlConfig
            Dim re As System.Text.RegularExpressions.Regex = Nothing

            Using client As MailKit.Net.Smtp.SmtpClient = New MailKit.Net.Smtp.SmtpClient() With {
                .ServerCertificateValidationCallback = Function(ByVal sender As Object, ByVal certificate As System.Security.Cryptography.X509Certificates.X509Certificate, ByVal chain As System.Security.Cryptography.X509Certificates.X509Chain, ByVal sslPolicyErrors As System.Net.Security.SslPolicyErrors)
                                                           '    Dim re As Regex = Nothing
                                                           ' Return (sslPolicyErrors = SslPolicyErrors.None OrElse (ignoreCertificateErrorsRegex.TryGetValue(domain, re) AndAlso re.IsMatch(certificate.Subject)))
                                                           Return True
                                                       End Function
            }


                'Si pas ajuster alors il prend l adresse du serveur local genre 192.168.168.201
                'Dans ce cas, il vas etre considere comme spammeur
                'Voir doc a ce sujet.
                'Adresse Host du HELO
                client.LocalDomain = "giv4.sourcevolution.com"
                sStep = "2"

                Dim ip As IPHostEntry = Nothing
                Dim sent As Boolean = False
                'Dim lookup As LookupClient = New LookupClient(IPAddress.Parse("24.200.241.37"))
                Dim lookup As LookupClient = New LookupClient()

                sStep = "2.1 Domain:" & domain & " "
                clsTaskMail.EventWritelog("Send mail domain:" & domain.Trim)

                Dim result As IDnsQueryResponse = lookup.Query(domain.Trim, QueryType.MX)



                sStep = "3"
                For Each record As Object In result.AllRecords
                    Try

                        'If domain.ToLower = "sourcevolution.ca" Then
                        '    'bug ici ne pas enlever, si non pas de from dans les courriel
                        '    msg.From.Clear()
                        '    msg.From.Add(MailBoxFROM)
                        '    sStep = "5z"
                        '    Dim MyIp As String = oXMLconfig.IpAdresse
                        '    Await client.ConnectAsync(MyIp, options:=MailKit.Security.SecureSocketOptions.Auto)
                        '    sStep = "6z"
                        '    Await client.SendAsync(msg, MailBoxFROM, mailBoxTos)
                        '    sent = True
                        '    ExecuteSQL("exec s1572SetSendWithSuccess @MailId=" & MailId.ToString)
                        '    Exit For
                        'End If

                        'If TypeOf (record) Is DnsClient.Protocol.MxRecord Then

                        'End If
                        ip = Await Dns.GetHostEntryAsync(record.Exchange)

                        For Each ipAddress As IPAddress In ip.AddressList
                            Dim host As String = ip.HostName
                            clsTaskMail.EventWritelog("Send mail IP:" & host)
                            ' BUG a la prochaine commande
                            sStep = "4"
                            Try
                                Dim sw As Stopwatch = New Stopwatch()

                                'bug ici ne pas enlever, si non pas de from dans les courriel
                                msg.From.Clear()
                                msg.From.Add(MailBoxFROM)
                                sStep = "5"
                                'Bug ici, blocage
                                Dim cts As New Threading.CancellationTokenSource
                                Dim token As Threading.CancellationToken = cts.Token
                                cts.CancelAfter(60000)
                                Dim SetLog As String = ""
                                SetLog = SetLog & "Step " & sStep & "  send messageSMTP" & vbCrLf
                                clsTaskMail.EventWritelog(SetLog)
                                sw.Restart()

                                'On fait la connection SMTP, pendant 20 minutes (20 boucles de 60000 ms)
                                Dim connectask As Task = client.ConnectAsync(host, options:=MailKit.Security.SecureSocketOptions.Auto, cancellationToken:=token)
                                Dim icountconnect As Integer = 0
                                Do
                                    clsTaskMail.EventWritelog("1-Task.WhenAny:" & host)
                                    Dim myTask = Await Task.WhenAny(connectask, Task.Delay(60000))
                                    clsTaskMail.EventWritelog("2-Task.WhenAny:" & host)
                                    icountconnect = icountconnect + 1
                                    If icountconnect > 20 Then
                                        Dim sTo As String = ""
                                        For Each ix As MailboxAddress In mailBoxTos
                                            sTo = sTo & ix.ToString
                                        Next
                                        SaveErrorMessage(MailId, "Error in Task.WhenAny", sTo)
                                        Await client.DisconnectAsync(True)
                                        Return
                                    End If
                                Loop While (connectask.IsCompleted = False)


                                'Await client.ConnectAsync(host, options:=MailKit.Security.SecureSocketOptions.Auto, cancellationToken:=token)

                                clsTaskMail.EventWritelog("Send mail SendAsync:" & host)
                                For Each ix As MailboxAddress In mailBoxTos
                                    clsTaskMail.EventWritelog("Send mail mailBoxTos:" & ix.ToString)
                                Next
                                'Bloque parfois ici, faire un watch ici sur Send Async
                                'Faire une boucle exemple comme en haut.
                                sStep = "6"
                                Await client.SendAsync(msg, MailBoxFROM, mailBoxTos)


                                'Threading.Thread.Sleep(3000)

                                sent = True
                                ExecuteSQL("exec s1572SetSendWithSuccess @MailId=" & MailId.ToString)

                                Exit For
                            Catch ex As Exception
                                Dim SetLog As String = ""
                                SetLog = SetLog & "Error 1, step " & sStep & " in SendMessage()" & vbCrLf
                                SetLog = SetLog & ex.Message & vbCrLf
                                clsTaskMail.ErrorWritelog(SetLog)
                                Dim sTo As String = ""
                                For Each ix As MailboxAddress In mailBoxTos
                                    sTo = sTo & ix.ToString
                                Next
                                SaveErrorMessage(MailId, ex.Message, sTo)


                            Finally


                            End Try
                            Await client.DisconnectAsync(True)
                        Next

                    Catch ex As Exception
                        Dim SetLog As String = ""
                        SetLog = SetLog & "Error 2, step " & sStep & " in SendMessage()" & vbCrLf
                        SetLog = SetLog & ex.Message & vbCrLf
                        clsTaskMail.ErrorWritelog(SetLog)
                        Dim sTo As String = ""
                        For Each ix As MailboxAddress In mailBoxTos
                            sTo = sTo & ix.ToString
                        Next
                        SaveErrorMessage(MailId, ex.Message, sTo)

                    End Try

                    If sent Then
                        Exit For
                    End If
                Next
            End Using

        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error 3, step " & sStep & " in SendMessage()" & vbCrLf
            SetLog = SetLog & ex.Message & vbCrLf
            clsTaskMail.ErrorWritelog(SetLog)
            Dim sTo As String = ""
            For Each ix As MailboxAddress In mailBoxTos
                sTo = sTo & ix.ToString
            Next
            SaveErrorMessage(MailId, ex.Message, sTo)

        End Try

    End Function

    Sub SaveErrorMessage(MailId As Integer, ByVal ErrorMessage As String, sTo As String)
        Try


            If UseDatabase <> "1" Then Return
            Dim cnn As New SqlClient.SqlConnection
            cnn.ConnectionString = ConnectionString
            Dim comm As SqlCommand
            comm = cnn.CreateCommand()
            comm.CommandType = System.Data.CommandType.StoredProcedure
            comm.CommandText = "s1575ErrorSendEmail"
            comm.Parameters.AddWithValue("@MailId", MailId)
            comm.Parameters.AddWithValue("@ErrorMessage", ErrorMessage)
            comm.Parameters.AddWithValue("@To", sTo)


            cnn.Open()
            comm.ExecuteScalar()
            cnn.Close()


        Catch ex As Exception
            Dim SetLog As String = ""
            SetLog = SetLog & "Error in clsTaskMail.ExecuteSQLds()" & vbCrLf

            SetLog = SetLog & "Error:" & ex.Message & vbCrLf
            clsTaskMail.ErrorWritelog(SetLog)

        End Try

    End Sub


    Public Shared Sub EventWritelog(Message As String)


        Try
            Dim _logFile As StreamWriter
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logEventFile

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
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logErrorFile

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
            Dim pathofApp As String = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) & "\" & clsLog.logErrorFile

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
#End Region






End Class
