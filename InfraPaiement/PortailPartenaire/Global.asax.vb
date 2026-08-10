Imports System.Web

''' <summary>
''' Application PortailPartenaire. Cycle de vie minimal (session InProc,
''' authentification par Session geree dans clsData / Site.Master).
''' </summary>
Public Class Global_asax
    Inherits System.Web.HttpApplication

    Sub Application_Start(sender As Object, e As EventArgs)
    End Sub

    Sub Application_BeginRequest(sender As Object, e As EventArgs)
    End Sub

    Sub Application_End(sender As Object, e As EventArgs)
    End Sub

End Class
