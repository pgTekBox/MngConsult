Imports System.Globalization

''' <summary>Une colonne du CSV : un chemin dans l'objet Apideck, ou un calcul.</summary>
Public Class Colonne
    Public ReadOnly Property Titre As String
    Private ReadOnly _chemin As String
    Private ReadOnly _calcul As Func(Of JsonNode, String)

    Public Sub New(titre As String, chemin As String)
        Me.Titre = titre
        _chemin = chemin
    End Sub

    Public Sub New(titre As String, calcul As Func(Of JsonNode, String))
        Me.Titre = titre
        _calcul = calcul
    End Sub

    Public Function Lire(noeud As JsonNode) As String
        If _calcul IsNot Nothing Then Return _calcul(noeud)
        Return JsonChemin.Valeur(noeud, _chemin)
    End Function
End Class

Public Enum GenreRapport
    Aucun
    BalanceAgeeClients
    BalanceAgeeFournisseurs
    Bilan
    Resultats
End Enum

''' <summary>
''' Une extraction = un bouton. Elle lit une ressource de l'API comptable
''' d'Apideck — ou un rapport — et produit un fichier, deux quand la ressource a
''' des lignes : l'entête (Factures.csv) et le détail (Factures_Lignes.csv).
''' </summary>
Public Class Extraction
    Public Property Categorie As String
    Public Property Libelle As String
    Public Property Fichier As String

    ''' <summary>La ressource sous /accounting/ : invoices, customers…</summary>
    Public Property Ressource As String = ""

    ''' <summary>Un seul objet plutôt qu'une liste (informations de la société).</summary>
    Public Property Unique As Boolean

    ''' <summary>
    ''' Le filtre de date qu'Apideck accepte pour cette ressource, avec {date} à
    ''' remplacer : « filter[start_date]={date} ». Vide : pas de filtre possible.
    ''' </summary>
    Public Property FiltreDate As String = ""

    Public Property Colonnes As List(Of Colonne)

    ''' <summary>Le tableau des lignes dans l'objet (line_items, allocations) ; vide si aucun.</summary>
    Public Property CheminLignes As String = ""
    Public Property ColonnesLignes As List(Of Colonne)

    Public Property Rapport As GenreRapport = GenreRapport.Aucun

    Public ReadOnly Property Fichiers As String
        Get
            If Rapport <> GenreRapport.Aucun Then Return Fichier & "_<date>.csv"
            Return Fichier & ".csv" & If(CheminLignes <> "", " + " & Fichier & "_Lignes.csv", "")
        End Get
    End Property
End Class

''' <summary>
''' Tout ce que l'application sait extraire par Apideck, et comment chaque
''' fichier est fait.
'''
''' Les en-têtes de colonnes sont les chemins du modèle unifié d'Apideck
''' (customer.display_name, ledger_account.nominal_code) : les mêmes quel que
''' soit le logiciel comptable relié, et tels que la documentation d'Apideck les
''' nomme.
''' </summary>
Public Module Catalogue

    Public Const CatReferentiels As String = "Référentiels"
    Public Const CatVentes As String = "Ventes"
    Public Const CatAchats As String = "Achats"
    Public Const CatBanque As String = "Banque et journal"
    Public Const CatRapports As String = "Rapports"

    Public ReadOnly Property Categories As String() = {CatReferentiels, CatVentes, CatAchats, CatBanque, CatRapports}

#Region "Outils de définition"

    ''' <summary>
    ''' Bâtit une liste de colonnes à partir de chemins. Jetons spéciaux :
    '''   @adresses     l'adresse de facturation puis celle de livraison, champ par champ
    '''   @billing_address / @shipping_address   une adresse unique d'un document
    '''   =allocations  les paiements appliqués (id:montant@date)
    '''   =suivi        les catégories de suivi (id:nom)
    ''' </summary>
    Private Function Cols(ParamArray chemins As String()) As List(Of Colonne)
        Dim champs = {"line1", "line2", "city", "state", "postal_code", "country"}
        Dim l As New List(Of Colonne)

        For Each c In chemins
            If c = "@adresses" Then
                For Each genre In {"billing", "shipping"}
                    For Each champ In champs
                        Dim g = genre, ch = champ
                        l.Add(New Colonne($"addresses[{g}].{ch}", Function(n) Adresse(n, g, ch)))
                    Next
                Next
            ElseIf c.StartsWith("@") Then
                For Each champ In champs
                    l.Add(New Colonne(c.Substring(1) & "." & champ, c.Substring(1) & "." & champ))
                Next
            ElseIf c = "=allocations" Then
                l.Add(New Colonne("payment_allocations", Function(n) Paires(JsonChemin.Enfant(n, "payment_allocations"), "id", "allocated_amount", "date")))
            ElseIf c = "=suivi" Then
                l.Add(New Colonne("tracking_categories", Function(n) Paires(JsonChemin.Enfant(n, "tracking_categories"), "id", "name", "")))
            Else
                l.Add(New Colonne(c, c))
            End If
        Next
        Return l
    End Function

    Private Function Plus(ParamArray listes As List(Of Colonne)()) As List(Of Colonne)
        Return listes.SelectMany(Function(x) x).ToList()
    End Function

    ''' <summary>
    ''' Un champ de l'adresse d'un genre donné. Sans adresse de facturation,
    ''' on prend l'adresse principale, puis la première venue.
    ''' </summary>
    Private Function Adresse(n As JsonNode, genre As String, champ As String) As String
        Dim adresses = TryCast(JsonChemin.Enfant(n, "addresses"), JsonArray)
        If adresses Is Nothing OrElse adresses.Count = 0 Then Return ""

        Dim deType = Function(t As String) adresses.FirstOrDefault(Function(a) String.Equals(JsonChemin.Valeur(a, "type"), t, StringComparison.OrdinalIgnoreCase))
        Dim trouvee = deType(genre)
        If trouvee Is Nothing AndAlso genre = "billing" Then trouvee = If(deType("primary"), adresses(0))
        Return If(trouvee Is Nothing, "", JsonChemin.Valeur(trouvee, champ))
    End Function

    Private Function Paires(tableau As JsonNode, cle As String, valeur As String, suffixe As String) As String
        Dim t = TryCast(tableau, JsonArray)
        If t Is Nothing Then Return ""
        Return String.Join(" | ", t.Select(Function(e) JsonChemin.Valeur(e, cle) & ":" & JsonChemin.Valeur(e, valeur) &
                                                         If(suffixe = "", "", "@" & JsonChemin.Valeur(e, suffixe))) _
                                   .Where(Function(s) s.Trim(":"c, "@"c) <> ""))
    End Function

#End Region

#Region "Colonnes communes"

    Private Function Suivi() As List(Of Colonne)
        Return Cols("created_at", "updated_at")
    End Function

    ''' <summary>Les lignes des documents de vente et d'achat.</summary>
    Private Function LignesDocument() As List(Of Colonne)
        Return Cols("id", "line_number", "type", "code", "description", "quantity", "unit_of_measure", "unit_price",
                    "discount_percentage", "discount_amount", "tax_amount", "total_amount", "service_date",
                    "item.id", "item.code", "item.name",
                    "ledger_account.id", "ledger_account.nominal_code", "ledger_account.name",
                    "tax_rate.id", "tax_rate.code", "tax_rate.name", "tax_rate.rate",
                    "customer.id", "customer.display_name", "=suivi", "memo")
    End Function

    ''' <summary>Les lignes d'un paiement : le document réglé et le montant qui lui est appliqué.</summary>
    Private Function LignesReglement() As List(Of Colonne)
        Return Cols("id", "type", "code", "amount", "allocation_id")
    End Function

#End Region

#Region "Le catalogue"

    Public Function Toutes() As List(Of Extraction)
        Return New List(Of Extraction) From {
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Entreprise", .Fichier = "Entreprise", .Ressource = "company-info", .Unique = True,
                .Colonnes = Plus(Cols("id", "company_name", "legal_name", "status", "country", "currency", "language",
                                      "sales_tax_number", "sales_tax_enabled", "fiscal_year_start_month", "company_start_date",
                                      "accounting_method", "@adresses", "phone_numbers.number", "emails.email"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Plan comptable", .Fichier = "PlanComptable", .Ressource = "ledger-accounts",
                .Colonnes = Plus(Cols("id", "display_id", "nominal_code", "code", "name", "fully_qualified_name", "description",
                                      "classification", "type", "sub_type", "level", "header", "sub_account",
                                      "parent_account.id", "parent_account.name", "currency", "opening_balance", "current_balance",
                                      "tax_type", "tax_rate.id", "tax_rate.name", "active", "status", "last_reconciliation_date"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Clients", .Fichier = "Clients", .Ressource = "customers",
                .Colonnes = Plus(Cols("id", "display_id", "display_name", "company_name", "title", "first_name", "middle_name",
                                      "last_name", "individual", "emails.email", "phone_numbers.number", "websites.url",
                                      "@adresses", "tax_number", "taxable", "tax_rate.id", "tax_rate.name", "currency",
                                      "terms", "terms_id", "payment_method", "parent.id", "parent.name",
                                      "account.id", "account.name", "status", "notes"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Fournisseurs", .Fichier = "Fournisseurs", .Ressource = "suppliers",
                .Colonnes = Plus(Cols("id", "display_id", "display_name", "company_name", "title", "first_name", "last_name",
                                      "individual", "emails.email", "phone_numbers.number", "websites.url", "@adresses",
                                      "tax_number", "taxable", "tax_rate.id", "tax_rate.name", "currency", "terms", "terms_id",
                                      "payment_method", "account.id", "account.name", "status", "notes"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Produits et services", .Fichier = "ProduitsServices", .Ressource = "invoice-items",
                .Colonnes = Plus(Cols("id", "display_id", "code", "name", "description", "type", "sold", "purchased", "tracked",
                                      "taxable", "quantity", "unit_price", "currency", "inventory_date",
                                      "sales_details.unit_price", "sales_details.tax_inclusive", "sales_details.tax_rate.id",
                                      "purchase_details.unit_price", "purchase_details.tax_inclusive", "purchase_details.tax_rate.id",
                                      "income_account.id", "income_account.name", "expense_account.id", "expense_account.name",
                                      "asset_account.id", "asset_account.name", "active"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Taux de taxe", .Fichier = "TauxTaxe", .Ressource = "tax-rates",
                .Colonnes = Plus(Cols("id", "display_id", "code", "name", "description", "type", "effective_tax_rate", "total_tax_rate",
                                      "components.name", "components.rate", "components.compound",
                                      "tax_payable_account_id", "tax_remitted_account_id", "report_tax_type", "country", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Modes de paiement", .Fichier = "ModesPaiement", .Ressource = "payment-methods",
                .Colonnes = Plus(Cols("id", "name", "type", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Catégories de suivi", .Fichier = "CategoriesSuivi", .Ressource = "tracking-categories",
                .Colonnes = Plus(Cols("id", "code", "name", "parent_id", "parent_name", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Emplacements", .Fichier = "Emplacements", .Ressource = "locations",
                .Colonnes = Plus(Cols("id", "display_id", "name", "company_name", "parent_id", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Départements", .Fichier = "Departements", .Ressource = "departments",
                .Colonnes = Plus(Cols("id", "code", "name", "parent_id", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Comptes bancaires", .Fichier = "ComptesBancaires", .Ressource = "bank-accounts",
                .Colonnes = Plus(Cols("id", "display_id", "name", "account_type", "account_number", "bank_name", "currency",
                                      "balance", "available_balance", "ledger_account.id", "ledger_account.name", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Factures clients", .Fichier = "Factures", .Ressource = "invoices",
                .Colonnes = Plus(Cols("id", "display_id", "number", "type", "customer.id", "customer.display_name", "invoice_date",
                                      "due_date", "terms", "po_number", "reference", "status", "currency", "currency_rate",
                                      "tax_inclusive", "sub_total", "total_tax", "tax_code", "discount_percentage", "discount_amount",
                                      "total", "balance", "deposit", "customer_memo", "@billing_address", "@shipping_address",
                                      "ledger_account.id", "=allocations", "=suivi"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Notes de crédit", .Fichier = "NotesCredit", .Ressource = "credit-notes",
                .Colonnes = Plus(Cols("id", "number", "type", "customer.id", "customer.display_name", "date_issued", "date_paid",
                                      "reference", "status", "currency", "currency_rate", "tax_inclusive", "sub_total", "total_tax",
                                      "total_amount", "balance", "remaining_credit", "note", "account.id", "account.name",
                                      "allocations.id", "allocations.amount", "=suivi"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Reçus de vente", .Fichier = "RecusVente", .Ressource = "sales-receipts",
                .Colonnes = Plus(Cols("id", "number", "customer.id", "customer.display_name", "transaction_date", "reference",
                                      "currency", "currency_rate", "tax_inclusive", "sub_total", "total_tax", "total_amount",
                                      "payment_method", "payment_method_reference", "account.id", "account.name",
                                      "note", "customer_memo", "@billing_address", "=suivi"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Paiements", .Fichier = "Paiements", .Ressource = "payments",
                .Colonnes = Plus(Cols("id", "display_id", "number", "type", "status", "transaction_date", "reference",
                                      "customer.id", "customer.display_name", "supplier.id", "supplier.display_name",
                                      "currency", "currency_rate", "total_amount", "payment_method", "payment_method_reference",
                                      "account.id", "account.name", "accounts_receivable_account_id", "reconciled", "note"), Suivi()),
                .CheminLignes = "allocations", .ColonnesLignes = LignesReglement()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Remboursements", .Fichier = "Remboursements", .Ressource = "refunds",
                .Colonnes = Plus(Cols("id", "number", "type", "status", "customer.id", "customer.display_name", "refund_date",
                                      "reference", "currency", "currency_rate", "sub_total", "total_tax", "total_amount",
                                      "payment_method", "account.id", "account.name", "note"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Soumissions", .Fichier = "Soumissions", .Ressource = "quotes",
                .Colonnes = Plus(Cols("id", "number", "status", "customer.id", "customer.display_name", "quote_date", "expiry_date",
                                      "reference", "invoice_id", "currency", "currency_rate", "sub_total", "total_tax", "total",
                                      "customer_memo", "@billing_address"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Factures fournisseurs", .Fichier = "FacturesFournisseurs", .Ressource = "bills",
                .FiltreDate = "filter[billed_since]={datetime}",
                .Colonnes = Plus(Cols("id", "display_id", "bill_number", "supplier.id", "supplier.display_name", "bill_date",
                                      "due_date", "paid_date", "po_number", "reference", "terms", "status", "currency",
                                      "currency_rate", "tax_inclusive", "sub_total", "total_tax", "total", "balance", "deposit",
                                      "tax_code", "notes", "ledger_account.id", "ledger_account.name", "=allocations", "=suivi"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Crédits fournisseurs", .Fichier = "CreditsFournisseurs", .Ressource = "bill-credit-notes",
                .Colonnes = Plus(Cols("id", "number", "type", "supplier.id", "supplier.display_name", "date_issued", "date_paid",
                                      "reference", "status", "currency", "currency_rate", "tax_inclusive", "sub_total", "total_tax",
                                      "total_amount", "balance", "remaining_credit", "note", "account.id", "account.name",
                                      "allocations.id", "allocations.amount", "=suivi"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Paiements fournisseurs", .Fichier = "PaiementsFournisseurs", .Ressource = "bill-payments",
                .Colonnes = Plus(Cols("id", "display_id", "number", "type", "status", "transaction_date", "reference",
                                      "supplier.id", "supplier.display_name", "currency", "currency_rate", "total_amount",
                                      "payment_method", "payment_method_reference", "account.id", "account.name", "reconciled", "note"), Suivi()),
                .CheminLignes = "allocations", .ColonnesLignes = LignesReglement()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Dépenses et chèques", .Fichier = "Depenses", .Ressource = "expenses",
                .Colonnes = Plus(Cols("id", "display_id", "number", "type", "status", "transaction_date", "reference",
                                      "account.id", "account.name", "supplier.id", "supplier.display_name", "payment_type",
                                      "currency", "currency_rate", "tax_inclusive", "sub_total", "total_tax", "total_amount",
                                      "memo", "=suivi"), Suivi()),
                .CheminLignes = "line_items",
                .ColonnesLignes = Cols("id", "line_number", "type", "description", "quantity", "unit_price", "tax_amount", "total_amount",
                                       "account.id", "account.name", "item.id", "item.name", "tax_rate.id", "tax_rate.name",
                                       "customer.id", "customer.display_name", "department.name", "location.name", "rebilling.rebillable", "=suivi")
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Bons de commande", .Fichier = "BonsCommande", .Ressource = "purchase-orders",
                .Colonnes = Plus(Cols("id", "display_id", "po_number", "reference", "status", "supplier.id", "supplier.display_name",
                                      "issued_date", "delivery_date", "expected_arrival_date", "due_date", "currency", "currency_rate",
                                      "tax_inclusive", "sub_total", "total_tax", "total", "memo", "notes", "@shipping_address"), Suivi()),
                .CheminLignes = "line_items", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Écritures de journal", .Fichier = "EcrituresJournal", .Ressource = "journal-entries",
                .FiltreDate = "filter[start_date]={date}",
                .Colonnes = Plus(Cols("id", "display_id", "number", "title", "posted_at", "status", "currency", "currency_rate",
                                      "memo", "journal_symbol", "tax_type", "tax_code", "tax_inclusive", "source_type", "source_id", "=suivi"), Suivi()),
                .CheminLignes = "line_items",
                .ColonnesLignes = Cols("id", "line_number", "type", "description", "sub_total", "tax_amount", "total_amount",
                                       "base_currency_amount", "ledger_account.id", "ledger_account.nominal_code", "ledger_account.name",
                                       "tax_rate.id", "tax_rate.name", "customer.id", "customer.display_name",
                                       "supplier.id", "supplier.display_name", "department_id", "location_id", "=suivi")
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Transactions du grand livre", .Fichier = "TransactionsGrandLivre", .Ressource = "general-ledger-transactions",
                .Colonnes = Plus(Cols("id", "posted_at", "source_type", "source_id", "number", "reference", "currency",
                                      "currency_rate", "memo"), Suivi()),
                .CheminLignes = "line_items",
                .ColonnesLignes = Cols("id", "line_number", "type", "description", "net_amount", "tax_amount",
                                       "ledger_account.id", "ledger_account.nominal_code", "ledger_account.name",
                                       "tax_rate.id", "tax_rate.name", "=suivi")
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Journaux", .Fichier = "Journaux", .Ressource = "journals",
                .Colonnes = Plus(Cols("id", "code", "name", "description", "type", "currency", "default_account.id", "blocked"), Suivi())
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance âgée clients (détail)", .Fichier = "BalanceAgeeClients",
                .Ressource = "aged-debtors", .Rapport = GenreRapport.BalanceAgeeClients
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance âgée fournisseurs (détail)", .Fichier = "BalanceAgeeFournisseurs",
                .Ressource = "aged-creditors", .Rapport = GenreRapport.BalanceAgeeFournisseurs
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Bilan", .Fichier = "Bilan",
                .Ressource = "balance-sheet", .Rapport = GenreRapport.Bilan
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "État des résultats", .Fichier = "EtatResultats",
                .Ressource = "profit-and-loss", .Rapport = GenreRapport.Resultats
            }
        }
    End Function

#End Region

End Module
