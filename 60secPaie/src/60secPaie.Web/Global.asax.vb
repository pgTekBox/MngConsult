Public Class Global_asax
    Inherits System.Web.HttpApplication

    Sub Application_Error(sender As Object, e As EventArgs)
        ' Trace minimale : les erreurs non gérées vont dans le journal d'événements de débogage.
        Dim ex = Server.GetLastError()
        If ex IsNot Nothing Then System.Diagnostics.Trace.TraceError(ex.ToString())
    End Sub

End Class
