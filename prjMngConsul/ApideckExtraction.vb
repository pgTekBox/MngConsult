Imports System.Data.SqlClient
Imports System.Text
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

''' <summary>
''' Le moteur d'extraction Apideck — lire chez la source, déposer le brut,
''' verser dans la préparation. Sans écran.
'''
''' Il a d'abord vécu dans la page « Importer depuis QuickBooks ». Le jour où
''' chaque écran d'import a voulu son propre bouton — rapatrier SES clients,
''' SA balance, SES factures, sans passer par la page qui rapatrie tout —, il
''' fallait que le moteur soit appelable d'ailleurs. Il ne connaît donc ni
''' contrôle ni requête : ce qu'il lui faut de la page (la compagnie,
''' l'utilisateur, l'accès à la base) lui vient de l'hôte, et ce qu'il lui
''' faut de l'écran (la date d'arrêt, la fréquence des taxes) lui est posé
''' avant l'appel.
'''
''' Ce qui arrive ne va PAS en comptabilité. Deux dépôts, dans cet ordre :
'''
'''   1. staging.ConnecteurDonnee reçoit TOUT, en JSON brut, ressource par
'''      ressource. Rien n'est interprété : ce qu'Apideck a rendu est conservé
'''      tel quel. Le jour où l'écran existe, la donnée est déjà là.
'''
'''   2. Les ressources que l'application sait traiter sont en plus versées
'''      dans les tables de préparation habituelles, par les mêmes procédures
'''      que les imports par fichier. Les écrans d'import les affichent alors
'''      sans rien savoir d'Apideck, avec leurs contrôles de doublons et leur
'''      bouton de création.
''' </summary>
Public Class ApideckExtraction

#Region "Le catalogue"

    ''' <summary>Une ressource d'Apideck, et ce qu'on en fait.</summary>
    Public Class Ressource
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

        ''' <summary>Vrai quand la lecture porte sur une période : la date d'arrêt est alors demandée.</summary>
        Public Property AvecDate As Boolean

        ''' <summary>Vrai quand la fréquence des déclarations de taxes compte.</summary>
        Public Property AvecFrequence As Boolean

    End Class

    ''' <summary>
    ''' Les vingt-huit ressources que le connecteur sait rendre — vingt-six de
    ''' l'API unifiée d'Apideck, les pièces jointes qui se demandent document par
    ''' document, et les conditions de paiement qui passent par le passe-plat.
    ''' L'ordre suit
    ''' celui d'une reprise : d'abord ce qui structure, puis les documents, puis
    ''' ce qui ne sert qu'au contrôle.
    ''' </summary>
    Public Shared ReadOnly Property Catalogue As List(Of Ressource)
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
                New Ressource With {.Groupe = "Grand livre", .Cle = "general-ledger", .Libelle = "Grand livre", .Vers = "GRAND_LIVRE", .Mode = "PASSERELLE", .AvecDate = True},
                New Ressource With {.Groupe = "Contrôle", .Cle = "balance-sheet", .Libelle = "Bilan", .Unique = True, .Vers = "BILAN"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "profit-and-loss", .Libelle = "Résultats", .Unique = True, .Vers = "RESULTATS"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "aged-debtors", .Libelle = "Balance âgée clients", .Unique = True, .Vers = "AGEE_CLIENTS"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "aged-creditors", .Libelle = "Balance âgée fournisseurs", .Unique = True, .Vers = "AGEE_FOURNISSEURS"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "trial-balance", .Libelle = "Balance de vérification", .Vers = "BALANCE_VERIF", .Mode = "PASSERELLE", .AvecDate = True},
                New Ressource With {.Groupe = "Contrôle", .Cle = "tax-summary", .Libelle = "Rapport de taxes", .Vers = "RAPPORT_TAXES", .Mode = "PASSERELLE", .AvecDate = True, .AvecFrequence = True},
                New Ressource With {.Groupe = "Contrôle", .Cle = "bank-accounts", .Libelle = "Comptes et soldes bancaires", .Vers = "BANQUES", .Mode = "PASSERELLE"},
                New Ressource With {.Groupe = "Contrôle", .Cle = "uncleared", .Libelle = "Opérations non rapprochées", .Vers = "RAPPROCHEMENT", .Mode = "PASSERELLE", .AvecDate = True},
                New Ressource With {.Groupe = "Contrôle", .Cle = "das", .Libelle = "Remises de DAS", .Vers = "REMISES_DAS", .Mode = "PASSERELLE", .AvecDate = True},
                New Ressource With {.Groupe = "Contrôle", .Cle = "inventory", .Libelle = "Inventaire", .Vers = "INVENTAIRE", .Mode = "PASSERELLE", .AvecDate = True},
                New Ressource With {.Groupe = "Contrôle", .Cle = "attachments", .Libelle = "Pièces jointes", .Vers = "PIECES_JOINTES", .Mode = "PAR_DOCUMENT"}
            }
        End Get
    End Property

#End Region

#Region "L'hôte et les réglages"

    ''' <summary>
    ''' La page ou le contrôle qui appelle : c'est lui qui porte la compagnie,
    ''' l'utilisateur et la connexion à la base. Le moteur n'a rien à lui.
    ''' </summary>
    Private ReadOnly hote As clsData

    ''' <summary>
    ''' La date de bascule — la veille du premier jour tenu ici. Six ressources
    ''' la demandent (balance de vérification, grand livre, taxes, pointage,
    ''' remises, inventaire) ; les autres n'en ont que faire, et on ne va pas
    ''' imposer une date à qui rapatrie des clients.
    ''' </summary>
    Public Property DateArret As Date?

    ''' <summary>Le nombre de mois d'une déclaration de taxes : 1, 3 ou 12.</summary>
    Public Property MoisParPeriode As Integer = 3

    Public Sub New(hote As clsData)
        If hote Is Nothing Then Throw New ArgumentNullException("hote")
        Me.hote = hote
    End Sub

    ''' <summary>La ressource du catalogue qui porte cette clé, ou rien.</summary>
    Public Shared Function Trouver(cle As String) As Ressource
        Dim c As String = If(cle, "").Trim()
        Return Catalogue.FirstOrDefault(Function(r) r.Cle = c)
    End Function

    ''' <summary>
    ''' Les ressources d'une liste de clés séparées par des virgules, dans
    ''' l'ordre du catalogue. Les clés inconnues sont ignorées sans bruit.
    ''' </summary>
    Public Shared Function Choisir(cles As String) As List(Of Ressource)
        Dim voulues As New HashSet(Of String)(
            If(cles, "").Split(","c).Select(Function(c) c.Trim()).Where(Function(c) c <> ""))
        Return Catalogue.Where(Function(r) voulues.Contains(r.Cle)).ToList()
    End Function

    ''' <summary>
    ''' La date d'arrêt telle qu'un champ de saisie la rend : ISO d'abord (c'est
    ''' ce qu'un champ « date » envoie), la culture du serveur ensuite. Vide ou
    ''' illisible : rien — et la ressource qui en a besoin le dira.
    ''' </summary>
    Public Shared Function LireDate(texte As String) As Date?
        Dim t As String = If(texte, "").Trim()
        If t.Length = 0 Then Return Nothing

        Dim d As Date
        If Date.TryParse(t, Globalization.CultureInfo.InvariantCulture,
                         Globalization.DateTimeStyles.None, d) Then Return d
        If Date.TryParse(t, d) Then Return d
        Return Nothing
    End Function

    ''' <summary>La fréquence des déclarations de taxes : « 1 », « 3 » ou « 12 » mois. Trimestriel sinon.</summary>
    Public Shared Function LireFrequence(choix As String) As Integer
        Select Case If(choix, "").Trim()
            Case "1" : Return 1
            Case "12" : Return 12
            Case Else : Return 3
        End Select
    End Function


#End Region

#Region "Le compte rendu"

    ''' <summary>Ce qu'une ressource a donné.</summary>
    Public Class LigneResultat
        Public Property Ressource As Ressource
        Public Property Nb As Integer
        Public Property VersDit As String = ""
        Public Property Erreur As String = ""

        Public ReadOnly Property Reussie As Boolean
            Get
                Return Erreur = ""
            End Get
        End Property
    End Class

    ''' <summary>Ce qu'une extraction a donné, ressource par ressource.</summary>
    Public Class Resultat
        Public Property RunId As Integer
        Public Property Lignes As New List(Of LigneResultat)
        Public Property NoteTaxes As String = ""

        Public ReadOnly Property Total As Integer
            Get
                Return Lignes.Where(Function(l) l.Reussie).Sum(Function(l) l.Nb)
            End Get
        End Property

        Public ReadOnly Property Echecs As Integer
            Get
                Return Lignes.Where(Function(l) Not l.Reussie).Count()
            End Get
        End Property

        Public ReadOnly Property Demandees As Integer
            Get
                Return Lignes.Count
            End Get
        End Property

        Public ReadOnly Property Fautives As List(Of String)
            Get
                Return Lignes.Where(Function(l) Not l.Reussie).Select(Function(l) l.Ressource.Cle).ToList()
            End Get
        End Property
    End Class

#End Region

#Region "L'extraction"

    ''' <summary>
    ''' Le cœur du moteur. Une extraction, ressource par ressource :
    '''
    '''   lire chez Apideck → déposer le brut → verser dans la préparation
    '''
    ''' Une ressource qui échoue n'arrête pas les autres. C'est délibéré : sur
    ''' vingt-sept appels, un connecteur refuse presque toujours quelque chose,
    ''' et tout perdre pour une balance âgée indisponible serait absurde.
    '''
    ''' Lève si l'extraction ne peut même pas s'ouvrir — la base injoignable,
    ''' par exemple. Tout le reste est rendu dans le compte rendu.
    ''' </summary>
    Public Function Importer(choisies As IList(Of Ressource)) As Resultat
        If choisies Is Nothing OrElse choisies.Count = 0 Then
            Throw New ArgumentException("Choisissez au moins une ressource à rapatrier.")
        End If

        Dim api As New clsApideck(hote.Company.ToString())
        Dim res As New Resultat With {.RunId = OuvrirRun()}
        Dim total As Integer = 0

        For Each r As Ressource In choisies
            ' QuickBooks plafonne les appels simultanés par société et répond 403
            ' au-delà. Une courte pause entre les ressources vaut mieux que de
            ' compter sur les réessais.
            If total > 0 Then Threading.Thread.Sleep(600)

            Dim ligne As New LigneResultat With {.Ressource = r}

            Try
                Dim brut As JArray = LireRessource(api, r)
                ligne.Nb = brut.Count

                ' 1) Le dépôt brut : tout y passe, sans interprétation.
                DeposerBrut(res.RunId, r.Cle, brut)

                ' 2) La préparation habituelle, pour celles qu'on sait traiter.
                If r.Vers <> "" AndAlso ligne.Nb > 0 Then
                    ligne.VersDit = Verser(r, brut, res.RunId)
                End If

                total += ligne.Nb

            Catch ex As Exception
                ligne.Erreur = ex.Message
            End Try

            res.Lignes.Add(ligne)
        Next

        res.NoteTaxes = RepartirTaxes()

        FermerRun(res.RunId, If(res.Echecs = 0, "TERMINE", "PARTIEL"),
                  If(res.Echecs = 0, Nothing,
                     res.Echecs & " ressource(s) en échec sur " & choisies.Count & " : " &
                     String.Join(", ", res.Fautives) & "."))

        Return res
    End Function

    ''' <summary>
    ''' Une liste complète, l'objet unique d'un rapport — ou l'une des deux
    ''' lectures particulières, qui ne passent pas par une adresse de liste.
    ''' </summary>
    Private Function LireRessource(api As clsApideck, r As Ressource) As JArray
        Select Case r.Mode
            Case "PAR_DOCUMENT" : Return LirePiecesJointes(api)
            Case "PASSERELLE"
                ' Huit ressources passent par le langage natif de QuickBooks.
                If r.Vers = "BALANCE_VERIF" Then Return LireBalanceVerification(api)
                If r.Vers = "GRAND_LIVRE" Then Return LireGrandLivre(api)
                If r.Vers = "RAPPORT_TAXES" Then Return LireRapportTaxes(api)
                If r.Vers = "BANQUES" Then Return LireComptesBancaires(api)
                If r.Vers = "RAPPROCHEMENT" Then Return LireOperationsRapprochement(api)
                If r.Vers = "REMISES_DAS" Then Return LireRemisesDas(api)
                If r.Vers = "INVENTAIRE" Then Return LireInventaire(api)
                Return LireConditionsPaiement(api)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Ressource", ressource))
        p.Add(New SqlParameter("@Lignes", paquet.ToString(Formatting.None)))
        hote.ExecuteSQLds("s0777ChargerConnecteurDonnees", p)
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
            Case "BALANCE_VERIF" : Return VerserBalanceVerification(brut, runId)
            Case "GRAND_LIVRE" : Return VerserGrandLivre(brut, runId)
            Case "RAPPORT_TAXES" : Return VerserRapportTaxes(brut, runId)
            Case "BANQUES" : Return VerserComptesBancaires(brut, runId)
            Case "RAPPROCHEMENT" : Return VerserOperationsRapprochement(brut, runId)
            Case "REMISES_DAS" : Return VerserRemisesDas(brut, runId)
            Case "INVENTAIRE" : Return VerserInventaire(brut, runId)
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
        ' Le plan comptable s'inscrit au registre comme les autres listes :
        ' ImportFiles porte la réponse brute d'Apideck, et les lignes pointent
        ' dessus. Il n'y a plus de lot à ouvrir — s0752 fait tout en un appel,
        ' et remplace le plan comptable précédent de la compagnie.
        Dim fichierId As Integer = InscrireAuRegistre("PlanComptable", "plan comptable", brut)

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
            ' plan comptable — l'import était ouvert, aucune ligne dedans.
            Dim solde As Object = Nombre(Valeur(c, "current_balance", "balance"))
            If solde IsNot Nothing Then o("Solde") = CDec(solde)
            lignes.Add(o)
        Next

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@SystemeSource", "APIDECK"))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0752ChargerPlanComptableStaging", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return "versé au plan comptable"
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "versé au plan comptable : " & Lire(r, "NbLignesRetenues") & " compte(s)"
        If Lire(r, "NbAnomalies") > 0 Then texte &= ", " & Lire(r, "NbAnomalies") & " à corriger"
        Return texte
    End Function

    ''' <summary>
    ''' Clients et fournisseurs empruntent le chemin de l'import par fichier :
    ''' un « fichier » est créé pour porter la réponse d'Apideck, son JSON est
    ''' posé comme résultat, et s0604 l'éclate vers staging.PartyImport. L'écran
    ''' Clients ou Fournisseurs le voit alors comme n'importe quel import.
    ''' </summary>
    ''' <summary>
    ''' Un tiers, en entier. Les douze premières clés sont celles que l'import
    ''' par fichier connaît déjà ; les autres n'existent que par Apideck, et
    ''' s0604 les lit quand elles y sont (script T256).
    '''
    ''' Deux adresses : la facturation, celle qu'on retient, et la livraison à
    ''' part. Trois téléphones : principal, mobile, fax — et le premier des
    ''' autres. Ce qui n'a pas de colonne (banques, champs personnalisés, taxes
    ''' multiples, contacts en surnombre) part tel quel dans « extra ».
    ''' </summary>
    Private Function VerserParties(brut As JArray, typeImport As String, genre As String) As String
        Dim lignes As New JArray()

        For Each t As JToken In brut
            Dim adr As JToken = AdresseDe(t, "billing")
            Dim liv As JToken = AdresseDe(t, "shipping")

            Dim o As New JObject()
            ' — ce que l'import par fichier connaît déjà —
            o("name") = Valeur(t, "company_name", "display_name", "name")
            o("contact_name") = Valeur(t, "display_name", "first_name")
            o("address1") = Valeur(adr, "line1", "street_name")
            o("address2") = Valeur(adr, "line2")
            o("city") = Valeur(adr, "city")
            o("province") = Valeur(adr, "state", "region")
            o("postal_code") = Valeur(adr, "postal_code", "zip_code")
            o("phone") = Telephone(t, "primary", "work", "office", "home", "billing")
            o("email") = Valeur(CourrielDe(t), "email")
            o("tps") = Valeur(t, "tax_number")
            o("tvq") = ""
            o("balance") = Valeur(t, "balance")

            ' — l'identité —
            o("source_id") = Valeur(t, "id")
            o("display_name") = Valeur(t, "display_name")
            o("company_name") = Valeur(t, "company_name")
            o("title") = Valeur(t, "title")
            o("first_name") = Valeur(t, "first_name")
            o("middle_name") = Valeur(t, "middle_name")
            o("last_name") = Valeur(t, "last_name")
            o("suffix") = Valeur(t, "suffix")
            o("individual") = Valeur(t, "individual")
            o("is_project") = Valeur(t, "project")
            o("category") = Valeur(t, "customer_category", "supplier_category")

            ' — l'adresse, au complet, et la livraison —
            o("address3") = Lignes3a5(adr)
            o("country") = Valeur(adr, "country")
            o("ship_attention") = Valeur(liv, "contact_name", "name")
            o("ship_address1") = Valeur(liv, "line1", "street_name")
            o("ship_address2") = String.Join(", ", New String() {Valeur(liv, "line2"), Lignes3a5(liv)}.Where(Function(x) x <> ""))
            o("ship_city") = Valeur(liv, "city")
            o("ship_province") = Valeur(liv, "state", "region")
            o("ship_postal_code") = Valeur(liv, "postal_code", "zip_code")
            o("ship_country") = Valeur(liv, "country")

            ' — les autres moyens de joindre —
            o("mobile") = Telephone(t, "mobile")
            o("fax") = Telephone(t, "fax")
            o("alt_phone") = AutreTelephone(t)
            o("website") = Valeur(Premier(t, "websites"), "url")

            ' — le commercial et le fiscal —
            o("taxable") = Valeur(t, "taxable")
            o("tax_rate_name") = Valeur(t, "tax_rate.name")
            o("tax_rate_code") = Valeur(t, "tax_rate.code")
            o("tax_rate") = Valeur(t, "tax_rate.rate")
            o("currency") = Valeur(t, "currency")
            o("terms") = Valeur(t, "terms")
            o("payment_method") = Valeur(t, "payment_method")
            o("parent_name") = Valeur(t, "parent.name")
            o("account_name") = Valeur(t, "account.name", "account.nominal_code")
            o("note") = Valeur(t, "notes")

            ' — la source —
            o("source_status") = Valeur(t, "status")
            o("source_created") = Valeur(t, "created_at")
            o("source_updated") = Valeur(t, "updated_at")
            o("extra") = Reste(t, "bank_accounts", "custom_fields", "tax_details", "tax_status_details",
                               "phone_numbers", "emails", "websites", "addresses")
            lignes.Add(o)
        Next

        Return Livrer(typeImport, genre, lignes)
    End Function

    ''' <summary>L'adresse d'un type ; à défaut, pour la facturation, la première venue.</summary>
    Private Shared Function AdresseDe(t As JToken, type As String) As JToken
        Dim liste As JArray = TryCast(If(t Is Nothing, Nothing, t("addresses")), JArray)
        If liste Is Nothing OrElse liste.Count = 0 Then Return Nothing

        For Each a As JToken In liste
            If String.Equals(Valeur(a, "type"), type, StringComparison.OrdinalIgnoreCase) Then
                ' Une adresse de livraison vide n'en est pas une.
                If type = "shipping" AndAlso Valeur(a, "line1", "city", "postal_code", "string") = "" Then Return Nothing
                Return a
            End If
        Next

        ' Pas de « billing » explicite : on prend la première qui n'est pas une livraison.
        If type = "billing" Then
            For Each a As JToken In liste
                If Not String.Equals(Valeur(a, "type"), "shipping", StringComparison.OrdinalIgnoreCase) Then Return a
            Next
        End If
        Return Nothing
    End Function

    ''' <summary>Les lignes 3, 4 et 5 d'une adresse, réunies — rares, mais QuickBooks les rend.</summary>
    Private Shared Function Lignes3a5(adr As JToken) As String
        Return String.Join(", ", New String() {Valeur(adr, "line3"), Valeur(adr, "line4"), Valeur(adr, "line5")}.
                           Where(Function(x) x <> ""))
    End Function

    ''' <summary>Le premier numéro dont le type est l'un de ceux demandés, dans cet ordre de préférence.</summary>
    Private Shared Function Telephone(t As JToken, ParamArray types As String()) As String
        Dim liste As JArray = TryCast(If(t Is Nothing, Nothing, t("phone_numbers")), JArray)
        If liste Is Nothing Then Return ""

        For Each type As String In types
            For Each p As JToken In liste
                If String.Equals(Valeur(p, "type"), type, StringComparison.OrdinalIgnoreCase) Then
                    Dim n As String = Valeur(p, "number")
                    Dim ext As String = Valeur(p, "extension")
                    Return If(ext = "", n, n & " poste " & ext)
                End If
            Next
        Next
        Return ""
    End Function

    ''' <summary>Le premier numéro qui n'est ni principal, ni mobile, ni fax — l'« autre » de la fiche.</summary>
    Private Shared Function AutreTelephone(t As JToken) As String
        Dim liste As JArray = TryCast(If(t Is Nothing, Nothing, t("phone_numbers")), JArray)
        If liste Is Nothing Then Return ""

        Dim pris As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase) From
            {"primary", "work", "office", "home", "billing", "mobile", "fax"}
        For Each p As JToken In liste
            If Not pris.Contains(Valeur(p, "type")) Then Return Valeur(p, "number")
        Next
        Return ""
    End Function

    ''' <summary>Le courriel principal ; à défaut, le premier.</summary>
    Private Shared Function CourrielDe(t As JToken) As JToken
        Dim liste As JArray = TryCast(If(t Is Nothing, Nothing, t("emails")), JArray)
        If liste Is Nothing OrElse liste.Count = 0 Then Return Nothing

        For Each e As JToken In liste
            If String.Equals(Valeur(e, "type"), "primary", StringComparison.OrdinalIgnoreCase) Then Return e
        Next
        Return liste(0)
    End Function

    ''' <summary>
    ''' Ce qui n'a pas de colonne, réuni en un seul objet JSON — ou rien du tout
    ''' quand la source n'a rien donné, pour ne pas remplir la table de « {} ».
    ''' </summary>
    Private Shared Function Reste(t As JToken, ParamArray noms As String()) As JToken
        Dim o As New JObject()
        For Each nom As String In noms
            Dim v As JToken = If(t Is Nothing, Nothing, t(nom))
            If v Is Nothing OrElse v.Type = JTokenType.Null Then Continue For
            If TypeOf v Is JArray AndAlso CType(v, JArray).Count = 0 Then Continue For
            If TypeOf v Is JObject AndAlso Not CType(v, JObject).HasValues Then Continue For
            o(nom) = v
        Next
        Return If(o.HasValues, o, Nothing)
    End Function

    ''' <summary>
    ''' Un article, en entier. Les quatre premières clés sont celles de l'import
    ''' par fichier ; les autres — type, coût, unités, taxes de vente et
    ''' d'achat, comptes de la source, quantité en main — n'existent que par
    ''' Apideck (script T256). Les comptes de la source restent des NOMS : la
    ''' correspondance avec le plan d'ici est un autre travail.
    ''' </summary>
    Private Function VerserProduits(brut As JArray) As String
        Dim lignes As New JArray()

        For Each a As JToken In brut
            Dim o As New JObject()
            ' — ce que l'import par fichier connaît déjà —
            o("name") = Valeur(a, "name", "code")
            o("description") = Valeur(a, "description", "sales_details.description")
            o("price") = Valeur(a, "unit_price", "sales_details.unit_price")
            o("taxable") = Valeur(a, "taxable")

            ' — l'article lui-même —
            o("source_id") = Valeur(a, "id")
            o("code") = Valeur(a, "code", "display_id")
            o("item_type") = Valeur(a, "type")
            o("active") = Valeur(a, "active")
            o("sold") = Valeur(a, "sold")
            o("purchased") = Valeur(a, "purchased")
            o("tracked") = Valeur(a, "tracked")
            o("category") = Valeur(a, "tracking_category.name", "category_id")
            o("parent_name") = Valeur(a, "parent.name")
            o("currency") = Valeur(a, "currency")

            ' — la vente et l'achat —
            o("unit") = Valeur(a, "sales_details.unit_of_measure")
            o("sales_tax_inclusive") = Valeur(a, "sales_details.tax_inclusive")
            o("sales_tax_rate_name") = Valeur(a, "sales_details.tax_rate.name")
            o("sales_tax_rate") = Valeur(a, "sales_details.tax_rate.rate")
            o("purchase_price") = Valeur(a, "purchase_details.unit_price")
            o("purchase_unit") = Valeur(a, "purchase_details.unit_of_measure")
            o("purchase_tax_inclusive") = Valeur(a, "purchase_details.tax_inclusive")
            o("purchase_tax_rate_name") = Valeur(a, "purchase_details.tax_rate.name")
            o("purchase_tax_rate") = Valeur(a, "purchase_details.tax_rate.rate")

            ' — les comptes de la source, et le stock —
            o("income_account_name") = Valeur(a, "income_account.name")
            o("income_account_code") = Valeur(a, "income_account.nominal_code", "income_account.code")
            o("expense_account_name") = Valeur(a, "expense_account.name")
            o("expense_account_code") = Valeur(a, "expense_account.nominal_code", "expense_account.code")
            o("asset_account_name") = Valeur(a, "asset_account.name")
            o("asset_account_code") = Valeur(a, "asset_account.nominal_code", "asset_account.code")
            o("quantity") = Valeur(a, "quantity")
            o("inventory_date") = Valeur(a, "inventory_date")

            ' — la source —
            o("source_created") = Valeur(a, "created_at")
            o("source_updated") = Valeur(a, "updated_at")
            o("extra") = Reste(a, "tracking_categories", "custom_fields", "department_id", "location_id",
                               "subsidiary_id", "tax_schedule_id")
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
            ' QuickBooks ne remplit pas « status » à travers Apideck : on déduit
            ' l'état des montants. Sans lui, rien ne distinguerait une facture
            ' payée d'une facture due, et les deux se créeraient pareillement.
            Dim etat As String = Valeur(d, "status")
            If etat = "" Then etat = EtatDocument(Valeur(d, "total"), Valeur(d, "balance"))
            o("statut") = etat

            Dim lignes As New JArray()
            Dim lot As JArray = TryCast(d("line_items"), JArray)
            Dim no As Integer = 0

            If lot IsNot Nothing Then
                For Each l As JToken In lot
                    If LigneDeRecapitulation(l) Then Continue For
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@DocumentTypeId", CObj(typeDocument)))
        p.Add(New SqlParameter("@Documents", docs.ToString(Formatting.None)))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0781ChargerDocumentsImport", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Champs", champs.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0788ChargerSocieteImport", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))

        Dim ds As DataSet = hote.ExecuteSQLds("s0815GetSourcesPiecesJointes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Function VerserPiecesJointes(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucune pièce jointe"

        Dim fichierId As Integer = InscrireAuRegistre("PieceJointe", "pièces jointes", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Pieces", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0814ChargerPiecesJointes", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Conditions", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0817ChargerConditionsPaiement", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Genre", genre))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Pieces", pieces.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0804ChargerPiecesCommerciales", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Sens", sens))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Paiements", paiements.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0806ChargerPaiementsImport", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Ecritures", ecritures.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0808ChargerEcrituresImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = "en préparation : " & Lire(r, "NbEquilibrees") & " équilibrée(s)"
        If Lire(r, "NbDesequilibrees") > 0 Then texte &= ", " & Lire(r, "NbDesequilibrees") & " déséquilibrée(s)"
        If Lire(r, "NbInvalides") > 0 Then texte &= ", " & Lire(r, "NbInvalides") & " sans ligne"
        Return texte
    End Function


    ''' <summary>
    ''' Une ligne de récapitulation, pas une ligne de contenu.
    '''
    ''' Apideck rend le sous-total de la pièce COMME UNE LIGNE, à côté des vraies :
    ''' la facture 1002 de 123 $ arrive avec une ligne « sales_item » de 123 $ et
    ''' une ligne « sub_total » de 123 $. Reprises toutes les deux, les lignes
    ''' totalisent le double de la pièce — et plus rien ne boucle. C'est la
    ''' répartition des taxes qui l'a fait ressortir : elle compare la somme des
    ''' lignes au total de l'entête, et les trois pièces en préparation étaient
    ''' déclarées déséquilibrées sans qu'une taxe soit en cause.
    '''
    ''' On écarte donc les types qui répètent ce que l'entête porte déjà. Tout le
    ''' reste passe — un rabais ou une ligne de description sont du contenu, même
    ''' quand ils ne ressemblent pas à un article.
    ''' </summary>
    Private Shared Function LigneDeRecapitulation(l As JToken) As Boolean
        Dim genre As String = Valeur(l, "type").Trim().ToLowerInvariant()
        Return genre = "sub_total" OrElse genre = "subtotal" OrElse genre = "total"
    End Function

    ''' <summary>Les lignes d'articles, forme partagée par les pièces commerciales.</summary>
    Private Shared Function LignesArticles(d As JToken) As JArray
        Dim lignes As New JArray()
        Dim lot As JArray = TryCast(d("line_items"), JArray)
        If lot Is Nothing Then Return lignes

        Dim no As Integer = 0
        For Each l As JToken In lot
            If LigneDeRecapitulation(l) Then Continue For
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
        ' Même raison que pour la balance âgée : le bilan et l'état des résultats
        ' ne doivent pas se remplacer l'un l'autre au registre.
        Dim fichierId As Integer = InscrireAuRegistre("Rapport" & genre, libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Genre", genre))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Entete", entete.ToString(Formatting.None)))
        p.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0810ChargerRapportImport", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Return "en préparation : " & Lire(ds.Tables(0).Rows(0), "NbLignes") & " poste(s)"
    End Function


    ''' <summary>
    ''' La balance de vérification, par la passerelle.
    '''
    ''' Apideck ne traduit pas ce rapport dans son API unifiée — l'adresse
    ''' /accounting/trial-balance n'existe pas. On demande donc à Apideck de
    ''' poser la question à QuickBooks dans son propre langage et de rendre la
    ''' réponse telle quelle. C'est Apideck qui appelle Intuit, jamais nous.
    '''
    ''' LES DEUX DATES SONT OBLIGATOIRES : essayé, QuickBooks ignore purement et
    ''' simplement une end_date seule et retourne « ce mois-ci à ce jour ». La
    ''' période va donc du 1er janvier de l'année choisie à la date d'arrêt.
    ''' </summary>
    Private Function LireBalanceVerification(api As clsApideck) As JArray
        Dim arrete As Date? = DateArret
        If Not arrete.HasValue Then
            Throw New Exception("Indiquez la date à laquelle la balance de vérification est arrêtée.")
        End If

        Dim fin As String = arrete.Value.ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)
        Dim debut As String = New Date(arrete.Value.Year, 1, 1).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)

        Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & api.RealmId() &
                            "/reports/TrialBalance?start_date=" & debut &
                            "&end_date=" & fin & "&minorversion=70"

        Dim rapport As JObject = api.Proxy(url)
        Dim liste As New JArray()
        If rapport Is Nothing Then Return liste

        ' Le rapport se lit en trois colonnes : le compte, son débit, son crédit.
        ' La ligne de total porte « Summary » plutôt que « ColData » : elle est
        ' un résultat, pas un compte, et n'a rien à faire dans la préparation.
        Dim rangs As JArray = TryCast(rapport.SelectToken("Rows.Row"), JArray)
        If rangs Is Nothing Then Return liste

        Dim rang As Integer = 0
        AjouterComptesBalance(rangs, liste, rang)

        ' L'entête voyage avec les lignes : la période que QuickBooks a
        ' réellement retenue vaut mieux que celle qu'on croit avoir demandée.
        If liste.Count > 0 Then
            Dim e As New JObject()
            e("entete") = "1"
            e("debut") = Valeur(rapport.SelectToken("Header"), "StartPeriod")
            e("fin") = Valeur(rapport.SelectToken("Header"), "EndPeriod")
            e("devise") = Valeur(rapport.SelectToken("Header"), "Currency")
            liste.Add(e)
        End If

        Return liste
    End Function

    ''' <summary>
    ''' Parcourt les lignes du rapport et retient les comptes.
    '''
    ''' QuickBooks peut grouper : une ligne porte alors ses propres lignes au
    ''' lieu de colonnes. On descend dedans plutôt que de l'ignorer — un compte
    ''' rangé dans une section n'est pas un compte de moins.
    '''
    ''' La ligne de total porte « Summary » et non « ColData » : c'est un
    ''' résultat, pas un compte, et elle n'entre pas dans la préparation.
    ''' </summary>
    Private Shared Sub AjouterComptesBalance(rangs As JArray, liste As JArray, ByRef rang As Integer)
        If rangs Is Nothing Then Return

        For Each ligne As JToken In rangs
            Dim filles As JArray = TryCast(ligne.SelectToken("Rows.Row"), JArray)
            If filles IsNot Nothing Then AjouterComptesBalance(filles, liste, rang)

            Dim cells As JArray = TryCast(ligne("ColData"), JArray)
            If cells Is Nothing OrElse cells.Count < 3 Then Continue For

            Dim nom As String = Valeur(cells(0), "value").Trim()
            If nom.Length = 0 Then Continue For

            rang += 1
            Dim o As New JObject()
            o("rang") = rang
            o("nom") = nom
            o("externe_id") = Valeur(cells(0), "id")
            o("debit") = Valeur(cells(1), "value")
            o("credit") = Valeur(cells(2), "value")
            liste.Add(o)
        Next
    End Sub

    ''' <summary>
    ''' Le grand livre, par la passerelle.
    '''
    ''' Apideck ne l'expose pas — /accounting/general-ledger-transactions répond
    ''' 404 pour QuickBooks. On demande donc le rapport natif, et Apideck le
    ''' relaie tel quel.
    '''
    ''' LES COLONNES SONT DEMANDÉES EXPLICITEMENT. Sans « columns », QuickBooks
    ''' rend un montant et un solde cumulé sous les entêtes « Débit » et
    ''' « Crédit » : essayé, la deuxième colonne valait 123,00 puis 346,00 pour
    ''' deux factures de 123 et 223. Prendre ce cumul pour un crédit aurait
    ''' produit un grand livre faux et vraisemblable.
    '''
    ''' La période est celle du champ de date de l'écran, comme la balance de
    ''' vérification : du 1er janvier de l'année à la date choisie.
    ''' </summary>
    Private Function LireGrandLivre(api As clsApideck) As JArray
        Dim arrete As Date? = DateArret
        If Not arrete.HasValue Then
            Throw New Exception("Indiquez la date d'arrêt : le grand livre est lu sur une période.")
        End If

        Dim fin As String = arrete.Value.ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)
        Dim debut As String = New Date(arrete.Value.Year, 1, 1).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)

        Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & api.RealmId() &
                            "/reports/GeneralLedger?start_date=" & debut & "&end_date=" & fin &
                            "&columns=tx_date,txn_type,doc_num,name,memo,split_acc,debt_amt,credit_amt" &
                            "&minorversion=70"

        Dim rapport As JObject = api.Proxy(url)
        Dim liste As New JArray()
        If rapport Is Nothing Then Return liste

        Dim entete As JToken = rapport.SelectToken("Header")
        Dim debutReel As String = Valeur(entete, "StartPeriod")
        Dim finReelle As String = Valeur(entete, "EndPeriod")
        Dim devise As String = Valeur(entete, "Currency")

        Dim sections As JArray = TryCast(rapport.SelectToken("Rows.Row"), JArray)
        If sections Is Nothing Then Return liste

        Dim ordreCompte As Integer = 0
        For Each section As JToken In sections
            ' Chaque section est un compte ; son entête en porte le nom.
            Dim compte As String = Valeur(section.SelectToken("Header.ColData[0]"), "value")
            If compte = "" Then compte = Valeur(section.SelectToken("Summary.ColData[0]"), "value")

            Dim operations As JArray = TryCast(section.SelectToken("Rows.Row"), JArray)
            If operations Is Nothing Then Continue For

            ordreCompte += 1
            Dim ordreLigne As Integer = 0

            For Each op As JToken In operations
                Dim c As JArray = TryCast(op("ColData"), JArray)
                If c Is Nothing OrElse c.Count < 8 Then Continue For

                ordreLigne += 1
                Dim o As New JObject()
                o("debut") = debutReel
                o("fin") = finReelle
                o("devise") = devise
                o("compte_ordre") = ordreCompte
                o("compte") = compte
                o("ligne_ordre") = ordreLigne
                o("date") = Valeur(c(0), "value")
                o("type") = Valeur(c(1), "value")
                o("numero") = Valeur(c(2), "value")
                o("tiers") = Valeur(c(3), "value")
                o("memo") = Valeur(c(4), "value")
                o("contrepartie") = Valeur(c(5), "value")
                o("debit") = Valeur(c(6), "value")
                o("credit") = Valeur(c(7), "value")
                liste.Add(o)
            Next
        Next

        Return liste
    End Function

    ''' <summary>
    ''' Dépose le grand livre en préparation. Rien ne s'applique à la
    ''' comptabilité : c'est une pièce de contrôle, comme la balance de
    ''' vérification — on la confronte, on ne la reprend pas.
    ''' </summary>
    Private Function VerserGrandLivre(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucune écriture"

        Dim fichierId As Integer = InscrireAuRegistre("GrandLivre", "grand livre", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Lignes", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0820ChargerGrandLivre", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Return Lire(r, "NbLignes") & " écriture(s) sur " & Lire(r, "NbComptes") & " compte(s)"
    End Function

    ''' <summary>
    ''' Dépose la balance dans staging.BalanceVerification — la table de l'écran
    ''' dédié, pas celle des rapports. Tout ce qui existe déjà s'y applique :
    ''' l'équilibre, les totaux, et le contrôle contre le plan comptable.
    '''
    ''' QuickBooks ne donne PAS le numéro de compte dans ce rapport, seulement
    ''' son nom et son identifiant interne. La colonne Compte reste donc vide et
    ''' le rapprochement se fera par le nom — ce que s0771 sait faire. Un compte
    ''' renommé entre deux extractions ressortira comme absent.
    ''' </summary>
    Private Function VerserBalanceVerification(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then Return "aucune ligne"

        Dim lignes As New JArray()
        Dim periode As String = ""

        For Each t As JToken In brut
            If Valeur(t, "entete") <> "" Then
                periode = Valeur(t, "debut") & " au " & Valeur(t, "fin")
                Continue For
            End If

            Dim o As New JObject()
            o("Description") = Valeur(t, "nom")

            ' Option Strict est à Off : affecter l'Object rendu par Nombre() à un
            ' champ JSON compile, mais lève à l'exécution. On passe par CDec.
            Dim d As Object = Nombre(Valeur(t, "debit"))
            Dim c As Object = Nombre(Valeur(t, "credit"))
            o("Debit") = If(d Is Nothing, 0D, CDec(d))
            o("Credit") = If(c Is Nothing, 0D, CDec(c))
            lignes.Add(o)
        Next

        If lignes.Count = 0 Then Return "aucun compte"

        Dim nom As String = "QuickBooks — balance de vérification (Apideck)"
        If periode <> "" Then nom &= " — " & periode

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))
        p.Add(New SqlParameter("@Vider", True))        ' une balance à la fois, la nouvelle remplace
        p.Add(New SqlParameter("@NomFichier", nom))
        p.Add(New SqlParameter("@Source", "APIDECK"))
        hote.ExecuteSQLds("s0768ImporterBalanceVerification", p)

        InscrireAuRegistre("BalanceVerification", "balance de vérification", brut)

        Return lignes.Count & " compte(s) — écran « Balance de vérification »"
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

        ' Le type porte le genre : clients et fournisseurs sont deux extractions
        ' distinctes. Un type commun les ferait s'effacer l'une l'autre, puisque
        ' s0819 remplace la précédente extraction DU MÊME TYPE.
        Dim typeImport As String = "BalanceAgee" & genre
        Dim libelle As String = If(genre = "Client", "balance âgée clients", "balance âgée fournisseurs")
        Dim fichierId As Integer = InscrireAuRegistre(typeImport, libelle, brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Genre", genre))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Lignes", lignes.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0812ChargerBalanceAgee", p)
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Elements", liste.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds(procedure, p)
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
    ''' L'inventaire, par la passerelle.
    '''
    ''' Apideck rend bien les articles, mais pas leurs QUANTITÉS : ni QtyOnHand,
    ''' ni le compte d'actif de stock. Or c'est tout l'objet d'une reprise
    ''' d'inventaire. On passe donc par l'entité Item native.
    '''
    ''' LE RAPPORT NE SERT À RIEN ICI. InventoryValuationSummary répond, mais ne
    ''' rend que deux colonnes — dont une « Calcul Moyenne » — et rien que
    ''' l'article ne porte déjà. Autant lire la source directement.
    '''
    ''' PAGINÉ, ET FILTRÉ ICI. QuickBooks rend cent articles par défaut et
    ''' s'arrête sans le dire : cette compagnie en a 214, et sans pagination on
    ''' en perdrait 114. Le tri sur le type se fait en VB plutôt que par une
    ''' clause WHERE — elle voyagerait encodée dans une URL relayée par un
    ''' tiers, et une apostrophe mal passée rendrait une liste vide qui
    ''' ressemble à une absence de stock.
    '''
    ''' LA VALEUR N'EST PAS LUE, ELLE EST CALCULÉE — quantité × coût — parce que
    ''' la source ne la rend pas sur l'article. Les deux facteurs sont déposés à
    ''' côté du produit pour qu'on puisse refaire la multiplication.
    ''' </summary>
    Private Function LireInventaire(api As clsApideck) As JArray
        Dim realm As String = api.RealmId()
        Dim liste As New JArray()
        Dim rang As Integer = 0

        ' La date d'arrêt est facultative ici : QuickBooks rend la quantité
        ' D'AUJOURD'HUI, pas celle d'une date passée. On note donc la date
        ' demandée quand il y en a une, et celle du jour sinon — pour que
        ' personne ne prenne ce stock pour celui de la bascule.
        Dim arrete As Date? = DateArret
        Dim quand As String = If(arrete.HasValue, arrete.Value, Date.Today).ToString(
            "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)

        For Each a As JToken In ArticlesDeLaSource(api, realm)
            If Valeur(a, "Type") <> "Inventory" Then Continue For

            rang += 1
            Dim o As New JObject()
            o("arrete") = quand
            o("devise") = ""
            o("rang") = rang
            o("externe_id") = Valeur(a, "Id")
            o("sku") = Valeur(a, "Sku")
            o("nom") = Valeur(a, "Name")
            o("nom_complet") = Valeur(a, "FullyQualifiedName")
            o("description") = Valeur(a, "Description")
            o("compte_actif") = Valeur(a, "AssetAccountRef.name")
            o("compte_revenu") = Valeur(a, "IncomeAccountRef.name")
            o("compte_cout") = Valeur(a, "ExpenseAccountRef.name")
            o("qte") = Valeur(a, "QtyOnHand")
            o("cout") = Valeur(a, "PurchaseCost")
            o("prix") = Valeur(a, "UnitPrice")
            o("point_commande") = Valeur(a, "ReorderPoint")
            o("debut_suivi") = Valeur(a, "InvStartDate")
            o("actif") = Valeur(a, "Active")
            liste.Add(o)
        Next

        Return liste
    End Function

    ''' <summary>
    ''' Tous les articles de la source, page par page. Même boucle que pour les
    ''' comptes, et pour la même raison : une page courte est le seul signal que
    ''' QuickBooks donne pour dire qu'il a fini.
    ''' </summary>
    Private Shared Function ArticlesDeLaSource(api As clsApideck, realm As String) As JArray
        Const TAILLE_PAGE As Integer = 100
        Const PLAFOND As Integer = 200

        Dim tous As New JArray()
        Dim depart As Integer = 1

        For tour As Integer = 1 To PLAFOND
            Dim requete As String = Uri.EscapeDataString(
                "select * from Item startposition " & depart & " maxresults " & TAILLE_PAGE)
            Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & realm &
                                "/query?query=" & requete & "&minorversion=75"

            Dim r As JObject = api.Proxy(url)
            If r Is Nothing Then Exit For

            Dim page As JArray = TryCast(r.SelectToken("QueryResponse.Item"), JArray)
            If page Is Nothing OrElse page.Count = 0 Then Exit For

            For Each a As JToken In page
                tous.Add(a)
            Next

            If page.Count < TAILLE_PAGE Then Exit For
            depart += TAILLE_PAGE
        Next

        Return tous
    End Function

    ''' <summary>
    ''' Dépose l'inventaire en préparation. Aucun article n'est créé, aucune
    ''' écriture de stock n'est passée : c'est une pièce de contrôle, et son
    ''' intérêt est le rapprochement avec le compte d'actif de stock que
    ''' l'écran affiche.
    ''' </summary>
    Private Function VerserInventaire(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then
            Return "aucun article d'inventaire — la source n'en tient pas"
        End If

        Dim fichierId As Integer = InscrireAuRegistre("Inventaire", "inventaire", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Articles", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0833ChargerInventaire", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = Lire(r, "NbArticles") & " article(s)"
        If Lire(r, "NbAnomalies") > 0 Then texte &= ", " & Lire(r, "NbAnomalies") & " à vérifier"
        Return texte
    End Function

    ''' <summary>
    ''' Les remises de DAS, par la passerelle — et par la comptabilité, faute
    ''' de mieux.
    '''
    ''' CE QUI NE MARCHE PAS, ET POURQUOI. La paie de QuickBooks est un produit
    ''' séparé : l'API HRIS d'Apideck répond 401, et le compte n'a qu'une seule
    ''' connexion — « accounting / quickbooks ». Les remises ne sont donc pas
    ''' récupérables comme objets de paie.
    '''
    ''' CE QUI MARCHE. Une remise de DAS est un paiement au Receveur général ou
    ''' à Revenu Québec qui DÉBITE un compte de passif de retenues. Ce mouvement
    ''' est dans le grand livre, et le grand livre passe par la passerelle. On
    ''' lit donc le rapport GeneralLedger et on ne garde que les sections dont
    ''' le compte est un compte de DAS.
    '''
    ''' LE CRÉDIT ACCUMULE, LE DÉBIT ÉTEINT. Sur un compte de passif, chaque
    ''' paie crédite la retenue et chaque remise la débite. La différence est ce
    ''' qui reste dû — et c'est le seul chiffre que la bascule doit reprendre.
    '''
    ''' LES COLONNES SONT DEMANDÉES EXPLICITEMENT, comme pour le grand livre :
    ''' sans « columns », QuickBooks rend un solde cumulé sous l'entête
    ''' « Crédit », et le reste dû serait faux d'autant.
    ''' </summary>
    Private Function LireRemisesDas(api As clsApideck) As JArray
        Dim arrete As Date? = DateArret
        If Not arrete.HasValue Then
            Throw New Exception("Indiquez la date d'arrêt : les remises se lisent sur une période.")
        End If

        Dim fin As String = arrete.Value.ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)
        Dim debut As String = New Date(arrete.Value.Year, 1, 1).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)

        Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & api.RealmId() &
                            "/reports/GeneralLedger?start_date=" & debut & "&end_date=" & fin &
                            "&columns=tx_date,txn_type,doc_num,name,memo,split_acc,debt_amt,credit_amt" &
                            "&minorversion=70"

        Dim rapport As JObject = api.Proxy(url)
        Dim liste As New JArray()
        If rapport Is Nothing Then Return liste

        Dim entete As JToken = rapport.SelectToken("Header")
        Dim debutReel As String = Valeur(entete, "StartPeriod")
        Dim finReelle As String = Valeur(entete, "EndPeriod")
        Dim devise As String = Valeur(entete, "Currency")

        Dim sections As JArray = TryCast(rapport.SelectToken("Rows.Row"), JArray)
        If sections Is Nothing Then Return liste

        Dim rang As Integer = 0
        For Each section As JToken In sections
            Dim compte As String = Valeur(section.SelectToken("Header.ColData[0]"), "value")
            If compte = "" Then compte = Valeur(section.SelectToken("Summary.ColData[0]"), "value")

            Dim autorite As String = AutoriteDuCompte(compte)
            If autorite Is Nothing Then Continue For

            Dim operations As JArray = TryCast(section.SelectToken("Rows.Row"), JArray)
            If operations Is Nothing Then Continue For

            For Each op As JToken In operations
                Dim c As JArray = TryCast(op("ColData"), JArray)
                If c Is Nothing OrElse c.Count < 8 Then Continue For

                rang += 1
                Dim o As New JObject()
                o("debut") = debutReel
                o("fin") = finReelle
                o("devise") = devise
                o("rang") = rang
                o("autorite") = autorite
                o("compte") = compte
                o("date") = Valeur(c(0), "value")
                o("type") = Valeur(c(1), "value")
                o("numero") = Valeur(c(2), "value")
                o("tiers") = Valeur(c(3), "value")
                o("memo") = Valeur(c(4), "value")
                o("debit") = Valeur(c(6), "value")
                o("credit") = Valeur(c(7), "value")
                liste.Add(o)
            Next
        Next

        Return liste
    End Function

    ''' <summary>
    ''' L'autorité à qui la retenue est due, déduite du nom du compte. Rend
    ''' Nothing quand le compte n'est pas un compte de DAS — c'est ce qui filtre
    ''' le grand livre.
    '''
    ''' LA RECONNAISSANCE EST VOLONTAIREMENT LARGE côté « est-ce une DAS », et
    ''' PRUDENTE côté « laquelle ». Un compte de retenues qu'on raterait ferait
    ''' disparaître une dette ; un compte fédéral rangé au Québec ferait deux
    ''' déclarations fausses. Ce qui ne tranche pas ressort en « Autre », et
    ''' l'écran le montre à part pour qu'on le classe à la main.
    ''' </summary>
    Private Shared Function AutoriteDuCompte(compte As String) As String
        Dim n As String = If(compte, "").ToLowerInvariant()
        If n = "" Then Return Nothing

        ' Est-ce un compte de retenues à la source ?
        Dim estDas As Boolean =
            n.Contains("das") OrElse n.Contains("retenue") OrElse
            n.Contains("source deduction") OrElse n.Contains("payroll") OrElse
            n.Contains("paie à payer") OrElse n.Contains("paie a payer") OrElse
            n.Contains("rrq") OrElse n.Contains("rqap") OrElse n.Contains("qpp") OrElse
            n.Contains("rpc") OrElse n.Contains("cpp") OrElse
            n.Contains("assurance-emploi") OrElse n.Contains("assurance emploi") OrElse
            n.Contains("receveur") OrElse n.Contains("receiver general") OrElse
            n.Contains("cnesst") OrElse n.Contains("fss")

        If Not estDas Then Return Nothing

        ' À qui ? Le Québec d'abord : « RRQ Québec » doit tomber au Québec, pas
        ' au fédéral parce que le mot « impôt » traîne ailleurs dans le nom.
        If n.Contains("québec") OrElse n.Contains("quebec") OrElse n.Contains("qc") OrElse
           n.Contains("rrq") OrElse n.Contains("rqap") OrElse n.Contains("qpp") OrElse
           n.Contains("fss") OrElse n.Contains("cnesst") OrElse n.Contains("revenu qu") Then
            Return "Quebec"
        End If

        If n.Contains("fédéral") OrElse n.Contains("federal") OrElse
           n.Contains("receveur général") OrElse n.Contains("receveur general") OrElse
           n.Contains("receiver general") OrElse n.Contains("arc") OrElse n.Contains("cra") OrElse
           n.Contains("rpc") OrElse n.Contains("cpp") OrElse n.Contains("assurance-emploi") OrElse
           n.Contains("assurance emploi") Then
            Return "Federal"
        End If

        Return "Autre"
    End Function

    ''' <summary>
    ''' Dépose les remises de DAS en préparation. Rien ne s'applique : ni à la
    ''' comptabilité, ni à paie.Paie. C'est une pièce de contrôle — elle dit ce
    ''' qui reste dû à chaque autorité au moment de la bascule.
    ''' </summary>
    Private Function VerserRemisesDas(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then
            Return "aucun compte de retenues à la source dans le grand livre"
        End If

        Dim fichierId As Integer = InscrireAuRegistre("RemiseDas", "remises de DAS", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Mouvements", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0831ChargerRemisesDas", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = Lire(r, "NbMouvements") & " mouvement(s), " &
                              Lire(r, "NbRemises") & " remise(s)"
        If Lire(r, "NbAClasser") > 0 Then
            texte &= ", " & Lire(r, "NbAClasser") & " à classer par autorité"
        End If
        Return texte
    End Function

    ''' <summary>
    ''' L'état de pointage des opérations, par la passerelle.
    '''
    ''' À la bascule, la base de l'ERP est VIDE : c'est le pointage de la source
    ''' qui fait foi. Sans lui, le premier rapprochement bancaire est faux de
    ''' tous les chèques émis avant la bascule et encaissés après.
    '''
    ''' OÙ IL SE TROUVE, ET POURQUOI JE NE L'AI PAS TROUVÉ DU PREMIER COUP. Le
    ''' rapport « UnclearedTransactions » n'existe pas — refusé, trois essais.
    ''' La colonne demandée à TransactionList s'appelle « is_cleared », pas
    ''' « cleared » : sous le mauvais nom, QuickBooks la retire de la réponse
    ''' SANS RIEN DIRE. On demande huit colonnes, on en reçoit sept, et rien ne
    ''' signale laquelle a sauté.
    '''
    ''' D'OÙ LE REPÉRAGE PAR CLÉ. Les colonnes sont localisées par leur ColKey
    ''' dans la réponse, jamais par leur rang. Si « is_cleared » manque, on
    ''' s'arrête au lieu de lire la colonne d'à côté et de prendre un montant
    ''' pour un état de pointage — c'est exactement l'erreur commise sur le
    ''' grand livre, où la huitième colonne s'est avérée être un solde cumulé.
    '''
    ''' CE QUE PORTE LA COLONNE : vide si l'opération n'est pas pointée, « C »
    ''' si elle est compensée, « R » si elle a été rapprochée dans un
    ''' rapprochement clos. La lettre est gardée telle quelle en plus du
    ''' booléen : les deux états ne se valent pas.
    ''' </summary>
    Private Function LireOperationsRapprochement(api As clsApideck) As JArray
        Dim arrete As Date? = DateArret
        If Not arrete.HasValue Then
            Throw New Exception("Indiquez la date d'arrêt : le pointage se lit sur une période.")
        End If

        Dim fin As String = arrete.Value.ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)
        Dim debut As String = New Date(arrete.Value.Year, 1, 1).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)

        Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & api.RealmId() &
                            "/reports/TransactionList?start_date=" & debut & "&end_date=" & fin &
                            "&columns=tx_date,txn_type,doc_num,name,memo,account_name,is_cleared,subt_nat_amount" &
                            "&minorversion=75"

        Dim rapport As JObject = api.Proxy(url)
        Dim liste As New JArray()
        If rapport Is Nothing Then Return liste

        ' Les colonnes, repérées par leur clé et pas par leur rang.
        Dim ou As Dictionary(Of String, Integer) = PositionsColonnes(rapport)
        If Not ou.ContainsKey("is_cleared") Then
            Throw New Exception("QuickBooks n'a pas rendu la colonne « is_cleared » : " &
                                "l'état de pointage ne peut pas être repris sans elle.")
        End If

        Dim entete As JToken = rapport.SelectToken("Header")
        Dim debutReel As String = Valeur(entete, "StartPeriod")
        Dim finReelle As String = Valeur(entete, "EndPeriod")
        Dim devise As String = Valeur(entete, "Currency")

        Dim rangs As JArray = TryCast(rapport.SelectToken("Rows.Row"), JArray)
        If rangs Is Nothing Then Return liste

        Dim rang As Integer = 0
        For Each r As JToken In rangs
            Dim c As JArray = TryCast(r("ColData"), JArray)
            If c Is Nothing Then Continue For

            rang += 1
            Dim o As New JObject()
            o("debut") = debutReel
            o("fin") = finReelle
            o("devise") = devise
            o("rang") = rang
            o("date") = Cellule(c, ou, "tx_date")
            o("type") = Cellule(c, ou, "txn_type")
            o("numero") = Cellule(c, ou, "doc_num")
            o("tiers") = Cellule(c, ou, "name")
            o("memo") = Cellule(c, ou, "memo")
            o("compte") = Cellule(c, ou, "account_name")
            o("pointage") = Cellule(c, ou, "is_cleared")
            o("montant") = Cellule(c, ou, "subt_nat_amount")
            liste.Add(o)
        Next

        Return liste
    End Function

    ''' <summary>
    ''' Où se trouve chaque colonne, d'après la clé que la source lui donne.
    ''' Une colonne demandée sous un nom que QuickBooks ne connaît pas est
    ''' retirée en silence : sans ce relevé, on lirait la suivante à sa place.
    ''' </summary>
    Private Shared Function PositionsColonnes(rapport As JObject) As Dictionary(Of String, Integer)
        Dim ou As New Dictionary(Of String, Integer)
        Dim colonnes As JArray = TryCast(rapport.SelectToken("Columns.Column"), JArray)
        If colonnes Is Nothing Then Return ou

        For i As Integer = 0 To colonnes.Count - 1
            Dim cle As String = CleColonne(colonnes(i))
            If cle <> "" AndAlso Not ou.ContainsKey(cle) Then ou(cle) = i
        Next
        Return ou
    End Function

    ''' <summary>La valeur d'une colonne, ou vide si la source ne l'a pas rendue.</summary>
    Private Shared Function Cellule(cellules As JArray, ou As Dictionary(Of String, Integer),
                                    cle As String) As String
        Dim i As Integer
        If Not ou.TryGetValue(cle, i) Then Return ""
        If i < 0 OrElse i >= cellules.Count Then Return ""
        Return Valeur(cellules(i), "value")
    End Function

    ''' <summary>
    ''' Dépose l'état de pointage en préparation. Rien ne s'applique à la
    ''' comptabilité : T142ReleveBancaire porte le relevé de la banque et n'est
    ''' pas touchée. Ce qui est déposé ici dit ce que la SOURCE tenait pour
    ''' pointé au moment de la bascule.
    ''' </summary>
    Private Function VerserOperationsRapprochement(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then
            Return "aucune opération sur la période"
        End If

        Dim fichierId As Integer = InscrireAuRegistre("Rapprochement", "état de pointage", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Operations", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0827ChargerOperationsRapprochement", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Return Lire(r, "NbOperations") & " opération(s), " &
               Lire(r, "NbNonPointees") & " non pointée(s)"
    End Function

    ''' <summary>
    ''' Les comptes et soldes bancaires, par la passerelle.
    '''
    ''' Apideck ne les expose pas : /accounting/bank-accounts répond 404 pour
    ''' QuickBooks. On interroge donc l'entité Account dans son langage natif.
    '''
    ''' CE N'EST PAS LE RAPPROCHEMENT, ET ÇA NE PEUT PAS L'ÊTRE. La feuille de
    ''' route visait T142ReleveBancaire à partir du « dernier Reconciliation
    ''' Report ». Ce rapport n'existe pas dans l'API : ReconciliationReport,
    ''' Reconciliation, BankReconciliation et UnclearedTransactions sont tous
    ''' refusés, et la colonne « cleared » demandée à TransactionList est
    ''' silencieusement retirée de la réponse — on la demande, on reçoit sept
    ''' colonnes au lieu de huit, sans un mot.
    '''
    ''' Et même exposé, il ne faudrait pas le verser dans T142 : cette table
    ''' porte le relevé de LA BANQUE, celui contre lequel les livres se
    ''' rapprochent. Le fabriquer à partir des mouvements comptables de la
    ''' source reviendrait à rapprocher les livres d'eux-mêmes.
    '''
    ''' LA PAGINATION N'EST PAS UN LUXE. QuickBooks rend 100 lignes par défaut
    ''' et s'arrête là, sans dire qu'il en reste. Un plan comptable de 140
    ''' comptes perdrait ses 40 derniers — et si un compte bancaire s'y trouve,
    ''' le solde manquant ne se remarquerait qu'au rapprochement suivant.
    ''' </summary>
    Private Function LireComptesBancaires(api As clsApideck) As JArray
        Dim realm As String = api.RealmId()
        Dim liste As New JArray()
        Dim rang As Integer = 0
        Dim arrete As String = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss",
                                                     Globalization.CultureInfo.InvariantCulture)

        For Each c As JToken In ComptesDeLaSource(api, realm)
            Dim genre As String = Valeur(c, "AccountType")
            If genre <> "Bank" AndAlso genre <> "Credit Card" Then Continue For

            rang += 1
            Dim o As New JObject()
            o("rang") = rang
            o("externe_id") = Valeur(c, "Id")
            o("numero") = Valeur(c, "AcctNum")
            o("nom") = Valeur(c, "Name")
            o("nom_complet") = Valeur(c, "FullyQualifiedName")
            o("description") = Valeur(c, "Description")
            o("type") = genre
            o("sous_type") = Valeur(c, "AccountSubType")
            o("devise") = Valeur(c, "CurrencyRef.value")
            o("masque") = Valeur(c, "AcctNum")
            o("solde") = Valeur(c, "CurrentBalance")
            o("solde_avec_sous") = Valeur(c, "CurrentBalanceWithSubAccounts")
            o("sous_compte") = Valeur(c, "SubAccount")
            o("parent_id") = Valeur(c, "ParentRef.value")
            o("actif") = Valeur(c, "Active")
            o("arrete_le") = arrete
            liste.Add(o)
        Next

        Return liste
    End Function

    ''' <summary>
    ''' Tous les comptes de la source, page par page.
    '''
    ''' On ne filtre pas sur AccountType dans la requête : une clause WHERE
    ''' voyage encodée dans une URL relayée par un tiers, et une apostrophe mal
    ''' passée rend une liste vide qui ressemble à une absence de comptes. Le
    ''' tri se fait ici, où il se lit.
    '''
    ''' La boucle s'arrête quand une page revient plus courte que demandée —
    ''' c'est le seul signal que QuickBooks donne — ou au garde-fou, pour qu'une
    ''' réponse inattendue ne tourne pas en rond.
    ''' </summary>
    Private Shared Function ComptesDeLaSource(api As clsApideck, realm As String) As JArray
        Const TAILLE_PAGE As Integer = 100
        Const PLAFOND As Integer = 100

        Dim tous As New JArray()
        Dim depart As Integer = 1

        For tour As Integer = 1 To PLAFOND
            Dim requete As String = Uri.EscapeDataString(
                "select * from Account startposition " & depart & " maxresults " & TAILLE_PAGE)
            Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & realm &
                                "/query?query=" & requete & "&minorversion=75"

            Dim r As JObject = api.Proxy(url)
            If r Is Nothing Then Exit For

            Dim page As JArray = TryCast(r.SelectToken("QueryResponse.Account"), JArray)
            If page Is Nothing OrElse page.Count = 0 Then Exit For

            For Each c As JToken In page
                tous.Add(c)
            Next

            If page.Count < TAILLE_PAGE Then Exit For
            depart += TAILLE_PAGE
        Next

        Return tous
    End Function

    ''' <summary>
    ''' Dépose les comptes bancaires en préparation. Rien ne s'applique à la
    ''' comptabilité : c'est une pièce de contrôle, comme le grand livre et les
    ''' déclarations de taxes — on la confronte, on ne la reprend pas.
    ''' </summary>
    Private Function VerserComptesBancaires(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then
            Return "aucun compte bancaire — la source n'en déclare pas"
        End If

        Dim fichierId As Integer = InscrireAuRegistre("CompteBancaire", "comptes bancaires", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Comptes", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0824ChargerComptesBancaires", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = Lire(r, "NbComptes") & " compte(s)"
        If Lire(r, "NbCartes") > 0 Then texte &= ", dont " & Lire(r, "NbCartes") & " carte(s) de crédit"
        Return texte
    End Function

    ''' <summary>
    ''' Les rapports de taxes, par la passerelle.
    '''
    ''' Apideck ne les expose pas : on demande le rapport natif « TaxSummary »,
    ''' et Apideck le relaie tel quel.
    '''
    ''' UN ABONNÉ N'A PAS UN RAPPORT, IL EN A PLUSIEURS — un par période de
    ''' déclaration et par administration fiscale. Un trimestriel québécois
    ''' arrivé en septembre en a trois : janvier-mars, avril-juin, puis le
    ''' trimestre en cours arrêté à la date demandée. On les rapatrie tous, et
    ''' l'écran les met côte à côte.
    '''
    ''' LA FRÉQUENCE VIENT DE L'ÉCRAN, PAS DE LA SOURCE. QuickBooks ne l'expose
    ''' nulle part : ni Preferences.TaxPrefs, qui ne dit que « UsingSalesTax »,
    ''' ni TaxAgency, qui ne porte que le nom et le numéro d'inscription.
    ''' Cherché, et pas trouvé. Alors on demande plutôt que de supposer — se
    ''' tromper de découpage produirait des déclarations d'apparence juste qui
    ''' ne correspondraient à aucune de celles qui ont été produites.
    '''
    ''' LE DÉBUT D'EXERCICE, LUI, EST CONNU : Preferences le donne, et c'est de
    ''' là que les périodes se comptent.
    '''
    ''' LES DEUX DATES SONT OBLIGATOIRES, ET ENSEMBLE. Une date isolée est
    ''' silencieusement ignorée : QuickBooks retombe alors sur « ce trimestre-ci »
    ''' et rend un rapport juste, mais pas celui qu'on a demandé. Même piège que
    ''' la balance de vérification, vérifié à la main sur ce rapport-ci.
    '''
    ''' « TaxSummary » EXIGE agency_id. Sans lui, QuickBooks répond 200 avec
    ''' « NoReportData: true » — poliment, sans nommer le paramètre qui manque.
    ''' On cherche longtemps une donnée qui est pourtant là.
    '''
    ''' ON NE PRÉSUME RIEN DES COLONNES. Au Québec le rapport en a une seule,
    ''' « Total », et ses lignes sont celles du formulaire : 101 les ventes, 106
    ''' le CTI, 206 le RTI, 217 le montant à payer ou à rembourser. Ailleurs ce
    ''' ne sont pas les mêmes. Alors on lit les entêtes que la source donne et on
    ''' les emporte avec chaque valeur, plutôt que de compter sur un ordre.
    ''' </summary>
    Private Function LireRapportTaxes(api As clsApideck) As JArray
        Dim arrete As Date? = DateArret
        If Not arrete.HasValue Then
            Throw New Exception("Indiquez la date d'arrêt : les rapports de taxes portent sur des périodes.")
        End If

        Dim realm As String = api.RealmId()
        Dim periodes As List(Of Date()) = PeriodesDeclaration(arrete.Value, PremierMoisExercice(api))
        Dim agences As JArray = api.QuickBooksQuery("TaxAgency", realm)

        Dim liste As New JArray()
        Dim ordre As Integer = 0
        Dim rang As Integer = 0

        For Each p As Date() In periodes
            rang += 1
            Dim debut As String = p(0).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)
            Dim fin As String = p(1).ToString("yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture)

            For Each agence As JToken In agences
                Dim agenceId As String = Valeur(agence, "Id")
                Dim agenceNom As String = Valeur(agence, "DisplayName", "Name")
                If agenceId = "" Then Continue For

                Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & realm &
                                    "/reports/TaxSummary?agency_id=" & Uri.EscapeDataString(agenceId) &
                                    "&start_date=" & debut & "&end_date=" & fin &
                                    "&minorversion=75"

                Dim rapport As JObject = api.Proxy(url)
                If rapport Is Nothing Then Continue For

                AjouterRapportTaxes(rapport, rang, agenceId, agenceNom, liste, ordre)
            Next
        Next

        Return liste
    End Function

    ''' <summary>
    ''' Le premier mois de l'exercice, tel que la source le déclare. Janvier par
    ''' défaut : c'est le cas de la très grande majorité, et une année civile
    ''' mal devinée se voit tout de suite sur les dates du rapport.
    ''' </summary>
    Private Shared Function PremierMoisExercice(api As clsApideck) As Integer
        Try
            Dim prefs As JObject = api.Proxy("https://quickbooks.api.intuit.com/v3/company/" &
                                             api.RealmId() & "/preferences?minorversion=75")
            Dim nom As String = Valeur(prefs, "Preferences.AccountingInfoPrefs.FirstMonthOfFiscalYear")
            If nom = "" Then Return 1

            Dim mois As Date
            If Date.TryParseExact(nom, "MMMM", Globalization.CultureInfo.GetCultureInfo("en-US"),
                                  Globalization.DateTimeStyles.None, mois) Then
                Return mois.Month
            End If
        Catch
            ' La préférence est un confort : son absence ne doit pas faire
            ' échouer l'extraction.
        End Try
        Return 1
    End Function

    ''' <summary>
    ''' Les périodes de déclaration de l'exercice en cours, jusqu'à la date
    ''' d'arrêt. La dernière est TRONQUÉE à cette date : c'est la déclaration en
    ''' cours, et la source la rend ainsi.
    '''
    ''' L'exercice retenu est celui qui CONTIENT la date d'arrêt, pas l'année
    ''' civile : un exercice commençant en juillet donnerait autrement des
    ''' périodes à cheval sur deux déclarations.
    ''' </summary>
    Private Function PeriodesDeclaration(arrete As Date, premierMois As Integer) As List(Of Date())
        Dim mois As Integer = MoisParPeriode
        Dim liste As New List(Of Date())

        ' Le début de l'exercice qui contient la date d'arrêt.
        Dim debutExercice As New Date(arrete.Year, premierMois, 1)
        If debutExercice > arrete Then debutExercice = debutExercice.AddYears(-1)

        Dim debut As Date = debutExercice
        While debut <= arrete
            Dim fin As Date = debut.AddMonths(mois).AddDays(-1)
            If fin > arrete Then fin = arrete
            liste.Add(New Date() {debut, fin})
            debut = debut.AddMonths(mois)
        End While

        Return liste
    End Function

    ''' <summary>
    ''' Une déclaration : celle d'une administration, pour une période. Les
    ''' administrations qui n'ont rien à déclarer sur la période répondent sans
    ''' lignes — elles passent leur tour sans bruit, ce n'est pas une anomalie.
    ''' </summary>
    Private Shared Sub AjouterRapportTaxes(rapport As JObject, periodeOrdre As Integer,
                                           agenceId As String, agenceNom As String,
                                           liste As JArray, ByRef ordre As Integer)
        Dim entete As JToken = rapport.SelectToken("Header")
        Dim debutReel As String = Valeur(entete, "StartPeriod")
        Dim finReelle As String = Valeur(entete, "EndPeriod")
        Dim devise As String = Valeur(entete, "Currency")

        ' Les colonnes telles que la source les nomme, titre et clé technique.
        Dim titres As New List(Of String)
        Dim cles As New List(Of String)
        Dim colonnes As JArray = TryCast(rapport.SelectToken("Columns.Column"), JArray)
        If colonnes IsNot Nothing Then
            For Each c As JToken In colonnes
                titres.Add(Valeur(c, "ColTitle"))
                cles.Add(CleColonne(c))
            Next
        End If

        Dim rangs As JArray = TryCast(rapport.SelectToken("Rows.Row"), JArray)
        If rangs Is Nothing Then Exit Sub

        AjouterRangsTaxes(rangs, "", 0, titres, cles, periodeOrdre, debutReel, finReelle, devise,
                          agenceId, agenceNom, liste, ordre)
    End Sub

    ''' <summary>
    ''' La clé technique d'une colonne, quand la source en donne une. Elle vit
    ''' dans un tableau de paires : MetaData = [{ Name: "ColKey", Value: "…" }].
    ''' </summary>
    Private Shared Function CleColonne(colonne As JToken) As String
        Dim meta As JArray = TryCast(colonne("MetaData"), JArray)
        If meta Is Nothing Then Return ""

        For Each m As JToken In meta
            If String.Equals(Valeur(m, "Name"), "ColKey", StringComparison.OrdinalIgnoreCase) Then
                Return Valeur(m, "Value")
            End If
        Next
        Return ""
    End Function

    ''' <summary>
    ''' Descend le rapport. QuickBooks y mêle trois sortes de rangs : une ligne
    ''' ordinaire porte son ColData ; une section porte un Header, des Rows et
    ''' un Summary. On les traite tous les trois, et la récursion garde le nom
    ''' de la section qui contient — sans quoi une ligne « Total » ne dirait pas
    ''' de quoi elle est le total.
    ''' </summary>
    Private Shared Sub AjouterRangsTaxes(rangs As JArray, groupe As String, niveau As Integer,
                                         titres As List(Of String), cles As List(Of String),
                                         periodeOrdre As Integer,
                                         debut As String, fin As String, devise As String,
                                         agenceId As String, agenceNom As String,
                                         liste As JArray, ByRef ordre As Integer)
        For Each r As JToken In rangs
            Dim propre As JArray = TryCast(r("ColData"), JArray)
            If propre IsNot Nothing Then
                ordre += 1
                CellulesTaxes(propre, Valeur(r, "group"), groupe, niveau, False, titres, cles, periodeOrdre, debut, fin, devise, agenceId, agenceNom, liste, ordre)
            End If

            Dim enteteSection As JArray = TryCast(r.SelectToken("Header.ColData"), JArray)
            If enteteSection IsNot Nothing Then
                ordre += 1
                CellulesTaxes(enteteSection, Valeur(r, "group"), groupe, niveau, False, titres, cles, periodeOrdre, debut, fin, devise, agenceId, agenceNom, liste, ordre)
            End If

            Dim dedans As JArray = TryCast(r.SelectToken("Rows.Row"), JArray)
            If dedans IsNot Nothing Then
                Dim nom As String = groupe
                If enteteSection IsNot Nothing AndAlso enteteSection.Count > 0 Then
                    nom = Valeur(enteteSection(0), "value")
                End If
                AjouterRangsTaxes(dedans, nom, niveau + 1, titres, cles, periodeOrdre, debut, fin, devise, agenceId, agenceNom, liste, ordre)
            End If

            Dim totalSection As JArray = TryCast(r.SelectToken("Summary.ColData"), JArray)
            If totalSection IsNot Nothing Then
                ordre += 1
                CellulesTaxes(totalSection, Valeur(r, "group"), groupe, niveau, True, titres, cles, periodeOrdre, debut, fin, devise, agenceId, agenceNom, liste, ordre)
            End If
        Next
    End Sub

    ''' <summary>
    ''' Une ligne devient autant d'enregistrements qu'elle a de valeurs. La
    ''' PREMIÈRE colonne n'en est pas une : c'est le libellé de la ligne, et il
    ''' est recopié sur chaque cellule pour qu'aucune ne se retrouve orpheline.
    '''
    ''' Une ligne sans colonne de valeur — le titre d'une section, par exemple —
    ''' produit quand même un enregistrement. Sinon elle disparaîtrait du
    ''' rapport, et sa section avec elle.
    ''' </summary>
    Private Shared Sub CellulesTaxes(cellules As JArray, ligneCode As String, groupe As String,
                                     niveau As Integer, estTotal As Boolean,
                                     titres As List(Of String), cles As List(Of String),
                                     periodeOrdre As Integer,
                                     debut As String, fin As String, devise As String,
                                     agenceId As String, agenceNom As String,
                                     liste As JArray, ordre As Integer)
        Dim libelle As String = ""
        If cellules.Count > 0 Then libelle = Valeur(cellules(0), "value")

        If cellules.Count <= 1 Then
            liste.Add(CelluleTaxes(periodeOrdre, debut, fin, devise, agenceId, agenceNom, ordre, niveau,
                                   ligneCode, groupe, libelle, estTotal, 0, "", "", ""))
            Exit Sub
        End If

        For i As Integer = 1 To cellules.Count - 1
            Dim titre As String = If(i < titres.Count, titres(i), "")
            Dim cle As String = If(i < cles.Count, cles(i), "")
            liste.Add(CelluleTaxes(periodeOrdre, debut, fin, devise, agenceId, agenceNom, ordre, niveau,
                                   ligneCode, groupe, libelle, estTotal,
                                   i, titre, cle, Valeur(cellules(i), "value")))
        Next
    End Sub

    Private Shared Function CelluleTaxes(periodeOrdre As Integer,
                                         debut As String, fin As String, devise As String,
                                         agenceId As String, agenceNom As String,
                                         ordre As Integer, niveau As Integer,
                                         ligneCode As String, groupe As String,
                                         libelle As String, estTotal As Boolean,
                                         colonne As Integer, titre As String, cle As String,
                                         valeur As String) As JObject
        Dim o As New JObject()
        o("periode_ordre") = periodeOrdre
        o("debut") = debut
        o("fin") = fin
        o("devise") = devise
        o("agence_id") = agenceId
        o("agence") = agenceNom
        o("ligne_ordre") = ordre
        o("niveau") = niveau
        o("ligne_code") = ligneCode
        o("groupe") = groupe
        o("libelle") = libelle
        o("est_total") = If(estTotal, "1", "0")
        o("colonne_ordre") = colonne
        o("colonne_titre") = titre
        o("colonne_cle") = cle
        o("valeur") = valeur
        Return o
    End Function

    ''' <summary>
    ''' Dépose le rapport de taxes en préparation. Rien ne s'applique à la
    ''' comptabilité : c'est une pièce de contrôle, comme le grand livre et la
    ''' balance âgée — on la confronte, on ne la reprend pas. Aucune écriture,
    ''' aucun compte de taxe, aucune déclaration.
    ''' </summary>
    Private Function VerserRapportTaxes(brut As JArray, runId As Integer) As String
        If brut Is Nothing OrElse brut.Count = 0 Then
            Return "aucune donnée — la source ne déclare aucune opération taxée sur l'exercice"
        End If

        Dim fichierId As Integer = InscrireAuRegistre("RapportTaxes", "rapport de taxes", brut)

        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Lignes", brut.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0822ChargerRapportTaxes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "en préparation"

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim texte As String = Lire(r, "NbPeriodes") & " déclaration(s), " &
                              Lire(r, "NbLignes") & " ligne(s)"
        If Lire(r, "NbAgences") > 1 Then texte &= ", " & Lire(r, "NbAgences") & " administrations"
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
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@ImportFileId", CObj(fichierId)))
        p.Add(New SqlParameter("@Taxes", taux.ToString(Formatting.None)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0792ChargerTaxesImport", p)
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
            p.Add(New SqlParameter("@CompanyGUID", hote.Company))

            Dim ds As DataSet = hote.ExecuteSQLds("s0794RepartirTaxesImport", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return ""

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim coupees As Integer = Lire(r, "NbLignesCoupees") + Lire(r, "NbDocumentsParTotal")
            Dim sousTotaux As Integer = Lire(r, "NbSousTotaux")
            Dim boiteux As Integer = Lire(r, "NbDesequilibres")

            If coupees = 0 AndAlso sousTotaux = 0 AndAlso boiteux = 0 Then Return ""

            Dim texte As String = "Taxes réparties : " & coupees & " élément(s)."
            If sousTotaux > 0 Then texte &= " " & sousTotaux & " sous-total(aux) déduit(s) du total et des taxes."
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


    ''' <summary>
    ''' Une ligne de comparaison. Les champs vides des deux côtés ne valent pas
    ''' la peine d'être montrés : ils allongeraient l'écran sans rien dire.
    ''' </summary>
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
    ''' Écarte l'extraction Apideck précédente de ce type, s'il y en a une.
    '''
    ''' Le registre garde une ligne par import, et c'est ce qui permet de
    ''' répondre à « qu'est-ce qui est entré, et quand ». Mais une extraction
    ''' relit toujours la même source : répétée, elle empile des copies. Trente
    ''' deux fichiers pour dix ressources, et quatre cent cinquante et un tiers
    ''' là où la source en compte deux cent un.
    '''
    ''' Un fichier déposé à la main, lui, garde son sens en plusieurs
    ''' exemplaires — trois listes de clients de trois succursales sont trois
    ''' fichiers distincts. La procédure ne touche donc QUE les extractions,
    ''' reconnues à leur ModelUsed « apideck/… ».
    '''
    ''' Un échec ici ne doit pas faire perdre l'extraction : le doublon est un
    ''' encombrement, pas une faute.
    ''' </summary>
    Private Sub RemplacerExtractionPrecedente(typeImport As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", hote.Company))
            p.Add(New SqlParameter("@TypeImport", typeImport))
            hote.ExecuteSQLds("s0819RemplacerImportApideck", p)
        Catch
            ' On continue : mieux vaut un doublon qu'une extraction perdue.
        End Try
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

        ' Une extraction relit toujours la même source : la précédente du même
        ' type n'a plus rien à apprendre et serait un doublon. Elle cède la
        ' place — ce qui a déjà été créé dans l'application reste intact.
        RemplacerExtractionPrecedente(typeImport)

        Dim p As New Collection
        p.Add(New SqlParameter("@TypeImport", typeImport))
        p.Add(New SqlParameter("@OriginalName", nom))
        p.Add(New SqlParameter("@FileExtension", ".json"))
        p.Add(New SqlParameter("@FileSize", CObj(CLng(octets.Length))))
        p.Add(New SqlParameter("@ContentType", "application/json"))
        p.Add(New SqlParameter("@FileContent", octets))
        p.Add(New SqlParameter("@UploadedBy", CObj(hote.UserId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))

        Dim ds As DataSet = hote.ExecuteSQLds("s0600InsertImportFile", p)
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
        hote.ExecuteSQL("s0602UpdateImportFileResult", p2)

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

        ' Une extraction relit toujours la même source : la précédente du même
        ' type n'a plus rien à apprendre et serait un doublon. Elle cède la
        ' place — ce qui a déjà été créé dans l'application reste intact.
        RemplacerExtractionPrecedente(typeImport)

        Dim p As New Collection
        p.Add(New SqlParameter("@TypeImport", typeImport))
        p.Add(New SqlParameter("@OriginalName", nom))
        p.Add(New SqlParameter("@FileExtension", ".json"))
        p.Add(New SqlParameter("@FileSize", CObj(CLng(octets.Length))))
        p.Add(New SqlParameter("@ContentType", "application/json"))
        p.Add(New SqlParameter("@FileContent", octets))
        p.Add(New SqlParameter("@UploadedBy", CObj(hote.UserId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))

        Dim ds As DataSet = hote.ExecuteSQLds("s0600InsertImportFile", p)
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
        hote.ExecuteSQL("s0602UpdateImportFileResult", p2)

        Dim p3 As New Collection
        p3.Add(New SqlParameter("@ImportFileId", CObj(id)))
        hote.ExecuteSQLds("s0604ProcessImportJson", p3)

        Return "versé en préparation — import " & id
    End Function

#End Region

#Region "La base"

    Private Function OuvrirRun() As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Connecteur", "APIDECK"))
        p.Add(New SqlParameter("@Service", clsApideck.ServiceId()))
        p.Add(New SqlParameter("@ConsumerId", hote.Company.ToString()))
        p.Add(New SqlParameter("@UserId", CObj(hote.UserId)))

        Dim ds As DataSet = hote.ExecuteSQLds("s0776OuvrirConnecteurRun", p)
        Return Convert.ToInt32(ds.Tables(0).Rows(0)(0))
    End Function

    Private Sub FermerRun(runId As Integer, statut As String, note As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@RunId", CObj(runId)))
        p.Add(New SqlParameter("@CompanyGUID", hote.Company))
        p.Add(New SqlParameter("@Statut", statut))
        p.Add(New SqlParameter("@Note", If(note Is Nothing, CObj(DBNull.Value), CObj(note))))
        hote.ExecuteSQL("s0778FermerConnecteurRun", p)
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


    ''' <summary>
    ''' L'état d'un document déduit de ses montants : « Payée » quand il ne
    ''' reste rien, « Partielle » quand il reste moins que le total, « Ouverte »
    ''' sinon.
    '''
    ''' On déduit parce que la source ne dit rien — Apideck laisse « status »
    ''' vide pour QuickBooks. Le solde, lui, est toujours là, et c'est
    ''' précisément ce qu'on veut savoir d'une facture reprise : reste-t-il
    ''' quelque chose à encaisser ou à payer.
    '''
    ''' Rend une chaîne vide quand le solde est absent : mieux vaut ne rien
    ''' affirmer que d'affirmer « Ouverte » sur un document dont on ignore tout.
    ''' </summary>
    Private Shared Function EtatDocument(total As String, solde As String) As String
        Dim s As Object = Nombre(solde)
        If s Is Nothing Then Return ""

        Dim reste As Decimal = CDec(s)
        If Math.Abs(reste) <= 0.01D Then Return "Payée"

        Dim t As Object = Nombre(total)
        If t IsNot Nothing AndAlso Math.Abs(CDec(t) - reste) > 0.01D Then Return "Partielle"
        Return "Ouverte"
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
