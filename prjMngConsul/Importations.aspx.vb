Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Le point d'entrée de toutes les importations. Chaque écran d'import s'atteint
''' d'ici : le menu n'en porte plus qu'une seule entrée, et le parcours se lit
''' d'un coup d'œil au lieu de se deviner.
'''
''' Chaque poste porte une note sur 10. Elle ne décrit pas une intention mais
''' l'état du code, sur quatre critères vérifiables :
'''
'''   lire le fichier · contrôler ce qu'il contient · le mettre en préparation ·
'''   l'appliquer pour de bon à la comptabilité
'''
''' Un écran qui lit et prépare sans jamais rien appliquer plafonne : les données
''' restent en attente, et la reprise n'avance pas.
''' </summary>
Public Class Importations
    Inherits clsData

#Region "Le catalogue"

    ''' <summary>Un poste d'importation, et ce qu'on peut en dire.</summary>
    Private Class Poste
        Public Property Titre As String
        Public Property Source As String          ' le rapport ou le fichier d'origine
        Public Property Destination As String     ' où les données atterrissent
        Public Property Page As String = ""       ' vide : l'écran n'existe pas
        Public Property Note As Integer           ' 1 à 10
        Public Property Fait As String            ' ce qui fonctionne
        Public Property Manque As String          ' ce qui manque pour aller à 10
        Public Property Icone As String = "📄"
        Public Property Etape As String = ""      ' numéro dans le parcours, si parcours
        Public Property Ressources As String = "" ' les ressources Apideck que l'écran lit, s'il en lit
    End Class

    ''' <summary>
    ''' Ce qu'une compagnie a réellement fait d'un poste : ce qui attend en
    ''' préparation et ce qui a été appliqué (créé en comptabilité, ou reconnu
    ''' pour les taxes). Lu une fois par page, par s0896GetAvancementImport.
    ''' </summary>
    Private Class Avancement
        Public Property Prepares As Integer
        Public Property Appliques As Integer
    End Class

    Private _avancement As Dictionary(Of String, Avancement)

    Private Function AvancementImport() As Dictionary(Of String, Avancement)
        If _avancement IsNot Nothing Then Return _avancement
        _avancement = New Dictionary(Of String, Avancement)(StringComparer.OrdinalIgnoreCase)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0896GetAvancementImport", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    _avancement(Convert.ToString(r("Poste"))) = New Avancement With {
                        .Prepares = Convert.ToInt32(r("Prepares")),
                        .Appliques = If(IsDBNull(r("Appliques")), 0, Convert.ToInt32(r("Appliques")))}
                Next
            End If
        Catch
            ' Sans la procédure, les postes gardent leur note de code : rien ne casse.
        End Try
        Return _avancement
    End Function

    ''' <summary>Titre du poste → ligne de l'avancement, pour les postes obligatoires.</summary>
    Private Shared ReadOnly PostesAvancement As New Dictionary(Of String, String)(StringComparer.Ordinal) From {
        {"Balance de vérification", "Balance"},
        {"Clients", "Client"},
        {"Fournisseurs", "Fournisseur"},
        {"Produits et services", "Produit"},
        {"Factures clients et fournisseurs", "Facture"},
        {"Codes et taux de taxe", "Taxe"}
    }

    ''' <summary>
    ''' La note d'un poste obligatoire dit où en est la compagnie, pas la maturité
    ''' du code : 0 tant que rien n'est en préparation, 5 quand les données
    ''' attendent, jusqu'à 10 quand tout est appliqué. La balance plafonne à 5 :
    ''' rien ne l'applique encore. Les quantités s'écrivent en tête de « ce qui
    ''' fonctionne » pour que la note se vérifie d'un coup d'œil.
    ''' </summary>
    Private Function NoterAvancement(postes As List(Of Poste)) As List(Of Poste)
        Dim av As Dictionary(Of String, Avancement) = AvancementImport()
        For Each poste In postes
            Dim cle As String = Nothing
            If Not PostesAvancement.TryGetValue(poste.Titre, cle) Then Continue For
            Dim a As Avancement = Nothing
            If Not av.TryGetValue(cle, a) OrElse a.Prepares = 0 Then
                poste.Note = 0
                poste.Fait = "Rien en préparation pour cette compagnie. " & poste.Fait
                Continue For
            End If
            Dim part As Double = a.Appliques / CDbl(a.Prepares)
            Select Case cle
                Case "Balance"
                    poste.Note = 5
                    poste.Fait = a.Prepares.ToString("N0") & " ligne(s) de balance en préparation ; les soldes d'ouverture ne s'appliquent pas encore. " & poste.Fait
                Case "Taxe"
                    poste.Note = 5 + CInt(Math.Round(5 * part))
                    poste.Fait = a.Prepares.ToString("N0") & " code(s) de taxe lu(s), " & a.Appliques.ToString("N0") & " reconnu(s) avec TPS et TVQ. " & poste.Fait
                Case "Facture"
                    poste.Note = 5 + CInt(Math.Round(5 * part))
                    poste.Fait = a.Prepares.ToString("N0") & " facture(s) en préparation, " & a.Appliques.ToString("N0") & " créée(s) en brouillon. " & poste.Fait
                Case Else
                    poste.Note = 5 + CInt(Math.Round(5 * part))
                    poste.Fait = a.Prepares.ToString("N0") & " " & cle.ToLowerInvariant() & "(s) en préparation, " & a.Appliques.ToString("N0") & " créé(s). " & poste.Fait
            End Select
        Next
        Return postes
    End Function

    ''' <summary>
    ''' La reprise du plan comptable : une seule boîte, qui mène à l'étape 1.
    ''' Le détail de chaque étape — ce qui fonctionne, ce qui manque — vit sur
    ''' l'écran lui-même, sous le fil des étapes. La note est celle de l'étape
    ''' la plus faible : un parcours ne vaut pas mieux.
    ''' La balance de vérification vient à côté : c'est la cible du contrôle final.
    ''' </summary>
    Private ReadOnly Property Parcours As List(Of Poste)
        Get
            Dim plan As EtatPlan = EtatPlanComptable()

            Return NoterAvancement(New List(Of Poste) From {
                New Poste With {
                    .Icone = "📊",
                    .Titre = "Plan comptable",
                    .Source = "QuickBooks : Liste des comptes (Account List)",
                    .Destination = "comptabilité — T121PlanComptable, en trois étapes",
                    .Page = "~/ImportPlanComptable.aspx",
                    .Note = plan.Note,
                    .Fait = plan.Fait & " Importer le fichier, décider de la correspondance de chaque compte, " &
                            "puis créer au plan ceux qui manquent. Chaque écran dit lui-même " &
                            "ce qui y fonctionne et ce qui y manque.",
                    .Manque = plan.Manque
                },
                New Poste With {
                    .Icone = "⚖️",
                    .Titre = "Balance de vérification",
                    .Source = "QuickBooks : Balance de vérification (Trial Balance)",
                    .Destination = "préparation — staging.BalanceVerification",
                    .Page = "~/ImportBalanceVerification.aspx",
                    .Note = 5,
                    .Fait = "Lit l'export tel quel ou par l'IA, contrôle l'équilibre et le total " &
                            "du fichier, garde la balance par compagnie et la confronte au plan " &
                            "comptable importé.",
                    .Manque = "Rien ne l'applique encore : les soldes d'ouverture ne sont pas " &
                              "écrits en comptabilité."
                }
            })
        End Get
    End Property

    ''' <summary>
    ''' La lecture directe, par connecteur. Les autres postes partent d'un
    ''' fichier que le client a exporté ; celui-ci part de sa comptabilité
    ''' elle-même. Il est à part parce qu'il ne remplace aucun écran : il les
    ''' alimente. Ce qu'il rapatrie se dépose en préparation, et les écrans
    ''' ci-dessous décident ensuite de ce qui est créé.
    '''
    ''' Sa note n'est pas celle du code : c'est celle de la dernière extraction
    ''' de cette compagnie — la part des ressources qui ont répondu. Tout
    ''' rapatrié, 10 ; rien d'extrait encore, 0. Voir <see cref="Extraction"/>.
    ''' </summary>
    Private ReadOnly Property Connexion As List(Of Poste)
        Get
            Dim ext As Extraction = DerniereExtraction()

            Return NoterAvancement(NoterRessources(New List(Of Poste) From {
                New Poste With {
                    .Icone = "🔌",
                    .Titre = "QuickBooks, en direct",
                    .Source = "Apideck : lecture de la comptabilité source, sans export",
                    .Destination = "préparation — staging.ConnecteurDonnee, puis les écrans ci-dessous",
                    .Page = "~/ImportApideck.aspx",
                    .Note = ext.Note,
                    .Fait = "Le client relie son QuickBooks une fois ; chaque extraction rapatrie " &
                            "toutes les ressources d'Apideck en préparation, et chacune rejoint " &
                            "l'écran d'import qui la valide. " & ext.Fait,
                    .Manque = ext.Manque
                },
                New Poste With {
                    .Icone = "🧾",
                    .Titre = "Factures clients et fournisseurs",
                    .Source = "ce que l'extraction a déposé, clients et fournisseurs",
                    .Destination = "T060Document + T061DocumentLine, en brouillon",
                    .Page = "~/ValiderFactures.aspx",
                    .Ressources = "tax-rates,invoices,bills",
                    .Note = 7,
                    .Fait = "Montre chaque facture avec son détail, son tiers et son verdict — " &
                            "nouvelle, déjà en comptabilité, ou à corriger. Toutes les factures sont " &
                            "rapatriées, payées comme dues, et un filtre « ouvertes / fermées » trie " &
                            "avant de cocher. On rapproche le tiers quand la source ne l'a pas " &
                            "retrouvé, on répartit les taxes, et les documents sont créés en " &
                            "brouillon : rien ne part au grand livre.",
                    .Manque = "Les montants et les lignes ne se retouchent pas ici — il faut corriger " &
                              "à la source. Et la comptabilisation reste à faire depuis la grille des factures."
                },
                New Poste With {
                    .Icone = "🏢",
                    .Titre = "Comparer la fiche d'entreprise",
                    .Source = "les informations de la société lues chez la source",
                    .Destination = "les paramètres de la compagnie — T100/T101, après validation",
                    .Page = "~/ValiderSociete.aspx",
                    .Ressources = "company-info",
                    .Note = 7,
                    .Fait = "Le seul import qui ne crée rien : le nom légal, l'adresse et le " &
                            "téléphone existent déjà ici. Chaque champ est montré des deux côtés, " &
                            "avec son écart, et seuls les champs cochés remplacent la valeur en place.",
                    .Manque = "Ce que la source connaît sans équivalent chez nous — devise, méthode " &
                              "comptable, mois de début d'exercice — s'affiche sans pouvoir être repris."
                },
                New Poste With {
                    .Icone = "🗂️",
                    .Titre = "Listes de structure",
                    .Source = "modes de paiement, catégories de suivi, départements, emplacements — et, par la passerelle, classes, agences de taxes, devises et taux de change",
                    .Destination = "préparation seulement — aucune destination dans 60Sec-AI à ce jour",
                    .Page = "~/ValiderListes.aspx",
                    .Ressources = "payment-methods,tracking-categories,departments,locations,classes,tax-agencies,currencies",
                    .Note = 5,
                    .Fait = "Quatre listes lues, chacune dans sa table, avec leurs doublons et leurs " &
                            "éléments inutilisables signalés. Une nouvelle extraction remplace la " &
                            "liste du même genre, sans toucher aux autres.",
                    .Manque = "Rien ne s'applique : l'application n'a pas d'écran des modes de " &
                              "paiement ni des départements. Les comptes bancaires et les journaux " &
                              "ont été retirés — Apideck ne les expose pas chez QuickBooks."
                },
                New Poste With {
                    .Icone = "📉",
                    .Titre = "Balance âgée",
                    .Source = "QuickBooks : soldes en souffrance, clients et fournisseurs",
                    .Destination = "contrôle seulement — rien ne s'applique à la comptabilité",
                    .Page = "~/ValiderBalanceAgee.aspx",
                    .Ressources = "aged-debtors,aged-creditors",
                    .Note = 6,
                    .Fait = "Les tranches d'ancienneté redeviennent des colonnes, et le total est " &
                            "rapproché du solde des factures en préparation, tiers par tiers, par " &
                            "l'identifiant de la source. L'écart est nommé quand il y en a un.",
                    .Manque = "Le rapport est agrégé : aucun numéro de facture, donc un écart se " &
                              "constate sans qu'on sache quelle facture manque. Le rapprochement " &
                              "suppose que les deux extractions viennent de la même journée."
                },
                New Poste With {
                    .Icone = "📚",
                    .Titre = "Grand livre",
                    .Source = "QuickBooks : General Ledger, par la passerelle",
                    .Destination = "contrôle seulement — rien ne s'applique à la comptabilité",
                    .Page = "~/ValiderGrandLivre.aspx",
                    .Ressources = "general-ledger",
                    .Note = 6,
                    .Fait = "Chaque écriture est reprise sous le compte qu'elle touche, avec sa " &
                            "contrepartie, dans l'ordre de la source. Les colonnes sont demandées " &
                            "explicitement — sans quoi QuickBooks rend un solde cumulé sous " &
                            "l'entête « Crédit ». L'équilibre débit-crédit est vérifié à l'écran.",
                    .Manque = "Le rapport porte sur une période, du 1er janvier à la date " &
                              "indiquée : les soldes d'ouverture n'y sont pas, et il ne se " &
                              "compare donc pas compte à compte avec la balance de vérification."
                },
                New Poste With {
                    .Icone = "🧮",
                    .Titre = "Codes et taux de taxe",
                    .Source = "QuickBooks : les taux de taxe avec leurs composantes — ou saisis ici, ou par fichier",
                    .Destination = "préparation — staging.TaxeImport ; ce que la répartition lit pour couper TPS et TVQ",
                    .Page = "~/ValiderTaxes.aspx",
                    .Ressources = "tax-rates",
                    .Note = 8,
                    .Fait = "Montre chaque code de l'ancien logiciel avec son nom, ses composantes " &
                            "TPS et TVQ et le nombre de lignes de factures qui s'en servent ; signale " &
                            "les codes que les lignes portent sans qu'aucun taux ne les décrive. On " &
                            "ajoute ou corrige un taux à la main ou par fichier, la saisie survit au " &
                            "prochain rapatriement, et la répartition des factures se lance d'ici.",
                    .Manque = "Rien ne s'applique aux taxes de la comptabilité : ces taux ne servent " &
                              "qu'à couper les factures en préparation."
                },
                New Poste With {
                    .Icone = "📑",
                    .Titre = "Rapport de taxes",
                    .Source = "QuickBooks : taux de taxe, et le rapport TaxSummary par la passerelle",
                    .Destination = "les taux coupent la TPS et la TVQ des pièces ; le rapport, contrôle seulement",
                    .Page = "~/ValiderRapportTaxes.aspx",
                    .Ressources = "tax-rates,tax-summary",
                    .Note = 8,
                    .Fait = "Les taux arrivent avec leurs composantes, et le classement québécois " &
                            "est fait : un taux unique à 14,975 % ressort en TPS 5 % et TVQ 9,975 %. " &
                            "Ceux qui ne se répartissent pas — détaxé, exonéré, redressements — sont " &
                            "signalés avec leur motif plutôt que devinés. La répartition coupe ensuite " &
                            "les taxes des pièces en préparation et en déduit le sous-total, que la " &
                            "source ne donne jamais. Le rapport, lui, est la déclaration elle-même : " &
                            "les lignes du formulaire, 101 aux ventes, 106 le CTI, 206 le RTI, 217 le " &
                            "montant à payer ou à rembourser — une par administration fiscale, et " &
                            "rien ne s'applique à la comptabilité.",
                    .Manque = "Le rapport exige le paramètre agency_id, faute de quoi QuickBooks " &
                              "répond vide sans dire ce qui manque ; on interroge donc chaque " &
                              "administration déclarée. Il ne couvre pas les déclarations déjà " &
                              "produites une à une : il rend l'état de la période demandée, du " &
                              "1er janvier à la date d'arrêt."
                },
                New Poste With {
                    .Icone = "🏦",
                    .Titre = "Soldes bancaires",
                    .Source = "QuickBooks : les comptes de banque et de carte de crédit, par la passerelle",
                    .Destination = "contrôle seulement — rien ne s'applique à la comptabilité",
                    .Page = "~/ValiderSoldesBancaires.aspx",
                    .Ressources = "bank-accounts",
                    .Note = 6,
                    .Fait = "Les comptes de banque et de carte de crédit arrivent avec leur nature, " &
                            "leur devise, leur hiérarchie et leurs deux soldes — celui du compte " &
                            "seul et celui qui inclut les sous-comptes. La lecture est paginée : " &
                            "QuickBooks rend cent comptes et s'arrête là sans le dire, et un compte " &
                            "bancaire perdu au-delà ne se remarquerait qu'au rapprochement suivant.",
                    .Manque = "CE N'EST PAS LE RAPPROCHEMENT, et ça ne peut pas le devenir. Le " &
                              "rapport de rapprochement n'existe pas dans l'API — ReconciliationReport, " &
                              "Reconciliation, BankReconciliation et UnclearedTransactions sont tous " &
                              "refusés — et la colonne « pointé » demandée à TransactionList est " &
                              "silencieusement retirée de la réponse. T142ReleveBancaire reste donc " &
                              "vide : elle porte le relevé de LA BANQUE, et le fabriquer à partir des " &
                              "mouvements comptables reviendrait à rapprocher les livres d'eux-mêmes. " &
                              "Le solde, lui, est celui de l'instant de l'extraction : pour un solde " &
                              "arrêté à une date, c'est la balance de vérification qu'il faut lire."
                },
                New Poste With {
                    .Icone = "💵",
                    .Titre = "Acomptes et règlements partiels",
                    .Source = "QuickBooks : encaissements, décaissements et remboursements, avec leurs imputations",
                    .Destination = "staging.PaiementImport — contrôle avant reprise",
                    .Page = "~/ValiderReglements.aspx",
                    .Ressources = "payments,bill-payments,refunds",
                    .Note = 7,
                    .Fait = "Chaque mouvement arrive avec ses imputations : ce qu'il règle, et " &
                            "sur quel document. L'écran nomme les trois cas au lieu de laisser " &
                            "lire des chiffres — soldé, partiel, et acompte quand une part ne " &
                            "règle encore rien. Le « partiel » ne se devine pas : s0826 va " &
                            "chercher ce que vaut le document visé, et une imputation vers un " &
                            "document absent de la reprise est signalée plutôt que passée sous " &
                            "silence — c'est le signe qu'il manque une facture.",
                    .Manque = "L'acompte est repris comme un montant non imputé, pas comme un " &
                              "document : il faudra décider à quel compte il s'impute à la " &
                              "création. Et l'imputation dépend des factures — reprenez-les " &
                              "avant, sinon tout ressort « document absent »."
                },
                New Poste With {
                    .Icone = "🔍",
                    .Titre = "Opérations non rapprochées",
                    .Source = "QuickBooks : la colonne is_cleared de la liste des opérations, par la passerelle",
                    .Destination = "contrôle seulement — T142ReleveBancaire n'est pas touchée",
                    .Page = "~/ValiderNonRapprochees.aspx",
                    .Ressources = "uncleared",
                    .Note = 7,
                    .Fait = "À la bascule la base est vide : c'est le pointage de la source qui " &
                            "fait foi, et il est repris tel quel. La lettre est conservée en plus " &
                            "du oui/non — « C » compensée, « R » rapprochée dans un rapprochement " &
                            "clos — parce que les deux états ne se valent pas. L'écran s'ouvre sur " &
                            "ce qui reste en suspens, groupé par compte, avec le montant total.",
                    .Manque = "Il n'existe PAS de rapport « opérations non rapprochées » dans " &
                              "l'API — cherché, refusé trois fois. C'est une colonne de la liste " &
                              "des opérations, et elle s'appelle « is_cleared » : demandée sous un " &
                              "autre nom, QuickBooks la retire de la réponse sans rien dire. Le " &
                              "lecteur repère donc les colonnes par leur clé et s'arrête si " &
                              "celle-ci manque. Une opération qui ne touche aucun compte bancaire " &
                              "ressort non pointée, ce qui est exact mais sans portée."
                },
                New Poste With {
                    .Icone = "🧾",
                    .Titre = "Paie",
                    .Source = "QuickBooks : l'entité Employee par la passerelle pour les employés ; la paie elle-même n'est pas exposée",
                    .Destination = "staging.PaieEmployeImport, PaieLotImport, PaieImport, PaieLigneImport",
                    .Page = "~/ValiderPaie.aspx",
                    .Ressources = "employees-native",
                    .Note = 4,
                    .Fait = "Les quatre tables de la reprise sont en place et chargées d'un seul " &
                            "coup, en une transaction : employés, lots, paies et lignes de talon. " &
                            "L'équilibre — brut moins retenues égale net — est vérifié à " &
                            "l'arrivée, et un écart est SIGNALÉ sans jamais être corrigé : on " &
                            "reprend ce qui a été versé, pas ce qui aurait dû l'être, sinon la " &
                            "reprise diverge des T4 et relevés 1 déjà produits. Le NAS et le " &
                            "numéro de compte ne sont pas repris — seulement de quoi savoir ce " &
                            "qu'il restera à saisir.",
                    .Manque = "LA SOURCE NE DONNE RIEN. L'entité Employee revient vide (trois " &
                              "essais), TimeActivity aussi, /accounting/employees répond 404 pour " &
                              "ce connecteur et l'API HRIS d'Apideck répond 401 : la paie de " &
                              "QuickBooks est un produit séparé qui ne passe pas par cette porte. " &
                              "Le point d'arrivée est donc prêt avant la porte d'entrée — la " &
                              "reprise viendra d'un fichier ou d'un autre connecteur. Ce qui est " &
                              "en préparation aujourd'hui est simulé, et le registre le dit."
                },
                New Poste With {
                    .Icone = "🏛️",
                    .Titre = "Remises de DAS",
                    .Source = "QuickBooks : les comptes de retenues du grand livre, par la passerelle",
                    .Destination = "contrôle seulement — ce qui reste dû au fédéral et au Québec",
                    .Page = "~/ValiderRemisesDas.aspx",
                    .Ressources = "das",
                    .Note = 6,
                    .Fait = "Les retenues s'accumulent au crédit d'un compte de passif à chaque " &
                            "paie et s'éteignent au débit à chaque remise : la différence est la " &
                            "dette envers chaque autorité, et c'est elle que la bascule doit " &
                            "reprendre. L'écran la donne par autorité, avec le détail des " &
                            "mouvements en dessous.",
                    .Manque = "PAS PAR LA PAIE. L'API HRIS d'Apideck répond 401 et le compte n'a " &
                              "qu'une connexion — « accounting / quickbooks » : les remises ne " &
                              "sont pas récupérables comme objets de paie. Elles le sont comme " &
                              "PAIEMENTS, dans le grand livre, et c'est par là qu'on passe. " &
                              "L'autorité est donc devinée au nom du compte : ce qui ne tranche " &
                              "pas ressort « À classer » plutôt que d'être rangé de force, parce " &
                              "qu'une remise fédérale comptée au Québec, c'est deux déclarations " &
                              "fausses."
                },
                New Poste With {
                    .Icone = "📦",
                    .Titre = "Inventaire",
                    .Source = "QuickBooks : l'entité Item, par la passerelle",
                    .Destination = "contrôle seulement — rapproché du compte d'actif de stock",
                    .Page = "~/ValiderInventaire.aspx",
                    .Ressources = "inventory",
                    .Note = 6,
                    .Fait = "Quantité en main, coût unitaire et compte de stock par article, avec " &
                            "la valeur calculée à côté de ses deux facteurs. L'écran rapproche la " &
                            "somme des articles du solde du compte d'actif de stock au grand " &
                            "livre : c'est la seule vérification qui attrape une reprise " &
                            "silencieusement fausse. Deux anomalies sont nommées — quantité " &
                            "négative, et quantité en main sans coût — et remontent en tête.",
                    .Manque = "La quantité est celle du JOUR de l'extraction : QuickBooks ne rend " &
                              "pas « le stock au 30 juin ». Le rapport InventoryValuationSummary " &
                              "n'apporte rien de plus — deux colonnes, dont une « Calcul " &
                              "Moyenne » — alors on lit l'entité Item directement. La lecture est " &
                              "paginée : cette compagnie a 214 articles, et sans cela on en " &
                              "perdrait 114."
                },
                New Poste With {
                    .Icone = "📎",
                    .Titre = "Pièces jointes",
                    .Source = "QuickBooks : l'entité Attachable, par la passerelle — tout ce qui est attaché, à qui que ce soit",
                    .Destination = "préparation — staging.PieceJointeImport, fichiers compris",
                    .Page = "~/ValiderPiecesJointes.aspx",
                    .Ressources = "attachments-all",
                    .Note = 5,
                    .Fait = "Toutes les pièces, quelle que soit l'entité porteuse — client, " &
                            "fournisseur, article, dépense, écriture — avec le fichier lui-même " &
                            "téléchargé pendant l'extraction et gardé en préparation, jusqu'à " &
                            "25 Mo par pièce. L'écran les montre par entité, dit lesquelles sont " &
                            "déjà retrouvées ici, et ouvre chaque fichier.",
                    .Manque = "Rien n'est rattaché aux fiches de l'application : on ne sait pas " &
                              "encore où 60Sec-AI range un fichier sur un client. Le lien de " &
                              "téléchargement de QuickBooks n'est valable que quelques minutes ; " &
                              "une pièce qui a échoué se relit à la prochaine extraction."
                },
                New Poste With {
                    .Icone = "🏧",
                    .Titre = "Dépôts et virements bancaires",
                    .Source = "QuickBooks : les entités Deposit et Transfer, par la passerelle",
                    .Destination = "contrôle seulement — staging.MouvementBancaireImport, avec les lignes des dépôts",
                    .Page = "~/ValiderMouvementsBancaires.aspx",
                    .Ressources = "bank-movements",
                    .Note = 5,
                    .Fait = "Chaque dépôt avec ses lignes — le montant, la contrepartie, le tiers, " &
                            "le mode de paiement, l'encaissement d'origine — et chaque virement " &
                            "avec ses deux comptes. Par genre, avec le total et la période.",
                    .Manque = "Rien n'est créé : ni règlement, ni ligne de relevé. C'est une pièce " &
                              "de contrôle pour le premier rapprochement bancaire."
                },
                New Poste With {
                    .Icone = "🔁",
                    .Titre = "Transactions récurrentes",
                    .Source = "QuickBooks : l'entité RecurringTransaction, par la passerelle",
                    .Destination = "contrôle seulement — staging.TransactionRecurrenteImport, modèle complet gardé",
                    .Page = "~/ValiderRecurrentes.aspx",
                    .Ressources = "recurring-transactions",
                    .Note = 5,
                    .Fait = "Chaque modèle avec son type, sa cadence dite en clair, son tiers, son " &
                            "montant et sa prochaine échéance. Les suspendus sont grisés.",
                    .Manque = "60Sec-AI n'a pas de transactions récurrentes : la liste dit ce qu'il " &
                              "faudra recréer à la main, et quand."
                },
                New Poste With {
                    .Icone = "🎯",
                    .Titre = "Budgets",
                    .Source = "QuickBooks : l'entité Budget, par la passerelle",
                    .Destination = "contrôle seulement — staging.BudgetImport, une ligne par compte et par période",
                    .Page = "~/ValiderBudgets.aspx",
                    .Ressources = "budgets",
                    .Note = 5,
                    .Fait = "Chaque budget, puis ses lignes par compte avec le sous-total du compte " &
                            "et le total, et la ventilation par client, classe ou département " &
                            "quand la source l'a faite.",
                    .Manque = "Les comptes sont des noms ; rien n'est repris dans un budget d'ici, " &
                              "qui n'existe pas encore."
                },
                New Poste With {
                    .Icone = "⏱️",
                    .Titre = "Feuilles de temps",
                    .Source = "QuickBooks : l'entité TimeActivity, par la passerelle",
                    .Destination = "contrôle seulement — staging.FeuilleTempsImport",
                    .Page = "~/ValiderFeuillesTemps.aspx",
                    .Ressources = "time-activities",
                    .Note = 5,
                    .Fait = "Par personne, les heures saisies et celles qui restent à facturer ; " &
                            "puis chaque activité avec le client, l'article, la durée, le taux et " &
                            "son état de facturation.",
                    .Manque = "Le temps à facturer n'est pas transformé en factures : c'est ce que " &
                              "la bascule doit régler avant de fermer la source."
                }
            }))
        End Get
    End Property
    ''' <summary>
    ''' Les listes : clients, fournisseurs, produits et services. Un même écran,
    ''' trois usages — lire le fichier ou l'extraire par l'IA, rapprocher de ce
    ''' qui existe, créer ce qui est nouveau.
    ''' </summary>
    Private ReadOnly Property Autres As List(Of Poste)
        Get
            Return NoterAvancement(New List(Of Poste) From {
                New Poste With {
                    .Icone = "👥",
                    .Titre = "Clients",
                    .Source = "QuickBooks : Ventes ▸ Clients ▸ Exporter",
                    .Destination = "T050Party + T054PartyAddress",
                    .Page = "~/ImportClients.aspx",
                    .Note = 8,
                    .Fait = "Lit l'export tel quel, ou l'extrait par l'IA quand il est mal formé ; " &
                            "signale ce qui existe déjà et ce que le fichier répète, puis crée les " &
                            "nouveaux clients et leur adresse.",
                    .Manque = "Ne met pas à jour un client existant. Le solde du client n'est pas " &
                              "repris : il viendra des factures ouvertes."
                },
                New Poste With {
                    .Icone = "🏭",
                    .Titre = "Fournisseurs",
                    .Source = "QuickBooks : Dépenses ▸ Fournisseurs ▸ Exporter",
                    .Destination = "T050Party + T054PartyAddress",
                    .Page = "~/ImportFournisseurs.aspx",
                    .Note = 8,
                    .Fait = "Lit l'export tel quel, ou l'extrait par l'IA quand il est mal formé ; " &
                            "signale ce qui existe déjà et ce que le fichier répète, puis crée les " &
                            "nouveaux fournisseurs et leur adresse.",
                    .Manque = "Ne met pas à jour un fournisseur existant, et n'en fait pas un client-" &
                              "fournisseur s'il est déjà client. Le solde dû viendra des factures ouvertes."
                },
                New Poste With {
                    .Icone = "🏷️",
                    .Titre = "Produits et services",
                    .Source = "QuickBooks : Ventes ▸ Produits et services ▸ Exporter",
                    .Destination = "T075Products",
                    .Page = "~/ImportProduits.aspx",
                    .Note = 8,
                    .Fait = "Lit l'export ou l'extrait par l'IA ; reprend le nom, la description, " &
                            "le prix de vente et la taxabilité ; n'en crée aucun en double.",
                    .Manque = "Chaque produit prend les comptes de revenus et de dépenses par défaut " &
                              "de la compagnie ; la catégorie et l'inventaire restent à reprendre."
                }
            })
        End Get
    End Property

    ''' <summary>
    ''' Ce qui reste à bâtir, dans l'ordre d'une reprise complète. Les nommer
    ''' ici plutôt que les taire : une page qui ne montre que le fait donne
    ''' l'illusion d'être au bout.
    ''' </summary>
    Private ReadOnly Property AVenir As List(Of Poste)
        Get
            ' Plus rien. Tous les postes de la reprise ont leur rail et leur écran —
            ' ce qui reste à faire est écrit dans le « Manque » de chacun, là où ça
            ' se lit au moment de s'en servir.
            Return New List(Of Poste)
        End Get
    End Property

#End Region

#Region "L'avancement du plan comptable"

    ''' <summary>Où en est la reprise du plan comptable de cette compagnie.</summary>
    Private Class EtatPlan
        Public Property Note As Integer
        Public Property Fait As String = ""
        Public Property Manque As String = ""
    End Class

    ''' <summary>
    ''' La note du plan comptable suit la reprise elle-même, pas l'état du code :
    ''' 0 tant qu'aucun plan n'est chargé ; 2 dès qu'il l'est ; jusqu'à 5 points
    ''' pour la part des comptes décidés à l'étape 2 ; jusqu'à 3 points pour la
    ''' part des comptes « Créer » réellement créés à l'étape 3. Dix veut dire
    ''' « tout décidé, tout créé » : tant qu'il reste un compte à décider ou à
    ''' créer, la note plafonne à 9. Les décomptes sont ceux de l'étape 3 (s0766).
    ''' </summary>
    Private Function EtatPlanComptable() As EtatPlan
        Dim etat As New EtatPlan With {.Note = 0}

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0766GetAAppliquer", p)

            If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(1).Rows.Count = 0 Then
                etat.Fait = "Aucun plan comptable chargé pour cette compagnie : la note montera " &
                            "avec la reprise."
                etat.Manque = "Charger le plan (étape 1), décider la correspondance (étape 2), créer les comptes (étape 3)."
                Return etat
            End If

            Dim r As DataRow = ds.Tables(1).Rows(0)
            Dim total As Integer = Entier(r("Total"))
            Dim aCreer As Integer = Entier(r("ACreer"))
            Dim crees As Integer = Entier(r("DejaCrees"))
            Dim lies As Integer = Entier(r("Lies"))
            Dim ignores As Integer = Entier(r("Ignores"))
            Dim aDecider As Integer = Entier(r("ADecider"))

            If total = 0 Then
                etat.Fait = "Aucun plan comptable chargé pour cette compagnie : la note montera " &
                            "avec la reprise."
                etat.Manque = "Charger le plan (étape 1), décider la correspondance (étape 2), créer les comptes (étape 3)."
                Return etat
            End If

            Dim decides As Integer = total - aDecider
            Dim partDecidee As Double = decides / total
            Dim partCreee As Double = If(aCreer + crees = 0, 1.0, crees / CDbl(aCreer + crees))

            etat.Note = 2 + CInt(Math.Round(5 * partDecidee)) + CInt(Math.Round(3 * partCreee))
            If (aDecider > 0 OrElse aCreer > 0) AndAlso etat.Note >= 10 Then etat.Note = 9
            If aDecider = 0 AndAlso aCreer = 0 Then etat.Note = 10

            etat.Fait = "Plan chargé : " & total & " compte(s), " & decides & " décidé(s) (" &
                        lies & " lié(s), " & ignores & " ignoré(s), " & crees & " créé(s))."

            If aDecider > 0 OrElse aCreer > 0 Then
                Dim bouts As New List(Of String)
                If aDecider > 0 Then bouts.Add(aDecider & " compte(s) à décider à l'étape 2")
                If aCreer > 0 Then bouts.Add(aCreer & " compte(s) à créer à l'étape 3")
                etat.Manque = "Reste : " & String.Join(" ; ", bouts) & "."
            End If

        Catch ex As Exception
            etat.Note = 0
            etat.Fait = "L'avancement du plan n'a pas pu être lu : " & ex.Message
        End Try

        Return etat
    End Function

    Private Shared Function Entier(v As Object) As Integer
        Return If(v Is Nothing OrElse IsDBNull(v), 0, Convert.ToInt32(v))
    End Function

#End Region

#Region "La dernière extraction"

    ''' <summary>
    ''' Ce que la dernière extraction de la compagnie permet de dire sur la carte
    ''' du connecteur : sa note, ce qui a marché, ce qui a manqué.
    ''' </summary>
    Private Class Extraction
        Public Property Note As Integer
        Public Property Fait As String = ""
        Public Property Manque As String = ""
    End Class

    Private _extraction As Extraction

    ''' <summary>
    ''' Lit la dernière extraction fermée (s0892) et la traduit en note : la part
    ''' des ressources demandées qui ont répondu, sur 10. Une extraction qui a
    ''' connu un échec ne monte jamais à 10, même quand l'arrondi le voudrait —
    ''' 10 veut dire « tout est là ». Sans extraction : 0, et la carte le dit.
    '''
    ''' Les extractions antérieures à T308 n'ont pas leurs décomptes : on relit
    ''' alors la phrase qu'elles ont laissée (« K ressource(s) en échec sur N »),
    ''' et faute de mieux, TERMINE vaut 10 et PARTIEL vaut 5.
    ''' </summary>
    Private Function DerniereExtraction() As Extraction
        If _extraction IsNot Nothing Then Return _extraction

        Dim ext As New Extraction With {.Note = 0}
        _extraction = ext

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0892GetDerniereExtraction", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ext.Fait = "Aucune extraction encore pour cette compagnie : la note montera avec " &
                       "les ressources rapatriées."
            ext.Manque = "Relier QuickBooks, puis lancer l'extraction."
            Return ext
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim statut As String = Convert.ToString(r("Statut"))
        Dim quand As String = Convert.ToDateTime(r("Debut")).ToString("yyyy-MM-dd HH:mm")
        Dim enregistrements As Integer = Convert.ToInt32(r("NbEnregistrements"))
        Dim note As String = If(IsDBNull(r("Note")), "", Convert.ToString(r("Note")))

        Dim demandees As Integer = 0, echecs As Integer = 0

        If Not IsDBNull(r("NbDemandees")) Then
            demandees = Convert.ToInt32(r("NbDemandees"))
            If Not IsDBNull(r("NbEchecs")) Then echecs = Convert.ToInt32(r("NbEchecs"))
        Else
            Dim m = Text.RegularExpressions.Regex.Match(note, "(\d+) ressource\(s\) en échec sur (\d+)")
            If m.Success Then
                echecs = CInt(m.Groups(1).Value)
                demandees = CInt(m.Groups(2).Value)
            End If
        End If

        If demandees > 0 Then
            ext.Note = CInt(Math.Round(10.0 * (demandees - echecs) / demandees))
            If echecs > 0 AndAlso ext.Note >= 10 Then ext.Note = 9
            If echecs < demandees AndAlso ext.Note <= 0 Then ext.Note = 1
        Else
            ext.Note = If(statut = "TERMINE", 10, 5)
        End If

        ext.Fait = "Dernière extraction le " & quand & " : "
        If demandees > 0 Then
            ext.Fait &= (demandees - echecs) & " ressource(s) sur " & demandees & " rapatriée(s), "
        End If
        ext.Fait &= enregistrements.ToString("N0") & " enregistrement(s) déposés en préparation."

        If echecs > 0 Then
            ext.Manque = If(note <> "", note, echecs & " ressource(s) n'ont pas répondu à la dernière extraction.") &
                         " Relancez l'extraction : ce qui a réussi reste déposé."
        End If

        Return ext
    End Function

    ''' <summary>Une ressource Apideck, telle que sa dernière lecture l'a laissée.</summary>
    Private Class EtatRessource
        Public Property Nb As Integer
        Public Property Reussie As Boolean
        Public Property Erreur As String = ""
        Public Property Quand As Date
    End Class

    Private _etats As Dictionary(Of String, EtatRessource)

    ''' <summary>La dernière issue de chaque ressource déjà lue (s0894), lue une fois par page.</summary>
    Private Function EtatsRessources() As Dictionary(Of String, EtatRessource)
        If _etats IsNot Nothing Then Return _etats
        _etats = New Dictionary(Of String, EtatRessource)(StringComparer.OrdinalIgnoreCase)

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0894GetEtatRessources", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return _etats

        For Each r As DataRow In ds.Tables(0).Rows
            _etats(Convert.ToString(r("Ressource"))) = New EtatRessource With {
                .Nb = Convert.ToInt32(r("Nb")),
                .Reussie = Convert.ToBoolean(r("Reussie")),
                .Erreur = If(IsDBNull(r("Erreur")), "", Convert.ToString(r("Erreur"))),
                .Quand = Convert.ToDateTime(r("Quand"))
            }
        Next

        Return _etats
    End Function

    ''' <summary>
    ''' Les cartes qui lisent des ressources sont notées comme le connecteur :
    ''' la part de leurs ressources dont la dernière lecture a réussi, sur 10.
    ''' Tout lu, 10 ; une ressource en échec ou jamais lue, 9 au plus ; rien de
    ''' lu encore, 0. Ce que l'écran sait faire reste écrit à la suite ; ce qui
    ''' a échoué est nommé en tête de « ce qui manque », avec son motif.
    ''' </summary>
    Private Function NoterRessources(postes As List(Of Poste)) As List(Of Poste)
        Dim etats As Dictionary(Of String, EtatRessource) = EtatsRessources()

        For Each poste In postes
            If poste.Ressources = "" Then Continue For

            Dim cles As List(Of String) = poste.Ressources.Split(","c).
                Select(Function(c) c.Trim()).Where(Function(c) c <> "").ToList()
            Dim lues As List(Of String) = cles.Where(Function(c) etats.ContainsKey(c)).ToList()
            Dim reussies As List(Of String) = lues.Where(Function(c) etats(c).Reussie).ToList()
            Dim echecs As List(Of String) = lues.Where(Function(c) Not etats(c).Reussie).ToList()

            If lues.Count = 0 Then
                poste.Note = 0
                poste.Fait = "Aucune extraction encore pour cette compagnie. " & poste.Fait
                Continue For
            End If

            poste.Note = CInt(Math.Round(10.0 * reussies.Count / cles.Count))
            If reussies.Count < cles.Count AndAlso poste.Note >= 10 Then poste.Note = 9
            If reussies.Count > 0 AndAlso poste.Note <= 0 Then poste.Note = 1

            Dim quand As Date = lues.Max(Function(c) etats(c).Quand)
            Dim nb As Integer = reussies.Sum(Function(c) etats(c).Nb)
            poste.Fait = "Dernière extraction le " & quand.ToString("yyyy-MM-dd HH:mm") & " : " &
                         reussies.Count & " ressource(s) sur " & cles.Count & " rapatriée(s), " &
                         nb.ToString("N0") & " enregistrement(s). " & poste.Fait

            If reussies.Count < cles.Count Then
                Dim bouts As New List(Of String)
                For Each c As String In echecs
                    bouts.Add(c & " : " & etats(c).Erreur.TrimEnd("."c))
                Next
                For Each c As String In cles.Where(Function(x) Not etats.ContainsKey(x))
                    bouts.Add(c & " : jamais lue")
                Next
                poste.Manque = "En échec — " & String.Join(" ; ", bouts) & ". " & poste.Manque
            End If
        Next

        Return postes
    End Function

#End Region

#Region "Rendu"

    ''' <summary>
    ''' L'ordre d'importance des postes, celui d'une reprise : ce qui structure
    ''' d'abord (plan, balance), puis les tiers et les articles, puis les
    ''' documents, puis ce qui ne sert qu'au contrôle. Un poste absent de la
    ''' liste passe en queue, par son titre.
    ''' </summary>
    Private Shared ReadOnly OrdreImportance As String() = {
        "Plan comptable",
        "Balance de vérification",
        "Clients",
        "Fournisseurs",
        "Produits et services",
        "Factures clients et fournisseurs",
        "Codes et taux de taxe",
        "Acomptes et règlements partiels",
        "Comparer la fiche d'entreprise",
        "Grand livre",
        "Balance âgée",
        "Rapport de taxes",
        "Soldes bancaires",
        "Opérations non rapprochées",
        "Dépôts et virements bancaires",
        "Listes de structure",
        "Inventaire",
        "Pièces jointes",
        "Transactions récurrentes",
        "Budgets",
        "Feuilles de temps",
        "Paie",
        "Remises de DAS"
    }

    ''' <summary>
    ''' Les postes sans lesquels rien ne se comptabilise : le plan et la balance
    ''' (la structure et les soldes d'ouverture), les tiers et les articles (pour
    ''' porter des factures), les factures elles-mêmes et les codes de taxe. Tout
    ''' le reste vérifie la reprise sans la conditionner : ce sont les écrans de
    ''' contrôle. Un poste se déplace d'une section à l'autre en changeant cette liste.
    ''' </summary>
    Private Shared ReadOnly Obligatoires As String() = {
        "Plan comptable",
        "Balance de vérification",
        "Clients",
        "Fournisseurs",
        "Produits et services",
        "Factures clients et fournisseurs",
        "Codes et taux de taxe"
    }
    Private Shared Function EstObligatoire(titre As String) As Boolean
        Return Array.IndexOf(Obligatoires, titre) >= 0
    End Function
    Private Shared Function RangImportance(titre As String) As Integer
        Dim i As Integer = Array.IndexOf(OrdreImportance, titre)
        Return If(i < 0, OrdreImportance.Length, i)
    End Function

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        PreparerVidage()

        If IsPostBack Then Return

        ' Trois sections : le connecteur en tête, pleine largeur ; puis les postes
        ' obligatoires pour la comptabilité, dans l'ordre d'une reprise ; puis les
        ' écrans de contrôle. La numérotation court d'une section à l'autre pour que
        ' l'ordre se lise sans le deviner.
        Dim connexion As List(Of Poste) = Me.Connexion
        Dim postes As List(Of Poste) = connexion.Skip(1).Concat(Parcours).Concat(Autres).
            OrderBy(Function(p) RangImportance(p.Titre)).ThenBy(Function(p) p.Titre).ToList()
        Dim obligatoires As List(Of Poste) = postes.Where(Function(p) EstObligatoire(p.Titre)).ToList()
        Dim controles As List(Of Poste) = postes.Where(Function(p) Not EstObligatoire(p.Titre)).ToList()

        Dim rang As Integer = 0
        For Each p In obligatoires.Concat(controles)
            rang += 1
            p.Titre = rang & ". " & p.Titre
        Next

        litConnexion.Text = Rendre(connexion.Take(1).ToList())
        litParcours.Text = Rendre(obligatoires)
        litAutres.Text = Rendre(controles)
        ' La section « À construire » disparaît quand il n'y a plus rien à
        ' construire : un titre suivi du vide ressemble à un écran cassé.
        Dim reste As List(Of Poste) = AVenir
        If reste.Count > 0 Then
            litTitreAVenir.Text = "<h2 class='sect'>À construire " &
                                  "<span>l'ordre d'une reprise complète</span></h2>"
            litAVenir.Text = Rendre(reste)
        Else
            litTitreAVenir.Text = ""
            litAVenir.Text = ""
        End If

        AfficherAvancement()
    End Sub

    ''' <summary>
    ''' L'avancement de l'ensemble : la moyenne mentirait — un écran fini et
    ''' neuf écrans vides donneraient une note flatteuse. On compte donc ce qui
    ''' est réellement utilisable.
    ''' </summary>
    Private Sub AfficherAvancement()
        Dim tous = New List(Of Poste)
        tous.AddRange(Connexion)
        tous.AddRange(Parcours)
        tous.AddRange(Autres)
        tous.AddRange(AVenir)

        litTotal.Text = tous.Count.ToString()
        litUtilisables.Text = tous.Where(Function(p) p.Note >= 7).Count.ToString()
        litPartiels.Text = tous.Where(Function(p) p.Note >= 2 AndAlso p.Note < 7).Count.ToString()
        litAFaire.Text = tous.Where(Function(p) p.Note <= 1).Count.ToString()
    End Sub

    Private Function Rendre(postes As List(Of Poste)) As String
        Dim sb As New StringBuilder()

        For Each p In postes
            Dim cliquable = (p.Page <> "")

            sb.Append("<div class='carte")
            If Not cliquable Then sb.Append(" inerte")
            sb.Append("'>")

            ' ── L'entête ────────────────────────────────────────────────────
            sb.Append("<div class='chef'>")
            sb.Append("<span class='ico'>").Append(p.Icone).Append("</span>")
            sb.Append("<div class='ident'>")

            If p.Etape <> "" Then
                sb.Append("<span class='etape'>Étape ").Append(p.Etape).Append("</span>")
            End If

            sb.Append("<div class='titre'>").Append(Server.HtmlEncode(p.Titre)).Append("</div>")
            sb.Append("<div class='src'>").Append(Server.HtmlEncode(p.Source)).Append("</div>")
            sb.Append("</div>")

            sb.Append("<div class='note ").Append(Teinte(p.Note)).Append("'>")
            sb.Append("<b>").Append(p.Note).Append("</b><span>/10</span>")
            sb.Append("</div>")
            sb.Append("</div>")

            ' ── La jauge ────────────────────────────────────────────────────
            sb.Append("<div class='jauge'><div class='").Append(Teinte(p.Note))
            sb.Append("' style='width:").Append(p.Note * 10).Append("%'></div></div>")

            ' ── Ce qu'on peut en dire ───────────────────────────────────────
            If p.Destination <> "" Then
                sb.Append("<div class='dest'>→ ").Append(Server.HtmlEncode(p.Destination)).Append("</div>")
            End If

            If p.Fait <> "" Then
                sb.Append("<p class='fait'><b>Ce qui fonctionne.</b> ")
                sb.Append(Server.HtmlEncode(p.Fait)).Append("</p>")
            End If

            If p.Manque <> "" Then
                sb.Append("<p class='manque'><b>Ce qui manque.</b> ")
                sb.Append(Server.HtmlEncode(p.Manque)).Append("</p>")
            End If

            ' ── L'accès ─────────────────────────────────────────────────────
            If cliquable Then
                sb.Append("<a class='ouvrir' href='").Append(ResolveUrl(p.Page)).Append("'>Ouvrir →</a>")
            Else
                sb.Append("<span class='absent'>Écran non construit</span>")
            End If

            sb.Append("</div>")
        Next

        Return sb.ToString()
    End Function

    ''' <summary>La couleur suit la note, pour que l'état se voie sans lire.</summary>
    Private Shared Function Teinte(note As Integer) As String
        If note >= 8 Then Return "vert"
        If note >= 5 Then Return "jaune"
        If note >= 2 Then Return "orange"
        Return "gris"
    End Function

#End Region


#Region "Vider la préparation"

    ''' <summary>
    ''' Le staging est un brouillon : on relit la même comptabilité plusieurs fois
    ''' avant d'appliquer quoi que ce soit, et il faut pouvoir repartir à zéro
    ''' entre deux essais. Ce bouton efface la préparation de CETTE compagnie —
    ''' pas des autres, et jamais la comptabilité elle-même.
    '''
    ''' Le garde-fou est côté navigateur : le geste est irréversible et mérite
    ''' d'être confirmé une fois. Piège maison : les asp:Button de l'ERP sont
    ''' rendus en type="button", donc un OnClientClick qui commence par « return »
    ''' avale le postback et le bouton ne fait plus rien. D'où le « return false »
    ''' à l'intérieur du test, et lui seul.
    ''' </summary>
    Private Sub PreparerVidage()
        litViderCie.Text = Server.HtmlEncode(If(CompanyName, "cette compagnie"))

        ' Le nom part dans un littéral JavaScript, lui-même dans un attribut HTML
        ' entre guillemets doubles : l'apostrophe s'échappe, le guillemet s'enlève.
        Dim nom As String = If(CompanyName, "cette compagnie")
        nom = nom.Replace("\", "\\").Replace("'", "\'").Replace("""", "")

        Dim question As String =
            "Vider toutes les tables de préparation de " & nom & " ?\n\n" &
            "Tout ce qui attend une validation sera effacé et devra être réimporté. " &
            "Ce qui est déjà passé en comptabilité n'est pas touché."

        btnVider.OnClientClick = "if (!confirm('" & question & "')) { return false; }"
    End Sub

    Protected Sub btnVider_Click(sender As Object, e As EventArgs) Handles btnVider.Click
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))

            Dim ds As DataSet = ExecuteSQLds("s0790ViderStaging", p)
            litViderEtat.Text = ResumerVidage(ds)

        Catch ex As Exception
            litViderEtat.Text = "<div class=""fait"" style=""color:#b91c1c"">Le vidage a échoué : " &
                                Server.HtmlEncode(ex.Message) & "</div>"
        End Try
    End Sub

    ''' <summary>
    ''' Ce qui a été effacé, table par table. Un simple « c'est fait » laisserait
    ''' planer un doute sur ce qui est parti ; le détail lève ce doute.
    ''' </summary>
    Private Function ResumerVidage(ds As DataSet) As String
        If ds Is Nothing OrElse ds.Tables.Count < 2 Then Return "<div class=""fait"">Préparation vidée.</div>"

        Dim total As Integer = 0
        If ds.Tables(1).Rows.Count > 0 AndAlso Not IsDBNull(ds.Tables(1).Rows(0)("Total")) Then
            total = Convert.ToInt32(ds.Tables(1).Rows(0)("Total"))
        End If

        If total = 0 Then Return "<div class=""fait"">La préparation était déjà vide.</div>"

        Dim sb As New StringBuilder()
        sb.Append("<div class=""fait"">Préparation vidée : ").Append(total).Append(" ligne(s) — ")

        Dim bouts As New List(Of String)
        For Each r As DataRow In ds.Tables(0).Rows
            bouts.Add(Server.HtmlEncode(Convert.ToString(r("Table"))) & " " & Convert.ToString(r("Lignes")))
        Next
        sb.Append(String.Join(", ", bouts.ToArray())).Append(".</div>")

        Return sb.ToString()
    End Function

#End Region

End Class
