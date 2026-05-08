Public Class wbfFakeEmail
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ' Récupérer le courriel simulé depuis la session
        Dim mail = TryCast(Session("FakeEmail"), FakeEmailMessage)

        If mail Is Nothing Then
            pnlMail.Visible = False
            pnlEmpty.Visible = True
            Return
        End If

        litFrom.Text = mail.FromDisplay
        litTo.Text = mail.ToEmail
        litSubject.Text = mail.Subject
        hfBody.Value = mail.HtmlBody

        'If Not String.IsNullOrEmpty(mail.ActionLink) Then
        '    lnkOpenLink.NavigateUrl = mail.ActionLink
        '    lnkOpenLink.Visible = True
        'Else
        '    lnkOpenLink.Visible = False
        'End If
    End Sub

End Class


''' <summary>
''' Représente un courriel simulé stocké en Session.
''' </summary>
<Serializable()>
Public Class FakeEmailMessage
    Public Property FromDisplay As String = "MngConsul <noreply@mngconsul.com>"
    Public Property ToEmail As String
    Public Property Subject As String
    Public Property HtmlBody As String
    Public Property ActionLink As String
End Class
