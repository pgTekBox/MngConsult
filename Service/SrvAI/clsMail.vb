Imports System.Net
Imports System.Net.Mail
Imports System.Data.SqlClient
Imports System

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



Public Class clsMail

    Public ClientIP As String
    Public Message As String
    Public Recipient As String

    Public Subject As String = ""
    Public TextBody As String = ""
    Public HtmlBody As String = ""

    Public From As String = ""
    Public BCC As String = ""
    Public CC As String = ""
    Public ReplyTo As String = ""
    Public ResentBcc As String = ""
    Public ResentCc As String = ""
    Public ResentFrom As String = ""
    Public ResentReplyTo As String = ""
    Public ResentSender As String = ""
    Public ResentTo As String = ""
    Public Sender As String = ""
    Public [To] As String = ""
    Public InReplyTo As String = ""
    Public Importance As String = ""
    Public XPriority As String = ""
    Public MessageId As String = ""
    Public ResentMessageId As String = ""

    Public ErrorParsing As String = ""

    Public DomaineName As String = ""

    Public Attachment As DataTable



    Sub New(sRCPT As String, sMessage As String, sClientIp As String)


        'Place le status d'erreur a vide
        'Si non vide alors il y a une erreur
        ErrorParsing = ""

        If sMessage = "" Then
            Subject = ""
            TextBody = ""
            HtmlBody = ""

            From = ""
            BCC = ""
            CC = ""

            ReplyTo = ""
            ResentBcc = ""
            ResentCc = ""
            ResentFrom = ""
            ResentReplyTo = ""
            ResentSender = ""
            ResentTo = ""
            Sender = ""
            [To] = ""
            InReplyTo = ""
            Importance = ""
            XPriority = ""
            MessageId = ""
            ResentMessageId = ""
            DomaineName = ""
            ClientIP = ""
            Message = ""
            Recipient = ""
            Attachment = CreateTBLAtt()
            ErrorParsing = ""
            Return

        End If



        DomaineName = ExtractDomain(sRCPT)
        'Info recu avec le email
        ClientIP = sClientIp
        Message = sMessage
        Recipient = sRCPT


        Try

            'Conversion du mail dans le MimeKit
            'Prepare le message mail pour la creation dans le MimeKit
            Dim byteArray As Byte()
            Dim stream As System.IO.MemoryStream
            Dim MyMessage As MimeKit.MimeMessage = Nothing
            byteArray = Encoding.UTF8.GetBytes(Message)
            stream = New System.IO.MemoryStream(byteArray)
            MyMessage = MimeKit.MimeMessage.Load(stream)

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


            Subject = GetStringMimeKit(MyMessage.Subject)
            TextBody = GetStringMimeKit(MyMessage.TextBody)
            HtmlBody = GetStringMimeKit(MyMessage.HtmlBody)

            From = GetAdresse(MyMessage.From)
            BCC = GetAdresse(MyMessage.Bcc)
            CC = GetAdresse(MyMessage.Cc)

            ReplyTo = GetAdresse(MyMessage.ReplyTo)
            ResentBcc = GetAdresse(MyMessage.ResentBcc)
            ResentCc = GetAdresse(MyMessage.ResentCc)
            ResentFrom = GetAdresse(MyMessage.ResentFrom)
            ResentReplyTo = GetAdresse(MyMessage.ResentReplyTo)
            ResentSender = GetAdresse(MyMessage.ResentSender)
            ResentTo = GetAdresse(MyMessage.ResentTo)
            Sender = GetAdresse(MyMessage.Sender)
            [To] = GetAdresse(MyMessage.To)
            InReplyTo = GetStringMimeKit(MyMessage.InReplyTo)
            Importance = GetStringMimeKitImportance(MyMessage.Importance)
            XPriority = GetStringMimeKitXPriority(MyMessage.XPriority)
            MessageId = GetStringMimeKit(MyMessage.MessageId)
            ResentMessageId = GetStringMimeKit(MyMessage.ResentMessageId)


            Attachment = CreateTBLAtt()





            For i As Integer = 0 To MyMessage.Attachments.Count - 1
                Dim MyMime As MimeEntity
                MyMime = MyMessage.Attachments(i)
                Dim mystr As New System.IO.MemoryStream()
                MyMime.WriteTo(mystr, True)

                Dim thebuye As Byte() = mystr.ToArray
                Dim Mystrw As String = MimeKit.Utils.Rfc2047.DecodeText(thebuye)

                Dim Mbytes = Convert.FromBase64String(Mystrw) 'Le contenu
                Dim FileName As String = MyMime.ContentDisposition.FileName
                Dim Disposition As String = MyMime.ContentDisposition.Disposition
                Dim ContentType As String = MyMime.ContentType.MimeType





                Attachment.Rows.Add(FileName, Disposition, ContentType)

            Next












        Catch ex As Exception
            ErrorParsing = ex.Message

        End Try






    End Sub
    Function ExtractDomain(emailadresse As String) As String

        Try


            Dim smail As String = Replace(emailadresse.Split("@")(1), ">", "")

            Return smail
        Catch ex As Exception
            Return ""
        End Try
    End Function
    Function CreateTBLAtt() As DataTable

        Dim dt As New DataTable
        dt.Columns.Add("FileName", GetType(String))
        'dt.Columns.Add("Content", GetType(Byte))
        dt.Columns.Add("Disposition", GetType(String))
        dt.Columns.Add("MimeType", GetType(String))

        Return dt
    End Function

    Public Sub StoreToBD(sRCPT As String, sMessage As String, sClientIp As String)


    End Sub

    Function GetStringMimeKit(ObjectMK As Object) As String

        If ObjectMK Is Nothing Then Return ""

        Return ObjectMK.ToString()


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

End Class
