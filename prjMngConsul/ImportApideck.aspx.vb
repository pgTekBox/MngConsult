Imports System.Data.SqlClient
Imports System.Text
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

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
'''      tel quel, y compris les quinze ressources qui n'ont pas encore
'''      d'écran. Le jour où l'écran existe, la donnée est déjà là.
'''
'''   2. Les douze que l'application sait traiter — comptes, clients,
'''      fournisseurs, produits — sont en plus versées dans les tables de
'''      préparation habituelles, par les mêmes procédures que les imports par
'''      fichier. Les écrans Plan comptable, Clients, Fournisseurs et Produits
'''      les affichent alors sans rien savoir d'Apideck, avec leurs contrôles de
'''      doublons et leur bouton de création.
'''
''' C'est ce deuxième point qui justifie l'écran : sans lui, on aurait des
''' données fraîches que personne ne saurait appliquer.
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
        AfficherRessources()
        AfficherHistorique()
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
        AfficherRessources()
        AfficherHistorique()
    End Sub

#End Region

#Region "L'extraction"

    ''' <summary>
    ''' L'écran ne fait plus que rassembler : ce qui est coché, la date, la
    ''' fréquence — et confie le tout au moteur <see cref="ApideckExtraction"/>,
    ''' celui-là même que chaque écran d'import appelle par son propre bouton.
    ''' Une ressource qui échoue n'arrête pas les autres ; le tableau le dit.
    ''' </summary>
    Protected Sub btnImporter_Click(sender As Object, e As EventArgs) Handles btnImporter.Click

        Dim choisies As List(Of ApideckExtraction.Ressource) = RessourcesChoisies()
        If choisies.Count = 0 Then
            AfficherRessources()
            AfficherHistorique()
            Message("Choisissez au moins une ressource à rapatrier.", "err")
            Return
        End If

        Dim moteur As New ApideckExtraction(Me) With {
            .DateArret = DateBalance(),
            .MoisParPeriode = MoisParPeriode()
        }

        Dim res As ApideckExtraction.Resultat

        Try
            res = moteur.Importer(choisies)
        Catch ex As Exception
            AfficherRessources()
            AfficherHistorique()
            Message("L'extraction n'a pas pu s'ouvrir : " & ex.Message, "err")
            Return
        End Try

        Dim lignes As New StringBuilder()

        For Each l As ApideckExtraction.LigneResultat In res.Lignes
            lignes.Append("<tr")
            If Not l.Reussie Then lignes.Append(" class='ko'")
            lignes.Append("><td>").Append(Server.HtmlEncode(l.Ressource.Libelle))
            lignes.Append(" <span style='color:#94a3b8'>").Append(l.Ressource.Cle).Append("</span></td>")
            lignes.Append("<td class='n'>").Append(If(l.Reussie, l.Nb.ToString("N0"), "—")).Append("</td>")

            lignes.Append("<td>")
            If Not l.Reussie Then
                lignes.Append("<span class='ko-txt'>").Append(Server.HtmlEncode(l.Erreur)).Append("</span>")
            ElseIf l.VersDit <> "" Then
                lignes.Append("<span class='vers'>").Append(Server.HtmlEncode(l.VersDit)).Append("</span>")
            Else
                lignes.Append("<span style='color:#64748b'>déposé en préparation</span>")
            End If
            lignes.Append("</td></tr>")
        Next

        AfficherRessources()
        AfficherResultat(lignes.ToString(), res.Total, res.Echecs, res.Demandees, res.NoteTaxes)
        AfficherHistorique()
    End Sub

#End Region

#Region "Les réglages de l'écran"

    ''' <summary>
    ''' La date à laquelle la balance est arrêtée, saisie sur l'écran.
    ''' Vide tant que la ressource n'est pas demandée : c'est la seule qui en a
    ''' besoin, et on ne va pas imposer une date à qui rapatrie des clients.
    ''' </summary>
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

    Private Sub AfficherRessources()
        Dim sb As New StringBuilder()
        sb.Append("<div class='ress'>")

        Dim groupe As String = ""
        For Each r As ApideckExtraction.Ressource In ApideckExtraction.Catalogue
            If r.Groupe <> groupe Then
                groupe = r.Groupe
                sb.Append("<div class='grp'>").Append(Server.HtmlEncode(groupe)).Append("</div>")
            End If

            ' Celles que l'application sait appliquer sont cochées d'avance :
            ' ce sont celles qui font avancer une reprise aujourd'hui.
            ' Celles que l'application sait appliquer sont cochées d'avance :
            ' ce sont celles qui font avancer une reprise aujourd'hui.
            Dim coche As String = If(r.Vers <> "", " checked='checked'", "")

            sb.Append("<label><input type='checkbox' name='res' value='")
            sb.Append(r.Cle).Append("'").Append(coche).Append(" />")
            sb.Append(Server.HtmlEncode(r.Libelle))

            If r.Vers <> "" Then
                sb.Append("<span class='vers'>→ écran d'import</span>")
            End If

            sb.Append("</label>")
        Next

        sb.Append("</div>")
        litRessources.Text = sb.ToString()
    End Sub

    ''' <summary>Ce que l'utilisateur a coché, dans l'ordre du catalogue.</summary>
    Private Function RessourcesChoisies() As List(Of ApideckExtraction.Ressource)
        Dim cochees As String() = Request.Form.GetValues("res")
        If cochees Is Nothing Then Return New List(Of ApideckExtraction.Ressource)

        Dim voulues As New HashSet(Of String)(cochees)
        Return ApideckExtraction.Catalogue.Where(Function(r) voulues.Contains(r.Cle)).ToList()
    End Function

    Private Sub AfficherResultat(lignes As String, total As Integer, echecs As Integer,
                                 demandees As Integer, noteTaxes As String)
        Dim sb As New StringBuilder()

        sb.Append("<div class='msg ").Append(If(echecs = 0, "ok", "err")).Append("'>")
        sb.Append(total.ToString("N0")).Append(" enregistrement(s) déposés en préparation, sur ")
        sb.Append(demandees).Append(" ressource(s) demandée(s).")
        If echecs > 0 Then
            sb.Append(" ").Append(echecs).Append(" n'ont pas répondu — le détail est dans le tableau.")
        End If
        sb.Append(" Rien n'a été écrit en comptabilité : les écrans d'import décident de la suite.")
        sb.Append("</div>")

        If noteTaxes <> "" Then
            sb.Append("<div class='msg'>").Append(Server.HtmlEncode(noteTaxes)).Append("</div>")
        End If

        sb.Append("<table class='res'><tr><th>Ressource</th><th style='text-align:right'>Enregistrements</th>")
        sb.Append("<th>Ce qui en a été fait</th></tr>")
        sb.Append(lignes).Append("</table>")

        litResultat.Text = sb.ToString()
        pnlResultat.Visible = True
    End Sub

    Private Sub AfficherHistorique()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0779GetConnecteurRuns", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            litHistorique.Text = "<div style='font-size:13px;color:#64748b'>Aucune extraction pour cette compagnie.</div>"
            Return
        End If

        Dim sb As New StringBuilder()
        sb.Append("<table class='res'><tr><th>Quand</th><th>Source</th>")
        sb.Append("<th style='text-align:right'>Ressources</th><th style='text-align:right'>Enregistrements</th>")
        sb.Append("<th>État</th></tr>")

        For Each r As DataRow In ds.Tables(0).Rows
            sb.Append("<tr><td>").Append(Convert.ToDateTime(r("Debut")).ToString("yyyy-MM-dd HH:mm")).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(r("Service").ToString())).Append("</td>")
            sb.Append("<td class='n'>").Append(r("NbRessources")).Append("</td>")
            sb.Append("<td class='n'>").Append(Convert.ToInt32(r("NbEnregistrements")).ToString("N0")).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(r("Statut").ToString()))

            If Not IsDBNull(r("Note")) AndAlso r("Note").ToString() <> "" Then
                sb.Append(" <span class='ko-txt'>").Append(Server.HtmlEncode(r("Note").ToString())).Append("</span>")
            End If

            sb.Append("</td></tr>")
        Next

        sb.Append("</table>")
        litHistorique.Text = sb.ToString()
    End Sub

    Private Sub Message(texte As String, genre As String)
        litMsg.Text = "<div class='msg " & genre & "'>" & Server.HtmlEncode(texte) & "</div>"
    End Sub

#End Region

End Class
