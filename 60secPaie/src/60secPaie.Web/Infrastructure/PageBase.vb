Imports System.Web.Security

''' <summary>
''' Page de base : compte MngConsul actif, rôle administrateur, compagnie courante configurée pour la paie,
''' traduction du HTML à la sortie, messages, sous-menus et téléchargements.
''' </summary>
Public Class PageBase
    Inherits System.Web.UI.Page

    Protected Overridable ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return True
        End Get
    End Property

    Protected Overridable ReadOnly Property ExigeAdmin As Boolean
        Get
            Return False
        End Get
    End Property

    Protected Overrides Sub OnLoad(e As EventArgs)
        ' Compte supprimé ou désactivé dans MngConsul pendant la session, ou plus aucune compagnie accessible : on ferme la session.
        If Contexte.Compte Is Nothing OrElse Contexte.CompanyGuid = Guid.Empty Then
            FormsAuthentication.SignOut()
            Session.Abandon()
            Response.Redirect("~/Login.aspx", True)
        End If

        If ExigeAdmin AndAlso Not Contexte.EstAdmin Then
            RedirigerAvecMessage("~/Default.aspx", Tr("Cette page est réservée aux administrateurs."))
        End If

        ' La paie n'est pas encore configurée pour la compagnie courante.
        If ExigeCompagnie AndAlso Contexte.CompagnieId = 0 Then
            Session("flash") = Tr("La paie n'est pas encore configurée pour {0}. Commencez par ses paramètres de paie.", Contexte.NomCompagnie)
            Response.Redirect("~/Config/Compagnie.aspx", True)
        End If
        MyBase.OnLoad(e)
    End Sub

    ''' <summary>Les pages sont écrites en français ; le HTML produit est traduit ici, en un seul endroit.</summary>
    Protected Overrides Sub Render(writer As HtmlTextWriter)
        I18n.RendreTraduit(writer, Sub(w) MyBase.Render(w))
    End Sub

    ' ---------- Sous-menus ----------

    Private Function SousMenu(actif As String, ParamArray items As String()()) As String
        Dim sb As New System.Text.StringBuilder("<div class=""sous-menu sans-impression"">")
        For Each item In items
            sb.Append("<a href=""").Append(ResolveUrl(item(1))).Append("""").Append(If(item(0) = actif, " class=""actif""", "")).Append(">")
            sb.Append(HttpUtility.HtmlEncode(item(2))).Append("</a>")
        Next
        Return sb.Append("</div>").ToString()
    End Function

    Protected Function SousMenuConfig(actif As String) As String
        Return SousMenu(actif,
            {"compagnie", "~/Config/Compagnie.aspx", "Paramètres de paie"},
            {"elements", "~/Config/ElementsPaie.aspx", "Éléments de paie"},
            {"comptes", "~/Config/PlanComptable.aspx", "Plan comptable"},
            {"depot", "~/Config/DepotDirect.aspx", "Dépôt direct"})
    End Function

    Protected Function SousMenuRapports(actif As String) As String
        Return SousMenu(actif,
            {"feuillets", "~/Rapports/Feuillets.aspx", "T4 et Relevés 1"},
            {"cnesst", "~/Rapports/CNESST.aspx", "Déclaration des salaires CNESST"},
            {"ecritures", "~/Rapports/Ecritures.aspx", "Écritures comptables"})
    End Function

    ' ---------- Fichiers ----------

    ''' <summary>Envoie un fichier en téléchargement et termine la requête.</summary>
    Protected Sub EnvoyerFichier(nomFichier As String, contenu As Byte(), typeMime As String)
        Response.Clear()
        Response.ContentType = typeMime
        Response.AddHeader("Content-Disposition", "attachment; filename=""" & nomFichier.Replace("""", "") & """")
        Response.AddHeader("Cache-Control", "no-store")
        Response.BinaryWrite(contenu)
        Response.End()
    End Sub

    ''' <summary>CSV pour Excel : séparateur point-virgule, UTF-8 avec BOM.</summary>
    Protected Sub EnvoyerCsv(nomFichier As String, lignes As IEnumerable(Of String()))
        Dim sb As New System.Text.StringBuilder()
        For Each ligne In lignes
            sb.AppendLine(String.Join(";", ligne.Select(Function(c) CelluleCsv(c))))
        Next
        Dim utf8 = New System.Text.UTF8Encoding(True)
        EnvoyerFichier(nomFichier, utf8.GetPreamble().Concat(utf8.GetBytes(sb.ToString())).ToArray(), "text/csv")
    End Sub

    Private Shared Function CelluleCsv(valeur As String) As String
        Dim v = If(valeur, "")
        ' Neutralise les formules (injection CSV) dans les textes issus de la base.
        If v.Length > 0 AndAlso "=+@".IndexOf(v(0)) >= 0 Then v = "'" & v
        If v.IndexOfAny({";"c, """"c, ControlChars.Cr, ControlChars.Lf}) >= 0 Then v = """" & v.Replace("""", """""") & """"
        Return v
    End Function

    Protected Function IdRequete(nom As String) As Integer
        Dim v As Integer
        Return If(Integer.TryParse(Request.QueryString(nom), v) AndAlso v > 0, v, 0)
    End Function

    ' ---------- Messages ----------

    Protected Sub Succes(message As String)
        DirectCast(Master, SiteMaster).Afficher(message, False)
    End Sub

    Protected Sub Erreur(message As String)
        DirectCast(Master, SiteMaster).Afficher(message, True)
    End Sub

    ''' <summary>Redirige et affiche le message sur la page suivante.</summary>
    Protected Sub RedirigerAvecMessage(url As String, message As String)
        Session("flash") = message
        Response.Redirect(url, True)
    End Sub

End Class
