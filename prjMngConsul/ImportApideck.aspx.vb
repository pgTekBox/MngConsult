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
''' </summary>
Public Class ImportApideck
    Inherits clsData

#Region "Le catalogue"

    ''' <summary>Une ressource d'Apideck, et ce qu'on en fait.</summary>
    Private Class Ressource
        Public Property Cle As String              ' le chemin chez Apideck
        Public Property Libelle As String
        Public Property Groupe As String

        ''' <summary>Un seul objet plutôt qu'une liste : informations, rapports.</summary>
        Public Property Unique As Boolean

        ''' <summary>
        ''' La préparation existante que cette ressource alimente en plus du
        ''' dépôt brut. Vide : elle se dépose sans être interprétée.
        ''' </summary>
        Public Property Vers As String = ""

        ''' <summary>
        ''' Comment la lire. Vide : une liste ordinaire. PAR_DOCUMENT : un
        ''' appel par document déjà en préparation. PASSERELLE : l'API native
        ''' de la source, par le passe-plat, faute d'équivalent unifié.
        ''' </summary>
        Public Property Mode As String = ""

    End Class

    ''' <summary>
    ''' Les vingt-huit ressources que le connecteur sait rendre — vingt-six de
    ''' l'API unifiée d'Apideck, les pièces jointes qui se demandent document par
    ''' document, et les conditions de paiement qui passent par le passe-plat.
    ''' L'ordre suit
    ''' celui d'une reprise : d'abord ce qui structure, puis les documents, puis
    ''' ce qui ne sert qu'au contrôle.
    ''' </summary>
    Private Shared ReadOnly Property Catalogue As List(Of Ressource)
        Get
            Return New List(Of Ressource) From {
                New Ressource With {.Groupe = "Structure", .Cle = "company-info", .Libelle = "Informations de la société", .Unique = True, .Vers = "SOCIETE"},
                New Ressource With {.Groupe = "Structure", .Cle = "ledger-accounts", .Libelle = "Plan comptable", .Vers = "PLAN"},
                New Ressource With {.Groupe = "Structure", .Cle = "tax-rates", .Libelle = "Taxes", .Vers = "TAXES"},
                New Ressource With {.Groupe = "Structure", .Cle = "payment-methods", .Libelle = "Modes de paiement", .Vers = "MODE_PAIEMENT"},
                New Ressource With {.Groupe = "Structure", .Cle = "terms", .Libelle = "Conditions de paiement", .Vers = "CONDITIONS", .Mode = "PASSERELLE"},
                New Ressource With {.Groupe = "Structure", .Cle = "tracking-categories", .Libelle = "Catégories de suivi", .Vers = "CATEGORIE_SUIVI"},
                New Ressource With {.Groupe = "Structure", .Cle = "departments", .Libelle = "Départements", .Vers = "DEPARTEMENT"},
                New Ressource With {.Groupe = "Structure", .Cle = "locations", .Libelle = "Emplacements", .Vers = "EMPLACEMENT"},
                New Ressource With {.Groupe = "Tiers et articles", .Cle = "customers", .Libelle = "Clients", .Vers = "CLIENTS"},
                New Ressource With {.Groupe = "Tiers et articles", .Cle = "suppliers", .Libelle = "Fournisseurs", .Vers = "FOURNISSEURS"},
                New Ressource With {.Groupe = "Tiers et articles", .Cle = "invoice-items", .Libelle = "Produits et services", .Vers = "PRODUITS"},
                New Ressource With {.Groupe = "Ventes", .Cle = "invoices", .Libelle = "Factures clients", .Vers = "FACTURES_CLIENTS"},
                New Ressource With {.Groupe = "Ventes", .Cle = "credit-notes", .Libelle = "Notes de crédit", .Vers = "AVOIRS_CLIENTS"},
                New Ressource With {.Groupe = "Ventes", .Cle = "sales-receipts", .Libelle = "Reçus de vente", .Vers = "RECUS_VENTE"},
                New Ressource With {.Groupe = "Ventes", .Cle = "quotes", .Libelle = "Soumissions", .Vers = "SOUMISSIONS"},
                New Ressource With {.Groupe = "Ventes", .Cle = "payments", .Libelle = "Encaissements", .Vers = "ENCAISSEMENTS"},
                New Ressource With {.Groupe = "Ventes", .Cle = "refunds", .Libelle = "Remboursements", .Vers = "REMBOURSEMENTS"},
                New Ressource With {.Groupe = "Achats", .Cle = "bills", .Libelle = "Factures fournisseurs", .Vers = "FACTURES_FOURNISSEURS"},
                New Ressource With {.Groupe = "Achats", .Cle = "bill-credit-notes", .Libelle = "Notes de crédit fournisseurs", .Vers = "AVOIRS_FOURNISSEURS"},
                New Ressource With {.Groupe = "Achats", .Cle = "bill-payments", .Libelle = "Décaissements", .Vers = "DECAISSEMENTS"},
                New Ressource With {.Groupe = "Achats", .Cle = "purchase-orders", .Libelle = "Bons de commande", .Vers = "BONS_COMMANDE"},
                New Ressource With {.Groupe = "Achats", .Cle = "expenses", .Libelle = "Dépenses", .Vers = "DEPENSES"},
                New Ressource With {.Groupe = "Grand livre", .Cle = "journal-entries", .Libelle = "Écritures de journal", .Vers = "ECRITURES"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "balance-sheet", .Libelle = "Bilan", .Unique = True, .Vers = "BILAN"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "profit-and-loss", .Libelle = "Résultats", .Unique = True, .Vers = "RESULTATS"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "aged-debtors", .Libelle = "Balance âgée clients", .Unique = True, .Vers = "AGEE_CLIENTS"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "aged-creditors", .Libelle = "Balance âgée fournisseurs", .Unique = True, .Vers = "AGEE_FOURNISSEURS"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "attachments", .Libelle = "Pièces jointes", .Vers = "PIECES_JOINTES", .Mode = "PAR_DOCUMENT"}
            }
        End Get
    End Property

#End Region

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
    ''' Le cœur de l'écran. Une extraction, ressource par ressource :
    '''
    '''   lire chez Apideck → déposer le brut → verser dans la préparation
    '''
    ''' Une ressource qui échoue n'arrête pas les autres. C'est délibéré : sur
    ''' vingt-sept appels, un connecteur refuse presque toujours quelque chose,
    ''' et tout perdre pour une balance âgée indisponible serait absurde.
    ''' </summary>
    Protected Sub btnImporter_Click(sender As Object, e As EventArgs) Handles btnImporter.Click

        Dim choisies As List(Of Ressource) = RessourcesChoisies()
        If choisies.Count = 0 Then
            AfficherRessources()
            AfficherHistorique()
            Message("Choisissez au moins une ressource à rapatrier.", "err")
            Return
        End If

        Dim api As New clsApideck(Company.ToString())
        Dim runId As Integer

        Try
            runId = OuvrirRun()
        Catch ex As Exception
            AfficherRessources()
            AfficherHistorique()
            Message("L'extraction n'a pas pu s'ouvrir : " & ex.Message, "err")
            Return
        End Try

        Dim lignes As New StringBuilder()
        Dim total As Integer = 0
        Dim echecs As Integer = 0
        Dim fautives As New List(Of String)

        For Each r As Ressource In choisies
            ' QuickBooks plafonne les appels simultanés par société et répond 403
            ' au-delà. Une courte pause entre les ressources vaut mieux que de
            ' compter sur les réessais.
            If total > 0 Then Threading.Thread.Sleep(600)

            Dim nb As Integer = 0
            Dim versDit As String = ""
            Dim erreur As String = ""

            Try
                Dim brut As JArray = LireRessource(api, r)
                nb = brut.Count

                ' 1) Le dépôt brut : tout y passe, sans interprétation.
                DeposerBrut(runId, r.Cle, brut)

                ' 2) La préparation habituelle, pour celles qu'on sait traiter.
                If r.Vers <> "" AndAlso nb > 0 Then
                    versDit = Verser(r, brut, runId)
                End If

                total += nb

            Catch ex As Exception
                erreur = ex.Message
                echecs += 1
                fautives.Add(r.Cle)
            End Try

            lignes.Append("<tr")
            If erreur <> "" Then lignes.Append(" class='ko'")
            lignes.Append("><td>").Append(Server.HtmlEncode(r.Libelle))
            lignes.Append(" <span style='color:#94a3b8'>").Append(r.Cle).Append("</span></td>")
            lignes.Append("<td class='n'>").Append(If(erreur = "", nb.ToString("N0"), "—")).Append("</td>")

            lignes.Append("<td>")
            If erreur <> "" Then
                lignes.Append("<span class='ko-txt'>").Append(Server.HtmlEncode(erreur)).Append("</span>")
            ElseIf versDit <> "" Then
                lignes.Append("<span class='vers'>").Append(Server.HtmlEncode(versDit)).Append("</span>")
            Else
                lignes.Append("<span style='color:#64748b'>déposé en préparation</span>")
            End If
            lignes.Append("</td></tr>")
        Next

        Dim noteTaxes As String = RepartirTaxes()

        FermerRun(runId, If(echecs = 0, "TERMINE", "PARTIEL"),
                  If(echecs = 0, Nothing,
                     echecs & " ressource(s) en échec sur " & choisies.Count & " : " &
                     String.Join(", ", fautives) & "."))

        AfficherRessources()
        AfficherResultat(lignes.ToString(), total, echecs, choisies.Count, noteTaxes)
        AfficherHistorique()
    End Sub

    ''' <summary>
    ''' Une liste complète, l'objet unique d'un rapport — ou l'une des deux
    ''' lectures particulières, qui ne passent pas par une adresse de liste.
    ''' </summary>
    Private Function LireRessource(api As clsApideck, r As Ressource) As JArray
        Select Case r.Mode
            Case "PAR_DOCUMENT" : Return LirePiecesJointes(api)
            Case "PASSERELLE" : Return LireConditionsPaiement(api)
        End Select

        If Not r.Unique Then Return api.ListAll(r.Cle)

        Dim un As JToken = api.One(r.Cle)
        Dim t As New JArray()
        If un IsNot Nothing AndAlso un.Type <> JTokenType.Null Then t.Add(un)
        Return t
    End Function

    ''' <summary>
    ''' Dépose la ressource telle quelle. Chaque enregistrement garde son
    ''' identifiant chez la source : c'est lui qui permettra, plus tard, de
    ''' reconnaître ce qui a changé d'une extraction à l'autre.
    ''' </summary>
    Private Sub DeposerBrut(runId As Integer, ressource As String, brut As JArray)
        Dim paquet As New JArray()

        For Each item As JToken In brut
            Dim o As New JObject()
            o("id") = If(item("id") Is Nothing, "", item("id").ToString())
            o("json") = item
            paquet.Add(o)
        Next

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Ressource", ressource))
        p.Add(New SqlParameter("@Lignes", paquet.ToString(Formatting.None)))
        ExecuteSQLds("s0777ChargerConnecteurDonnees", p)
    End Sub

#End Region

#Region "Le versement vers la préparation existante"

    ''' <summary>
    ''' Verse une ressource connue dans la préparation que les écrans d'import
    ''' consultent déjà. Rien de neuf n'est écrit : on réutilise les procédures
    ''' des imports par fichier, donc les mêmes contrôles de doublons et les
    ''' mêmes boutons de création.
    ''' </summary>
    Private Function Verser(r As Ressource, brut As JArray, runId As Integer) As String
        Select Case r.Vers
            Case "PLAN" : Return VerserPlanComptable(brut)
            Case "CLIENTS" : Return VerserParties(brut, "Client", "clients")
            Case "FOURNISSEURS" : Return VerserParties(brut, "Fournisseur", "fournisseurs")
            Case "PRODUITS" : Return VerserProduits(brut)
            Case "FACTURES_CLIENTS" : Return VerserDocuments(brut, 1, runId)
            Case "FACTURES_FOURNISSEURS" : Return VerserDocuments(brut, 2, runId)
            Case "AVOIRS_CLIENTS" : Return VerserDocuments(brut, 3, runId)
            Case "AVOIRS_FOURNISSEURS" : Return VerserDocuments(brut, 4, runId)
            Case "DEPENSES" : Return VerserDocuments(brut, 6, runId)
            Case "RECUS_VENTE" : Return VerserDocuments(brut, 7, runId)
            Case "SOUMISSIONS" : Return VerserPieces(brut, "Soumission", runId)
            Case "BONS_COMMANDE" : Return VerserPieces(brut, "BonCommande", runId)
            Case "ENCAISSEMENTS" : Return VerserPaiements(brut, "Encaissement", runId)
            Case "DECAISSEMENTS" : Return VerserPaiements(brut, "Decaissement", runId)
            Case "REMBOURSEMENTS" : Return VerserPaiements(brut, "Remboursement", runId)
            Case "ECRITURES" : Return VerserEcritures(brut, runId)
            Case "BILAN" : Return VerserBilan(brut, runId)
            Case "RESULTATS" : Return VerserResultats(brut, runId)
            Case "AGEE_CLIENTS" : Return VerserBalanceAgee(brut, "Client", runId)
            Case "AGEE_FOURNISSEURS" : Return VerserBalanceAgee(brut, "Fournisseur", runId)
            Case "CONDITIONS" : Return VerserConditionsPaiement(brut, runId)
            Case "PIECES_JOINTES" : Return VerserPiecesJointes(brut, runId)
            Case "SOCIETE" : Return VerserSociete(brut, runId)
            Case "TAXES" : Return VerserTaxes(brut, runId)
            Case "MODE_PAIEMENT" : Return VerserModesPaiement(brut, runId)
            Case "CATEGORIE_SUIVI" : Return VerserCategoriesSuivi(brut, runId)
            Case "DEPARTEMENT" : Return VerserDepartements(brut, runId)
            Case "EMPLACEMENT" : Return VerserEmplacements(brut, runId)
            Case Else : Return ""
        End Select
    End Function

    ''' <summary>
    ''' Le plan comptable passe par un lot, comme l'import par fichier : même
    ''' table, même écran, mêmes verdicts. Le type n'est pas normalisé ici — la
    ''' correspondance est justement le travail de l'écran suivant.
    ''' </summary>
    Private Function VerserPlanComptable(brut As JArray) As String
        ' Le plan comptable emprunte le rail du lot, mais son origine s'inscrit
        ' au même registre que les listes : ImportFiles porte la réponse brute
        ' d'Apideck, et le lot pointe dessus.
        Dim fichierId As Integer = InscrireAuRegistre("PlanComptable", "plan comptable", brut)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@SystemeSource", "APIDECK"))
        p.Add(New SqlParameter("@TypeDonnees", "PLAN_COMPTABLE"))
        p.Add(New SqlParameter("@NomFichier", "QuickBooks — Plan comptable (Apideck)"))
        p.Add(New SqlParameter("@UserId", CObj(UserId)))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))

        Dim ds As DataSet = ExecuteSQLds("s0751OuvrirImportLot", p)
        Dim lotId As Integer = Convert.ToInt32(ds.Tables(0).Rows(0)(0))

        Dim lignes As New JArray()
        Dim no As Integer = 0

        For Each c As JToken In brut
            no += 1
            Dim numero As String = Valeur(c, "code", "nominal_code", "account_number")
            Dim nom As String = Valeur(c, "name", "display_name")

            Dim o As New JObject()
            o("LigneNo") = no
            o("CompteSource") = numero
            o("NomSource") = nom
            o("TypeSource") = Valeur(c, "classification", "type")
            o("SoldeSource") = Valeur(c, "current_balance", "balance")
            o("SensSource") = ""
            o("Compte") = numero
            o("Nom") = nom
            ' Option Strict est à Off : affecter l'Object rendu par Nombre() à un
            ' champ JSON compile, mais lève à l'exécution. C'est ce qui vidait le
            ' lot du plan comptable — le lot était créé, aucune ligne dedans.
            Dim solde As Object = Nombre(Valeur(c, "current_balance", "balance"))
            If solde IsNot Nothing Then o("Solde") = CDec(solde)
            lignes.Add(o)
        Next

        Dim p2 As New Collection
        p2.Add(New SqlParameter("@LotId", CObj(lotId)))
        p2.Add(New SqlParameter("@CompanyGUID", Company))
        p2.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))
        ExecuteSQLds("s0752ChargerPlanComptableStaging", p2)

        Return "versé au plan comptable — lot " & lotId
    End Function

    ''' <summary>
    ''' Clients et fournisseurs empruntent le chemin de l'import par fichier :
    ''' un « fichier » est créé pour porter la réponse d'Apideck, son JSON est
    ''' posé comme résultat, et s0604 l'éclate vers staging.PartyImport. L'écran
    ''' Clients ou Fournisseurs le voit alors comme n'importe quel import.
    ''' </summary>
    Private Function VerserParties(brut As JArray, typeImport As String, genre As String) As String
        Dim lignes As New JArray()

        For Each t As JToken In brut
            Dim adr As JToken = Premier(t, "addresses")

            Dim o As New JObject()
            o("name") = Valeur(t, "company_name", "display_name", "name")
            o("contact_name") = Valeur(t, "display_name", "first_name")
            o("address1") = Valeur(adr, "line1", "street_name")
            o("address2") = Valeur(adr, "line2")
            o("city") = Valeur(adr, "city")
            o("province") = Valeur(adr, "state", "region")
            o("postal_code") = Valeur(adr, "postal_code", "zip_code")
            o("phone") = Valeur(Premier(t, "phone_numbers"), "number")
            o("email") = Valeur(Premier(t, "emails"), "email")
            o("tps") = Valeur(t, "tax_number")
            o("tvq") = ""
            o("balance") = Valeur(t, "balance")
            lignes.Add(o)
        Next

        Return Livrer(typeImport, genre, lignes)
    End Function

    Private Function VerserProduits(brut As JArray) As String
        Dim lignes As New JArray()

        For Each a As JToken In brut
            Dim o As New JObject()
            o("name") = Valeur(a, "name", "code")
            o("description") = Valeur(a, "description", "sales_details.description")
            o("price") = Valeur(a, "unit_price", "sales_details.unit_price")
            o("taxable") = Valeur(a, "taxable")
            lignes.Add(o)
        Next

        Return Livrer("Produit", "produits et services", lignes)
    End Function

    ''' <summary>
    ''' Les documents — factures clients et fournisseurs — vont dans leur propre
    ''' préparation, entête et lignes, parce qu'ils ne se valident pas comme une
    ''' liste : on approuve un document entier, avec son détail, son tiers et ses
    ''' totaux. La procédure pose ensuite les verdicts et retrouve le tiers.
    ''' </summary>
    Private Function VerserDocuments(brut As JArray, typeDocument As Integer, runId As Integer) As String
        ' Comme le plan comptable et les listes : la réponse d'origine est
        ' inscrite au registre, et les documents déposés pointent dessus.
        ' Le type décide de tout : le nom au registre, le libellé affiché, et
        ' surtout la portée du remplacement côté SQL — s0781 efface par
        ' (compagnie + type + extraction). Deux ressources qui partageraient un
        ' type s'effaceraient l'une l'autre dans la même passe.
        Dim genre As String, libelle As String
        Select Case typeDocument
            Case 1 : genre = "FactureClient" : libelle = "factures clients"
            Case 2 : genre = "FactureFournisseur" : libelle = "factures fournisseurs"
            Case 3 : genre = "AvoirClient" : libelle = "notes de crédit"
            Case 4 : genre = "AvoirFournisseur" : libelle = "notes de crédit fournisseurs"
            Case 6 : genre = "Depense" : libelle = "dépenses"
            Case 7 : genre = "RecuVente" : libelle = "reçus de vente"
            Case Else : genre = "FactureClient" : libelle = "documents"
        End Select
        Dim fichierId As Integer = InscrireAuRegistre(genre, libelle, brut)
        Dim docs As New JArray()
        Dim rang As Integer = 0

        For Each d As JToken In brut
            rang += 1

            Dim tiers As JToken = If(d("customer"), d("supplier"))

            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(d, "id")
            o("numero") = Valeur(d, "number", "bill_number", "invoice_number", "reference")
            o("date") = Valeur(d, "invoice_date", "bill_date", "issue_date", "transaction_date")
            o("echeance") = Valeur(d, "due_date")
            o("tiers_id") = Valeur(tiers, "id")
            o("tiers") = Valeur(tiers, "display_name", "company_name", "name")
            o("devise") = Valeur(d, "currency")
            o("sous_total") = Valeur(d, "sub_total")
            o("taxes") = Valeur(d, "total_tax")
            o("total") = Valeur(d, "total")
            o("solde") = Valeur(d, "balance")
            o("statut") = Valeur(d, "status")

            Dim lignes As New JArray()
            Dim lot As JArray = TryCast(d("line_items"), JArray)
            Dim no As Integer = 0

            If lot IsNot Nothing Then
                For Each l As JToken In lot
                    no += 1
                    Dim ligne As New JObject()
                    ligne("no") = no
                    ligne("description") = Valeur(l, "description")
                    ligne("produit_id") = Valeur(l, "item.id")
                    ligne("produit") = Valeur(l, "item.name", "item.code")
                    ligne("qte") = Valeur(l, "quantity")
                    ligne("prix") = Valeur(l, "unit_price")
                    ligne("montant") = Valeur(l, "total_amount", "amount")
                    ligne("taxe") = Valeur(l, "tax_rate.code", "tax_rate.id")
                    ligne("taxe_montant") = Valeur(l, "tax_amount")
                    ligne("compte") = Valeur(l, "ledger_account.code", "ledger_account.nominal_code")
                    ligne("compte_nom") = Valeur(l, "ledger_account.name")
                    lignes.Add(ligne)
                Next
            End If

            o("lignes") = lignes
            docs.Add(o)
        Next

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@DocumentTypeId", CObj(typeDocument)))
        p.Add(New SqlParameter("@Documents", docs.ToString(Formatting.None)))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))

        Dim ds As DataSet = ExecuteSQLds("s0781ChargerDocumentsImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return "versé en préparation"
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Return "en préparation : " & Lire(r, "NbNouveaux") & " nouveau(x), " &
               Lire(r, "NbExistants") & " déjà en comptabilité, " &
               Lire(r, "NbAnomalies") & " à corriger"
    End Function

    ''' <summary>Un compte qui peut être NULL quand la fournée est vide.</summary>
    Private Shared Function Lire(r As DataRow, champ As String) As Integer
        If IsDBNull(r(champ)) Then Return 0
        Return Convert.ToInt32(r(champ))
    End Function

    ''' <summary>
    ''' La fiche d'entreprise ne se verse pas comme le reste : il n'y a rien à
    ''' créer. Le nom légal, l'adresse et le téléphone existent déjà chez nous —
    ''' non pas dans une table, mais dans les paramètres de la compagnie
    ''' (T100ParamComptable / T101ParamValues), ceux-là mêmes que dbo.fCompanyName
    ''' relit pour afficher le nom en haut de l'écran.
    '''
    ''' Ce qui arrive de la source est donc mis EN REGARD de ce qui est en place,
    ''' champ par champ, dans staging.SocieteImport. L'écran de validation montrera
    ''' les deux colonnes et l'utilisateur tranchera. Rien n'est appliqué ici :
    ''' remplacer l'adresse d'une entreprise parce qu'un autre logiciel en connaît
    ''' une différente ne peut pas être une décision automatique.
    ''' </summary>
    Private Function VerserSociete(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucune fiche"

        Dim fiche As JToken = brut(0)
        Dim adr As JToken = AdressePrincipale(fiche)
        Dim champs As New JArray()

        ' Les correspondances sûres : même notion des deux côtés.
        Ajouter(champs, "LEGAL_NAME", "Nom légal", Valeur(fiche, "legal_name", "company_name"))
        Ajouter(champs, "TRADE_NAME", "Nom commercial", Valeur(fiche, "company_name"))
        Ajouter(champs, "ADDR1", "Adresse (ligne 1)", Valeur(adr, "line1"))
        Ajouter(champs, "ADDR2", "Adresse (ligne 2)", Valeur(adr, "line2"))
        Ajouter(champs, "CITY", "Ville", Valeur(adr, "city"))
        Ajouter(champs, "PROVINCE", "Province", Valeur(adr, "state"))
        Ajouter(champs, "POSTAL", "Code postal", Valeur(adr, "postal_code"))
        Ajouter(champs, "COUNTRY", "Pays", Valeur(adr, "country"))
        Ajouter(champs, "PHONE", "Téléphone", Valeur(Premier(fiche, "phone_numbers"), "number"))

        ' Ce que la source connaît et qui n'a pas d'équivalent chez nous. Sans
        ' nom de paramètre : ces lignes s'affichent pour information, elles ne
        ' pourront rien écraser. On ne les invente pas de correspondance —
        ' fiscal_year_start_month n'est pas FISCAL_YEAR_END, et company_start_date
        ' est le début des livres, pas la date de constitution.
        Ajouter(champs, "", "Courriel (source)", Valeur(Premier(fiche, "emails"), "email"))
        Ajouter(champs, "", "Devise (source)", Valeur(fiche, "currency"))
        Ajouter(champs, "", "Méthode comptable (source)", Valeur(fiche, "accounting_method"))
        Ajouter(champs, "", "Mois de début d'exercice (source)", Valeur(fiche, "fiscal_year_start_month"))
        Ajouter(champs, "", "Début des livres (source)", Valeur(fiche, "company_start_date"))
        Ajouter(champs, "", "Taxes à la vente activées (source)", Valeur(fiche, "sales_tax_enabled"))
        Ajouter(champs, "", "Identifiant chez la source", Valeur(fiche, "id"))

        Dim fichierId As Integer = InscrireAuRegistre("Societe", "informations de la société", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Champs", champs.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0788ChargerSocieteImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return "fiche comparée"
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Return "fiche comparée : " & Lire(r, "NbDifferents") & " écart(s), " &
               Lire(r, "NbIdentiques") & " identique(s), " &
               Lire(r, "NbNouveaux") & " absent(s) chez nous"
    End Function

    ''' <summary>
    ''' Une entreprise peut avoir plusieurs adresses chez la source — livraison,
    ''' facturation, siège. On cherche celle qui la désigne, et on retombe sur la
    ''' première plutôt que de ne rien montrer.
    ''' </summary>
    Private Shared Function AdressePrincipale(fiche As JToken) As JToken
        Dim a As JArray = TryCast(fiche("addresses"), JArray)
        If a Is Nothing OrElse a.Count = 0 Then Return Nothing

        For Each recherche As String In New String() {"primary", "legal", "billing"}
            For Each item As JToken In a
                If String.Equals(Valeur(item, "type"), recherche, StringComparison.OrdinalIgnoreCase) Then
                    Return item
                End If
            Next
        Next
        Return a(0)
    End Function

    ''' <summary>
    ''' Une ligne de comparaison. Les champs vides des deux côtés ne valent pas
    ''' la peine d'être montrés : ils allongeraient l'écran sans rien dire.
    ''' </summary>




    ''' <summary>
    ''' Les pièces jointes — ce que le client a agrafé à ses factures : le PDF du
    ''' fournisseur, la photo du reçu. Sans elles, une facture reprise n'a pas son
    ''' justificatif.
    '''
    ''' Elles ne se lisent pas comme le reste : Apideck n'en donne pas de liste,
    ''' l'adresse est /attachments/{type}/{id}. Il faut donc un appel PAR
    ''' DOCUMENT, et les documents doivent déjà être en préparation — d'où la
    ''' place de cette ressource en fin de catalogue.
    '''
    ''' Seules les métadonnées sont gardées, pas les octets : rapatrier des
    ''' centaines de PDF pendant une extraction la ferait durer des heures, pour
    ''' des fichiers que personne n'a encore validés.
    ''' </summary>
    Private Function LirePiecesJointes(api As clsApideck) As JArray
        Dim sources As DataTable = SourcesPiecesJointes()
        Dim tout As New JArray()

        If sources Is Nothing OrElse sources.Rows.Count = 0 Then Return tout

        For Each s As DataRow In sources.Rows
            Dim genre As String = Convert.ToString(s("Genre"))
            Dim docId As String = Convert.ToString(s("ExterneId"))
            If genre = "" OrElse docId = "" Then Continue For

            Dim liste As JArray
            Try
                liste = api.AttachmentsOf(genre, docId)
            Catch ex As Exception
                ' Un document dont les pièces jointes sont refusées ne doit pas
                ' faire échouer les autres : on passe, la ressource reste utile.
                Continue For
            End Try

            For Each a As JToken In liste
                Dim o As New JObject()
                o("genre") = genre
                o("document_id") = docId
                o("document_numero") = If(IsDBNull(s("Numero")), "", Convert.ToString(s("Numero")))
                o("externe_id") = Valeur(a, "id")
                o("nom") = Valeur(a, "name", "file_name", "filename")
                o("description") = Valeur(a, "description")
                o("type") = Valeur(a, "content_type", "type", "mime_type")
                o("taille") = Valeur(a, "size", "file_size")
                o("url") = Valeur(a, "url", "download_url", "file_url")
                o("date") = Valeur(a, "created_at", "updated_at")
                tout.Add(o)
            Next

            ' La même courtoisie qu'entre les ressources : QuickBooks n'accepte
            ' que dix appels simultanés par société, et ici on en enchaîne un
            ' par document.
            Threading.Thread.Sleep(250)
        Next

        Return tout
    End Function

    ''' <summary>Les documents à interroger, et le nom qu'Apideck leur donne.</summary>
    Private Function SourcesPiecesJointes() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0815GetSourcesPiecesJointes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Function VerserPiecesJointes(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucune pièce jointe"

        Dim fichierId As Integer = InscrireAuRegistre("PieceJointe", "pièces jointes", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Pieces", brut.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0814ChargerPiecesJointes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbPieces") & " pièce(s) sur " &
                              Lire(r, "NbDocuments") & " document(s)"
        If Lire(r, "NbSansLien") > 0 Then texte &= ", " & Lire(r, "NbSansLien") & " sans adresse"
        Return texte
    End Function

    ''' <summary>
    ''' Les conditions de paiement.
    '''
    ''' Apideck ne les cartographie pas : elles viennent du PASSE-PLAT, c'est-à-dire
    ''' de l'API native de QuickBooks, en réutilisant le jeton de la connexion.
    ''' C'est la seule ressource du catalogue dans ce cas, et c'est assumé : une
    ''' condition de paiement n'est pas une étiquette, c'est une date d'échéance —
    ''' « Net 30 » décide de quand la facture est due.
    '''
    ''' Contrepartie à connaître : la réponse est celle d'Intuit, pas d'Apideck.
    ''' Un autre connecteur ne répondra pas la même chose.
    ''' </summary>
    Private Function LireConditionsPaiement(api As clsApideck) As JArray
        Dim brut As JArray = api.QuickBooksQuery("Term", api.RealmId())
        Dim liste As New JArray()
        Dim rang As Integer = 0

        For Each t As JToken In brut
            rang += 1
            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(t, "Id")
            o("nom") = Valeur(t, "Name")
            o("type") = Valeur(t, "Type")
            o("jours") = Valeur(t, "DueDays")
            o("jours_escompte") = Valeur(t, "DiscountDays")
            o("pourcent_escompte") = Valeur(t, "DiscountPercent")
            o("jour_du_mois") = Valeur(t, "DayOfMonthDue")
            o("actif") = Valeur(t, "Active")
            liste.Add(o)
        Next

        Return liste
    End Function

    Private Function VerserConditionsPaiement(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucune condition"

        Dim fichierId As Integer = InscrireAuRegistre("ConditionPaiement", "conditions de paiement", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Conditions", brut.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0817ChargerConditionsPaiement", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbNouvelles") & " condition(s)"
        If Lire(r, "NbActives") > 0 Then texte &= ", " & Lire(r, "NbActives") & " active(s)"
        If Lire(r, "NbAnomalies") > 0 Then texte &= ", " & Lire(r, "NbAnomalies") & " à corriger"
        Return texte
    End Function

    ''' <summary>
    ''' Les engagements : soumissions et bons de commande.
    '''
    ''' Ni l'un ni l'autre ne touche un compte — ce sont des promesses. Les mêler
    ''' aux documents comptables ferait entrer en comptabilité des montants qui
    ''' n'y ont rien à faire. D'où leur propre table.
    ''' </summary>
    Private Function VerserPieces(brut As JArray, genre As String, runId As Integer) As String
        Dim typeImport As String = If(genre = "Soumission", "Soumission", "BonCommande")
        Dim libelle As String = If(genre = "Soumission", "soumissions", "bons de commande")

        Dim pieces As New JArray()
        Dim rang As Integer = 0

        For Each d As JToken In brut
            rang += 1
            Dim tiers As JToken = If(d("customer"), d("supplier"))

            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(d, "id")
            o("numero") = Valeur(d, "number", "quote_number", "po_number", "reference")
            o("date") = Valeur(d, "quote_date", "po_date", "issue_date", "transaction_date", "created_at")
            o("expiration") = Valeur(d, "expiry_date", "expiration_date", "due_date", "delivery_date")
            o("tiers_id") = Valeur(tiers, "id")
            o("tiers") = Valeur(tiers, "display_name", "company_name", "name")
            o("devise") = Valeur(d, "currency")
            o("sous_total") = Valeur(d, "sub_total")
            o("taxes") = Valeur(d, "total_tax")
            o("total") = Valeur(d, "total", "total_amount")
            o("statut") = Valeur(d, "status")
            o("lignes") = LignesArticles(d)
            pieces.Add(o)
        Next

        Dim fichierId As Integer = InscrireAuRegistre(typeImport, libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", genre))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Pieces", pieces.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0804ChargerPiecesCommerciales", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbValides") & " pièce(s)"
        If Lire(r, "NbSansTiers") > 0 Then texte &= ", " & Lire(r, "NbSansTiers") & " sans tiers reconnu"
        If Lire(r, "NbAnomalies") > 0 Then texte &= ", " & Lire(r, "NbAnomalies") & " à corriger"
        Return texte
    End Function

    ''' <summary>
    ''' Les mouvements d'argent : encaissements, décaissements, remboursements.
    '''
    ''' Le même geste dans les trois cas — de l'argent change de mains et s'impute
    ''' sur des documents. L'imputation compte autant que le montant : un paiement
    ''' qui règle trois factures doit dire lesquelles, sinon le rapprochement
    ''' devient une devinette.
    ''' </summary>
    Private Function VerserPaiements(brut As JArray, sens As String, runId As Integer) As String
        Dim libelle As String
        Select Case sens
            Case "Encaissement" : libelle = "encaissements"
            Case "Decaissement" : libelle = "décaissements"
            Case Else : libelle = "remboursements"
        End Select

        Dim paiements As New JArray()
        Dim rang As Integer = 0

        For Each d As JToken In brut
            rang += 1
            Dim tiers As JToken = If(d("customer"), d("supplier"))

            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(d, "id")
            o("reference") = Valeur(d, "reference", "number", "transaction_number")
            o("date") = Valeur(d, "transaction_date", "payment_date", "date", "created_at")
            o("tiers_id") = Valeur(tiers, "id")
            o("tiers") = Valeur(tiers, "display_name", "company_name", "name")
            o("devise") = Valeur(d, "currency")
            o("montant") = Valeur(d, "total_amount", "amount")
            o("non_impute") = Valeur(d, "unallocated_amount", "remaining_credit")
            o("mode") = Valeur(d, "payment_method.name", "payment_method", "method")
            o("compte_id") = Valeur(d, "account.id", "bank_account.id")
            o("compte") = Valeur(d, "account.name", "bank_account.name")
            o("statut") = Valeur(d, "status")

            ' Les imputations. Apideck les nomme differemment selon la
            ' ressource ; on prend la premiere qui repond.
            Dim affectations As New JArray()
            Dim lot As JArray = TryCast(d("allocations"), JArray)
            If lot Is Nothing Then lot = TryCast(d("payment_allocations"), JArray)
            If lot Is Nothing Then lot = TryCast(d("linked_transactions"), JArray)

            If lot IsNot Nothing Then
                Dim no As Integer = 0
                For Each a As JToken In lot
                    no += 1
                    Dim x As New JObject()
                    x("no") = no
                    x("document_id") = Valeur(a, "id", "invoice.id", "transaction_id")
                    x("document_numero") = Valeur(a, "number", "invoice.number", "reference")
                    x("document_type") = Valeur(a, "type", "transaction_type")
                    x("montant") = Valeur(a, "amount", "total_amount", "allocated_amount")
                    affectations.Add(x)
                Next
            End If
            o("affectations") = affectations

            paiements.Add(o)
        Next

        Dim fichierId As Integer = InscrireAuRegistre(sens, libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Sens", sens))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Paiements", paiements.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0806ChargerPaiementsImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbValides") & " mouvement(s), " &
                              Lire(r, "NbAffectations") & " imputation(s)"
        If Lire(r, "NbSansTiers") > 0 Then texte &= ", " & Lire(r, "NbSansTiers") & " sans tiers reconnu"
        If Lire(r, "NbAnomalies") > 0 Then texte &= ", " & Lire(r, "NbAnomalies") & " à corriger"
        Return texte
    End Function

    ''' <summary>
    ''' Les écritures de journal.
    '''
    ''' Seule famille où l'équilibre se vérifie : des débits qui ne font pas les
    ''' crédits, c'est faux, et il vaut mieux l'apprendre à l'import qu'au moment
    ''' de comptabiliser. Les totaux sont recalculés en SQL à partir des lignes,
    ''' jamais repris de la source — c'est le seul jugement indépendant possible.
    ''' </summary>
    Private Function VerserEcritures(brut As JArray, runId As Integer) As String
        Dim ecritures As New JArray()
        Dim rang As Integer = 0

        For Each d As JToken In brut
            rang += 1

            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(d, "id")
            o("numero") = Valeur(d, "journal_symbol", "number", "reference")
            o("date") = Valeur(d, "posted_at", "transaction_date", "date", "created_at")
            o("libelle") = Valeur(d, "memo", "description", "title")
            o("devise") = Valeur(d, "currency")
            o("journal") = Valeur(d, "journal_symbol", "journal.symbol", "journal.name")
            o("statut") = Valeur(d, "status")

            Dim lignes As New JArray()
            Dim lot As JArray = TryCast(d("line_items"), JArray)
            If lot Is Nothing Then lot = TryCast(d("lines"), JArray)

            If lot IsNot Nothing Then
                Dim no As Integer = 0
                For Each l As JToken In lot
                    no += 1
                    Dim ligne As New JObject()
                    ligne("no") = no
                    ligne("compte_id") = Valeur(l, "ledger_account.id", "account_id")
                    ligne("compte") = Valeur(l, "ledger_account.code", "ledger_account.nominal_code")
                    ligne("compte_nom") = Valeur(l, "ledger_account.name")
                    ligne("description") = Valeur(l, "description", "memo")

                    ' Apideck donne soit un debit et un credit separes, soit un
                    ' montant signe avec un type. On accepte les deux formes.
                    Dim debit As String = Valeur(l, "debit_amount", "debit")
                    Dim credit As String = Valeur(l, "credit_amount", "credit")

                    If debit = "" AndAlso credit = "" Then
                        Dim montant As String = Valeur(l, "total_amount", "amount")
                        Dim sens As String = Valeur(l, "type").ToLowerInvariant()
                        If sens = "debit" Then
                            debit = montant
                        ElseIf sens = "credit" Then
                            credit = montant
                        Else
                            ' Sans indication, un montant négatif est un crédit.
                            Dim v As Object = Nombre(montant)
                            If v IsNot Nothing AndAlso CDec(v) < 0D Then
                                credit = Math.Abs(CDec(v)).ToString(Globalization.CultureInfo.InvariantCulture)
                            Else
                                debit = montant
                            End If
                        End If
                    End If

                    ligne("debit") = debit
                    ligne("credit") = credit
                    ligne("tiers_id") = Valeur(l, "customer.id", "supplier.id", "contact.id")
                    ligne("tiers") = Valeur(l, "customer.display_name", "supplier.display_name", "contact.name")
                    lignes.Add(ligne)
                Next
            End If

            o("lignes") = lignes
            ecritures.Add(o)
        Next

        Dim fichierId As Integer = InscrireAuRegistre("EcritureJournal", "écritures de journal", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Ecritures", ecritures.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0808ChargerEcrituresImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbEquilibrees") & " équilibrée(s)"
        If Lire(r, "NbDesequilibrees") > 0 Then texte &= ", " & Lire(r, "NbDesequilibrees") & " déséquilibrée(s)"
        If Lire(r, "NbInvalides") > 0 Then texte &= ", " & Lire(r, "NbInvalides") & " sans ligne"
        Return texte
    End Function

    ''' <summary>Les lignes d'articles, forme partagée par les pièces commerciales.</summary>
    Private Shared Function LignesArticles(d As JToken) As JArray
        Dim lignes As New JArray()
        Dim lot As JArray = TryCast(d("line_items"), JArray)
        If lot Is Nothing Then Return lignes

        Dim no As Integer = 0
        For Each l As JToken In lot
            no += 1
            Dim ligne As New JObject()
            ligne("no") = no
            ligne("description") = Valeur(l, "description")
            ligne("produit_id") = Valeur(l, "item.id")
            ligne("produit") = Valeur(l, "item.name", "item.code")
            ligne("qte") = Valeur(l, "quantity")
            ligne("prix") = Valeur(l, "unit_price")
            ligne("montant") = Valeur(l, "total_amount", "amount")
            ligne("taxe") = Valeur(l, "tax_rate.code", "tax_rate.id")
            lignes.Add(ligne)
        Next
        Return lignes
    End Function


    ''' <summary>
    ''' Le bilan.
    '''
    ''' La source le rend en ARBRE : ACTIFS 223 → Actifs à court terme 223 →
    ''' Comptes clients 223 (compte 58). On l'aplatit ici, en gardant le niveau
    ''' et l'ordre : la récursion se fait mieux en .NET qu'en T-SQL, et une table
    ''' plate se somme, se compare et s'affiche sans détour.
    '''
    ''' Ce rapport ne sert pas à créer quoi que ce soit. Il sert à répondre, la
    ''' reprise terminée, à la seule question qui compte : est-ce que mon bilan
    ''' donne le même total que celui de la source ?
    ''' </summary>
    Private Function VerserBilan(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucun rapport"

        ' La source emballe le bilan dans une liste de rapports.
        Dim r As JToken = brut(0)
        Dim lot As JArray = TryCast(r("reports"), JArray)
        If lot IsNot Nothing AndAlso lot.Count > 0 Then r = lot(0)

        Dim lignes As New JArray()
        Dim ordre As Integer = 0

        Aplatir(r("assets"), "ACTIF", 0, lignes, ordre)
        Aplatir(r("liabilities"), "PASSIF", 0, lignes, ordre)
        Aplatir(r("equity"), "CAPITAL", 0, lignes, ordre)

        Dim entete As New JObject()
        entete("nom") = Valeur(r, "report_name")
        entete("debut") = Valeur(r, "start_date")
        entete("fin") = Valeur(r, "end_date")
        entete("devise") = Valeur(r, "currency")
        entete("actif") = Valeur(r, "assets.value", "assets.total")
        entete("passif") = Valeur(r, "liabilities.value", "liabilities.total")
        entete("capital") = Valeur(r, "equity.value", "equity.total")

        Return DeposerRapport("Bilan", "bilan", entete, lignes, brut, runId)
    End Function

    ''' <summary>
    ''' L'état des résultats.
    '''
    ''' Forme différente du bilan — des sections nommées, chacune avec ses
    ''' enregistrements — d'où un aplatissement à part. Vouloir un seul parcours
    ''' pour les deux aurait demandé d'inventer une forme commune que la source
    ''' n'a pas.
    ''' </summary>
    Private Function VerserResultats(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucun rapport"

        Dim r As JToken = brut(0)
        Dim lot As JArray = TryCast(r("reports"), JArray)
        If lot IsNot Nothing AndAlso lot.Count > 0 Then r = lot(0)

        Dim lignes As New JArray()
        Dim ordre As Integer = 0

        Section(r("income"), "REVENUS", lignes, ordre)
        Section(r("cost_of_goods_sold"), "COUT_VENTES", lignes, ordre)
        Section(r("expenses"), "DEPENSES", lignes, ordre)
        Section(r("other_income"), "AUTRES_REVENUS", lignes, ordre)
        Section(r("other_expenses"), "AUTRES_DEPENSES", lignes, ordre)

        ' Les trois résultats intermédiaires : des totaux, pas du détail.
        AjouterTotal(lignes, ordre, "RESULTAT", "Bénéfice brut", Valeur(r, "gross_profit.total"))
        AjouterTotal(lignes, ordre, "RESULTAT", "Résultat d'exploitation", Valeur(r, "net_operating_income.total"))
        AjouterTotal(lignes, ordre, "RESULTAT", "Résultat net", Valeur(r, "net_income.total"))

        Dim entete As New JObject()
        entete("nom") = Valeur(r, "report_name")
        entete("debut") = Valeur(r, "start_date")
        entete("fin") = Valeur(r, "end_date")
        entete("devise") = Valeur(r, "currency")
        entete("revenus") = Valeur(r, "income.total")
        entete("depenses") = Valeur(r, "expenses.total")
        entete("resultat") = Valeur(r, "net_income.total")

        Return DeposerRapport("Resultats", "état des résultats", entete, lignes, brut, runId)
    End Function

    ''' <summary>
    ''' Descend une branche du bilan. Un nœud qui porte des enfants est un
    ''' sous-total : on le marque comme tel pour qu'une somme du détail ne le
    ''' compte pas deux fois.
    ''' </summary>
    Private Shared Sub Aplatir(noeud As JToken, section As String, niveau As Integer,
                               lignes As JArray, ByRef ordre As Integer)
        If noeud Is Nothing OrElse noeud.Type = JTokenType.Null Then Exit Sub

        Dim enfants As JArray = TryCast(noeud("items"), JArray)
        If enfants Is Nothing Then enfants = TryCast(noeud("records"), JArray)

        Dim o As New JObject()
        o("section") = section
        o("niveau") = niveau
        o("ordre") = ordre
        o("libelle") = Valeur(noeud, "name", "title")
        o("compte_id") = Valeur(noeud, "account_id", "id")
        o("montant") = Valeur(noeud, "value", "total")
        o("total") = If(enfants IsNot Nothing AndAlso enfants.Count > 0, 1, 0)
        lignes.Add(o)
        ordre += 1

        If enfants Is Nothing Then Exit Sub
        For Each enfant As JToken In enfants
            Aplatir(enfant, section, niveau + 1, lignes, ordre)
        Next
    End Sub

    ''' <summary>Une section de l'état des résultats : son titre, puis son détail.</summary>
    Private Shared Sub Section(noeud As JToken, section As String,
                               lignes As JArray, ByRef ordre As Integer)
        If noeud Is Nothing OrElse noeud.Type = JTokenType.Null Then Exit Sub
        Aplatir(noeud, section, 0, lignes, ordre)
    End Sub

    Private Shared Sub AjouterTotal(lignes As JArray, ByRef ordre As Integer,
                                    section As String, libelle As String, montant As String)
        If montant = "" Then Exit Sub

        Dim o As New JObject()
        o("section") = section
        o("niveau") = 0
        o("ordre") = ordre
        o("libelle") = libelle
        o("compte_id") = ""
        o("montant") = montant
        o("total") = 1
        lignes.Add(o)
        ordre += 1
    End Sub

    Private Function DeposerRapport(genre As String, libelle As String,
                                    entete As JObject, lignes As JArray,
                                    brut As JArray, runId As Integer) As String
        Dim fichierId As Integer = InscrireAuRegistre("Rapport", libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", genre))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Entete", entete.ToString(Formatting.None)))
        p.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0810ChargerRapportImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Return "en préparation : " & Lire(ds.Tables(0).Rows(0), "NbLignes") & " poste(s)"
    End Function

    ''' <summary>
    ''' Les balances âgées.
    '''
    ''' Rien à voir avec un arbre de comptes : des montants par tiers, par devise
    ''' et par tranche de jours. La forme impose sa table, et l'aplatissement
    ''' répète le total du tiers sur chacune de ses tranches — c'est le prix
    ''' d'une table plate, et il est faible.
    ''' </summary>
    Private Function VerserBalanceAgee(brut As JArray, genre As String, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucun rapport"

        Dim r As JToken = brut(0)
        Dim arrete As String = Valeur(r, "report_as_of_date")
        Dim longueur As String = Valeur(r, "period_length")

        Dim lignes As New JArray()
        Dim tiersLot As JArray = TryCast(r("outstanding_balances"), JArray)

        If tiersLot IsNot Nothing Then
            For Each t As JToken In tiersLot
                Dim tiersId As String = Valeur(t, "customer_id", "supplier_id", "id")
                Dim tiersNom As String = Valeur(t, "customer_name", "supplier_name", "name")

                Dim devises As JArray = TryCast(t("outstanding_balances_by_currency"), JArray)
                If devises Is Nothing Then Continue For

                For Each dev As JToken In devises
                    Dim periodes As JArray = TryCast(dev("balances_by_period"), JArray)
                    If periodes Is Nothing Then Continue For

                    Dim ordre As Integer = 0
                    For Each per As JToken In periodes
                        Dim o As New JObject()
                        o("arrete") = arrete
                        o("longueur") = longueur
                        o("tiers_id") = tiersId
                        o("tiers") = tiersNom
                        o("devise") = Valeur(dev, "currency")
                        o("total_tiers") = Valeur(dev, "total_amount")
                        o("ordre") = ordre
                        o("debut") = Valeur(per, "start_date")
                        o("fin") = Valeur(per, "end_date")
                        o("montant") = Valeur(per, "total_amount")
                        lignes.Add(o)
                        ordre += 1
                    Next
                Next
            Next
        End If

        If lignes.Count = 0 Then Return "aucun solde en souffrance"

        Dim typeImport As String = "BalanceAgee"
        Dim libelle As String = If(genre = "Client", "balance âgée clients", "balance âgée fournisseurs")
        Dim fichierId As Integer = InscrireAuRegistre(typeImport, libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", genre))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0812ChargerBalanceAgee", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim x As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(x, "NbTiers") & " tiers, " &
                              Lire(x, "NbLignes") & " tranche(s)"
        If Lire(x, "NbSansTiers") > 0 Then texte &= ", " & Lire(x, "NbSansTiers") & " sans tiers reconnu"
        Return texte
    End Function

    ''' <summary>
    ''' Les listes de structure. Chacune a sa table — un mode de paiement n'a pas
    ''' les colonnes d'un emplacement, et les loger ensemble obligeait soit à une
    ''' table pleine de trous, soit à appauvrir les six au plus petit dénominateur.
    '''
    ''' Ce qui reste commun tient ici : la mise en forme du JSON, l'inscription au
    ''' registre, et la lecture du compte rendu. Ce qui diffère est dans la
    ''' fonction de chaque liste — c'est-à-dire presque rien, et c'est le signe
    ''' que le découpage est au bon endroit.
    '''
    ''' Ces listes n'ont aucune destination dans l'ERP : elles s'arrêtent à la
    ''' préparation. Le client voit ce que sa comptabilité contient, et la donnée
    ''' est là le jour où la fonction correspondante existera.
    ''' </summary>
    Private Function VerserModesPaiement(brut As JArray, runId As Integer) As String
        Dim liste As New JArray()
        Dim rang As Integer = 0

        For Each e As JToken In brut
            rang += 1
            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(e, "id")
            o("code") = Valeur(e, "code", "display_id")
            o("nom") = Valeur(e, "name", "display_name")
            o("type") = Valeur(e, "type")
            o("statut") = Valeur(e, "status")
            o("extra") = e
            liste.Add(o)
        Next

        Return DeposerListe(liste, "s0797ChargerModesPaiementImport",
                            "ModePaiement", "modes de paiement", brut, runId)
    End Function

    Private Function VerserCategoriesSuivi(brut As JArray, runId As Integer) As String
        Dim liste As New JArray()
        Dim rang As Integer = 0

        For Each e As JToken In brut
            rang += 1
            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(e, "id")
            o("code") = Valeur(e, "code", "display_id")
            o("nom") = Valeur(e, "name")
            o("parent_id") = Valeur(e, "parent_id", "parent.id")
            o("statut") = Valeur(e, "status")
            o("extra") = e
            liste.Add(o)
        Next

        Return DeposerListe(liste, "s0798ChargerCategoriesSuiviImport",
                            "CategorieSuivi", "catégories de suivi", brut, runId)
    End Function

    Private Function VerserDepartements(brut As JArray, runId As Integer) As String
        Dim liste As New JArray()
        Dim rang As Integer = 0

        For Each e As JToken In brut
            rang += 1
            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(e, "id")
            o("code") = Valeur(e, "code", "display_id")
            o("nom") = Valeur(e, "name")
            o("parent_id") = Valeur(e, "parent_id", "parent.id")
            o("statut") = Valeur(e, "status")
            o("extra") = e
            liste.Add(o)
        Next

        Return DeposerListe(liste, "s0799ChargerDepartementsImport",
                            "Departement", "départements", brut, runId)
    End Function

    Private Function VerserEmplacements(brut As JArray, runId As Integer) As String
        Dim liste As New JArray()
        Dim rang As Integer = 0

        For Each e As JToken In brut
            rang += 1
            Dim adr As JToken = If(e("address"), Premier(e, "addresses"))

            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(e, "id")
            o("code") = Valeur(e, "code", "display_id")
            o("nom") = Valeur(e, "name")
            o("parent_id") = Valeur(e, "parent_id", "parent.id")
            o("adresse") = Valeur(adr, "line1", "string")
            o("ville") = Valeur(adr, "city")
            o("province") = Valeur(adr, "state")
            o("code_postal") = Valeur(adr, "postal_code")
            o("pays") = Valeur(adr, "country")
            o("statut") = Valeur(e, "status")
            o("extra") = e
            liste.Add(o)
        Next

        Return DeposerListe(liste, "s0800ChargerEmplacementsImport",
                            "Emplacement", "emplacements", brut, runId)
    End Function

    ''' <summary>
    ''' Le chemin commun : inscrire la réponse d'origine au registre, appeler le
    ''' chargement de la liste, et dire ce qui en est ressorti.
    ''' </summary>
    Private Function DeposerListe(liste As JArray, procedure As String,
                                  typeImport As String, libelle As String,
                                  brut As JArray, runId As Integer) As String
        If liste.Count = 0 Then Return "aucun élément"

        Dim fichierId As Integer = InscrireAuRegistre(typeImport, libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Elements", liste.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds(procedure, p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return "en préparation"
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbNouveaux") & " élément(s)"
        If Lire(r, "NbDoublons") > 0 Then texte &= ", " & Lire(r, "NbDoublons") & " en double"
        If Lire(r, "NbInvalides") > 0 Then texte &= ", " & Lire(r, "NbInvalides") & " sans nom ni code"
        Return texte
    End Function

    ''' <summary>
    ''' Les taux de taxe de la source.
    '''
    ''' C'est la pièce qui manquait pour que les factures importées bouclent. La
    ''' source donne, sur chaque ligne, un code de taxe — et un total de taxes sur
    ''' l'entête. Tant que ces codes ne voulaient rien dire ici, TPS et TVQ
    ''' restaient vides et le document ne s'additionnait pas.
    '''
    ''' La difficulté est canadienne : une taxe québécoise arrive comme UN taux
    ''' portant DEUX composantes, « GST » 5 % et « QST » 9,975 %. Le taux global
    ''' ne suffit donc pas — il faut les composantes, et c'est le chargement qui
    ''' les range d'un côté ou de l'autre.
    ''' </summary>
    Private Function VerserTaxes(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucun taux"

        Dim taux As New JArray()
        Dim rang As Integer = 0

        For Each t As JToken In brut
            rang += 1

            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(t, "id")
            o("code") = Valeur(t, "code", "display_id")
            o("nom") = Valeur(t, "name")
            o("description") = Valeur(t, "description")
            o("pays") = Valeur(t, "country")
            o("taux_effectif") = Valeur(t, "effective_tax_rate")
            o("taux_total") = Valeur(t, "total_tax_rate")
            o("type") = Valeur(t, "type", "report_tax_type")
            o("statut") = Valeur(t, "status")

            ' Les composantes recopiées telles quelles : le classement TPS/TVQ se
            ' fait en SQL, où il reste lisible et vérifiable après coup.
            Dim composantes As New JArray()
            Dim liste As JArray = TryCast(t("components"), JArray)
            If liste IsNot Nothing Then
                For Each c As JToken In liste
                    Dim x As New JObject()
                    x("nom") = Valeur(c, "name")
                    x("taux") = Valeur(c, "rate")
                    composantes.Add(x)
                Next
            End If
            o("composantes") = composantes

            taux.Add(o)
        Next

        Dim fichierId As Integer = InscrireAuRegistre("Taxe", "taxes", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Taxes", taux.ToString(Formatting.None)))

        Dim ds As DataSet = ExecuteSQLds("s0792ChargerTaxesImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return "taux déposés"
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = Lire(r, "NbTaux") & " taux, " & Lire(r, "NbReconnues") & " répartissable(s)"
        If Lire(r, "NbAVerifier") > 0 Then
            texte &= ", " & Lire(r, "NbAVerifier") & " à vérifier"
        End If
        Return texte
    End Function

    ''' <summary>
    ''' Coupe les taxes des documents en préparation d'après les taux importés.
    '''
    ''' Se fait à la fin de l'extraction, pas au fil de l'eau : dans une même
    ''' passe, les taux arrivent avant les factures, mais l'utilisateur peut très
    ''' bien n'avoir coché que les factures. En repassant à la fin, on profite
    ''' aussi des taux d'une extraction précédente.
    ''' </summary>
    Private Function RepartirTaxes() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))

            Dim ds As DataSet = ExecuteSQLds("s0794RepartirTaxesImport", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return ""

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim coupees As Integer = Lire(r, "NbLignesCoupees") + Lire(r, "NbDocumentsParTotal")
            Dim boiteux As Integer = Lire(r, "NbDesequilibres")

            If coupees = 0 AndAlso boiteux = 0 Then Return ""

            Dim texte As String = "Taxes réparties : " & coupees & " élément(s)."
            If boiteux > 0 Then
                texte &= " " & boiteux & " document(s) ne bouclent toujours pas — " &
                         "ils ne pourront pas être créés tant que la répartition n'est pas faite."
            End If
            Return texte

        Catch ex As Exception
            ' La répartition est un confort, pas une étape critique : son échec
            ' ne doit pas faire perdre une extraction qui a réussi.
            Return "La répartition des taxes a échoué : " & ex.Message
        End Try
    End Function


    Private Shared Sub Ajouter(champs As JArray, nom As String, libelle As String, valeur As String)
        If nom = "" AndAlso valeur = "" Then Exit Sub

        Dim o As New JObject()
        o("ordre") = champs.Count
        o("champ") = nom
        o("libelle") = libelle
        o("valeur") = valeur
        champs.Add(o)
    End Sub

    ''' <summary>
    ''' Inscrit une ressource au registre des imports sans l'éclater. Sert aux
    ''' ressources qui ont leur propre rail — le plan comptable — pour qu'elles
    ''' figurent quand même dans staging.ImportFiles avec leur contenu d'origine.
    '''
    ''' On n'appelle pas s0604 : il ne sait éclater que les listes et lèverait
    ''' sur un type qu'il ne connaît pas.
    ''' </summary>
    Private Function InscrireAuRegistre(typeImport As String, genre As String, brut As JArray) As Integer
        Dim json As String = New JObject(New JProperty("rows", brut)).ToString(Formatting.None)
        Dim octets As Byte() = Encoding.UTF8.GetBytes(json)
        Dim nom As String = "QuickBooks — " & genre & " (Apideck) — " &
                            DateTime.Now.ToString("yyyy-MM-dd HH:mm") & ".json"

        Dim p As New Collection
        p.Add(New SqlParameter("@TypeImport", typeImport))
        p.Add(New SqlParameter("@OriginalName", nom))
        p.Add(New SqlParameter("@FileExtension", ".json"))
        p.Add(New SqlParameter("@FileSize", CObj(CLng(octets.Length))))
        p.Add(New SqlParameter("@ContentType", "application/json"))
        p.Add(New SqlParameter("@FileContent", octets))
        p.Add(New SqlParameter("@UploadedBy", CObj(UserId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0600InsertImportFile", p)
        Dim id As Integer = Convert.ToInt32(ds.Tables(0).Rows(0)(0))

        Dim p2 As New Collection
        p2.Add(New SqlParameter("@Id", CObj(id)))
        p2.Add(New SqlParameter("@JsonResult", json))
        p2.Add(New SqlParameter("@InputTokens", CObj(0)))
        p2.Add(New SqlParameter("@OutputTokens", CObj(0)))
        p2.Add(New SqlParameter("@EstimatedCostUsd", CObj(0D)))
        p2.Add(New SqlParameter("@ModelUsed", "apideck/" & clsApideck.ServiceId()))
        p2.Add(New SqlParameter("@Status", "Done"))
        p2.Add(New SqlParameter("@ErrorMessage", DBNull.Value))
        ExecuteSQL("s0602UpdateImportFileResult", p2)

        Return id
    End Function
    ''' <summary>
    ''' Le chemin commun des listes : un fichier virtuel, son JSON en résultat,
    ''' puis l'éclatement par s0604 — exactement ce que fait l'import par
    ''' fichier une fois l'IA passée.
    '''
    ''' staging.ImportFiles attend un fichier. Ici il n'y en a pas, alors on y
    ''' dépose la réponse d'Apideck elle-même : l'origine reste vérifiable, et
    ''' la suite du chemin ne change pas d'un octet.
    ''' </summary>
    Private Function Livrer(typeImport As String, genre As String, lignes As JArray) As String
        Dim json As String = New JObject(New JProperty("rows", lignes)).ToString(Formatting.None)
        Dim octets As Byte() = Encoding.UTF8.GetBytes(json)
        Dim nom As String = "QuickBooks — " & genre & " (Apideck) — " &
                            DateTime.Now.ToString("yyyy-MM-dd HH:mm") & ".json"

        Dim p As New Collection
        p.Add(New SqlParameter("@TypeImport", typeImport))
        p.Add(New SqlParameter("@OriginalName", nom))
        p.Add(New SqlParameter("@FileExtension", ".json"))
        p.Add(New SqlParameter("@FileSize", CObj(CLng(octets.Length))))
        p.Add(New SqlParameter("@ContentType", "application/json"))
        p.Add(New SqlParameter("@FileContent", octets))
        p.Add(New SqlParameter("@UploadedBy", CObj(UserId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0600InsertImportFile", p)
        Dim id As Integer = Convert.ToInt32(ds.Tables(0).Rows(0)(0))

        ' Aucune IA n'est intervenue : les jetons et le coût restent à zéro,
        ' et le modèle dit d'où vient la donnée.
        Dim p2 As New Collection
        p2.Add(New SqlParameter("@Id", CObj(id)))
        p2.Add(New SqlParameter("@JsonResult", json))
        p2.Add(New SqlParameter("@InputTokens", CObj(0)))
        p2.Add(New SqlParameter("@OutputTokens", CObj(0)))
        p2.Add(New SqlParameter("@EstimatedCostUsd", CObj(0D)))
        p2.Add(New SqlParameter("@ModelUsed", "apideck/" & clsApideck.ServiceId()))
        p2.Add(New SqlParameter("@Status", "Done"))
        p2.Add(New SqlParameter("@ErrorMessage", DBNull.Value))
        ExecuteSQL("s0602UpdateImportFileResult", p2)

        Dim p3 As New Collection
        p3.Add(New SqlParameter("@ImportFileId", CObj(id)))
        ExecuteSQLds("s0604ProcessImportJson", p3)

        Return "versé en préparation — import " & id
    End Function

#End Region

#Region "La base"

    Private Function OuvrirRun() As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Connecteur", "APIDECK"))
        p.Add(New SqlParameter("@Service", clsApideck.ServiceId()))
        p.Add(New SqlParameter("@ConsumerId", Company.ToString()))
        p.Add(New SqlParameter("@UserId", CObj(UserId)))

        Dim ds As DataSet = ExecuteSQLds("s0776OuvrirConnecteurRun", p)
        Return Convert.ToInt32(ds.Tables(0).Rows(0)(0))
    End Function

    Private Sub FermerRun(runId As Integer, statut As String, note As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Statut", statut))
        p.Add(New SqlParameter("@Note", If(note Is Nothing, CObj(DBNull.Value), CObj(note))))
        ExecuteSQL("s0778FermerConnecteurRun", p)
    End Sub

#End Region

#Region "Affichage"

    Private Sub AfficherRessources()
        Dim sb As New StringBuilder()
        sb.Append("<div class='ress'>")

        Dim groupe As String = ""
        For Each r As Ressource In Catalogue
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
    Private Function RessourcesChoisies() As List(Of Ressource)
        Dim cochees As String() = Request.Form.GetValues("res")
        If cochees Is Nothing Then Return New List(Of Ressource)

        Dim voulues As New HashSet(Of String)(cochees)
        Return Catalogue.Where(Function(r) voulues.Contains(r.Cle)).ToList()
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

#Region "Petits secours"

    ''' <summary>
    ''' La première valeur non vide parmi plusieurs chemins. Apideck normalise,
    ''' mais pas complètement : un même champ s'appelle « company_name » chez un
    ''' connecteur et « display_name » chez un autre.
    ''' </summary>
    Private Shared Function Valeur(t As JToken, ParamArray chemins As String()) As String
        If t Is Nothing Then Return ""

        For Each c As String In chemins
            Dim v As JToken = t.SelectToken(c)
            If v Is Nothing OrElse v.Type = JTokenType.Null Then Continue For

            Dim s As String = v.ToString()
            If s <> "" Then Return s
        Next
        Return ""
    End Function

    ''' <summary>Le premier élément d'un tableau : l'adresse ou le téléphone principal.</summary>
    Private Shared Function Premier(t As JToken, nom As String) As JToken
        If t Is Nothing Then Return Nothing
        Dim a As JArray = TryCast(t(nom), JArray)
        If a Is Nothing OrElse a.Count = 0 Then Return Nothing
        Return a(0)
    End Function

    ''' <summary>Un nombre lisible par SQL, ou rien : le point décimal, jamais la virgule.</summary>
    Private Shared Function Nombre(texte As String) As Object
        Dim d As Decimal
        If Decimal.TryParse(If(texte, "").Replace(","c, "."c), Globalization.NumberStyles.Any,
                            Globalization.CultureInfo.InvariantCulture, d) Then
            Return d
        End If
        Return Nothing
    End Function

#End Region

End Class
