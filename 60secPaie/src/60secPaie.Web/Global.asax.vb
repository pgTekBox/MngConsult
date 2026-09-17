Public Class Global_asax
    Inherits System.Web.HttpApplication

    ''' <summary>
    ''' La racine du site montre la présentation, pas la page de connexion.
    '''
    ''' Le document par défaut ne suffit pas : l'autorisation d'ASP.NET juge
    ''' l'URL demandée — « / » — bien avant qu'IIS ne la résolve vers un
    ''' fichier. La règle « deny users=? » frappe donc la racine et renvoie le
    ''' visiteur vers Login.aspx sans qu'il ait rien vu du service.
    '''
    ''' BeginRequest passe avant AuthorizeRequest : c'est le seul endroit d'où
    ''' l'on peut rattraper la racine. On ne touche à rien d'autre — un visiteur
    ''' qui demande une page protégée aboutit toujours à la connexion, avec son
    ''' ReturnUrl intact.
    ''' </summary>
    Sub Application_BeginRequest(sender As Object, e As EventArgs)
        Dim chemin = Request.AppRelativeCurrentExecutionFilePath
        If chemin <> "~/" Then Return

        Dim connecte = (Request.IsAuthenticated)
        If connecte Then Return

        ' La chaîne de requête suit : sans elle, « /?lang=en » rendrait du français.
        Response.Redirect("~/Accueil.aspx" & Request.Url.Query, False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Sub Application_Error(sender As Object, e As EventArgs)
        ' Trace minimale : les erreurs non gérées vont dans le journal d'événements de débogage.
        Dim ex = Server.GetLastError()
        If ex IsNot Nothing Then System.Diagnostics.Trace.TraceError(ex.ToString())
    End Sub

End Class
