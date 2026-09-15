Imports System.Globalization

''' <summary>Une colonne du CSV : un chemin dans l'objet Codat, ou un calcul.</summary>
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
''' Une extraction = un bouton. Elle lit un type de données Codat — ou un
''' rapport — et produit un fichier, deux quand le type a des lignes : l'entête
''' (Factures.csv) et le détail (Factures_Lignes.csv).
''' </summary>
Public Class Extraction
    Public Property Categorie As String
    Public Property Libelle As String
    Public Property Fichier As String

    ''' <summary>Le nom du type de données chez Codat (invoices, customers…), tel que dataStatus le connaît.</summary>
    Public Property TypeDonnees As String = ""

    ''' <summary>
    ''' Chemin sous /companies/{companyId}/ : « data/invoices ». Les types liés
    ''' à une connexion commencent par « connections/{connectionId}/ ».
    ''' </summary>
    Public Property Chemin As String = ""

    ''' <summary>Un seul objet plutôt qu'une liste paginée (informations de la société).</summary>
    Public Property Unique As Boolean

    ''' <summary>Le champ de date filtrable par la date de début (issueDate, date, postedOn) ; vide si aucun.</summary>
    Public Property ChampDate As String = ""

    Public Property Colonnes As List(Of Colonne)

    ''' <summary>Le tableau des lignes dans l'objet (lineItems, lines, journalLines) ; vide si aucun.</summary>
    Public Property CheminLignes As String = ""
    Public Property ColonnesLignes As List(Of Colonne)

    Public Property Rapport As GenreRapport = GenreRapport.Aucun

    Public ReadOnly Property ParConnexion As Boolean
        Get
            Return Chemin.StartsWith("connections/")
        End Get
    End Property

    Public ReadOnly Property Fichiers As String
        Get
            If Rapport <> GenreRapport.Aucun Then Return Fichier & "_<date>.csv"
            Return Fichier & ".csv" & If(CheminLignes <> "", " + " & Fichier & "_Lignes.csv", "")
        End Get
    End Property
End Class

''' <summary>
''' Tout ce que l'application sait extraire de Codat, et comment chaque fichier
''' est fait.
'''
''' Les en-têtes de colonnes sont les chemins du modèle de données Codat
''' (customerRef.companyName, lineItems.accountRef.name) : ils sont les mêmes
''' quel que soit le logiciel comptable relié, et se retrouvent tels quels dans
''' la documentation de Codat.
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
    '''   =allocations  les paiements appliqués (payment.id:montant@date)
    '''   =suivi        les catégories de suivi (id:nom)
    ''' </summary>
    Private Function Cols(ParamArray chemins As String()) As List(Of Colonne)
        Dim l As New List(Of Colonne)
        For Each c In chemins
            Select Case c
                Case "@adresses"
                    For Each genre In {"Billing", "Delivery"}
                        For Each champ In {"line1", "line2", "city", "region", "country", "postalCode"}
                            Dim g = genre, ch = champ
                            l.Add(New Colonne($"addresses[{g}].{ch}", Function(n) Adresse(n, g, ch)))
                        Next
                    Next
                Case "=allocations"
                    l.Add(New Colonne("paymentAllocations", AddressOf Allocations))
                Case "=suivi"
                    l.Add(New Colonne("trackingCategoryRefs", Function(n) Paires(JsonChemin.Enfant(n, "trackingCategoryRefs"), "id", "name")))
                Case Else
                    l.Add(New Colonne(c, c))
            End Select
        Next
        Return l
    End Function

    Private Function Plus(ParamArray listes As List(Of Colonne)()) As List(Of Colonne)
        Return listes.SelectMany(Function(x) x).ToList()
    End Function

    ''' <summary>
    ''' Un champ de l'adresse d'un genre donné. Sans adresse de ce genre,
    ''' l'adresse de facturation reprend la première adresse venue — beaucoup de
    ''' logiciels n'en typent aucune.
    ''' </summary>
    Private Function Adresse(n As JsonNode, genre As String, champ As String) As String
        Dim adresses = TryCast(JsonChemin.Enfant(n, "addresses"), JsonArray)
        If adresses Is Nothing OrElse adresses.Count = 0 Then Return ""

        Dim trouvee = adresses.FirstOrDefault(Function(a) String.Equals(JsonChemin.Valeur(a, "type"), genre, StringComparison.OrdinalIgnoreCase))
        If trouvee Is Nothing AndAlso genre = "Billing" Then trouvee = adresses(0)
        Return If(trouvee Is Nothing, "", JsonChemin.Valeur(trouvee, champ))
    End Function

    Private Function Allocations(n As JsonNode) As String
        Dim t = TryCast(JsonChemin.Enfant(n, "paymentAllocations"), JsonArray)
        If t Is Nothing Then Return ""
        Return String.Join(" | ", t.Select(Function(a) JsonChemin.Valeur(a, "payment.id") & ":" &
                                                         JsonChemin.Valeur(a, "allocation.totalAmount") & "@" &
                                                         JsonChemin.Valeur(a, "allocation.allocatedOnDate")))
    End Function

    Private Function Paires(tableau As JsonNode, cle As String, valeur As String) As String
        Dim t = TryCast(tableau, JsonArray)
        If t Is Nothing Then Return ""
        Return String.Join(" | ", t.Select(Function(e) JsonChemin.Valeur(e, cle) & ":" & JsonChemin.Valeur(e, valeur)) _
                                   .Where(Function(s) s <> ":"))
    End Function

#End Region

#Region "Colonnes communes"

    Private Function Suivi() As List(Of Colonne)
        Return Cols("metadata.isDeleted", "modifiedDate", "sourceModifiedDate")
    End Function

    ''' <summary>Les lignes des documents : factures, notes de crédit, factures fournisseurs, commandes.</summary>
    Private Function LignesDocument() As List(Of Colonne)
        Return Cols("lineNumber", "description", "quantity", "unitOfMeasurement", "unitAmount",
                    "discountAmount", "discountPercentage", "subTotal", "taxAmount", "totalAmount",
                    "accountRef.id", "accountRef.name",
                    "taxRateRef.id", "taxRateRef.name", "taxRateRef.effectiveTaxRate",
                    "itemRef.id", "itemRef.name", "=suivi", "isDirectIncome", "isDirectCost")
    End Function

    Private Function LignesReglement() As List(Of Colonne)
        Return Cols("amount", "allocatedOnDate", "links.type", "links.id", "links.amount", "links.currencyRate")
    End Function

#End Region

#Region "Le catalogue"

    Public Function Toutes() As List(Of Extraction)
        Return New List(Of Extraction) From {
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Entreprise", .Fichier = "Entreprise",
                .TypeDonnees = "company", .Chemin = "data/info", .Unique = True,
                .Colonnes = Cols("companyName", "companyLegalName", "accountingPlatformRef", "registrationNumber", "taxNumber",
                                 "baseCurrency", "financialYearStartDate", "ledgerLockDate", "createdDate",
                                 "@adresses", "phoneNumbers.number", "webLinks.url", "sourceUrls", "lastUpdatedUtc")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Plan comptable", .Fichier = "PlanComptable",
                .TypeDonnees = "chartOfAccounts", .Chemin = "data/accounts",
                .Colonnes = Plus(Cols("id", "nominalCode", "name", "description", "fullyQualifiedCategory", "fullyQualifiedName",
                                      "type", "status", "currency", "currentBalance", "isBankAccount"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Clients", .Fichier = "Clients",
                .TypeDonnees = "customers", .Chemin = "data/customers",
                .Colonnes = Plus(Cols("id", "customerName", "contactName", "emailAddress", "phone", "defaultCurrency",
                                      "registrationNumber", "taxNumber", "status", "@adresses",
                                      "contacts.name", "contacts.email"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Fournisseurs", .Fichier = "Fournisseurs",
                .TypeDonnees = "suppliers", .Chemin = "data/suppliers",
                .Colonnes = Plus(Cols("id", "supplierName", "contactName", "emailAddress", "phone", "defaultCurrency",
                                      "registrationNumber", "taxNumber", "status", "@adresses"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Produits et services", .Fichier = "ProduitsServices",
                .TypeDonnees = "items", .Chemin = "data/items",
                .Colonnes = Plus(Cols("id", "code", "name", "type", "itemStatus",
                                      "isInvoiceItem", "invoiceItem.description", "invoiceItem.unitPrice",
                                      "invoiceItem.accountRef.id", "invoiceItem.accountRef.name",
                                      "invoiceItem.taxRateRef.id", "invoiceItem.taxRateRef.name",
                                      "isBillItem", "billItem.description", "billItem.unitPrice",
                                      "billItem.accountRef.id", "billItem.accountRef.name",
                                      "billItem.taxRateRef.id", "billItem.taxRateRef.name"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Taux de taxe", .Fichier = "TauxTaxe",
                .TypeDonnees = "taxRates", .Chemin = "data/taxRates",
                .Colonnes = Plus(Cols("id", "code", "name", "status", "effectiveTaxRate", "totalTaxRate",
                                      "components.name", "components.rate", "components.isCompound"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Modes de paiement", .Fichier = "ModesPaiement",
                .TypeDonnees = "paymentMethods", .Chemin = "data/paymentMethods",
                .Colonnes = Plus(Cols("id", "name", "type", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Catégories de suivi", .Fichier = "CategoriesSuivi",
                .TypeDonnees = "trackingCategories", .Chemin = "data/trackingCategories",
                .Colonnes = Plus(Cols("id", "name", "parentId", "hasChildren", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Journaux", .Fichier = "Journaux",
                .TypeDonnees = "journals", .Chemin = "data/journals",
                .Colonnes = Plus(Cols("id", "journalCode", "name", "type", "parentId", "hasChildren", "status", "createdOn"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Comptes bancaires", .Fichier = "ComptesBancaires",
                .TypeDonnees = "bankAccounts", .Chemin = "connections/{connectionId}/data/bankAccounts",
                .Colonnes = Plus(Cols("id", "accountName", "accountType", "nominalCode", "institution", "sortCode",
                                      "accountNumber", "iBan", "currency", "balance", "availableBalance",
                                      "overdraftLimit", "status"), Suivi())
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Factures clients", .Fichier = "Factures",
                .TypeDonnees = "invoices", .Chemin = "data/invoices", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "invoiceNumber", "customerRef.id", "customerRef.companyName", "issueDate", "dueDate",
                                      "paidOnDate", "currency", "currencyRate", "subTotal", "totalDiscount", "discountPercentage",
                                      "totalTaxAmount", "additionalTaxAmount", "additionalTaxPercentage",
                                      "withholdingTax.name", "withholdingTax.amount", "totalAmount", "amountDue",
                                      "status", "note", "salesOrderRefs.id", "=allocations"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Notes de crédit", .Fichier = "NotesCredit",
                .TypeDonnees = "creditNotes", .Chemin = "data/creditNotes", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "creditNoteNumber", "customerRef.id", "customerRef.companyName", "issueDate",
                                      "allocatedOnDate", "currency", "currencyRate", "subTotal", "totalDiscount",
                                      "totalTaxAmount", "totalAmount", "remainingCredit", "status", "note", "=allocations"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Paiements clients", .Fichier = "PaiementsClients",
                .TypeDonnees = "payments", .Chemin = "data/payments", .ChampDate = "date",
                .Colonnes = Plus(Cols("id", "reference", "customerRef.id", "customerRef.companyName", "date",
                                      "accountRef.id", "accountRef.name", "paymentMethodRef.id", "paymentMethodRef.name",
                                      "currency", "currencyRate", "totalAmount", "note"), Suivi()),
                .CheminLignes = "lines", .ColonnesLignes = LignesReglement()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Commandes clients", .Fichier = "CommandesClients",
                .TypeDonnees = "salesOrders", .Chemin = "data/salesOrders", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "salesOrderNumber", "customerPurchaseOrderNumber", "customerRef.id",
                                      "customerRef.companyName", "issueDate", "expectedDeliveryDate", "status",
                                      "invoicingStatus", "currency", "currencyRate", "subTotal", "totalDiscount",
                                      "totalTaxAmount", "totalAmount", "note"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Revenus directs", .Fichier = "RevenusDirects",
                .TypeDonnees = "directIncomes", .Chemin = "connections/{connectionId}/data/directIncomes", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "reference", "contactRef.id", "contactRef.dataType", "issueDate", "currency",
                                      "currencyRate", "subTotal", "taxAmount", "totalAmount", "note", "=allocations"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Factures fournisseurs", .Fichier = "FacturesFournisseurs",
                .TypeDonnees = "bills", .Chemin = "data/bills", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "reference", "supplierRef.id", "supplierRef.supplierName", "issueDate", "dueDate",
                                      "currency", "currencyRate", "subTotal", "taxAmount", "totalAmount", "amountDue",
                                      "withholdingTax.name", "withholdingTax.amount", "status", "note",
                                      "purchaseOrderRefs.id", "=allocations"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Crédits fournisseurs", .Fichier = "CreditsFournisseurs",
                .TypeDonnees = "billCreditNotes", .Chemin = "data/billCreditNotes", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "billCreditNoteNumber", "supplierRef.id", "supplierRef.supplierName", "issueDate",
                                      "allocatedOnDate", "currency", "currencyRate", "subTotal", "totalDiscount",
                                      "totalTaxAmount", "totalAmount", "remainingCredit", "status", "note", "=allocations"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Paiements fournisseurs", .Fichier = "PaiementsFournisseurs",
                .TypeDonnees = "billPayments", .Chemin = "data/billPayments", .ChampDate = "date",
                .Colonnes = Plus(Cols("id", "reference", "supplierRef.id", "supplierRef.supplierName", "date",
                                      "accountRef.id", "accountRef.name", "paymentMethodRef.id", "paymentMethodRef.name",
                                      "currency", "currencyRate", "totalAmount", "note"), Suivi()),
                .CheminLignes = "lines", .ColonnesLignes = LignesReglement()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Bons de commande", .Fichier = "BonsCommande",
                .TypeDonnees = "purchaseOrders", .Chemin = "data/purchaseOrders", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "purchaseOrderNumber", "supplierRef.id", "supplierRef.supplierName", "issueDate",
                                      "paymentDueDate", "expectedDeliveryDate", "deliveryDate", "status", "currency",
                                      "currencyRate", "subTotal", "totalDiscount", "totalTaxAmount", "totalAmount", "note"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Dépenses directes", .Fichier = "DepensesDirectes",
                .TypeDonnees = "directCosts", .Chemin = "connections/{connectionId}/data/directCosts", .ChampDate = "issueDate",
                .Colonnes = Plus(Cols("id", "reference", "contactRef.id", "contactRef.dataType", "issueDate", "currency",
                                      "currencyRate", "subTotal", "taxAmount", "totalAmount", "note", "=allocations"), Suivi()),
                .CheminLignes = "lineItems", .ColonnesLignes = LignesDocument()
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Écritures de journal", .Fichier = "EcrituresJournal",
                .TypeDonnees = "journalEntries", .Chemin = "data/journalEntries", .ChampDate = "postedOn",
                .Colonnes = Plus(Cols("id", "description", "postedOn", "createdOn", "updatedOn", "journalRef.id", "journalRef.name",
                                      "recordRef.id", "recordRef.dataType"), Suivi()),
                .CheminLignes = "journalLines",
                .ColonnesLignes = Cols("description", "netAmount", "transactionAmount", "currency", "transactionCurrency",
                                       "accountRef.id", "accountRef.name", "contactRef.id", "contactRef.dataType",
                                       "tracking.recordRefs.id", "tracking.recordRefs.dataType")
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Transactions de comptes", .Fichier = "TransactionsComptes",
                .TypeDonnees = "accountTransactions", .Chemin = "connections/{connectionId}/data/accountTransactions", .ChampDate = "date",
                .Colonnes = Plus(Cols("id", "transactionId", "date", "status", "bankAccountRef.id", "bankAccountRef.name",
                                      "currency", "currencyRate", "totalAmount", "note"), Suivi()),
                .CheminLignes = "lines",
                .ColonnesLignes = Cols("description", "amount", "recordRef.id", "recordRef.dataType")
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Virements", .Fichier = "Virements",
                .TypeDonnees = "transfers", .Chemin = "connections/{connectionId}/data/transfers", .ChampDate = "date",
                .Colonnes = Plus(Cols("id", "description", "date", "status",
                                      "from.accountRef.id", "from.accountRef.name", "from.amount", "from.currency",
                                      "to.accountRef.id", "to.accountRef.name", "to.amount", "to.currency",
                                      "contactRef.id", "contactRef.dataType", "depositedRecordRefs.id", "=suivi"), Suivi())
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance âgée clients", .Fichier = "BalanceAgeeClients",
                .TypeDonnees = "invoices", .Rapport = GenreRapport.BalanceAgeeClients
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance âgée fournisseurs", .Fichier = "BalanceAgeeFournisseurs",
                .TypeDonnees = "bills", .Rapport = GenreRapport.BalanceAgeeFournisseurs
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Bilan (mensuel)", .Fichier = "Bilan",
                .TypeDonnees = "balanceSheet", .Rapport = GenreRapport.Bilan
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "État des résultats (mensuel)", .Fichier = "EtatResultats",
                .TypeDonnees = "profitAndLoss", .Rapport = GenreRapport.Resultats
            }
        }
    End Function

#End Region

End Module
