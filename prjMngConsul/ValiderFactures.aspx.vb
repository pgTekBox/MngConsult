Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Factures clients et fournisseurs — le pas entre la préparation et la
''' comptabilité.
'''
''' Les listes se valident en masse : on regarde une colonne, on crée tout ce qui
''' est nouveau. Un document, non. Il a un tiers, des dates, un détail et des
''' totaux, et chacun peut être faux séparément. Cet écran les montre donc un par
''' un, avec leur verdict, et ne crée que ce qui est coché.
'''
''' Une seule correction est possible ici : la répartition TPS/TVQ, que la
''' source ne donne pas de façon fiable. Le tiers ne se choisit pas : il est
''' reconnu parmi les clients et fournisseurs EN PRÉPARATION (T261), et la
''' facture attend qu'il soit créé depuis son écran.
'''
''' Le reste — numéro, dates, montants, lignes — vient de la source et ne se
''' retouche pas : si c'est faux, c'est la source qu'il faut corriger, pas la
''' copie, sinon les deux comptabilités divergent en silence.
'''
''' Les documents sont créés EN BROUILLON. Le déclencheur de comptabilisation ne
''' réagit qu'au changement de statut : rien ne part au grand livre ici.
''' </summary>
Public Class ValiderFactures
    Inherits clsData

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If IsPostBack Then Return
        Afficher()
    End Sub

    Protected Sub ddlType_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlType.SelectedIndexChanged
        Afficher()
    End Sub

    Protected Sub ddlEtat_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlEtat.SelectedIndexChanged
        Afficher()
    End Sub

#End Region

#Region "Les actions"

    ''' <summary>
    ''' Enregistre les corrections saisies. On ne passe en base que ce qui a
    ''' réellement changé : réécrire deux cents documents identiques pour en
    ''' corriger un serait du bruit.
    ''' </summary>
    ''' <summary>
    ''' Répartit le total des taxes en TPS et TVQ sur tout ce qui est en préparation :
    ''' d'après les taux rapatriés de la source, ou les taux du Québec à défaut (s0794).
    ''' </summary>
    Protected Sub btnTaxes_Click(sender As Object, e As EventArgs) Handles btnTaxes.Click
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0794RepartirTaxesImport", p)
            Afficher()

            Dim coupes As Integer = 0, defaut As Integer = 0, restants As Integer = 0, boiteux As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                coupes = Entier(r, "NbLignesCoupees") + Entier(r, "NbLignesParCode") + Entier(r, "NbDocumentsParTotal")
                defaut = Entier(r, "NbParDefaut")
                restants = Entier(r, "NbSansRepartition")
                boiteux = Entier(r, "NbDesequilibres")
            End If

            Dim texte As New StringBuilder()
            If coupes = 0 AndAlso defaut = 0 Then
                texte.Append("Rien à répartir : les taxes sont déjà réparties, ou aucun document ne porte de taxes.")
            Else
                texte.Append("Taxes réparties sur ").Append(coupes + defaut).Append(" élément(s)")
                If defaut > 0 Then texte.Append(", dont ").Append(defaut).Append(" aux taux du Québec (5 % + 9,975 %) faute de taux dans la source")
                texte.Append(".")
            End If
            If restants > 0 Then texte.Append(" ").Append(restants).Append(" document(s) restent sans répartition : saisissez TPS et TVQ, puis Enregistrer les corrections.")
            If boiteux > 0 Then texte.Append(" ").Append(boiteux).Append(" ne bouclent pas (sous-total + taxes ≠ total).")
            Message(texte.ToString(), If(restants > 0 OrElse boiteux > 0, "info", "ok"))

        Catch ex As Exception
            Afficher()
            Message("La répartition a échoué : " & ex.Message, "err")
        End Try
    End Sub

    Protected Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Dim touches As Integer = 0

        For Each cle As String In Request.Form.AllKeys
            If cle Is Nothing OrElse Not cle.StartsWith("tps_") Then Continue For

            Dim id As Integer
            If Not Integer.TryParse(cle.Substring(4), id) Then Continue For

            Dim tps As Object = Montant(Request.Form("tps_" & id))
            Dim tvq As Object = Montant(Request.Form("tvq_" & id))
            If tps Is DBNull.Value AndAlso tvq Is DBNull.Value Then Continue For

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@EnteteId", CObj(id)))
            p.Add(New SqlParameter("@TPS", tps))
            p.Add(New SqlParameter("@TVQ", tvq))
            ExecuteSQL("s0784MajDocumentImport", p)
            touches += 1
        Next

        Afficher()
        Message(If(touches = 0, "Rien à enregistrer.", touches & " document(s) mis à jour."),
                If(touches = 0, "info", "ok"))
    End Sub

    ''' <summary>
    ''' Crée en comptabilité les documents cochés. La procédure écarte d'elle-même
    ''' ce qui n'a pas de tiers ou porte une anomalie, et dit combien.
    ''' </summary>
    Protected Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        Dim ids As String = Coches()
        If ids = "" Then
            Afficher()
            Message("Cochez au moins un document à créer.", "err")
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Ids", ids))
            p.Add(New SqlParameter("@UserId", CObj(UserId)))
            Dim ds As DataSet = ExecuteSQLds("s0785CreerDocumentsDepuisImport", p)

            Afficher()

            Dim crees As Integer = 0, sansTiers As Integer = 0, ecartes As Integer = 0
            Dim boiteux As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                crees = Entier(r, "NbCrees")
                sansTiers = Entier(r, "NbSansTiers")
                ecartes = Entier(r, "NbEcartes")
                boiteux = Entier(r, "NbDesequilibres")
            End If

            Dim texte As New StringBuilder()
            texte.Append(crees).Append(" document(s) créés en brouillon. ")
            texte.Append("Rien n'est encore au grand livre : comptabilisez-les depuis la grille des factures.")
            If sansTiers > 0 Then
                texte.Append(" ").Append(sansTiers).Append(" ont été écartés parce que leur client ou fournisseur n'est pas encore créé.")
            End If
            If ecartes > 0 Then
                texte.Append(" ").Append(ecartes).Append(" portaient une anomalie.")
            End If
            If boiteux > 0 Then
                ' Sans cette phrase, un document refusé disparaîtrait du compte
                ' sans explication — et on chercherait longtemps pourquoi.
                texte.Append(" ").Append(boiteux)
                texte.Append(" ne s'additionnent pas (sous-total + TPS + TVQ ≠ total) : ")
                texte.Append("répartissez les taxes avant de les créer.")
            End If

            Message(texte.ToString(), If(crees > 0, "ok", "err"))

        Catch ex As Exception
            Afficher()
            Message("La création a échoué : " & ex.Message, "err")
        End Try
    End Sub

    ''' <summary>
    ''' Retire de la préparation. Sans conséquence : rien n'a été comptabilisé,
    ''' et une nouvelle extraction les ramènerait.
    ''' </summary>
    Protected Sub btnSupprimer_Click(sender As Object, e As EventArgs) Handles btnSupprimer.Click
        Dim cochees As String() = Request.Form.GetValues("sel")
        If cochees Is Nothing OrElse cochees.Length = 0 Then
            Afficher()
            Message("Cochez au moins un document à retirer.", "err")
            Return
        End If

        Dim n As Integer = 0
        For Each s As String In cochees
            Dim id As Integer
            If Not Integer.TryParse(s, id) Then Continue For

            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@RunId", DBNull.Value))
            p.Add(New SqlParameter("@DocumentTypeId", DBNull.Value))
            p.Add(New SqlParameter("@EnteteId", CObj(id)))
            ExecuteSQLds("s0783SupprimerDocumentsImport", p)
            n += 1
        Next

        Afficher()
        Message(n & " document(s) retirés de la préparation.", "ok")
    End Sub

    Private Function Coches() As String
        Dim cochees As String() = Request.Form.GetValues("sel")
        If cochees Is Nothing Then Return ""
        Return String.Join(",", cochees.Where(Function(s) IsNumeric(s)))
    End Function

#End Region

#Region "L'affichage"

    Private Sub Afficher()
        Dim typeDoc As Integer = CInt(ddlType.SelectedValue)

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@DocumentTypeId", CObj(typeDoc)))
        p.Add(New SqlParameter("@RunId", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0782GetDocumentsImport", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            litBilan.Text = ""
            litDocs.Text = "<div class='vide'>Aucune facture en préparation pour ce type. " &
                           "Le bouton <b>Importer depuis QuickBooks</b>, ci-dessus, les rapatrie en direct.</div>"
            Return
        End If

        Dim entetes As DataTable = ds.Tables(0)
        Dim lignes As DataTable = If(ds.Tables.Count > 1, ds.Tables(1), Nothing)

        ' Le filtre porte sur le SOLDE, pas sur le libellé venu de la source :
        ' c'est le solde qui décide s'il reste quelque chose à encaisser, et
        ' c'est lui que l'écran affiche. Un libellé et un montant qui se
        ' contrediraient laisseraient l'utilisateur sans recours.
        Dim voulu As String = If(ddlEtat.SelectedValue, "")
        If voulu <> "" Then
            Dim garde As New List(Of DataRow)
            For Each r As DataRow In entetes.Rows
                Dim solde As Decimal = If(IsDBNull(r("Solde")), 0D, Convert.ToDecimal(r("Solde")))
                Dim ouverte As Boolean = (Math.Abs(solde) > 0.01D)
                If (voulu = "O" AndAlso ouverte) OrElse (voulu = "F" AndAlso Not ouverte) Then garde.Add(r)
            Next

            Dim filtre As DataTable = entetes.Clone()
            For Each r As DataRow In garde
                filtre.ImportRow(r)
            Next
            entetes = filtre
        End If

        If entetes.Rows.Count = 0 Then
            litBilan.Text = ""
            litDocs.Text = "<div class='vide'>Aucune facture " &
                           If(voulu = "O", "ouverte", If(voulu = "F", "fermée", "")) &
                           " dans la préparation de ce type.</div>"
            Return
        End If


        litBilan.Text = Bilan(entetes)
        litDocs.Text = Tableau(entetes, lignes, typeDoc)
    End Sub

    ''' <summary>
    ''' Quatre chiffres, pour savoir où on en est sans lire le tableau : ce qui
    ''' est prêt, ce qui bloque, ce qui existe déjà, ce qui est fait.
    ''' </summary>
    Private Function Bilan(entetes As DataTable) As String
        Dim total As Integer = entetes.Rows.Count
        Dim prets As Integer = 0, bloques As Integer = 0, migres As Integer = 0

        For Each r As DataRow In entetes.Rows
            Dim statut As String = r("Statut").ToString()
            If statut = "MIGRE" Then
                migres += 1
            ElseIf statut = "OK" AndAlso Not IsDBNull(r("PartyGUID")) Then
                prets += 1
            Else
                bloques += 1
            End If
        Next

        Dim sb As New StringBuilder()
        sb.Append("<div class='bilan'>")
        sb.Append("<div class='bil'><div class='l'>En préparation</div><div class='v'>").Append(total).Append("</div></div>")
        sb.Append("<div class='bil ok'><div class='l'>Prêtes à créer</div><div class='v'>").Append(prets).Append("</div></div>")
        sb.Append("<div class='bil no'><div class='l'>À corriger</div><div class='v'>").Append(bloques).Append("</div></div>")
        sb.Append("<div class='bil mi'><div class='l'>Déjà créées</div><div class='v'>").Append(migres).Append("</div></div>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Function Tableau(entetes As DataTable, lignes As DataTable, typeDoc As Integer) As String

        Dim sb As New StringBuilder()
        sb.Append("<table class='docs'><tr>")
        sb.Append("<th style='width:34px'><input type='checkbox' onclick='toutCocher(this)' /></th>")
        sb.Append("<th>Numéro</th><th>Date</th><th>Échéance</th>")
        sb.Append("<th>").Append(If(typeDoc = 1, "Client", "Fournisseur")).Append("</th>")
        sb.Append("<th style='text-align:right'>Sous-total</th>")
        sb.Append("<th style='text-align:right'>Taxes</th>")
        sb.Append("<th style='text-align:right'>TPS</th><th style='text-align:right'>TVQ</th>")
        sb.Append("<th style='text-align:right'>Total</th><th style='text-align:right'>Solde</th>")
        sb.Append("<th>État</th></tr>")

        For Each r As DataRow In entetes.Rows
            Dim id As Integer = Convert.ToInt32(r("Id"))
            Dim statut As String = r("Statut").ToString()
            Dim migre As Boolean = (statut = "MIGRE")
            Dim sansTiers As Boolean = IsDBNull(r("PartyGUID"))
            Dim anomalie As Boolean = (statut = "INVALIDE" OrElse statut = "DOUBLON_FICHIER")

            Dim classe As String = ""
            If migre Then
                classe = " class='migre'"
            ElseIf anomalie Then
                classe = " class='bloque'"
            ElseIf sansTiers Then
                classe = " class='souci'"
            End If

            sb.Append("<tr").Append(classe).Append(">")

            ' La case à cocher : inutile sur ce qui est déjà créé.
            sb.Append("<td>")
            If Not migre Then
                sb.Append("<input type='checkbox' name='sel' value='").Append(id).Append("' />")
            End If
            sb.Append("</td>")

            sb.Append("<td>").Append(IconeConformite(r, lignes, migre)).Append("<b>").Append(Server.HtmlEncode(Texte(r("Numero")))).Append("</b>")
            If Not IsDBNull(r("Anomalie")) AndAlso r("Anomalie").ToString() <> "" Then
                sb.Append("<span class='anom'>").Append(Server.HtmlEncode(r("Anomalie").ToString())).Append("</span>")
            End If
            sb.Append(Detail(lignes, id))
            sb.Append("</td>")

            sb.Append("<td>").Append(DateCourte(r("DateDocument"))).Append("</td>")
            sb.Append("<td>").Append(DateCourte(r("DateEcheance"))).Append("</td>")

            ' ── Le tiers ────────────────────────────────────────────────────
            sb.Append("<td>").Append(CelluleTiers(r, migre, sansTiers)).Append("</td>")

            sb.Append("<td class='n'>").Append(Somme(r("SousTotal"))).Append("</td>")
            sb.Append("<td class='n'>").Append(Somme(r("TotalTaxes"))).Append("</td>")

            ' ── TPS et TVQ : les deux seules valeurs qu'on saisit ───────────
            sb.Append("<td class='n'>").Append(Champ("tps_" & id, r("TPS"), migre)).Append("</td>")
            sb.Append("<td class='n'>").Append(Champ("tvq_" & id, r("TVQ"), migre)).Append("</td>")

            sb.Append("<td class='n'><b>").Append(Somme(r("Total"))).Append("</b></td>")
            sb.Append("<td class='n'>").Append(Somme(r("Solde"))).Append(EtatPastille(r)).Append("</td>")

            sb.Append("<td>").Append(Etiquette(statut, sansTiers)).Append("</td>")
            sb.Append("</tr>")
        Next

        sb.Append("</table>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' L'icône devant le numéro : la facture est-elle conforme, c'est-à-dire
    ''' tout ce qu'il lui faut est validé en préparation, avant tout passage en
    ''' comptabilité ? Conforme = pas d'anomalie de chargement, tiers créé ou en
    ''' préparation, chaque ligne sur un compte lié / existant / créé / à créer,
    ''' chaque produit créé ou en préparation (ou ligne sans produit), et
    ''' sous-total + taxes = total. Sinon l'info-bulle dit ce qui manque.
    ''' Un document déjà créé garde un crochet gris.
    ''' </summary>
    Private Function IconeConformite(r As DataRow, lignes As DataTable, migre As Boolean) As String
        If migre Then Return "<span class='conf cree' title='Déjà créée dans la comptabilité'>✔</span>"

        Dim raisons As New List(Of String)
        Dim statut As String = r("Statut").ToString()
        If statut = "INVALIDE" OrElse statut = "DOUBLON_FICHIER" Then raisons.Add("anomalie de chargement : " & Texte(r("Anomalie")))
        ' Un tiers en préparation est en règle : tout se valide en préparation avant de passer en comptabilité.
        If IsDBNull(r("PartyGUID")) AndAlso IsDBNull(r("PartyImportId")) Then raisons.Add("tiers absent de la préparation")

        Dim sousTotal As Decimal = If(IsDBNull(r("SousTotal")), 0D, Convert.ToDecimal(r("SousTotal")))
        Dim tps As Decimal = If(IsDBNull(r("TPS")), 0D, Convert.ToDecimal(r("TPS")))
        Dim tvq As Decimal = If(IsDBNull(r("TVQ")), 0D, Convert.ToDecimal(r("TVQ")))
        Dim total As Decimal = If(IsDBNull(r("Total")), 0D, Convert.ToDecimal(r("Total")))
        Dim totalTaxes As Decimal = If(IsDBNull(r("TotalTaxes")), 0D, Convert.ToDecimal(r("TotalTaxes")))
        ' Les taxes viennent soit réparties (TPS, TVQ), soit en bloc (TotalTaxes) : l'une ou l'autre doit boucler.
        If Math.Abs(sousTotal + tps + tvq - total) > 0.02D AndAlso Math.Abs(sousTotal + totalTaxes - total) > 0.02D Then
            raisons.Add("montants : sous-total + taxes ≠ total")
        End If

        Dim nbLignes As Integer = 0, comptesKo As Integer = 0, produitsKo As Integer = 0
        If lignes IsNot Nothing Then
            For Each l As DataRow In lignes.Select("EnteteId = " & Convert.ToInt32(r("Id")))
                nbLignes += 1
                Dim ce As String = Texte(l("CompteEtat"))
                ' Une ligne de texte seul (ni compte, ni produit, ni montant : une note sur la facture) n'a rien à valider.
                Dim montantLigne As Decimal = If(IsDBNull(l("Montant")), 0D, Convert.ToDecimal(l("Montant")))
                If ce = "AUCUN" AndAlso Texte(l("ProduitEtat")) = "AUCUN" AndAlso montantLigne = 0D Then Continue For
                ' Un compte décidé « Créer » (A_CREER) est en règle lui aussi : l'étape 3 le créera.
                If ce <> "LIE" AndAlso ce <> "EXISTE" AndAlso ce <> "CREE" AndAlso ce <> "A_CREER" Then comptesKo += 1
                Dim pe As String = Texte(l("ProduitEtat"))
                ' Un produit en préparation (A_CREER) est en règle : l'écran Produits le créera avec la facture.
                If pe <> "CREE" AndAlso pe <> "A_CREER" AndAlso pe <> "AUCUN" Then produitsKo += 1
            Next
        End If
        If nbLignes = 0 Then raisons.Add("aucune ligne")
        If comptesKo > 0 Then raisons.Add(comptesKo & " ligne(s) sans compte lié, existant, créé ou à créer")
        If produitsKo > 0 Then raisons.Add(produitsKo & " ligne(s) dont le produit est absent de la préparation")

        If raisons.Count = 0 Then
            Return "<span class='conf ok' title='Conforme : tout est validé en préparation (tiers, comptes, produits) et les montants bouclent'>✅</span>"
        End If
        Return "<span class='conf non' title='" & Server.HtmlEncode("Non conforme : " & String.Join(" · ", raisons)) & "'>⚠️</span>"
    End Function

    ''' <summary>Le détail du document, replié : on ne l'ouvre que si on doute.</summary>
    Private Function Detail(lignes As DataTable, enteteId As Integer) As String
        If lignes Is Nothing Then Return ""

        Dim siennes = lignes.Select("EnteteId = " & enteteId)
        If siennes.Length = 0 Then Return ""

        ' Le résumé de la ligne repliée : combien de comptes sont liés, à créer,
        ' à décider… pour savoir d'un coup d'œil si le document est prêt.
        Dim comptes As New Dictionary(Of String, Integer), produits As New Dictionary(Of String, Integer)
        For Each l As DataRow In siennes
            Compter(comptes, Texte(l("CompteEtat")))
            Compter(produits, Texte(l("ProduitEtat")))
        Next

        Dim sb As New StringBuilder()
        sb.Append("<details class='lignes'><summary>").Append(siennes.Length).Append(" ligne(s)")
        sb.Append(ResumeEtats(" — comptes : ", comptes, LibellesCompte)).Append(ResumeEtats(" — produits : ", produits, LibellesProduit))
        sb.Append("</summary>")
        sb.Append("<table class='lig'><tr><th>Description</th><th>Produit</th><th>Compte</th>")
        sb.Append("<th style='text-align:right'>Qté</th><th style='text-align:right'>Prix</th>")
        sb.Append("<th style='text-align:right'>Montant</th></tr>")

        For Each l As DataRow In siennes
            sb.Append("<tr><td>").Append(Server.HtmlEncode(Texte(l("Description")))).Append("</td>")
            ' Le produit, tel que la PRÉPARATION le connaît : créé, importé mais
            ' pas encore créé, ou absent. Aucun ne bloque : une ligne peut être
            ' du texte libre, et le document se crée avec un produit vide.
            sb.Append("<td>")
            Dim produitSource As String = Texte(l("ProduitNom"))
            Dim produitReconnu As String = Texte(l("ProduitReconnu"))
            Dim produitEtat As String = Texte(l("ProduitEtat"))
            Select Case produitEtat
                Case "AUCUN"
                    sb.Append("<span style='color:#94a3b8'>—</span>")
                Case "CREE"
                    sb.Append(Server.HtmlEncode(If(produitReconnu <> "", produitReconnu, produitSource)))
                    sb.Append(" <span class='etiq ok'>créé</span>")
                Case "A_CREER"
                    sb.Append(Server.HtmlEncode(If(produitReconnu <> "", produitReconnu, produitSource)))
                    sb.Append(" <span class='etiq ok'>en préparation</span>")
                Case Else
                    sb.Append(Server.HtmlEncode(produitSource))
                    sb.Append(" <span class='etiq anomalie'>absent de la préparation</span>")
            End Select
            sb.Append("</td>")
            ' Le compte : ce que l'étape 2 (Correspondance) en a décidé et ce que
            ' l'étape 3 en a fait. Lié / existe / créé → le numéro d'ici ; à créer
            ' → le numéro que l'étape 3 donnera ; à décider, ignoré, absent → à
            ' régler avant de comptabiliser. Aucun ne bloque la création du
            ' brouillon, mais on le dit clairement.
            sb.Append("<td>")
            Dim compteNom As String = Texte(l("CompteNom"))
            If compteNom = "" Then compteNom = Texte(l("CompteSource"))
            Dim etat As String = Texte(l("CompteEtat"))
            Dim numero As String = Texte(l("CompteEtatNumero"))
            Dim nomCible As String = Texte(l("CompteEtatNom"))
            Dim cible As String = If(numero <> "", "<b>" & Server.HtmlEncode(numero) & "</b>" & If(nomCible <> "", " " & Server.HtmlEncode(nomCible), ""), "")
            Select Case etat
                Case "AUCUN"
                    sb.Append("<span style='color:#94a3b8'>—</span>")
                Case "LIE"
                    sb.Append("<span class='etiq ok'>lié</span> → ").Append(cible)
                    sb.Append(" <span style='color:#94a3b8'>(").Append(Server.HtmlEncode(compteNom)).Append(")</span>")
                Case "EXISTE"
                    sb.Append("<span class='etiq ok'>existe au plan</span> → ").Append(cible)
                    sb.Append(" <span style='color:#94a3b8'>(").Append(Server.HtmlEncode(compteNom)).Append(")</span>")
                Case "CREE"
                    sb.Append("<span class='etiq migre'>créé à l'étape 3</span> → ").Append(cible)
                    sb.Append(" <span style='color:#94a3b8'>(").Append(Server.HtmlEncode(compteNom)).Append(")</span>")
                Case "A_CREER"
                    sb.Append(Server.HtmlEncode(compteNom))
                    sb.Append(" <span class='etiq existe'>à créer (étape 3)</span>")
                    If cible <> "" Then sb.Append(" → ").Append(cible)
                Case "LIE_SANS_CIBLE"
                    sb.Append(Server.HtmlEncode(compteNom))
                    sb.Append(" <span class='etiq anomalie'>lié, sans compte cible (étape 2)</span>")
                Case "IGNORE"
                    sb.Append(Server.HtmlEncode(compteNom))
                    sb.Append(" <span class='etiq anomalie'>ignoré à l'étape 2 : aucun compte</span>")
                Case "A_DECIDER"
                    sb.Append(Server.HtmlEncode(compteNom))
                    sb.Append(" <span class='etiq anomalie'>à décider (étape 2)</span>")
                Case Else
                    sb.Append(Server.HtmlEncode(compteNom))
                    sb.Append(" <span class='etiq anomalie'>absent du plan comptable importé</span>")
            End Select
            sb.Append("</td>")
            sb.Append("<td class='n'>").Append(Somme(l("Quantite"))).Append("</td>")
            sb.Append("<td class='n'>").Append(Somme(l("PrixUnitaire"))).Append("</td>")
            sb.Append("<td class='n'>").Append(Somme(l("Montant"))).Append("</td></tr>")
        Next

        sb.Append("</table></details>")
        Return sb.ToString()
    End Function

    Private Shared ReadOnly LibellesCompte As New Dictionary(Of String, String) From {
        {"LIE", "lié"}, {"EXISTE", "existe au plan"}, {"CREE", "créé"}, {"A_CREER", "à créer"},
        {"LIE_SANS_CIBLE", "lié sans compte cible"}, {"IGNORE", "ignoré"}, {"A_DECIDER", "à décider"}, {"ABSENT", "absent du plan importé"}}
    Private Shared ReadOnly LibellesProduit As New Dictionary(Of String, String) From {
        {"CREE", "créé"}, {"A_CREER", "en préparation"}, {"ABSENT", "absent"}}

    Private Shared Sub Compter(d As Dictionary(Of String, Integer), cle As String)
        If cle = "" OrElse cle = "AUCUN" Then Return
        If d.ContainsKey(cle) Then d(cle) += 1 Else d(cle) = 1
    End Sub

    ''' <summary>« — comptes : 2 liés · 1 à créer · 1 à décider », dans l'ordre des libellés.</summary>
    Private Function ResumeEtats(prefixe As String, d As Dictionary(Of String, Integer), libelles As Dictionary(Of String, String)) As String
        If d.Count = 0 Then Return ""
        Dim parts As New List(Of String)
        For Each kv In libelles
            If d.ContainsKey(kv.Key) Then
                Dim n As Integer = d(kv.Key)
                Dim libelle As String = kv.Value
                ' accord du pluriel pour les participes (lié → liés, créé → créés) ; « à créer », « à décider » ne bougent pas.
                If n > 1 AndAlso (libelle.EndsWith("é") OrElse libelle.EndsWith("gnoré")) Then libelle &= "s"
                parts.Add(n & " " & libelle)
            End If
        Next
        Return Server.HtmlEncode(prefixe & String.Join(" · ", parts))
    End Function

    ''' <summary>
    ''' Le tiers, tel que la PRÉPARATION le connaît — jamais choisi à la main.
    ''' Reconnu parmi les clients ou fournisseurs importés : s'il est déjà créé,
    ''' la facture peut l'être ; sinon elle attend qu'on le crée depuis son
    ''' écran. Absent de la préparation : il faut d'abord l'importer.
    ''' </summary>
    Private Function CelluleTiers(r As DataRow, migre As Boolean, sansTiers As Boolean) As String
        Dim reconnu As String = Texte(r("TiersReconnu"))
        Dim source As String = Texte(r("TiersNom"))
        Dim enPreparation As Boolean = Not IsDBNull(r("PartyImportId"))
        Dim ecran As String = If(CInt(ddlType.SelectedValue) = 2, "Fournisseurs", "Clients")

        ' La source ne donne que le nom d'affichage (« Amanda Reid »). Le nom de
        ' l'entreprise vient du tiers en préparation, quand il est reconnu : on
        ' l'affiche en premier, comme sur les écrans Clients et Fournisseurs, et
        ' le nom d'affichage en dessous quand il diffère.
        Dim entreprise As String = If(reconnu <> "", reconnu, source)
        Dim sous As String = ""
        If reconnu <> "" AndAlso source <> "" AndAlso Not String.Equals(reconnu, source, StringComparison.OrdinalIgnoreCase) Then
            sous = "<span style='display:block;font-size:11.5px;color:#64748b'>" & Server.HtmlEncode(source) & "</span>"
        End If

        If migre OrElse Not sansTiers Then
            Return Server.HtmlEncode(entreprise) & sous
        End If

        If enPreparation Then
            Return "<div class='sansTiers'>" & Server.HtmlEncode(entreprise) &
                   " — en préparation, pas encore créé</div>" & sous &
                   "<span class='anom'>Créez-le depuis l'écran " & ecran & ".</span>"
        End If

        Return "<div class='sansTiers'>" & Server.HtmlEncode(source) & " — absent de la préparation</div>" &
               "<span class='anom'>Importez d'abord vos " & ecran.ToLowerInvariant() & ", puis créez-le.</span>"
    End Function

    ''' <summary>
    ''' « Payée » ou « Partielle » à côté du solde. Rien pour une facture
    ''' entièrement due : c'est le cas ordinaire d'une reprise, et le signaler
    ''' sur chaque ligne noierait les deux qui méritent un regard.
    '''
    ''' Le mot vient du solde, pas de StatutSource : c'est le montant qui décide,
    ''' et c'est lui qui est affiché juste à gauche.
    ''' </summary>
    Private Shared Function EtatPastille(r As DataRow) As String
        Dim solde As Decimal = If(IsDBNull(r("Solde")), 0D, Convert.ToDecimal(r("Solde")))
        If Math.Abs(solde) > 0.01D Then
            Dim total As Decimal = If(IsDBNull(r("Total")), 0D, Convert.ToDecimal(r("Total")))
            If total <> 0D AndAlso Math.Abs(total - solde) > 0.01D Then
                Return " <span class='pay part'>partielle</span>"
            End If
            Return ""
        End If
        Return " <span class='pay'>payée</span>"
    End Function

    Private Shared Function Etiquette(statut As String, sansTiers As Boolean) As String
        Select Case statut
            Case "MIGRE" : Return "<span class='etiq migre'>créée</span>"
            Case "EXISTE" : Return "<span class='etiq existe'>déjà en comptabilité</span>"
            Case "INVALIDE", "DOUBLON_FICHIER" : Return "<span class='etiq anomalie'>à corriger</span>"
            Case Else
                If sansTiers Then Return "<span class='etiq anomalie'>tiers à créer</span>"
                Return "<span class='etiq ok'>prête</span>"
        End Select
    End Function

    ''' <summary>Une case de saisie, ou la valeur figée quand le document est créé.</summary>
    Private Shared Function Champ(nom As String, valeur As Object, fige As Boolean) As String
        Dim v As String = If(IsDBNull(valeur), "", Convert.ToDecimal(valeur).ToString("N2"))
        If fige Then Return v
        Return "<input class='mt' type='text' name='" & nom & "' value='" & v & "' />"
    End Function

#End Region

#Region "Petits secours"

    Private Sub Message(texte As String, genre As String)
        litMsg.Text = "<div class='msg " & genre & "'>" & Server.HtmlEncode(texte) & "</div>"
    End Sub

    Private Shared Function Texte(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return v.ToString()
    End Function

    Private Shared Function Somme(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToDecimal(v).ToString("N2")
    End Function

    Private Shared Function DateCourte(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToDateTime(v).ToString("yyyy-MM-dd")
    End Function

    Private Shared Function Entier(r As DataRow, champ As String) As Integer
        If IsDBNull(r(champ)) Then Return 0
        Return Convert.ToInt32(r(champ))
    End Function

    ''' <summary>
    ''' Un montant saisi, ou DBNull. La virgule est acceptée : personne ne tape
    ''' un point décimal en français.
    ''' </summary>
    Private Shared Function Montant(saisie As String) As Object
        If String.IsNullOrWhiteSpace(saisie) Then Return DBNull.Value

        Dim d As Decimal
        If Decimal.TryParse(saisie.Replace(" "c, "").Replace(","c, "."c),
                            Globalization.NumberStyles.Any,
                            Globalization.CultureInfo.InvariantCulture, d) Then
            Return d
        End If
        Return DBNull.Value
    End Function

#End Region

End Class
