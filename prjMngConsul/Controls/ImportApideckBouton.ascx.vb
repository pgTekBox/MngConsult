Imports System.Text

''' <summary>
''' « Importer depuis QuickBooks » — le même bouton sur chaque écran d'import.
'''
''' La page « Importer depuis QuickBooks » rapatrie tout d'un coup. Mais qui
''' est sur l'écran des clients veut ses clients, pas les vingt-huit ressources
''' du catalogue : ce contrôle ne demande au moteur <see cref="ApideckExtraction"/>
''' que ce que l'écran qui le pose sait montrer (<see cref="Ressources"/>), et
''' l'écran se recharge ensuite sur la préparation, comme s'il venait d'y
''' déposer un fichier.
'''
''' Après l'extraction, on redirige sur la même adresse plutôt que de rester sur
''' le postback : chaque écran retrouve ainsi ce qu'il montre par son propre
''' chemin de chargement, et un rafraîchissement du navigateur ne relance pas
''' une extraction. Le compte rendu traverse la redirection par la session.
'''
''' La date d'arrêt, quand une ressource la demande, est retenue en session :
''' c'est la date de bascule, la même pour tous les écrans.
''' </summary>
Public Class ImportApideckBouton
    Inherits clsDataUC

    ''' <summary>Les clés du catalogue à rapatrier, séparées par des virgules : « customers », « invoices,bills »…</summary>
    Public Property Ressources As String = ""

    ''' <summary>Le texte du bouton, quand celui par défaut ne convient pas.</summary>
    Public Property Libelle As String = ""

    Private Const CleResultat As String = "ApideckBouton.Resultat"
    Private Const CleDate As String = "ApideckBouton.DateArret"
    Private Const CleRelie As String = "ApideckBouton.Relie"
    Private Const CleRelieQuand As String = "ApideckBouton.RelieQuand"

    ''' <summary>
    ''' L'état de la liaison est demandé à Apideck : un appel réseau. Le
    ''' garder dix minutes évite de le refaire à chaque écran ouvert.
    ''' </summary>
    Private Const MinutesEtat As Integer = 10

    Private ReadOnly Property Choisies As List(Of ApideckExtraction.Ressource)
        Get
            Return ApideckExtraction.Choisir(Ressources)
        End Get
    End Property

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ' La date de bascule, la même d'un écran à l'autre.
        txtDate.Text = If(TryCast(Session(CleDate), String), "")

        ' Le compte rendu de l'extraction qui vient d'avoir lieu, s'il y en a un.
        Dim html As String = TryCast(Session(CleResultat), String)
        If Not String.IsNullOrEmpty(html) Then
            litResultat.Text = html
            Session.Remove(CleResultat)
        End If
    End Sub

    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim liste As List(Of ApideckExtraction.Ressource) = Choisies

        ' Aucune ressource connue : le bouton n'a rien à faire, il s'efface.
        If liste.Count = 0 Then
            Visible = False
            Return
        End If

        pnlDate.Visible = liste.Any(Function(r) r.AvecDate)
        ddlFrequence.Visible = liste.Any(Function(r) r.AvecFrequence)
        If Libelle <> "" Then btnImporter.Text = Libelle

        AfficherEtat(liste)
    End Sub

#End Region

#Region "L'état de la liaison"

    ''' <summary>
    ''' Trois états, trois actions : configurer le serveur, relier la
    ''' compagnie, ou importer. On les distingue au lieu d'un « non connecté ».
    ''' </summary>
    Private Sub AfficherEtat(liste As List(Of ApideckExtraction.Ressource))
        Dim quoi As String = String.Join(", ", liste.Select(Function(r) H(r.Libelle)))

        If Not clsApideck.IsConfigured() Then
            spanEtat.Attributes("class") = "apb-etat ko"
            litEtat.Text = "Apideck n'est pas configuré sur ce serveur : rien ne peut être importé."
            btnImporter.Enabled = False
            hlLiaison.Visible = False
            Return
        End If

        Dim erreur As String = ""
        If EstReliee(erreur) Then
            spanEtat.Attributes("class") = "apb-etat"
            litEtat.Text = "Rapatrie : " & quoi & ". Tout se dépose en préparation, rien n'est créé."
            btnImporter.Enabled = True
            hlLiaison.Text = "Gérer la liaison"
        ElseIf erreur <> "" Then
            spanEtat.Attributes("class") = "apb-etat ko"
            litEtat.Text = "Impossible de joindre Apideck : " & H(erreur)
            btnImporter.Enabled = False
            hlLiaison.Text = "Vérifier la liaison"
        Else
            spanEtat.Attributes("class") = "apb-etat off"
            litEtat.Text = "Cette compagnie n'a pas encore relié sa comptabilité."
            btnImporter.Enabled = False
            hlLiaison.Text = "Relier QuickBooks"
        End If
    End Sub

    ''' <summary>
    ''' La liaison, telle qu'Apideck la voit — gardée dix minutes en session.
    ''' Un échec réseau n'est pas « non reliée » : il est rendu à part.
    ''' </summary>
    Private Function EstReliee(ByRef erreur As String) As Boolean
        Dim quand As Object = Session(CleRelieQuand)
        If quand IsNot Nothing AndAlso TypeOf quand Is Date AndAlso
           Date.Now.Subtract(CDate(quand)).TotalMinutes < MinutesEtat AndAlso
           Session(CleRelie) IsNot Nothing Then
            Return CBool(Session(CleRelie))
        End If

        Try
            Dim api As New clsApideck(Company.ToString())
            Dim relie As Boolean = api.IsConnected()
            Session(CleRelie) = relie
            Session(CleRelieQuand) = Date.Now
            Return relie

        Catch ex As Exception
            erreur = ex.Message
            Return False
        End Try
    End Function

    ''' <summary>Oublie l'état gardé : après une extraction qui a échoué, on redemandera.</summary>
    Private Sub OublierEtat()
        Session.Remove(CleRelie)
        Session.Remove(CleRelieQuand)
    End Sub

#End Region

#Region "L'extraction"

    Protected Sub btnImporter_Click(sender As Object, e As EventArgs) Handles btnImporter.Click
        Dim liste As List(Of ApideckExtraction.Ressource) = Choisies
        If liste.Count = 0 Then Return

        Dim hote As clsData = TryCast(Page, clsData)
        If hote Is Nothing Then
            litResultat.Text = "<div class='apb-msg err'>Cet écran ne porte pas de compagnie : l'extraction ne peut pas partir.</div>"
            Return
        End If

        Session(CleDate) = txtDate.Text
        Dim arrete As Date? = ApideckExtraction.LireDate(txtDate.Text)

        ' Une période sans date : le moteur refuserait chaque ressource une à
        ' une. Autant le dire une fois, avant de partir. L'inventaire, lui, s'en
        ' passe — QuickBooks ne rend que le stock du jour.
        If Not arrete.HasValue AndAlso liste.Any(Function(r) r.AvecDate AndAlso r.Cle <> "inventory") Then
            litResultat.Text = "<div class='apb-msg err'>Indiquez la date d'arrêt : cette lecture porte sur une période.</div>"
            Return
        End If

        Dim moteur As New ApideckExtraction(hote) With {
            .DateArret = arrete,
            .MoisParPeriode = ApideckExtraction.LireFrequence(ddlFrequence.SelectedValue)
        }

        Dim html As String

        Try
            Dim res As ApideckExtraction.Resultat = moteur.Importer(liste)
            html = Rendre(res)
            If res.Echecs > 0 Then OublierEtat()

        Catch ex As Exception
            OublierEtat()
            html = "<div class='apb-msg err'>L'extraction n'a pas pu s'ouvrir : " & H(ex.Message) & "</div>"
        End Try

        ' Le compte rendu traverse la redirection ; l'écran, lui, se recharge
        ' sur la préparation par son propre chemin.
        Session(CleResultat) = html
        Response.Redirect(Request.RawUrl, False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    ''' <summary>Le compte rendu, ressource par ressource — court, l'écran a mieux à montrer.</summary>
    Private Function Rendre(res As ApideckExtraction.Resultat) As String
        Dim sb As New StringBuilder()

        sb.Append("<div class='apb-msg ").Append(If(res.Echecs = 0, "ok", "err")).Append("'>")
        sb.Append("<b>").Append(res.Total.ToString("N0")).Append(" enregistrement(s)</b> rapatriés de QuickBooks")
        If res.Echecs > 0 Then
            sb.Append(" — ").Append(res.Echecs).Append(" ressource(s) n'ont pas répondu")
        End If
        sb.Append(". Rien n'a été écrit en comptabilité : ce qui suit attend votre décision.")

        sb.Append("<ul>")
        For Each l As ApideckExtraction.LigneResultat In res.Lignes
            sb.Append("<li>").Append(H(l.Ressource.Libelle)).Append(" : ")
            If Not l.Reussie Then
                sb.Append("<span class='ko'>").Append(H(l.Erreur)).Append("</span>")
            Else
                sb.Append(l.Nb.ToString("N0")).Append(" lu(s)")
                If l.VersDit <> "" Then sb.Append(" — <span class='vers'>").Append(H(l.VersDit)).Append("</span>")
            End If
            sb.Append("</li>")
        Next
        sb.Append("</ul>")

        If res.NoteTaxes <> "" Then
            sb.Append("<div style='margin-top:6px'>").Append(H(res.NoteTaxes)).Append("</div>")
        End If

        sb.Append("</div>")
        Return sb.ToString()
    End Function

#End Region

    Private Function H(s As String) As String
        Return Server.HtmlEncode(If(s, ""))
    End Function

End Class
