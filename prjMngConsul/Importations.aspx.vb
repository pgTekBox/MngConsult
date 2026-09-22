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
    End Class

    ''' <summary>
    ''' La reprise du plan comptable : une seule boîte, qui mène à l'étape 1.
    ''' Le détail de chaque étape — ce qui fonctionne, ce qui manque — vit sur
    ''' l'écran lui-même, sous le fil des étapes. La note est celle de l'étape
    ''' la plus faible : un parcours ne vaut pas mieux.
    ''' La balance de vérification vient à côté : c'est la cible du contrôle final.
    ''' </summary>
    Private ReadOnly Property Parcours As List(Of Poste)
        Get
            Return New List(Of Poste) From {
                New Poste With {
                    .Icone = "📊",
                    .Titre = "Plan comptable",
                    .Source = "QuickBooks : Liste des comptes (Account List)",
                    .Destination = "comptabilité — T121PlanComptable, en trois étapes",
                    .Page = "~/ImportPlanComptable.aspx",
                    .Note = EtapesReprise.NoteParcours,
                    .Fait = "Importer le fichier, décider de la correspondance de chaque compte, " &
                            "puis créer au plan ceux qui manquent. Chaque écran dit lui-même " &
                            "ce qui y fonctionne et ce qui y manque."
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
            }
        End Get
    End Property

    ''' <summary>
    ''' La lecture directe, par connecteur. Les autres postes partent d'un
    ''' fichier que le client a exporté ; celui-ci part de sa comptabilité
    ''' elle-même. Il est à part parce qu'il ne remplace aucun écran : il les
    ''' alimente. Ce qu'il rapatrie se dépose en préparation, et les écrans
    ''' ci-dessous décident ensuite de ce qui est créé.
    ''' </summary>
    Private ReadOnly Property Connexion As List(Of Poste)
        Get
            Return New List(Of Poste) From {
                New Poste With {
                    .Icone = "🔌",
                    .Titre = "QuickBooks, en direct",
                    .Source = "Apideck : lecture de la comptabilité source, sans export",
                    .Destination = "préparation — staging.ConnecteurDonnee, puis les écrans ci-dessous",
                    .Page = "~/ImportApideck.aspx",
                    .Note = 6,
                    .Fait = "Le client relie son QuickBooks une fois ; chaque extraction ramène " &
                            "les vingt-sept ressources d'Apideck en préparation. Douze sont en plus " &
                            "interprétées : le plan comptable, les clients, les fournisseurs et les " &
                            "produits rejoignent les écrans d'import existants ; les factures clients " &
                            "et fournisseurs sont déposées avec leurs lignes, leur tiers reconnu et " &
                            "leur verdict, prêtes à être validées une par une.",
                    .Manque = "Les quinze autres " &
                              "ressources se déposent sans être interprétées. Sage passera par le " &
                              "même chemin, c'est un autre connecteur d'Apideck."
                },
                New Poste With {
                    .Icone = "🧾",
                    .Titre = "Valider les factures importées",
                    .Source = "ce que l'extraction a déposé, clients et fournisseurs",
                    .Destination = "T060Document + T061DocumentLine, en brouillon",
                    .Page = "~/ValiderFactures.aspx",
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
                    .Source = "modes de paiement, catégories de suivi, départements, emplacements",
                    .Destination = "préparation seulement — aucune destination dans 60Sec-AI à ce jour",
                    .Page = "~/ValiderListes.aspx",
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
                    .Titre = "Taxes",
                    .Source = "QuickBooks : taux de taxe, et le rapport TaxSummary par la passerelle",
                    .Destination = "les taux coupent la TPS et la TVQ des pièces ; le rapport, contrôle seulement",
                    .Page = "~/ValiderRapportTaxes.aspx",
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
                    .Source = "aucune : QuickBooks n'expose pas la paie par son API",
                    .Destination = "staging.PaieEmployeImport, PaieLotImport, PaieImport, PaieLigneImport",
                    .Page = "~/ValiderPaie.aspx",
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
                }
            }
        End Get
    End Property
    ''' <summary>
    ''' Les listes : clients, fournisseurs, produits et services. Un même écran,
    ''' trois usages — lire le fichier ou l'extraire par l'IA, rapprocher de ce
    ''' qui existe, créer ce qui est nouveau.
    ''' </summary>
    Private ReadOnly Property Autres As List(Of Poste)
        Get
            Return New List(Of Poste) From {
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
            }
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

#Region "Rendu"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        PreparerVidage()

        If IsPostBack Then Return

        litConnexion.Text = Rendre(Connexion)
        litParcours.Text = Rendre(Parcours)
        litAutres.Text = Rendre(Autres)
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
