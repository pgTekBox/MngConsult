Imports System.Web
Imports System.Configuration

''' <summary>
''' Déclencheur du dispatcher de webhooks. À appeler périodiquement (SQL
''' Agent, tâche planifiée) avec l'en-tête X-Dispatch-Secret = valeur de
''' Web.config "Webhook.DispatchSecret". Traite les livraisons dues.
''' </summary>
Public Class WebhookDispatcher
    Implements IHttpHandler

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"

        Dim expected As String = ConfigurationManager.AppSettings("Webhook.DispatchSecret")
        Dim provided As String = context.Request.Headers("X-Dispatch-Secret")

        ' Mode sûr par défaut : sans secret configuré, on refuse.
        If String.IsNullOrEmpty(expected) OrElse provided <> expected Then
            context.Response.StatusCode = 401
            context.Response.Write("{""error"":""unauthorized""}")
            Return
        End If

        Dim maxParam As Integer
        If Not Integer.TryParse(context.Request.QueryString("max"), maxParam) OrElse maxParam <= 0 Then maxParam = 50

        Try
            Dim n As Integer = clsWebhookDispatcher.ProcessDueDeliveries(maxParam)
            context.Response.Write("{""processed"":" & n & "}")
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write("{""error"":""server_error""}")
            System.Diagnostics.Debug.WriteLine("WebhookDispatcher: " & ex.Message)
        End Try
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
