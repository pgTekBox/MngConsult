Imports System.Net
Imports System.Net.Mail
Imports System.Configuration

Public Class EmailHelper

    ''' <summary>
    ''' Envoie un courriel HTML.
    ''' Configuration via Web.config (section system.net/mailSettings/smtp)
    ''' OU via les clés AppSettings : SmtpHost, SmtpPort, SmtpUser, SmtpPassword, SmtpFrom, SmtpEnableSSL
    ''' </summary>
    Public Shared Sub Send(toEmail As String, subject As String, htmlBody As String)

        ' Lire les paramètres depuis Web.config
        Dim host As String = GetSetting("SmtpHost", "")
        Dim port As Integer = Integer.Parse(GetSetting("SmtpPort", "587"))
        Dim user As String = GetSetting("SmtpUser", "")
        Dim pwd As String = GetSetting("SmtpPassword", "")
        Dim fromEmail As String = GetSetting("SmtpFrom", user)
        Dim fromName As String = GetSetting("SmtpFromName", "60Sec-AI")
        Dim ssl As Boolean = Boolean.Parse(GetSetting("SmtpEnableSSL", "True"))

        If String.IsNullOrEmpty(host) Then
            Throw New Exception("SmtpHost n'est pas configuré dans Web.config (AppSettings).")
        End If
        If String.IsNullOrEmpty(fromEmail) Then
            Throw New Exception("SmtpFrom n'est pas configuré dans Web.config (AppSettings).")
        End If

        Using msg As New MailMessage()
            msg.From = New MailAddress(fromEmail, fromName)
            msg.To.Add(toEmail)
            msg.Subject = subject
            msg.Body = htmlBody
            msg.IsBodyHtml = True
            msg.BodyEncoding = System.Text.Encoding.UTF8
            msg.SubjectEncoding = System.Text.Encoding.UTF8

            Using smtp As New SmtpClient(host, port)
                smtp.EnableSsl = ssl
                If Not String.IsNullOrEmpty(user) Then
                    smtp.Credentials = New NetworkCredential(user, pwd)
                End If
                smtp.DeliveryMethod = SmtpDeliveryMethod.Network

                smtp.Send(msg)
            End Using
        End Using
    End Sub

    Private Shared Function GetSetting(key As String, defaultValue As String) As String
        Dim v = ConfigurationManager.AppSettings(key)
        If String.IsNullOrEmpty(v) Then Return defaultValue
        Return v
    End Function

End Class
