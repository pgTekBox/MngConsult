Imports System.Text

''' <summary>
''' Importer depuis QuickBooks par Apideck — l'autre voie de reprise.
'''
''' Les écrans d'import existants partent d'un fichier que le client a exporté.
''' Celui-ci part de sa comptabilité elle-même : il la lit par l'API unifiée
''' d'Apideck, qui traduit chaque appel vers QuickBooks — et vers Sage le jour
''' où on changera la clé Apideck.ServiceId.
'''
''' Ce qui arrive ne va PAS en comptabilité. Deux dépôts, dans cet ordre :
'''
'''   1. staging.ConnecteurDonnee reçoit TOUT, en JSON brut, ressource par
'''      ressource. Rien n'est interprété : ce qu'Apideck a rendu est conservé
'''      tel quel, y compris les ressources qui n'ont pas encore d'écran. Le
'''      jour où l'écran existe, la donnée est déjà là.
'''
'''   2. Celles que l'application sait traiter — comptes, clients,
'''      fournisseurs, produits, factures… — sont en plus versées dans les
'''      tables de préparation habituelles, par les mêmes procédures que les
'''      imports par fichier. Les écrans d'import les affichent alors sans rien
'''      savoir d'Apideck, avec leurs contrôles de doublons et leur bouton de
'''      création.
'''
''' C'est ce deuxième point qui justifie l'écran : sans lui, on aurait des
''' données fraîches que personne ne saurait appliquer.
'''
''' Il n'y a rien à choisir : chaque extraction rapatrie tout le catalogue.
''' Trier d'avance obligeait à savoir ce qu'on voulait avant d'avoir vu ce
''' qu'il y a ; tout prendre, puis décider écran par écran, est plus sûr.
'''
''' Le moteur lui-même — lire, déposer, verser — vit dans ApideckExtraction :
''' chaque écran d'import l'appelle aussi, par son propre bouton, pour la
''' seule ressource qu'il sait montrer. Cette page reste celle qui rapatrie tout.
''' </summary>
Public Class ImportApideck
    Inherits clsData

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If IsPostBack Then Return

        AfficherEtat()
        AfficherCatalogue()
    End Sub

#End Region

#Region "La liaison"

    ''' <summary>
    ''' Où en est la compagnie : configurée côté serveur, puis reliée côté
    ''' client. Les deux échecs n'appellent pas la même action, donc on les
    ''' distingue au lieu d'afficher « non connecté ».
    ''' </summary>
    Private Sub AfficherEtat()
        If Not clsApideck.IsConfigured() Then
            pastille.Attributes("class") = "pastille off"
            litEtat.Text = "Apideck n'est pas configuré sur ce serveur : la clé d'API ou l'App ID " &
                           "manquent dans la configuration. Rien ne peut être importé tant que ce n'est pas fait."
            btnRelier.Enabled = False
            btnVerifier.Enabled = False
            btnImporter.Enabled = False
            Return
        End If

        Try
            Dim api As New clsApideck(Company.ToString())
            If api.IsConnected() Then
                pastille.Attributes("class") = "pastille on"
                litEtat.Text = "La comptabilité de cette compagnie est reliée. Les extractions liront " &
                               "les données à jour, sans nouvelle intervention du client."
            Else
                pastille.Attributes("class") = "pastille mid"
                litEtat.Text = "Cette compagnie n'a pas encore relié sa comptabilité. « Relier QuickBooks » " &
                               "ouvre la page d'Apideck où le client entre ses identifiants — nous ne les voyons jamais."
                btnImporter.Enabled = False
            End If

        Catch ex As Exception
            pastille.Attributes("class") = "pastille off"
            litEtat.Text = "Impossible de joindre Apideck : " & Server.HtmlEncode(ex.Message)
            btnImporter.Enabled = False
        End Try
    End Sub

    ''' <summary>
    ''' Ouvre une session Vault et y envoie l'utilisateur. L'adresse expire vite :
    ''' on en demande une neuve à chaque clic plutôt que d'en garder une.
    ''' </summary>
    Protected Sub btnRelier_Click(sender As Object, e As EventArgs) Handles btnRelier.Click
        Try
            Dim api As New clsApideck(Company.ToString())
            Dim url As String = api.CreateVaultSession(CompanyName)

            If url = "" Then
                Message("Apideck n'a pas rendu d'adresse de liaison.", "err")
                Return
            End If

            Response.Redirect(url, False)
            Context.ApplicationInstance.CompleteRequest()

        Catch ex As Exception
            Message("La liaison n'a pas pu s'ouvrir : " & ex.Message, "err")
        End Try
    End Sub

    Protected Sub btnVerifier_Click(sender As Object, e As EventArgs) Handles btnVerifier.Click
        AfficherEtat()
        AfficherCatalogue()
    End Sub

#End Region

#Region "L'extraction"

    ''' <summary>
    ''' L'écran ne fait que rassembler la date et la fréquence, et confie tout
    ''' le catalogue au moteur <see cref="ApideckExtraction"/> — celui-là même
    ''' que chaque écran d'import appelle par son propre bouton. Une ressource
    ''' qui échoue n'arrête pas les autres ; le compte rendu nomme chaque échec.
    '''
    ''' La date est exigée avant de partir : cinq ressources en ont besoin, et
    ''' puisqu'elles sont toujours demandées, partir sans date garantirait cinq
    ''' erreurs qu'on aurait pu éviter d'une phrase.
    ''' </summary>
    Protected Sub btnImporter_Click(sender As Object, e As EventArgs) Handles btnImporter.Click
        AfficherCatalogue()

        Dim dateArret As Date? = DateBalance()
        If Not dateArret.HasValue Then
            Message("Indiquez la date de bascule avant d'importer : la balance de vérification, le grand livre, " &
                    "les taxes, les remises et le pointage se lisent sur une période.", "err")
            Return
        End If

        Dim moteur As New ApideckExtraction(Me) With {
            .DateArret = dateArret,
            .MoisParPeriode = MoisParPeriode()
        }

        Dim res As ApideckExtraction.Resultat

        Try
            res = moteur.Importer(ApideckExtraction.Catalogue)
        Catch ex As Exception
            Message("L'extraction n'a pas pu s'ouvrir : " & ex.Message, "err")
            Return
        End Try

        AfficherResultat(res)
    End Sub

#End Region

#Region "Les réglages de l'écran"

    ''' <summary>La date de bascule, saisie sur l'écran ; vide si elle manque.</summary>
    Private Function DateBalance() As Date?
        Return ApideckExtraction.LireDate(txtDateBalance.Text)
    End Function

    ''' <summary>
    ''' Le nombre de mois d'une période de déclaration, choisi sur l'écran.
    ''' Trimestriel par défaut — le cas le plus courant ici.
    ''' </summary>
    Private Function MoisParPeriode() As Integer
        Return ApideckExtraction.LireFrequence(ddlFrequenceTaxes.SelectedValue)
    End Function

#End Region

#Region "Affichage"

    ''' <summary>
    ''' Une phrase pour dire ce que l'extraction rapatrie, puisqu'il n'y a plus
    ''' de liste à lire : le nombre de ressources, et où elles vont ensuite.
    ''' </summary>
    Private Sub AfficherCatalogue()
        Dim total As Integer = ApideckExtraction.Catalogue.Count
        litTout.Text = "Chaque extraction rapatrie <span class='n'>les " & total & " ressources</span> " &
                       "que QuickBooks expose par Apideck — plan comptable, tiers, articles, factures, " &
                       "règlements, grand livre, taxes, paie, inventaire et le reste. Chacune est déposée " &
                       "en préparation telle quelle, puis rejoint l'écran d'import où elle se valide."
    End Sub

    ''' <summary>
    ''' Le compte rendu : le total en une phrase, puis les erreurs en premier et
    ''' en rouge — c'est ce qu'on vient lire. Le détail des ressources réussies
    ''' reste disponible, replié, pour qui veut vérifier les décomptes.
    ''' </summary>
    Private Sub AfficherResultat(res As ApideckExtraction.Resultat)
        Dim sb As New StringBuilder()
        Dim echecs = res.Lignes.Where(Function(l) Not l.Reussie).ToList()
        Dim reussies = res.Lignes.Where(Function(l) l.Reussie).ToList()

        sb.Append("<div class='msg ").Append(If(echecs.Count = 0, "ok", "err")).Append("'>")
        sb.Append(res.Total.ToString("N0")).Append(" enregistrement(s) déposés en préparation, sur ")
        sb.Append(res.Demandees).Append(" ressource(s).")
        If echecs.Count > 0 Then
            sb.Append(" ").Append(echecs.Count).Append(" n'ont pas répondu — le détail est ci-dessous.")
        End If
        sb.Append(" Rien n'a été écrit en comptabilité : les écrans d'import décident de la suite.")
        sb.Append("</div>")

        If res.NoteTaxes <> "" Then
            sb.Append("<div class='msg info'>").Append(Server.HtmlEncode(res.NoteTaxes)).Append("</div>")
        End If

        If echecs.Count > 0 Then
            sb.Append("<h3 class='erreurs'>").Append(echecs.Count).Append(" ressource(s) en erreur</h3>")
            sb.Append("<table class='res'><tr><th>Ressource</th><th>Erreur</th></tr>")
            For Each l As ApideckExtraction.LigneResultat In echecs
                sb.Append("<tr class='ko'><td>").Append(Server.HtmlEncode(l.Ressource.Libelle))
                sb.Append(" <span style='color:#94a3b8'>").Append(l.Ressource.Cle).Append("</span></td>")
                sb.Append("<td><span class='ko-txt'>").Append(Server.HtmlEncode(l.Erreur)).Append("</span></td></tr>")
            Next
            sb.Append("</table>")
        End If

        If reussies.Count > 0 Then
            sb.Append("<details class='detail'><summary>Voir le détail des ").Append(reussies.Count)
            sb.Append(" ressource(s) rapatriée(s)</summary>")
            sb.Append("<table class='res'><tr><th>Ressource</th><th style='text-align:right'>Enregistrements</th>")
            sb.Append("<th>Ce qui en a été fait</th></tr>")
            For Each l As ApideckExtraction.LigneResultat In reussies
                sb.Append("<tr><td>").Append(Server.HtmlEncode(l.Ressource.Libelle))
                sb.Append(" <span style='color:#94a3b8'>").Append(l.Ressource.Cle).Append("</span></td>")
                sb.Append("<td class='n'>").Append(l.Nb.ToString("N0")).Append("</td><td>")
                If l.VersDit <> "" Then
                    sb.Append("<span class='vers'>").Append(Server.HtmlEncode(l.VersDit)).Append("</span>")
                Else
                    sb.Append("<span style='color:#64748b'>déposé en préparation</span>")
                End If
                sb.Append("</td></tr>")
            Next
            sb.Append("</table></details>")
        End If

        litResultat.Text = sb.ToString()
        pnlResultat.Visible = True
    End Sub

    Private Sub Message(texte As String, genre As String)
        litMsg.Text = "<div class='msg " & genre & "'>" & Server.HtmlEncode(texte) & "</div>"
    End Sub

#End Region

End Class
