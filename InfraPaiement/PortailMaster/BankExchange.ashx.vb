Imports System.Web
Imports System.Configuration

''' <summary>
''' Declencheur de l'echange bancaire (envoi des .005 + reception/traitement
''' des retours et releves). A appeler periodiquement (SQL Agent / Planificateur)
''' avec l'en-tete X-Exchange-Secret = Web.config Bank.ExchangeSecret.
''' </summary>
Public Class BankExchange
    Implements IHttpHandler

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim ctx As HttpContext = context
        ctx.Response.ContentType = "application/json"

        Dim expected As String = ConfigurationManager.AppSettings("Bank.ExchangeSecret")
        Dim provided As String = ctx.Request.Headers("X-Exchange-Secret")
        If String.IsNullOrEmpty(expected) OrElse provided <> expected Then
            ctx.Response.StatusCode = 401
            ctx.Response.Write("{""error"":""unauthorized""}")
            Return
        End If

        Try
            Dim push As clsBankExchange.ExchangeResult = clsBankExchange.PushOutbound()
            Dim pull As clsBankExchange.ExchangeResult = clsBankExchange.PullInbound()
            ctx.Response.Write("{""sent"":" & push.Sent & ",""received"":" & pull.Processed &
                               ",""errors"":" & (push.Errors + pull.Errors) & "}")
        Catch ex As Exception
            ctx.Response.StatusCode = 500
            ctx.Response.Write("{""error"":""server_error""}")
            System.Diagnostics.Debug.WriteLine("BankExchange: " & ex.ToString())
        End Try
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
