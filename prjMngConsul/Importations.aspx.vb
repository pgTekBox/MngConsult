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
            Return New List(Of Poste) From {
                New Poste With {.Icone = "💵", .Titre = "Acomptes et règlements partiels", .Note = 1,
                    .Source = "QuickBooks : Transaction List by Customer",
                    .Destination = "T140Reglement + T141ReglementDocument", .Manque = "À faire."},
                New Poste With {.Icone = "🏦", .Titre = "Soldes bancaires", .Note = 1,
                    .Source = "QuickBooks : dernier Reconciliation Report",
                    .Destination = "T142ReleveBancaire", .Manque = "À faire."},
                New Poste With {.Icone = "🔍", .Titre = "Opérations non rapprochées", .Note = 1,
                    .Source = "QuickBooks : Uncleared Transactions",
                    .Destination = "sans quoi le rapprochement suivant est faux", .Manque = "À faire."},
                New Poste With {.Icone = "📦", .Titre = "Inventaire", .Note = 1,
                    .Source = "QuickBooks : Inventory Valuation Summary",
                    .Destination = "si vous tenez un inventaire permanent", .Manque = "À faire."}
            }
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
        litAVenir.Text = Rendre(AVenir)

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
