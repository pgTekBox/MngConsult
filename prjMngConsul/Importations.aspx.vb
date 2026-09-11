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
                New Poste With {.Icone = "📉", .Titre = "Balance âgée clients", .Note = 1,
                    .Source = "QuickBooks : A/R Aging Detail",
                    .Destination = "contrôle du solde clients", .Manque = "À faire."},
                New Poste With {.Icone = "📈", .Titre = "Balance âgée fournisseurs", .Note = 1,
                    .Source = "QuickBooks : A/P Aging Detail",
                    .Destination = "contrôle du solde fournisseurs", .Manque = "À faire."},
                New Poste With {.Icone = "🧾", .Titre = "Factures clients ouvertes", .Note = 1,
                    .Source = "QuickBooks : Open Invoices, par ligne",
                    .Destination = "T060Document + T061DocumentLine", .Manque = "À faire."},
                New Poste With {.Icone = "📥", .Titre = "Factures fournisseurs ouvertes", .Note = 1,
                    .Source = "QuickBooks : Unpaid Bills Detail",
                    .Destination = "T060Document, autre type", .Manque = "À faire."},
                New Poste With {.Icone = "💵", .Titre = "Acomptes et règlements partiels", .Note = 1,
                    .Source = "QuickBooks : Transaction List by Customer",
                    .Destination = "T140Reglement + T141ReglementDocument", .Manque = "À faire."},
                New Poste With {.Icone = "🏦", .Titre = "Soldes bancaires", .Note = 1,
                    .Source = "QuickBooks : dernier Reconciliation Report",
                    .Destination = "T142ReleveBancaire", .Manque = "À faire."},
                New Poste With {.Icone = "🔍", .Titre = "Opérations non rapprochées", .Note = 1,
                    .Source = "QuickBooks : Uncleared Transactions",
                    .Destination = "sans quoi le rapprochement suivant est faux", .Manque = "À faire."},
                New Poste With {.Icone = "🧮", .Titre = "Taxes", .Note = 1,
                    .Source = "QuickBooks : Sales Tax Liability",
                    .Destination = "contrôle des comptes de taxes", .Manque = "À faire."},
                New Poste With {.Icone = "📚", .Titre = "Grand livre", .Note = 1,
                    .Source = "QuickBooks : General Ledger",
                    .Destination = "reprise détaillée seulement", .Manque = "À faire."},
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

        If IsPostBack Then Return

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

End Class
