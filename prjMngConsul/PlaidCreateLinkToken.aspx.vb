Imports Newtonsoft.Json
Imports System.IO

Public Class PlaidCreateLinkToken
    Inherits System.Web.UI.Page

    Protected Async Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Response.ContentType = "application/json"

        If Request.HttpMethod <> "POST" Then
            Response.Write("{""success"":false,""message"":""POST requis""}")
            Response.End()
            Return
        End If

        Try
            Dim svc As New Plaid()

            ' Remplace ceci par ton vrai identifiant stable
            Dim clientUserId As String = GetClientUserId()

            Dim linkToken As String = Await svc.CreateLinkTokenAsync(clientUserId)

            Response.Write("{""success"":true,""link_token"":""" & EscapeJson(linkToken) & """}")
        Catch ex As Exception
            Response.Write("{""success"":false,""message"":""" & EscapeJson(ex.Message) & """}")
        End Try

        Response.End()
    End Sub
    Private Function GetClientUserId() As String
        ' Exemple:
        ' Return Session("CompanyGUID").ToString()
        ' ou Return Company.ToString() si tu as cette propriété dans ton projet

        If Session("CompanyGUID") IsNot Nothing Then
            Return Session("CompanyGUID").ToString()
        End If

        Return "demo-user-1"
    End Function

    Private Function EscapeJson(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("\", "\\").Replace("""", "\""").Replace(vbCrLf, "\n").Replace(vbCr, "\n").Replace(vbLf, "\n")
    End Function
End Class